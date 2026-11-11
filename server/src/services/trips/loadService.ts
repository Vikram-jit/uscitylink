import { Op } from "sequelize";
import { ChatLoad, ChatTrip, ChatTripEvent, ChatTripProblem, ChatTripStop, LoadType } from "../../models/ChatTrip";
import { UserProfile } from "../../models/UserProfile";
import { byLeg, refreshLoadStatus } from "./legs";
import { conflictsFor, yardVisitsOfLoad } from "./equipment";
import { historyOf, segmentsOf } from "./loadControl";
import { Actor, cleanInvoice, createTrip, editTrip, sendLoad, setInvoice, StopInput, syncPriced, TripError, TripInput } from "./tripService";

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
