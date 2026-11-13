import { Op } from "sequelize";
import { ChatLoad, ChatTrip, ChatTripEvent, ChatTripProblem, ChatTripStop, LoadType } from "../../models/ChatTrip";
import { UserProfile } from "../../models/UserProfile";
import Role from "../../models/Role";
import { Message } from "../../models/Message";
import { loadsOfMessage } from "./messageLoads";
import { byLeg, refreshLoadStatus } from "./legs";
import { conflictsFor, yardVisitsOfLoad } from "./equipment";
import { deriveType, endLegNow, historyOf, segmentsOf } from "./loadControl";
import { documentsOf } from "./paperwork";
import { truckOfGroup } from "./truckGroup";
import { trackToken } from "./publicTracking";
import { parseLoad } from "./parseLoad";
import { Actor, announce, cleanInvoice, createTrip, driverOfTruck, editTrip, record, sendLoad, setInvoice, StopInput, syncPriced, TripError, TripInput } from "./tripService";

// Loads (Loads screen): one load, tracked by its invoice #, moved by one or more legs —
//   direct        pickup → delivery
//   via_yard      pickup → our yard · yard → delivery (same or another driver / truck / trailer)
//   relay         pickup → meet point · meet point → delivery (trailer changes hands)
//   trailer_move  move a trailer from → to
// Each leg is a normal trip (tripService): the driver app, chat messages, live ETA and problems work
// per leg. Route List entries are on hold for loads with more than one leg.

export const LOAD_TYPES: LoadType[] = ["direct", "via_yard", "relay", "trailer_move"];

export interface LoadInput {
  type?: LoadType;
  invoiceNo?: string | null;
  notes?: string | null;
  legs: TripInput[];
}

const legInclude = [
  { model: ChatTripStop, as: "stops" },
  { model: ChatTripEvent, as: "events" },
  { model: ChatTripProblem, as: "problems" },
];

/** Where legs drop trailers at our yard: the last yard stop used, or YARD_* settings. */
export async function defaultYardStop(): Promise<StopInput> {
  const last = await ChatTripStop.findOne({ where: { type: "yard" }, order: [["id", "DESC"]] });
  if (last) return { type: "yard", name: last.name, street: last.street, city: last.city, state: last.state, zip: last.zip };
  return {
    type: "yard",
    name: process.env.YARD_NAME || "US CITY LINK YARD",
    street: process.env.YARD_STREET || null,
    city: process.env.YARD_CITY || null,
    state: process.env.YARD_STATE || null,
    zip: process.env.YARD_ZIP || null,
  };
}

/** A leg that hands over (yard / meet point) starts the next leg at the same place. */
function chainStops(legs: TripInput[]): TripInput[] {
  return legs.map((leg, i) => {
    if (i === 0) return leg;
    const prevLast = legs[i - 1].stops[legs[i - 1].stops.length - 1];
    if (!prevLast || (prevLast.type !== "yard" && prevLast.type !== "switch")) return leg;
    const first = leg.stops[0];
    const same = first && first.type === prevLast.type && (first.city || "").trim().toUpperCase() === (prevLast.city || "").trim().toUpperCase();
    return same ? leg : { ...leg, stops: [{ ...prevLast, appointment: null }, ...leg.stops] };
  });
}

/** "Truck 23865 is on L0047 (rolling)" — kept on the leg so dispatch sees it was chosen anyway. */
async function conflictNotes(leg: TripInput, loadId: number | null): Promise<string[]> {
  const conflicts = await conflictsFor({
    truckNumber: leg.truckNumber,
    trailerNumbers: leg.trailerNumbers,
    driverProfileIds: [leg.driverProfileId, leg.teamDriverProfileId].filter(Boolean) as string[],
    loadId,
  });
  return conflicts
    .filter((c) => c.severity === "on_load")
    .map((c) => `${c.label} is on ${c.leg.tripNo || `trip ${c.leg.tripId}`} (${c.leg.status}) — chosen anyway`);
}

