import { Op, QueryTypes } from "sequelize";
import { primarySequelize, secondarySequelize } from "../../sequelize";
import { ChatLoad, ChatTrip, ChatTripEvent, ChatTripStop, LoadType } from "../../models/ChatTrip";
import { UserProfile } from "../../models/UserProfile";
import {
  Actor,
  addMileage,
  alertStaff,
  announce,
  closeScaleRoute,
  createTrip,
  offerNextLoad,
  postToChat,
  record,
  sendLinedUpNext,
  sendLoad,
  syncRoute,
  TripError,
  withStops,
} from "./tripService";
import { byLeg, legTripNo, refreshLoadStatus } from "./legs";
import { nextPosition } from "./lineup";
import { defaultYardStop } from "./loadService";
import { localToDate, stateTimezone } from "./stateTimezone";
import { loadRef, statusLine } from "./tripMessages";
import { liveTrip } from "./liveTrip";
import { placeAt, PlaceStop } from "./places";

// Full control of a load after it's planned: hand the load to another driver / truck mid-way (a
// breakdown, out of hours, a swap at the yard) — the leg is cut where it is and a new leg takes the
// rest; undo that while the new leg hasn't started; change the load's type; correct times the driver
// tapped wrong; fix miles. Everything is recorded on the legs (chat_trip_events) so the load's history
// shows who had it, on which truck, from when to when, and why it changed hands.

export const HANDOVER_REASONS: Record<string, string> = {
  breakdown: "Breakdown",
  out_of_hours: "Out of hours",
  swap_at_yard: "Swap at the yard",
  driver_request: "Driver request",
  planned: "Planned relay",
  other: "Other",
};

/** The leg is on the road: its truck has the load */
const ON_ROAD = ["started", "rolling", "on_hold"];
const DONE = ["ended", "paperwork", "completed", "routed", "cancelled"];
const NOT_STARTED = ["scheduled", "offered", "planned", "accepted"];

export interface PlaceInput {
  type?: "yard" | "switch";
  name?: string | null;
  street?: string | null;
  city?: string | null;
  state?: string | null;
  zip?: string | null;
}

export interface SplitInput {
  /** now: hand over right now · at: it happened at [at] · plan: re-plan a leg that hasn't started */
  when?: "now" | "at" | "plan";
  at?: string | null;
  place: PlaceInput;
  /** Re-plan: stops after this seq go to the new leg */
  afterSeq?: number | null;
  driverProfileId?: string | null;
  truckNumber?: string | null;
  teamDriverProfileId?: string | null;
  trailerNumbers?: string[] | null;
  reason: string;
  note?: string | null;
  /** Send the new leg to its driver right away (otherwise offered — dispatch confirms) */
  send?: boolean;
}

const placeText = (p: { name?: string | null; city?: string | null; state?: string | null }) =>
  [p.name, [p.city, p.state].filter(Boolean).join(", ")].filter(Boolean).join(" · ");

const stopInput = (s: ChatTripStop) => ({
  type: s.type,
  name: s.name,
  street: s.street,
  city: s.city,
  state: s.state,
  zip: s.zip,
  appointment: s.appointment_local,
  ref: s.ref,
});

async function loadOf(leg: ChatTrip): Promise<ChatLoad> {
  const load = leg.load_id ? await ChatLoad.findByPk(leg.load_id) : null;
  if (!load) throw new TripError("This trip has no load");
  return load;
}

/** Direct when one leg is left; a yard handover makes it via yard, any other one a relay. */
export async function deriveType(loadId: number) {
  const load = await ChatLoad.findByPk(loadId);
  if (!load || load.type === "trailer_move") return;
  const legs = (await ChatTrip.findAll({ where: { load_id: loadId } })).filter((l) => l.status !== "cancelled");
  const type: LoadType = legs.length <= 1 ? "direct" : legs.some((l) => l.ends_at_yard) ? "via_yard" : "relay";
  if (type !== load.type) await load.update({ type });
}

/** Renumber a load's legs 1..n in leg order (trip numbers follow: L0047, L0047-2 …). */
async function renumber(load: ChatLoad, order: ChatTrip[]) {
  // Two passes so leg_no never clashes on the way
  for (const [i, l] of order.entries()) await l.update({ leg_no: 1000 + i });
  for (const [i, l] of order.entries()) {
    await l.update({ leg_no: i + 1, trip_no: load.load_no ? legTripNo(load.load_no, i + 1) : l.trip_no });
  }
}