export async function createLoad(input: LoadInput, actor: Actor, opts: { send?: boolean } = {}) {
  const type: LoadType = LOAD_TYPES.includes(input.type as LoadType) ? (input.type as LoadType) : "direct";
  if (!input.legs?.length) throw new TripError("Add at least one leg");
  const legs = chainStops(input.legs);
  const invoice = cleanInvoice(input.invoiceNo);

  const load = await ChatLoad.create({
    type,
    invoice_no: invoice,
    notes: input.notes?.trim() || null,
    status: "scheduled",
    created_by: actor.id || null,
    created_by_name: actor.name || null,
  });
  const created: number[] = [];
  try {
    let loadNo: string | null = null;
    for (let i = 0; i < legs.length; i++) {
      const leg = legs[i];
      const notes = await conflictNotes(leg, null);
      const trip = await createTrip(
        { ...leg, invoiceNo: invoice, allowNoDriver: i > 0, reviewNotes: [...(leg.reviewNotes || []), ...notes], source: "form" },
        actor,
        { send: false, quiet: i === 0 && !!opts.send, leg: { loadId: load.id, legNo: i + 1, loadNo } }
      );
      if (!trip) throw new TripError("Could not save the leg", 500);
      created.push(trip.id);
      if (i === 0) {
        loadNo = trip.trip_no;
        await load.update({ load_no: loadNo });
      }
    }
  } catch (err) {
    // All or nothing: take back the legs already saved
    if (created.length) {
      await ChatTripEvent.destroy({ where: { chat_trip_id: created } });
      await ChatTripStop.destroy({ where: { chat_trip_id: created } });
      await ChatTrip.destroy({ where: { id: created } });
    }
    await load.destroy();
    throw err;
  }
  if (opts.send) await sendLoad(created[0], actor);
  await refreshLoadStatus(load.id);
  return getLoad(load.id);
}

/** Add one more leg at the end (e.g. the load goes through the yard again). */
export async function addLeg(loadId: number, leg: TripInput, actor: Actor) {
  const load = await ChatLoad.findByPk(loadId);
  if (!load) throw new TripError("Load not found", 404);
  const legs = byLeg(await ChatTrip.findAll({ where: { load_id: loadId }, include: [{ model: ChatTripStop, as: "stops" }] }));
  const last = legs[legs.length - 1];
  if (last && ["completed", "routed"].includes(last.status)) throw new TripError("This load is completed");
  const lastStop = last ? [...(last.stops || [])].sort((a, b) => a.seq - b.seq).pop() : null;
  const [chained] = chainStops([
    { stops: lastStop ? [{ type: lastStop.type as StopInput["type"], name: lastStop.name, street: lastStop.street, city: lastStop.city, state: lastStop.state, zip: lastStop.zip }] : [] },
    leg,
  ]).slice(1);
  const notes = await conflictNotes(leg, loadId);
  await createTrip(
    { ...chained, invoiceNo: load.invoice_no, allowNoDriver: true, reviewNotes: [...(leg.reviewNotes || []), ...notes], source: "form" },
    actor,
    { leg: { loadId, legNo: (last?.leg_no || 0) + 1, loadNo: load.load_no } }
  );
  await refreshLoadStatus(loadId);
  return getLoad(loadId);
}

export async function updateLoad(id: number, input: { invoiceNo?: string | null; notes?: string | null; type?: LoadType }, actor: Actor) {
  const load = await ChatLoad.findByPk(id);
  if (!load) throw new TripError("Load not found", 404);
  const changes: Record<string, any> = {};
  if (input.notes !== undefined) changes.notes = input.notes?.trim() || null;
  if (input.type && LOAD_TYPES.includes(input.type)) changes.type = input.type;
  if (Object.keys(changes).length) await load.update(changes);
  if (input.invoiceNo !== undefined) {
    const first = await ChatTrip.findOne({ where: { load_id: id }, order: [["leg_no", "ASC"]] });
    if (first) await setInvoice(first, input.invoiceNo, actor);
    else await load.update({ invoice_no: cleanInvoice(input.invoiceNo) });
  }
  return getLoad(id);
}

/** Put a driver / truck / trailer on a leg (often one waiting in the yard), and send it when it can go. */
export async function assignLeg(
  loadId: number,
  legId: number,
  input: { driverProfileId?: string | null; truckNumber?: string | null; teamDriverProfileId?: string | null; trailerNumbers?: string[]; send?: boolean },
  actor: Actor
) {
  const leg = await ChatTrip.findOne({ where: { id: legId, load_id: loadId } });
  if (!leg) throw new TripError("Leg not found", 404);
  if (!input.driverProfileId && !input.truckNumber && !leg.driver_profile_id) throw new TripError("Choose a driver or a truck");
  const notes = await conflictNotes({ ...input, stops: [] }, loadId);
  await editTrip(legId, { ...input, stops: undefined } as any, actor, { quiet: !!input.send });
  if (notes.length) {
    const fresh = await ChatTrip.findByPk(legId);
    await fresh?.update({ needs_review: true, review_notes: [fresh.review_notes, ...notes].filter(Boolean).join("\n") });
  }
  if (input.send) await sendLoad(legId, actor);
  await refreshLoadStatus(loadId);
  return getLoad(loadId);
}