/** Where the leg's truck is now, as a stop (Samsara + Google) — the default handover place. */
export async function truckPlace(legId: number): Promise<(PlaceStop & { at: string | null; address: string | null }) | null> {
  const leg = await ChatTrip.findByPk(legId, withStops);
  if (!leg) throw new TripError("Leg not found", 404);
  const live = await liveTrip(leg, leg.stops || []);
  if (!live.truck) return null;
  const stop = await placeAt(live.truck.lat, live.truck.lng);
  return {
    ...(stop || { name: null, street: null, city: null, state: null, zip: null, lat: live.truck.lat, lng: live.truck.lng }),
    name: stop?.street ? null : live.truck.address,
    at: live.truck.at,
    address: live.truck.address,
  };
}

const moment = (v: string | Date | null | undefined, label: string): Date => {
  const d = v ? new Date(v) : null;
  if (!d || !Number.isFinite(d.getTime())) throw new TripError(`${label}: not a valid date / time`);
  if (d.getTime() > Date.now() + 60_000) throw new TripError(`${label} is in the future`);
  return d;
};

// ---------- hand over / split ----------

/**
 * Rolling means loaded: the pickups are behind the truck, and so is where this leg took the load
 * over (its first stop when that's our yard or a meet point) — they don't go to the next driver.
 */
const originDone = (leg: ChatTrip, stops: ChatTripStop[], s: ChatTripStop) =>
  leg.status === "rolling" && (s.type === "pickup" || (s.id === stops[0]?.id && (s.type === "yard" || s.type === "switch")));

export async function splitLeg(legId: number, input: SplitInput, actor: Actor) {
  const leg = await ChatTrip.findByPk(legId, withStops);
  if (!leg) throw new TripError("Leg not found", 404);
  if (DONE.includes(leg.status)) throw new TripError("This leg is already delivered — add a leg instead");
  const load = await loadOf(leg);
  if (!HANDOVER_REASONS[input.reason]) throw new TripError("Pick a reason");
  const place = input.place || {};
  if (!place.city?.trim() || !place.state?.trim()) throw new TripError("Where does the load change hands? Pick a place with a city and state");

  const stops = [...(leg.stops || [])].sort((a, b) => a.seq - b.seq);
  const live = ON_ROAD.includes(leg.status) && !!leg.started_at && input.when !== "plan";
  // What goes to the new leg
  let moving: ChatTripStop[];
  if (input.afterSeq !== undefined && input.afterSeq !== null) moving = stops.filter((s) => s.seq > Number(input.afterSeq));
  else if (live) moving = stops.filter((s) => !s.arrived_at && !originDone(leg, stops, s));
  else throw new TripError("This leg hasn't started — choose after which stop the load changes hands");
  if (!moving.length) throw new TripError("Nothing left for the next driver — every stop is done");
  const staying = stops.filter((s) => !moving.includes(s));
  if (!live && !staying.length) throw new TripError("Keep at least one stop on this leg");

  const at = live ? (input.when === "at" ? moment(input.at, "Handover time") : new Date()) : null;
  if (at && leg.started_at && at.getTime() < new Date(leg.started_at).getTime()) throw new TripError("The handover can't be before the leg started");
  const type = place.type === "yard" ? "yard" : "switch";
  const reasonLabel = HANDOVER_REASONS[input.reason];

  // Make room after this leg
  const later = byLeg(await ChatTrip.findAll({ where: { load_id: load.id, leg_no: { [Op.gt]: leg.leg_no } } }));
  for (const l of [...later].reverse()) await l.update({ leg_no: l.leg_no + 1, trip_no: load.load_no ? legTripNo(load.load_no, l.leg_no + 1) : l.trip_no });

  // The new leg: from the handover place, the rest of the stops, same trailer unless changed
  let next: ChatTrip | null = null;
  try {
    next = await createTrip(
      {
        driverProfileId: input.driverProfileId || null,
        truckNumber: input.truckNumber?.trim() || null,
        teamDriverProfileId: input.teamDriverProfileId || null,
        trailerNumbers: input.trailerNumbers?.length ? input.trailerNumbers : leg.trailer_numbers ? leg.trailer_numbers.split(/,\s*/) : [],
        temperature: leg.temperature,
        loadedTrailer: true,
        notes: leg.notes,
        invoiceNo: load.invoice_no,
        allowNoDriver: true,
        source: "form",
        stops: [{ type, name: place.name || null, street: place.street || null, city: place.city, state: place.state, zip: place.zip || null }, ...moving.map(stopInput)],
      },
      actor,
      { quiet: true, leg: { loadId: load.id, legNo: leg.leg_no + 1, loadNo: load.load_no } }
    );
  } catch (err) {
    for (const l of later) await l.update({ leg_no: l.leg_no - 1, trip_no: load.load_no ? legTripNo(load.load_no, l.leg_no - 1) : l.trip_no });
    throw err;
  }
  if (!next) throw new TripError("Could not create the new leg", 500);

  // The current leg ends at the handover place
  const before = { status: leg.status, ended_at: leg.ended_at, ends_at_yard: leg.ends_at_yard, handover_reason: leg.handover_reason };
  let handoverStopId = 0;
  await primarySequelize.transaction(async (t) => {
    await ChatTripStop.destroy({ where: { id: moving.map((s) => s.id) }, transaction: t });
    const state = place.state!.trim().toUpperCase().slice(0, 2);
    const hs = await ChatTripStop.create(
      {
        chat_trip_id: leg.id,
        seq: (staying[staying.length - 1]?.seq || 0) + 1,
        type,
        name: place.name?.trim() || null,
        street: place.street?.trim() || null,
        city: place.city!.trim(),
        state,
        zip: place.zip?.trim() || null,
        timezone: stateTimezone(state),
        arrived_at: at,
      },
      { transaction: t }
    );
    handoverStopId = hs.id;
    await leg.update(
      { ends_at_yard: type === "yard", handover_reason: input.reason, ...(live ? { status: "ended", ended_at: at } : {}) },
      { transaction: t }
    );
  });

  const who = async (l: ChatTrip) => {
    const name = l.driver_profile_id ? (await UserProfile.findByPk(l.driver_profile_id))?.username || "Driver" : "No driver yet";
    return `${name}${l.truck_number ? ` / truck ${l.truck_number}` : ""}`;
  };
  const fresh = (await ChatTrip.findByPk(next.id))!;
  const text = `${reasonLabel}: ${await who(leg)} → ${await who(fresh)} at ${placeText(place)}${input.note ? ` — ${input.note}` : ""}`;
  await record(leg, {
    type: "transfer",
    from: before.status,
    to: live ? "ended" : before.status,
    actor,
    at: at || undefined,
    note: text,
    data: { transferTo: fresh.id, reason: input.reason, before, handoverStopId, moved: moving.length, live },
  });
  await record(fresh, { type: "transfer", actor, at: at || undefined, note: `Took over the load — ${text}`, data: { transferFrom: leg.id, reason: input.reason } });

  // First in the new driver's lineup: it's urgent
  if (fresh.driver_profile_id) {
    await fresh.update({ queue_pos: 0 });
    await nextPosition(fresh.driver_profile_id);
  }

  if (live) {
    await postToChat(leg, `🔁 ${loadRef(leg)} handed over at ${placeText(place)} (${reasonLabel.toLowerCase()}) — thank you, dispatch has the rest of this load`);
    await closeScaleRoute(leg).catch(() => undefined);
    void addMileage(leg.id).catch(() => undefined);
    if (leg.driver_profile_id && leg.driver_profile_id !== fresh.driver_profile_id) {
      void offerNextLoad(leg.driver_profile_id, "ended").catch(() => undefined);
    }
    // The load is at the handover now: the next driver can have it
    if (fresh.driver_profile_id) {
      if (input.send) await sendLoad(fresh.id, actor);
      else {
        await fresh.update({ status: "offered" });
        await record(fresh, { type: "offer", from: "scheduled", to: "offered", actor: { role: "system", name: "Dispatch Assistant" }, note: `Handover: ${reasonLabel}` });
        await postToChat(fresh, statusLine.offered());
        alertStaff("trip:offer", { tripId: fresh.id, tripNo: fresh.trip_no, driverProfileId: fresh.driver_profile_id, truck: fresh.truck_number, reason: "handover" });
      }
    } else {
      alertStaff("load:transfer", { loadId: load.id, tripId: fresh.id, tripNo: fresh.trip_no, atYard: type === "yard" });
    }
  }
  // Planned for later: the new driver gets it when dispatch sends it (drivers don't see lined-up loads)

  await deriveType(load.id);
  await refreshLoadStatus(load.id);
  announce(leg.id);
  announce(fresh.id);
  return { cut: leg.id, next: fresh.id };
}