// ---------- reading ----------

async function driverNames(legs: ChatTrip[]) {
  const ids = [...new Set(legs.map((l) => l.driver_profile_id).filter(Boolean))] as string[];
  const profiles = ids.length ? await UserProfile.findAll({ where: { id: ids }, attributes: ["id", "username"] }) : [];
  return Object.fromEntries(profiles.map((p) => [p.id, p.username]));
}

/** Delivered vs the appointment and vs the ETA the leg had when it went Rolling. */
export function deliveryTiming(legs: ChatTrip[]) {
  const live = byLeg(legs).filter((l) => l.status !== "cancelled");
  const last = live[live.length - 1];
  if (!last) return null;
  const stop = [...(last.stops || [])].sort((a, b) => a.seq - b.seq).pop();
  const deliveredAt = last.ended_at ? new Date(last.ended_at) : null;
  const appointmentAt = stop?.appointment_at ? new Date(stop.appointment_at) : null;
  const etaAt = last.planned_eta_at ? new Date(last.planned_eta_at) : null;
  const diff = (a: Date | null, b: Date | null) => (a && b ? Math.round((a.getTime() - b.getTime()) / 60000) : null);
  return {
    deliveredAt,
    appointmentAt,
    etaAt,
    /** + late / − early against the appointment */
    lateMinutes: diff(deliveredAt, appointmentAt),
    /** + later / − earlier than the ETA at Rolling */
    etaOffMinutes: diff(deliveredAt, etaAt),
    /** The ETA at Rolling against the appointment (was it already going to be late?) */
    etaVsAppointmentMinutes: diff(etaAt, appointmentAt),
  };
}

export async function getLoad(id: number) {
  const load = await ChatLoad.findByPk(id);
  if (!load) throw new TripError("Load not found", 404);
  await trackToken(load); // the shipper's tracking link (older loads get one now)
  const legs = byLeg(
    await ChatTrip.findAll({
      where: { load_id: id },
      include: legInclude,
      order: [
        [{ model: ChatTripStop, as: "stops" }, "seq", "ASC"],
        [{ model: ChatTripEvent, as: "events" }, "happened_at", "ASC"],
      ] as any,
    })
  );
  await syncPriced(legs);
  const visits = await yardVisitsOfLoad(legs).catch((e) => {
    console.warn("[loads] yard visits:", e?.message || e);
    return [];
  });
  const names = await driverNames(legs);
  const { segments, totals } = await segmentsOf(legs, names);
  return {
    load,
    legs,
    segments,
    milesTotals: totals,
    history: historyOf(legs),
    documents: await documentsOf(legs),
    driverNames: names,
    yardVisits: visits,
    yardMinutes: visits.reduce((a, v) => a + v.minutes, 0),
    timing: deliveryTiming(legs),
  };
}

export const LOAD_TABS: Record<string, string[]> = {
  transfer: ["transfer"],
  waiting: ["waiting"],
  scheduled: ["scheduled"],
  active: ["active"],
  delivered: ["delivered"],
  completed: ["completed"],
  cancelled: ["cancelled"],
};