// ---------- the handover happened: start the next leg ----------

/**
 * Dispatch knows the load changed hands (the driver before didn't tap it): the leg before is marked
 * handed over at [at] (default now) at its handover stop, then this leg is sent to its driver.
 */
export async function releaseLeg(legId: number, input: { at?: string | null }, actor: Actor) {
  const leg = await ChatTrip.findByPk(legId);
  if (!leg) throw new TripError("Leg not found", 404);
  if (!["scheduled", "offered"].includes(leg.status)) throw new TripError("This leg is already sent");
  if (!leg.driver_profile_id) throw new TripError("Assign a driver to this leg first");
  const prevLegs = byLeg(await ChatTrip.findAll({ where: { load_id: leg.load_id, leg_no: { [Op.lt]: leg.leg_no }, status: { [Op.ne]: "cancelled" } } }));
  const open = prevLegs.filter((l) => !["ended", "paperwork", "completed", "routed"].includes(l.status));
  if (open.length > 1) throw new TripError(`Leg ${open[0].leg_no} isn't handed over yet either`);
  if (open[0]) await endLegNow(open[0].id, actor, { at: input.at, handover: true });
  await sendLoad(leg.id, actor);
  await refreshLoadStatus(leg.load_id);
  return { leg: leg.id, handedOver: open[0]?.id ?? null };
}

/**
 * Dispatch ends a leg the driver didn't end (or hands it over): marked delivered / handed over at
 * [at] (default now) at its last stop, the driver is told, the trip leaves their app, miles are read.
 * A leg never sent to the driver is cancelled instead (nothing happened on it).
 */
export async function endLegNow(legId: number, actor: Actor, opts: { at?: string | Date | null; handover?: boolean; note?: string; sendNext?: boolean } = {}) {
  const leg = await ChatTrip.findByPk(legId, withStops);
  if (!leg) throw new TripError("Leg not found", 404);
  if (["ended", "paperwork", "completed", "routed", "cancelled"].includes(leg.status)) return leg;
  const from = leg.status;
  if (from === "scheduled" || from === "offered") {
    await leg.update({ status: "cancelled", queue_pos: null });
    await record(leg, { type: "status", from, to: "cancelled", actor, note: opts.note || "Not sent — replaced by dispatch" });
    announce(leg.id);
    await refreshLoadStatus(leg.load_id);
    return leg;
  }
  const at = opts.at ? moment(opts.at instanceof Date ? opts.at.toISOString() : opts.at, "End time") : new Date();
  if (leg.started_at && at.getTime() < new Date(leg.started_at).getTime()) throw new TripError(`Leg ${leg.leg_no} started after that time`);
  const stops = [...(leg.stops || [])].sort((a, b) => a.seq - b.seq);
  const last = stops[stops.length - 1];
  await primarySequelize.transaction(async (t) => {
    if (last && !last.arrived_at) await last.update({ arrived_at: at }, { transaction: t });
    await leg.update({ status: "ended", ended_at: at, status_before_hold: null }, { transaction: t });
  });
  const tapped = from === "rolling" || from === "started";
  await record(leg, {
    type: "status",
    from,
    to: "ended",
    actor,
    at,
    note: opts.note || `${opts.handover ? "Handed over" : "Ended"} by dispatch${tapped ? "" : " (the driver hadn't tapped Rolling)"}`,
    data: { action: "end_by_dispatch", before: { trip: { status: from, ended_at: null } } },
  });
  const where = last ? ` at ${placeText(last)}` : "";
  await postToChat(
    leg,
    opts.handover
      ? `🔁 ${loadRef(leg)} handed over${where} — thank you, dispatch has the rest of this load`
      : `✅ ${loadRef(leg)} ended by dispatch${where} — thank you. Send the BOL / POD photos here if you have them`
  );
  await closeScaleRoute(leg).catch(() => undefined);
  void addMileage(leg.id).catch(() => undefined);
  announce(leg.id);
  await refreshLoadStatus(leg.load_id);
  // The driver is free: a load lined up after this one goes out now (not when dispatch sends one itself)
  if (opts.sendNext !== false && leg.driver_profile_id) await sendLinedUpNext(leg.driver_profile_id).catch(() => null);
  return leg;
}

// ---------- undo a handover / merge legs ----------

/** Put [next]'s stops back on [prev] and drop next (cancelled, kept for the record). */
async function mergeInto(prev: ChatTrip, next: ChatTrip, restore: Record<string, any> | null, handoverStopId: number | null) {
  const prevStops = (await ChatTripStop.findAll({ where: { chat_trip_id: prev.id } })).sort((a, b) => a.seq - b.seq);
  const handover = handoverStopId ? prevStops.find((s) => s.id === handoverStopId) : prevStops[prevStops.length - 1];
  const nextStops = (await ChatTripStop.findAll({ where: { chat_trip_id: next.id } })).sort((a, b) => a.seq - b.seq);
  // next starts at the handover place: that stop isn't a real stop of the load
  const back = nextStops[0] && (nextStops[0].type === "yard" || nextStops[0].type === "switch") ? nextStops.slice(1) : nextStops;
  await primarySequelize.transaction(async (t) => {
    if (handover && (handover.type === "yard" || handover.type === "switch")) await handover.destroy({ transaction: t });
    let seq = Math.max(0, ...prevStops.filter((s) => s.id !== handover?.id).map((s) => s.seq));
    for (const s of back) await s.update({ chat_trip_id: prev.id, seq: ++seq }, { transaction: t });
    await prev.update({ ends_at_yard: false, handover_reason: null, ...(restore || {}) }, { transaction: t });
    await next.update({ status: "cancelled", queue_pos: null }, { transaction: t });
  });
}

export async function undoSplit(nextLegId: number, actor: Actor) {
  const next = await ChatTrip.findByPk(nextLegId);
  if (!next) throw new TripError("Leg not found", 404);
  if (!NOT_STARTED.includes(next.status) || next.started_at) throw new TripError("The new driver already started — it can't be undone; hand it over again instead");
  const load = await loadOf(next);
  const legs = byLeg(await ChatTrip.findAll({ where: { load_id: load.id, status: { [Op.ne]: "cancelled" } } }));
  const prev = legs.filter((l) => l.leg_no < next.leg_no).pop();
  if (!prev) throw new TripError("There's no leg before this one");
  const ev = await ChatTripEvent.findOne({ where: { chat_trip_id: prev.id, type: "transfer" }, order: [["id", "DESC"]] });
  if (!ev || Number(ev.data?.transferTo) !== next.id) throw new TripError("This leg wasn't made by a handover — cancel it instead");
  if (["completed", "routed"].includes(prev.status)) throw new TripError(`Leg ${prev.leg_no} is already completed`);

  const restore = ev.data?.before || {};
  const nextDriver = next.status === "planned" || next.status === "accepted" ? next : null;
  await mergeInto(prev, next, { status: restore.status ?? prev.status, ended_at: restore.ended_at ?? null, ...(prev.miles_source === "samsara" ? { total_mileage: null, miles_source: null } : {}) }, Number(ev.data?.handoverStopId) || null);
  await renumber(load, legs.filter((l) => l.id !== next.id));

  await record(prev, { type: "transfer_undone", from: prev.status, to: restore.status, actor, note: `Handover undone — the load stays on leg ${prev.leg_no}`, data: { undid: ev.id, removedLeg: next.id } });
  await record(next, { type: "transfer_undone", from: next.status, to: "cancelled", actor, note: "Handover undone — this leg was removed" });
  if (nextDriver) await postToChat(nextDriver, `↩️ Dispatch changed the plan — ${loadRef(next, false)} is not yours anymore`);
  if (restore.status && ON_ROAD.includes(restore.status)) await postToChat(prev, `↩️ Dispatch undid the handover — ${loadRef(prev, false)} continues with you`);

  await deriveType(load.id);
  await refreshLoadStatus(load.id);
  announce(prev.id);
  announce(next.id);
  return { leg: prev.id };
}