export async function listLoads(query: { status?: string; q?: string; page?: number; limit?: number }) {
  const where: any = {};
  if (query.status) where.status = { [Op.in]: String(query.status).split(",") };
  const q = String(query.q || "").trim();
  if (q) {
    const like = { [Op.like]: `%${q}%` };
    const drivers = await UserProfile.findAll({ where: { username: like }, attributes: ["id"] });
    const legHits = await ChatTrip.findAll({
      where: {
        [Op.or]: [
          { truck_number: like },
          { trailer_numbers: like },
          { trip_no: like },
          { invoice_no: like },
          ...(drivers.length ? [{ driver_profile_id: drivers.map((d) => d.id) }] : []),
        ],
      },
      attributes: ["load_id"],
      limit: 500,
    });
    where[Op.or] = [{ invoice_no: like }, { load_no: like }, { id: [...new Set(legHits.map((l) => l.load_id).filter(Boolean))] }];
  }
  const page = Math.max(1, Number(query.page) || 1);
  const limit = Math.min(100, Math.max(1, Number(query.limit) || 30));
  const { rows, count } = await ChatLoad.findAndCountAll({
    where,
    include: [{ model: ChatTrip, as: "legs", include: [{ model: ChatTripStop, as: "stops" }] }],
    order: [
      // Needs dispatch first: a driver waiting, then a load waiting in the yard
      [ChatLoad.sequelize!.literal("ChatLoad.status = 'waiting'"), "DESC"],
      [ChatLoad.sequelize!.literal("ChatLoad.status = 'transfer'"), "DESC"],
      ["id", "DESC"],
      [{ model: ChatTrip, as: "legs" }, "leg_no", "ASC"],
      [{ model: ChatTrip, as: "legs" }, { model: ChatTripStop, as: "stops" }, "seq", "ASC"],
    ] as any,
    distinct: true,
    limit,
    offset: (page - 1) * limit,
  });
  const legs = rows.flatMap((r) => r.legs || []);
  await syncPriced(legs);
  // Priced legs changed status: keep the loads in step
  for (const r of rows) {
    const fresh = await refreshLoadStatus(r.id);
    if (fresh) r.status = fresh.status;
  }
  const counts = Object.fromEntries(
    ((await ChatLoad.count({ group: ["status"] })) as unknown as { status: string; count: number }[]).map((c) => [c.status, Number(c.count)])
  );
  return { loads: rows, total: count, page, counts, driverNames: await driverNames(legs) };
}

// ---------- simple loads: the Load # decides the legs ----------
//
// Dispatch adds a plain load with its own Load # (= invoice #). The same Load # again — another
// driver / truck / trailer, typed, pasted or from the form — is the next leg of that load. The type
// (direct / via yard / transfer) follows from the legs. Before ending anything dispatch is asked:
// the previous leg of this load still open, or the driver already on another load.

const OPEN_LEG = ["scheduled", "offered", "planned", "accepted", "started", "rolling", "on_hold"];
/** The driver has a load on their app (sent, not delivered) */
const ON_DRIVER = ["planned", "accepted", "started", "rolling", "on_hold"];
const SAME_LOAD_DAYS = 60;
/** Saved / lined up, not sent to a driver yet */
const NOT_SENT = ["scheduled", "offered"];