/** Planned loads: Direct ⇄ Via yard / Relay. A load already moving is changed with a handover. */
export async function changeType(loadId: number, input: { type: LoadType; place?: PlaceInput | null }, actor: Actor) {
  const load = await ChatLoad.findByPk(loadId);
  if (!load) throw new TripError("Load not found", 404);
  const legs = byLeg(await ChatTrip.findAll({ where: { load_id: loadId, status: { [Op.ne]: "cancelled" } }, include: [{ model: ChatTripStop, as: "stops" }] }));
  if (input.type === load.type) return { load: loadId };
  if (input.type === "trailer_move") {
    await load.update({ type: "trailer_move" });
    return { load: loadId };
  }
  if (input.type === "direct") {
    if (legs.slice(1).some((l) => !["scheduled", "offered"].includes(l.status))) throw new TripError("A later leg is already sent or moving — cancel it first");
    if (legs[0] && DONE.includes(legs[0].status)) throw new TripError("Leg 1 is already delivered");
    for (const l of legs.slice(1).reverse()) {
      const prev = legs[legs.indexOf(l) - 1];
      await mergeInto(prev, l, null, null);
      await record(l, { type: "transfer_undone", actor, note: "Load changed to Direct — leg merged into the one before" });
    }
    await renumber(load, [legs[0]]);
    await load.update({ type: "direct" });
    await record(legs[0], { type: "edit", actor, note: "Load type → Direct" });
  } else if (legs.length === 1) {
    const leg = legs[0];
    if (!NOT_STARTED.includes(leg.status) || leg.started_at) throw new TripError("This load is already moving — use Change driver / truck to hand it over");
    const stops = [...(leg.stops || [])].sort((a, b) => a.seq - b.seq);
    const lastPickup = [...stops].reverse().find((s) => s.type === "pickup") || stops[0];
    const place = input.place?.city ? input.place : input.type === "via_yard" ? await defaultYardStop() : null;
    if (!place?.city) throw new TripError("Pick the meet point");
    await splitLeg(leg.id, { when: "plan", afterSeq: lastPickup.seq, place: { ...place, type: input.type === "via_yard" ? "yard" : "switch" } as PlaceInput, reason: "planned" }, actor);
    await load.update({ type: input.type });
  } else {
    await load.update({ type: input.type });
  }
  await refreshLoadStatus(loadId);
  for (const l of legs) announce(l.id);
  return { load: loadId };
}

// ---------- correct times / miles ----------

export interface TimesInput {
  startedAt?: string | null;
  endedAt?: string | null;
  stops?: { id: number; arrivedAt?: string | null; departedAt?: string | null; appointment?: string | null }[];
}

export async function correctTimes(legId: number, input: TimesInput, reason: string, actor: Actor) {
  const leg = await ChatTrip.findByPk(legId, withStops);
  if (!leg) throw new TripError("Leg not found", 404);
  if (["routed", "cancelled"].includes(leg.status)) throw new TripError("This leg is closed");
  if (!reason?.trim()) throw new TripError("Say why the times are changed");
  const legChanges: Record<string, Date | null> = {};
  const legBefore: Record<string, any> = {};
  if (input.startedAt !== undefined) {
    legChanges.started_at = input.startedAt ? moment(input.startedAt, "Start") : null;
    legBefore.started_at = leg.started_at;
  }
  if (input.endedAt !== undefined) {
    legChanges.ended_at = input.endedAt ? moment(input.endedAt, "End") : null;
    legBefore.ended_at = leg.ended_at;
  }
  const started = "started_at" in legChanges ? legChanges.started_at : leg.started_at ? new Date(leg.started_at) : null;
  const ended = "ended_at" in legChanges ? legChanges.ended_at : leg.ended_at ? new Date(leg.ended_at) : null;
  if (started && ended && ended.getTime() < started.getTime()) throw new TripError("The end can't be before the start");
  if (ended && !started && input.endedAt) throw new TripError("Set the start too");

  const stops = leg.stops || [];
  const stopChanges: { stop: ChatTripStop; changes: Record<string, any>; before: Record<string, any> }[] = [];
  for (const s of input.stops || []) {
    const stop = stops.find((x) => x.id === Number(s.id));
    if (!stop) throw new TripError("A stop isn't on this leg");
    const changes: Record<string, any> = {};
    const before: Record<string, any> = {};
    if (s.arrivedAt !== undefined) {
      changes.arrived_at = s.arrivedAt ? moment(s.arrivedAt, `${stop.name || stop.city} arrival`) : null;
      before.arrived_at = stop.arrived_at;
    }
    if (s.departedAt !== undefined) {
      changes.departed_at = s.departedAt ? moment(s.departedAt, `${stop.name || stop.city} departure`) : null;
      before.departed_at = stop.departed_at;
    }
    if (s.appointment !== undefined) {
      const local = s.appointment && /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/.test(s.appointment) ? s.appointment : null;
      changes.appointment_local = local;
      changes.appointment_at = local ? localToDate(local, stop.timezone || stateTimezone(stop.state)) : null;
      before.appointment_local = stop.appointment_local;
    }
    const arrived = "arrived_at" in changes ? changes.arrived_at : stop.arrived_at;
    const departed = "departed_at" in changes ? changes.departed_at : stop.departed_at;
    if (arrived && departed && new Date(departed).getTime() < new Date(arrived).getTime()) throw new TripError(`${stop.name || stop.city}: left before it arrived`);
    if (arrived && ended && new Date(arrived).getTime() > ended.getTime() + 60_000) throw new TripError(`${stop.name || stop.city}: arrived after the leg ended`);
    if (Object.keys(changes).length) stopChanges.push({ stop, changes, before });
  }

  // Legs follow each other: this one can't start before the one before ended, or end after the next started
  if (leg.load_id && (started || ended)) {
    const siblings = byLeg(await ChatTrip.findAll({ where: { load_id: leg.load_id, status: { [Op.ne]: "cancelled" } } }));
    const prev = siblings.filter((l) => l.leg_no < leg.leg_no).pop();
    const nextLeg = siblings.find((l) => l.leg_no > leg.leg_no);
    if (started && prev?.ended_at && started.getTime() < new Date(prev.ended_at).getTime() - 60_000) throw new TripError(`Leg ${prev.leg_no} ended after this start`);
    if (ended && nextLeg?.started_at && ended.getTime() > new Date(nextLeg.started_at).getTime() + 60_000) throw new TripError(`Leg ${nextLeg.leg_no} started before this end`);
  }
  if (!Object.keys(legChanges).length && !stopChanges.length) throw new TripError("Nothing changed");

  await primarySequelize.transaction(async (t) => {
    if (Object.keys(legChanges).length) await leg.update(legChanges, { transaction: t });
    for (const c of stopChanges) await c.stop.update(c.changes, { transaction: t });
  });
  await record(leg, {
    type: "time_correction",
    actor,
    note: reason.trim(),
    data: {
      before: { leg: legBefore, stops: stopChanges.map((c) => ({ id: c.stop.id, ...c.before })) },
      after: { leg: legChanges, stops: stopChanges.map((c) => ({ id: c.stop.id, ...c.changes })) },
    },
  });
  // Times decide the Samsara miles window
  if ("started_at" in legChanges || "ended_at" in legChanges) await addMileage(leg.id).catch(() => undefined);
  const fresh = await ChatTrip.findByPk(leg.id, withStops);
  if (fresh) await syncRoute(fresh).catch(() => undefined);
  await refreshLoadStatus(leg.load_id);
  announce(leg.id);
  return { leg: leg.id };
}

/** Dispatch types the miles (Samsara missing / wrong), or null to go back to Samsara. */
export async function setMiles(legId: number, miles: number | null, note: string | null, actor: Actor) {
  const leg = await ChatTrip.findByPk(legId);
  if (!leg) throw new TripError("Leg not found", 404);
  const before = { total_mileage: leg.total_mileage, miles_source: leg.miles_source };
  if (miles === null) {
    await leg.update({ miles_source: null, miles_note: null });
    await addMileage(leg.id).catch(() => undefined);
  } else {
    if (!Number.isFinite(miles) || miles < 0 || miles > 10000) throw new TripError("Miles must be between 0 and 10,000");
    if (!note?.trim()) throw new TripError("Say why the miles are changed");
    await leg.update({ total_mileage: Math.round(miles * 10) / 10, miles_source: "manual", miles_note: note.trim().slice(0, 255) });
  }
  const after = await ChatTrip.findByPk(legId);
  await record(leg, {
    type: "miles",
    actor,
    note: miles === null ? "Miles back to Samsara" : `Miles set to ${miles} — ${note}`,
    data: { before, after: { total_mileage: after?.total_mileage, miles_source: after?.miles_source } },
  });
  const fresh = await ChatTrip.findByPk(leg.id, withStops);
  if (fresh) await syncRoute(fresh).catch(() => undefined);
  announce(leg.id);
  return { leg: leg.id };
}