/** The load number exactly as staff typed it (a leading "#" and spaces dropped, upper case) */
export const cleanLoadNo = (v?: string | null) =>
  String(v || "")
    .trim()
    .replace(/^#/, "")
    .toUpperCase()
    .slice(0, 64) || null;

/** dispatch has to answer before this can go ahead (the form asks and sends again) */
export class NeedsAnswer extends TripError {
  constructor(
    public needs: "endPrevious" | "driverBusy" | "replaceLinedUp",
    public info: Record<string, any>,
    message: string
  ) {
    super(message, 409);
  }
}

export async function findLoadByNo(no: string): Promise<ChatLoad | null> {
  return ChatLoad.findOne({
    // The same number as typed by staff — nothing added or removed
    where: { invoice_no: no, status: { [Op.ne]: "cancelled" }, updated_at: { [Op.gte]: new Date(Date.now() - SAME_LOAD_DAYS * 86400000) } },
    order: [["id", "DESC"]],
  });
}

async function legBrief(l: ChatTrip | null) {
  if (!l) return null;
  const stops = l.stops || (await ChatTripStop.findAll({ where: { chat_trip_id: l.id } }));
  const sorted = [...stops].sort((a, b) => a.seq - b.seq);
  const name = l.driver_profile_id ? (await UserProfile.findByPk(l.driver_profile_id))?.username || "Driver" : null;
  const where = (s?: ChatTripStop) => (s ? [s.city, s.state].filter(Boolean).join(", ") || s.name || "—" : "—");
  return {
    tripId: l.id,
    loadId: l.load_id,
    legNo: l.leg_no,
    tripNo: l.trip_no,
    status: l.status,
    open: OPEN_LEG.includes(l.status),
    driverProfileId: l.driver_profile_id,
    driverName: name,
    truck: l.truck_number,
    trailers: l.trailer_numbers,
    from: where(sorted[0]),
    to: where(sorted[sorted.length - 1]),
  };
}

/** The load / trip the driver has on their app now (sent, not delivered), not counting [exceptLoad] */
async function driverCurrent(profileId: string | null | undefined, exceptLoad?: number | null) {
  if (!profileId) return null;
  return ChatTrip.findOne({
    where: { driver_profile_id: profileId, status: { [Op.in]: ON_DRIVER }, ...(exceptLoad ? { load_id: { [Op.ne]: exceptLoad } } : {}) },
    order: [["sent_at", "DESC"], ["id", "DESC"]],
  });
}

/** Add-load form: what the Load # means (new load, or leg N after …) and whether the driver is busy. */
export async function lookupLoad(no: string | null | undefined, driverProfileId?: string | null) {
  const loadNo = cleanLoadNo(no);
  const load = loadNo ? await findLoadByNo(loadNo) : null;
  const legs = load ? byLeg(await ChatTrip.findAll({ where: { load_id: load.id, status: { [Op.ne]: "cancelled" } }, include: [{ model: ChatTripStop, as: "stops" }] })) : [];
  const last = legs[legs.length - 1] || null;
  // The same Load # already lined up (not sent): sending it again replaces that copy
  const linedUp = last && NOT_SENT.includes(last.status) ? last : null;
  const prev = linedUp ? legs[legs.length - 2] || null : last;
  const busy = await driverCurrent(driverProfileId, load?.id);
  return {
    loadNo,
    load: load ? { id: load.id, loadNo: load.load_no, invoiceNo: load.invoice_no, type: load.type, status: load.status, legs: legs.length } : null,
    nextLegNo: linedUp ? linedUp.leg_no : legs.length + 1,
    prev: await legBrief(prev),
    linedUp: await legBrief(linedUp),
    driverBusy: await legBrief(busy),
  };
}

export async function addLoad(
  input: TripInput & { loadNo?: string | null },
  actor: Actor,
  opts: { send?: boolean; endPrevious?: boolean; endDriverCurrent?: boolean; lineUp?: boolean; replace?: boolean; typed?: boolean; fromChat?: boolean; groupId?: string | null; messageId?: string | null } = {}
) {
  const no = cleanLoadNo(input.loadNo ?? input.invoiceNo);
  if (!no && !opts.typed) throw new TripError("Enter the Load # — it's how the load is tracked");
  const load = no ? await findLoadByNo(no) : null;
  const all = load ? byLeg(await ChatTrip.findAll({ where: { load_id: load.id, status: { [Op.ne]: "cancelled" } }, include: [{ model: ChatTripStop, as: "stops" }] })) : [];

  // Who gets it (the truck's driver when only a truck is given)
  const driverId = input.driverProfileId || (input.truckNumber ? (await driverOfTruck(input.truckNumber.trim()))?.id : null) || null;

  // The same Load # is already lined up (saved, not sent): this copy replaces it — asked first, with
  // the driver's current load in the same question (end it & send, or line up after it)
  const last = all[all.length - 1] || null;
  const linedUp = last && NOT_SENT.includes(last.status) ? last : null;
  if (linedUp && !opts.replace) {
    const l = await legBrief(linedUp);
    const current = opts.send ? await legBrief(await driverCurrent(driverId, load?.id)) : null;
    throw new NeedsAnswer("replaceLinedUp", { linedUp: l, current }, `Load ${no} is already lined up${l?.driverName ? ` for ${l.driverName}` : ""} (not sent yet)`);
  }
  const legs = linedUp ? all.slice(0, -1) : all;
  const prev = legs[legs.length - 1] || null;
  const prevOpen = !!prev && OPEN_LEG.includes(prev.status);

  // Ask first — nothing is ended without dispatch saying so
  if (opts.send && prevOpen && !opts.endPrevious) {
    const p = await legBrief(prev);
    throw new NeedsAnswer("endPrevious", { prev: p }, `${p?.driverName || "The driver"} hasn't ended leg ${prev!.leg_no} (#${prev!.trip_no}) yet`);
  }
  const busy = opts.send ? await driverCurrent(driverId, load?.id) : null;
  if (busy && !opts.endDriverCurrent && !opts.lineUp) {
    const b = await legBrief(busy);
    throw new NeedsAnswer("driverBusy", { current: b }, `${b?.driverName || "The driver"} is on load #${b?.tripNo} (${b?.status})`);
  }

  // Answers given: the old lined-up copy goes (kept, cancelled, for the record) …
  if (linedUp) {
    await linedUp.update({ status: "cancelled", queue_pos: null, auto_send: false });
    await record(linedUp, { type: "status", from: linedUp.status, to: "cancelled", actor, note: `Replaced — Load ${no} sent again by ${actor.name || "dispatch"}` });
    announce(linedUp.id);
  }
  // … and end what dispatch said to end
  if (prevOpen && opts.endPrevious) await endLegNow(prev!.id, actor, { handover: true, sendNext: !opts.send || prev!.driver_profile_id !== driverId });
  if (busy && opts.endDriverCurrent) await endLegNow(busy.id, actor, { sendNext: false });

  // A leg that ends at our yard makes the load "via yard"
  const yard = await defaultYardStop();
  const atYard = (s?: ChatTripStop) =>
    !!s && (s.type === "yard" || (!!yard.city && s.city?.toUpperCase() === yard.city?.toUpperCase() && (!yard.name || s.name?.toUpperCase() === yard.name?.toUpperCase())));
  const prevLast = prev ? [...(prev.stops || [])].sort((a, b) => a.seq - b.seq).pop() : undefined;
  if (prev && atYard(prevLast) && !prev.ends_at_yard) await prev.update({ ends_at_yard: true });

  const reviewNotes = [...(input.reviewNotes || [])];
  if (opts.typed && !no) reviewNotes.push("Load # missing — add it so the next leg of this load joins it");
  if (opts.typed && prevOpen) reviewNotes.push(`Leg ${prev!.leg_no} (#${prev!.trip_no}) is still open — end it on the Loads screen`);
  // Dispatch's own message is already in the driver's chat and the load goes out now: the trip IS that
  // message (linked, sent) — nothing is posted again. Lined up / saved loads wait for dispatch instead.
  const goesNow = !!opts.send && (!busy || !!opts.endDriverCurrent);
  const leg = {
    ...input,
    messageId: goesNow && opts.messageId ? opts.messageId : null,
    invoiceNo: no,
    trailerNumbers: input.trailerNumbers?.length ? input.trailerNumbers : prev?.trailer_numbers ? prev.trailer_numbers.split(/,\s*/) : [],
    loadedTrailer: input.loadedTrailer ?? (prev ? true : false),
    allowNoDriver: false,
    reviewNotes,
    source: opts.typed || opts.fromChat ? ("typed" as const) : ("form" as const),
  };

  let target = load;
  if (!target) {
    target = await ChatLoad.create({ load_no: no, invoice_no: no, type: "direct", status: "scheduled", created_by: actor.id || null, created_by_name: actor.name || null });
  }
  let trip: ChatTrip | null;
  try {
    trip = await createTrip(leg, actor, {
      send: false,
      // Sent right away → the full load goes to the chat; lined up → nothing to the driver yet
      quiet: !!opts.typed || (!!opts.send && (!busy || !!opts.endDriverCurrent)),
      leg: { loadId: target.id, legNo: linedUp ? linedUp.leg_no : (legs[legs.length - 1]?.leg_no || 0) + 1, loadNo: target.load_no },
    });
  } catch (err) {
    if (!load) await target.destroy();
    throw err;
  }
  if (!trip) throw new TripError("Could not save the load", 500);
  if (!target.load_no) await target.update({ load_no: trip.trip_no });
  if (atYard([...(trip.stops || [])].sort((a, b) => a.seq - b.seq).pop()) && !trip.ends_at_yard) await trip.update({ ends_at_yard: true });

  await deriveType(target.id);
  // Lined up after the driver's current load: it goes out by itself when they end that one
  if (busy && opts.lineUp && !opts.endDriverCurrent) await trip.update({ auto_send: true });
  // Send now — unless dispatch chose to line it up after the driver's current load
  if (goesNow && !trip.sent_at) await sendLoad(trip.id, actor, { groupId: opts.groupId });
  await refreshLoadStatus(target.id);
  return getLoad(target.id);
}


/**
 * A load pasted in a driver's chat box: the chat box sends it here instead of as a chat message, so
 * nothing reaches the driver until it's really sent. Same questions as Add load (NeedsAnswer → 409);
 * sent → the standard load message; lined up → nothing to the driver yet.
 */
export async function loadFromText(
  text: string,
  driverProfileId: string | null,
  actor: Actor,
  answers: { endPrevious?: boolean; endDriverCurrent?: boolean; lineUp?: boolean; replace?: boolean } = {},
  channelId: string | null = null,
  groupId: string | null = null
) {
  // From a truck chat: the load is for the truck — its main driver, the team mate and the truck number
  const truck = await truckOfGroup(groupId);
  const driverId = driverProfileId || truck?.driver?.id || null;
  if (!driverId) throw new TripError(groupId ? "There's no driver in this truck chat — add the driver to the truck first" : "Open a driver's chat first");
  const parsed = parseLoad(text);
  if (!parsed) throw new TripError("Couldn't read a pickup / delivery address from that text — use Add load", 422);
  if (!parsed.loadNo) throw new TripError('Add a line "LOAD # 1234" — the Load # is required', 422);
  const data = await addLoad(
    {
      loadNo: parsed.loadNo,
      driverProfileId: driverId,
      channelId,
      truckNumber: parsed.truck || truck?.truck || null,
      teamNames: parsed.team,
      ...(truck?.team && !parsed.team.length ? { teamDriverProfileId: truck.team.id } : {}),
      trailerNumbers: parsed.trailers,
      temperature: parsed.temperature,
      loadedTrailer: parsed.loadedTrailer,
      stops: parsed.stops,
      needsReview: parsed.needsReview,
      reviewNotes: parsed.reasons,
      rawText: text,
    },
    actor,
    { send: true, fromChat: true, groupId: truck?.groupId || null, ...answers }
  );
  return { data, loadNo: parsed.loadNo };
}

// ---------- a load pasted / typed straight into a driver's chat ----------
//
// Treated like the form's Send now: Load # required (same number = next leg), the driver gets the
// standard load message and the trip card. If dispatch has to answer first (previous leg open /
// driver busy) the question pops up on their screen; the answer comes back by id.

const pendingTyped = new Map<
  string,
  { input: TripInput & { loadNo?: string | null; sourceMessageId?: string | null; groupId?: string | null }; actor: Actor; at: number; answers: { endPrevious?: boolean; endDriverCurrent?: boolean; lineUp?: boolean; replace?: boolean } }
>();
const PENDING_MS = 30 * 60_000;

export type TypedLoadOutcome =
  | { kind: "sent"; loadId: number; loadNo: string | null; tripNo: string | null; legNo: number }
  | { kind: "noLoadNo" }
  | { kind: "question"; id: string; needs: "endPrevious" | "driverBusy" | "replaceLinedUp"; info: Record<string, any>; loadNo: string | null; message: string };

/** The staff's own chat message that made a leg: deleting that message offers to delete the load. */
async function linkSource(res: Awaited<ReturnType<typeof getLoad>>, messageId: string | null | undefined, actor: Actor) {
  if (!messageId) return;
  const legs = res.legs.filter((l) => l.status !== "cancelled");
  const leg = legs[legs.length - 1];
  if (leg) await record(leg, { type: "source_message", actor, messageId, note: "Made from a chat message" });
}

export async function loadFromChat(input: TripInput & { loadNo?: string | null; sourceMessageId?: string | null; groupId?: string | null }, actor: Actor): Promise<TypedLoadOutcome> {
  if (!cleanLoadNo(input.loadNo)) return { kind: "noLoadNo" };
  try {
    const res = await addLoad(input, actor, { send: true, fromChat: true, groupId: input.groupId || null, messageId: input.sourceMessageId || null });
    await linkSource(res, input.sourceMessageId, actor);
    return outcome(res);
  } catch (err) {
    if (!(err instanceof NeedsAnswer)) throw err;
    const id = `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 8)}`;
    for (const [k, v] of pendingTyped) if (Date.now() - v.at > PENDING_MS) pendingTyped.delete(k);
    pendingTyped.set(id, { input, actor, at: Date.now(), answers: {} });
    return { kind: "question", id, needs: err.needs, info: err.info, loadNo: cleanLoadNo(input.loadNo), message: err.message };
  }
}

/** Dispatch answered the question about a typed load (End & send / Line up). */
export async function answerTypedLoad(id: string, answers: { endPrevious?: boolean; endDriverCurrent?: boolean; lineUp?: boolean; replace?: boolean }, actor: Actor): Promise<TypedLoadOutcome> {
  const p = pendingTyped.get(id);
  if (!p || Date.now() - p.at > PENDING_MS) throw new TripError("That question expired — add the load from the Loads screen", 410);
  // Answers add up (end the previous leg, then: the driver is busy too)
  p.answers = { ...p.answers, ...answers };
  try {
    const res = await addLoad(p.input, actor, { send: true, fromChat: true, groupId: p.input.groupId || null, messageId: p.input.sourceMessageId || null, ...p.answers });
    pendingTyped.delete(id);
    await linkSource(res, (p.input as any).sourceMessageId, actor);
    return outcome(res);
  } catch (err) {
    if (!(err instanceof NeedsAnswer)) throw err;
    // The next question (e.g. previous leg ended, now the driver is busy): same id, more answers
    return { kind: "question", id, needs: err.needs, info: err.info, loadNo: cleanLoadNo(p.input.loadNo), message: err.message };
  }
}

function outcome(res: Awaited<ReturnType<typeof getLoad>>): TypedLoadOutcome {
  const legs = res.legs.filter((l) => l.status !== "cancelled");
  const leg = legs[legs.length - 1];
  return { kind: "sent", loadId: res.load.id, loadNo: res.load.invoice_no || res.load.load_no, tripNo: leg?.trip_no || null, legNo: leg?.leg_no || 1 };
}


// ---------- "Convert to load": a chat message that never became a load ----------
//
// A load text that was skipped (the driver was busy, a question went unanswered, an older app sent it
// as plain text) is turned into a load from the message itself. It is only ADDED to the Loads list
// (lined up, "saved for later") — nothing is sent to the driver again; dispatch sends it from Loads
// when it's time. The message is remembered as the load's source, so Delete on it asks about the load.

export async function convertMessageToLoad(messageId: string, actor: Actor, opts: { loadNo?: string | null } = {}) {
  const m = await Message.findByPk(messageId);
  if (!m || !m.body) throw new TripError("Message not found", 404);

  // Already a load? Say where it is instead of making a second one
  const already = (await loadsOfMessage(messageId))[0];
  if (already) return { data: await getLoad(already.loadId), loadNo: already.loadNo, already: true, plan: false };

  // plan: true → a message with a Load # but no address becomes a plan-only load (no stops yet)
  const typedNo = cleanLoadNo(opts.loadNo);
  const parsed = parseLoad(String(m.body), { plan: true }) ?? (typedNo ? parseLoad(`LOAD # ${typedNo}\n${m.body}`, { plan: true }) : null);
  const loadNo = typedNo || parsed?.loadNo || null;
  if (!parsed || !loadNo) throw new TripError('This message has no Load # — type it to add the load', 422);

  // Whose load: the truck's main driver in a truck chat, else the driver of this chat
  let driverId = m.userProfileId;
  const truck = await truckOfGroup(m.groupId);
  if (m.groupId) {
    if (!truck?.driver) throw new TripError("There's no driver in this truck chat — add the driver to the truck first", 422);
    driverId = truck.driver.id;
  } else {
    const who = await UserProfile.findByPk(driverId, { include: [{ model: Role, as: "role" }] });
    if ((who as any)?.role?.name !== "driver") throw new TripError("Open a driver's chat to turn a message into a load", 422);
  }

  // The same Load # is already in Loads: that's where it is (a second leg is added with Add load)
  const look = await lookupLoad(loadNo, driverId);
  if (look.load) throw new TripError(`Load ${loadNo} is already in Loads (${look.load.legs} leg${look.load.legs > 1 ? "s" : ""}) — open it there`, 409);

  const res = await addLoad(
    {
      loadNo,
      driverProfileId: driverId,
      channelId: m.groupId ? null : m.channelId,
      truckNumber: parsed.truck || truck?.truck || null,
      teamNames: parsed.team,
      ...(truck?.team && !parsed.team.length ? { teamDriverProfileId: truck.team.id } : {}),
      trailerNumbers: parsed.trailers,
      temperature: parsed.temperature,
      loadedTrailer: parsed.loadedTrailer,
      stops: parsed.stops,
      plan: !parsed.stops.length,
      needsReview: parsed.needsReview,
      reviewNotes: parsed.reasons,
      rawText: String(m.body),
    },
    actor,
    { send: false, fromChat: true }
  );
  await linkSource(res, messageId, actor);
  return { data: res, loadNo, already: false, plan: !parsed.stops.length };
}