// ---------- history / segments ----------

/** Yard driver names (team drivers aren't always chat users). */
async function yardNames(ids: number[]): Promise<Map<number, string>> {
  if (!ids.length) return new Map();
  const rows = await secondarySequelize.query<{ id: number; name: string }>(`SELECT id, name FROM drivers WHERE id IN (:ids)`, {
    replacements: { ids },
    type: QueryTypes.SELECT,
  });
  return new Map(rows.map((r) => [Number(r.id), r.name]));
}

export interface Segment {
  legId: number;
  legNo: number;
  tripNo: string | null;
  status: string;
  driverProfileId: string | null;
  drivers: string[];
  truck: string | null;
  trailers: string | null;
  from: string;
  to: string;
  startedAt: Date | null;
  endedAt: Date | null;
  minutes: number | null;
  miles: number | null;
  milesSource: string | null;
  milesNote: string | null;
  handoverReason: string | null;
}

export async function segmentsOf(legs: ChatTrip[], profileNames: Record<string, string | undefined>) {
  const live = byLeg(legs).filter((l) => l.status !== "cancelled");
  const names = await yardNames([...new Set(live.flatMap((l) => [l.driver_id_1, l.driver_id_2]).filter(Boolean).map(Number))]);
  const segments: Segment[] = live.map((l) => {
    const stops = [...(l.stops || [])].sort((a, b) => a.seq - b.seq);
    const p = (s?: ChatTripStop) => (s ? placeText(s) : "—");
    const drivers = [
      (l.driver_profile_id && profileNames[l.driver_profile_id]) || (l.driver_id_1 ? names.get(Number(l.driver_id_1)) : null),
      l.driver_id_2 ? names.get(Number(l.driver_id_2)) || "Team driver" : null,
    ].filter(Boolean) as string[];
    const start = l.started_at ? new Date(l.started_at) : null;
    const end = l.ended_at ? new Date(l.ended_at) : null;
    return {
      legId: l.id,
      legNo: l.leg_no,
      tripNo: l.trip_no,
      status: l.status,
      driverProfileId: l.driver_profile_id,
      drivers,
      truck: l.truck_number,
      trailers: l.trailer_numbers,
      from: p(stops[0]),
      to: p(stops[stops.length - 1]),
      startedAt: start,
      endedAt: end,
      minutes: start && end ? Math.round((end.getTime() - start.getTime()) / 60000) : null,
      miles: l.total_mileage !== null && l.total_mileage !== undefined ? Number(l.total_mileage) : null,
      milesSource: l.miles_source,
      milesNote: l.miles_note,
      handoverReason: l.handover_reason,
    };
  });
  const sum = (key: (s: Segment) => string[]) => {
    const out: Record<string, number> = {};
    for (const s of segments) for (const k of key(s)) out[k] = Math.round(((out[k] || 0) + (s.miles || 0)) * 10) / 10;
    return out;
  };
  return {
    segments,
    totals: {
      miles: Math.round(segments.reduce((a, s) => a + (s.miles || 0), 0) * 10) / 10,
      missing: segments.filter((s) => s.endedAt && s.miles === null).length,
      byDriver: sum((s) => s.drivers),
      byTruck: sum((s) => (s.truck ? [s.truck] : [])),
    },
  };
}

export interface HistoryEntry {
  at: Date;
  legNo: number;
  tripNo: string | null;
  type: string;
  from: string | null;
  to: string | null;
  note: string | null;
  actor: string;
  actorRole: string;
  data: any;
}

/** Every leg's record, in time order — who did what to the load and when. */
export function historyOf(legs: ChatTrip[]): HistoryEntry[] {
  const out: HistoryEntry[] = [];
  for (const l of legs) {
    for (const e of l.events || []) {
      out.push({
        at: new Date(e.happened_at || e.created_at),
        legNo: l.leg_no,
        tripNo: l.trip_no,
        type: e.type,
        from: e.from_status,
        to: e.to_status,
        note: e.note,
        actor: e.actor_name || (e.actor_role === "system" ? "System" : e.actor_role),
        actorRole: e.actor_role,
        data: ["time_correction", "miles", "transfer", "document"].includes(e.type) ? e.data : null,
      });
    }
  }
  return out.sort((a, b) => a.at.getTime() - b.at.getTime());
}
