import { Op, QueryTypes } from "sequelize";
import { secondarySequelize } from "../../sequelize";
import { ChatLoad, ChatTrip, ChatTripEvent, ChatTripStop } from "../../models/ChatTrip";
import { UserProfile } from "../../models/UserProfile";
import Group from "../../models/Group";
import GroupUser from "../../models/GroupUser";
import { DRIVER_CURRENT } from "./lifecycle";
import { blockingLeg } from "./legs";

// A driver's lineup: the load they're on now and the loads lined up after it, in the order dispatch
// wants (chat_trips.queue_pos, lower first). When the current load is delivered (or the driver asks),
// #1 is offered — dispatch still confirms before it's sent (tripService.offerNextLoad uses the same
// order). Loads lined up on the driver's truck count too: they go to whoever drives the truck.

export const LINED_UP = ["scheduled", "offered"];

export interface LegSummary {
  tripId: number;
  loadId: number | null;
  tripNo: string | null;
  invoiceNo: string | null;
  legNo: number;
  legCount: number;
  status: string;
  truck: string | null;
  trailers: string | null;
  first: StopBrief | null;
  last: StopBrief | null;
  /** When it should be done: the ETA at Rolling, else the last appointment */
  finishAt: string | null;
}
interface StopBrief {
  type: string;
  name: string | null;
  city: string | null;
  state: string | null;
  appointmentLocal: string | null;
  appointmentAt: string | null;
}
export interface LineupItem extends LegSummary {
  position: number;
  /** An earlier leg of the same load isn't delivered yet: this one can't go first */
  blockedBy: { legNo: number; tripNo: string | null } | null;
  /** The plan doesn't fit, e.g. the pickup is before the previous delivery */
  fit: string | null;
}
export interface Lineup {
  driver: { profileId: string; name: string | null; truck: string | null };
  now: LegSummary | null;
  next: LineupItem[];
}

const brief = (s?: ChatTripStop | null): StopBrief | null =>
  s
    ? {
        type: s.type,
        name: s.name,
        city: s.city,
        state: s.state,
        appointmentLocal: s.appointment_local,
        appointmentAt: s.appointment_at ? new Date(s.appointment_at).toISOString() : null,
      }
    : null;

/** "11/12 08:00 AM" from the stop's own local time */
const local = (v?: string | null) => {
  if (!v) return "";
  const [d, t = "00:00"] = v.split("T");
  const [, m, day] = d.split("-");
  const [hh, mm] = t.split(":").map(Number);
  return `${m}/${day} ${String(hh % 12 || 12).padStart(2, "0")}:${String(mm).padStart(2, "0")} ${hh >= 12 ? "PM" : "AM"}`;
};

async function truckIdOf(profileId: string): Promise<{ number: string | null; id: number | null }> {
  const links = await GroupUser.findAll({ where: { userProfileId: profileId } });
  const group: any = links.length ? await Group.findOne({ where: { id: links.map((l: any) => l.groupId), type: "truck" } }) : null;
  const number = group?.name ? String(group.name) : null;
  if (!number) return { number: null, id: null };
  const rows = await secondarySequelize.query<{ id: number }>(`SELECT id FROM trucks WHERE number = :n LIMIT 1`, { replacements: { n: number }, type: QueryTypes.SELECT });
  return { number, id: rows[0]?.id ? Number(rows[0].id) : null };
}

/** The driver's lined-up legs (their own, or on their truck), in lineup order — offerNextLoad uses this. */
export async function linedUpLegs(profileId: string, opts: { truckId?: number | null; exclude?: number } = {}): Promise<ChatTrip[]> {
  const truckId = opts.truckId === undefined ? (await truckIdOf(profileId)).id : opts.truckId;
  return ChatTrip.findAll({
    where: {
      status: { [Op.in]: LINED_UP },
      [Op.or]: [{ driver_profile_id: profileId }, ...(truckId ? [{ truck_id: truckId }] : [])],
      ...(opts.exclude ? { id: { [Op.ne]: opts.exclude } } : {}),
    },
    include: [{ model: ChatTripStop, as: "stops" }],
    order: [
      [ChatTrip.sequelize!.literal("ChatTrip.queue_pos IS NULL"), "ASC"],
      ["queue_pos", "ASC"],
      ["planned_start_at", "ASC"],
      ["id", "ASC"],
      [{ model: ChatTripStop, as: "stops" }, "seq", "ASC"],
    ] as any,
  });
}

/**
 * The place a leg gets when it's lined up for this driver: after everything already there. The
 * lineup is numbered 1..n first, so older loads without a number keep their place.
 */
export async function nextPosition(profileId: string, exclude?: number): Promise<number> {
  const legs = await linedUpLegs(profileId, { exclude });
  for (let i = 0; i < legs.length; i++) if (legs[i].queue_pos !== i + 1) await legs[i].update({ queue_pos: i + 1 });
  return legs.length + 1;
}

async function summaries(legs: ChatTrip[]): Promise<Map<number, LegSummary>> {
  const loadIds = [...new Set(legs.map((l) => l.load_id).filter(Boolean))] as number[];
  const loads = new Map((loadIds.length ? await ChatLoad.findAll({ where: { id: loadIds } }) : []).map((l) => [Number(l.id), l]));
  const counts = new Map<number, number>();
  if (loadIds.length) {
    for (const r of (await ChatTrip.count({ where: { load_id: loadIds, status: { [Op.ne]: "cancelled" } }, group: ["load_id"] })) as unknown as { load_id: number; count: number }[]) {
      counts.set(Number(r.load_id), Number(r.count));
    }
  }
  return new Map(
    legs.map((l) => {
      const stops = [...(l.stops || [])].sort((a, b) => a.seq - b.seq);
      const last = stops[stops.length - 1];
      const finish = l.planned_eta_at || last?.appointment_at || null;
      return [
        l.id,
        {
          tripId: l.id,
          loadId: l.load_id,
          tripNo: l.trip_no,
          invoiceNo: (l.load_id ? loads.get(Number(l.load_id))?.invoice_no : null) ?? l.invoice_no ?? null,
          legNo: l.leg_no,
          legCount: l.load_id ? counts.get(Number(l.load_id)) || 1 : 1,
          status: l.status,
          truck: l.truck_number,
          trailers: l.trailer_numbers,
          first: brief(stops[0]),
          last: brief(last),
          finishAt: finish ? new Date(finish).toISOString() : null,
        },
      ];
    })
  );
}

const lastStop = (l: ChatTrip) => [...(l.stops || [])].sort((a, b) => a.seq - b.seq).pop() || null;
const finishOf = (l: ChatTrip): Date | null => {
  const at = l.planned_eta_at || lastStop(l)?.appointment_at;
  return at ? new Date(at) : null;
};
/** "11/12 10:00 AM" in the delivery's own time zone */
const finishText = (l: ChatTrip): string => {
  const stop = lastStop(l);
  if (!l.planned_eta_at) return local(stop?.appointment_local);
  const parts = new Intl.DateTimeFormat("en-US", { timeZone: stop?.timezone || "America/Los_Angeles", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit", hour12: true }).format(new Date(l.planned_eta_at));
  return parts.replace(",", "");
};

/** First stop with an appointment (a later leg starts at the yard, usually without one) */
const pickupOf = (l: ChatTrip) => [...(l.stops || [])].sort((a, b) => a.seq - b.seq).find((s) => s.appointment_at) || null;

export async function lineupOf(profileId: string): Promise<Lineup> {
  const profile = await UserProfile.findByPk(profileId);
  const truck = await truckIdOf(profileId);
  const current = await ChatTrip.findOne({
    where: { driver_profile_id: profileId, status: { [Op.in]: DRIVER_CURRENT } },
    include: [{ model: ChatTripStop, as: "stops" }],
    order: [
      ["sent_at", "DESC"],
      ["id", "DESC"],
    ],
  });
  const lined = await linedUpLegs(profileId, { truckId: truck.id });
  const info = await summaries([...(current ? [current] : []), ...lined]);

  // Does each load fit after the one before? Compare its pickup appointment with the previous finish.
  let prevFinish: Date | null = current ? finishOf(current) : null;
  let prevLabel = current ? `${current.planned_eta_at ? "the current load's ETA" : "the current delivery"} ${finishText(current)}` : "";
  const next: LineupItem[] = [];
  for (let i = 0; i < lined.length; i++) {
    const leg = lined[i];
    const blocking = await blockingLeg(leg);
    const pickup = pickupOf(leg);
    let fit: string | null = null;
    if (pickup?.appointment_at && prevFinish && new Date(pickup.appointment_at).getTime() < prevFinish.getTime()) {
      fit = `Pickup ${local(pickup.appointment_local)} is before ${prevLabel}`;
    }
    next.push({ ...info.get(leg.id)!, position: i + 1, blockedBy: blocking ? { legNo: blocking.leg_no, tripNo: blocking.trip_no } : null, fit });
    prevFinish = finishOf(leg);
    prevLabel = `#${i + 1}'s delivery ${finishText(leg)}`;
  }
  return { driver: { profileId, name: profile?.username || null, truck: truck.number }, now: current ? info.get(current.id)! : null, next };
}

/** Dispatch puts the lineup in a new order. Only the driver's own lined-up legs can be in the list. */
export async function reorderLineup(profileId: string, tripIds: number[], actor: { role: string; id?: string | null; name?: string | null }) {
  const legs = await linedUpLegs(profileId);
  const known = new Map(legs.map((l) => [l.id, l]));
  const order = tripIds.map(Number).filter((id) => known.has(id));
  // Anything left out keeps its relative place after the ones given
  for (const l of legs) if (!order.includes(l.id)) order.push(l.id);
  for (let i = 0; i < order.length; i++) {
    const leg = known.get(order[i])!;
    if (leg.queue_pos === i + 1) continue;
    const before = leg.queue_pos;
    await leg.update({ queue_pos: i + 1 });
    await ChatTripEvent.create({
      chat_trip_id: leg.id,
      type: "edit",
      actor_role: actor.role,
      actor_id: actor.id || null,
      actor_name: actor.name || null,
      note: `Lineup: now #${i + 1}`,
      data: { before: { queue_pos: before }, after: { queue_pos: i + 1 } },
      happened_at: new Date(),
    });
  }
  return lineupOf(profileId);
}

/** Take a lined-up leg off the driver: it goes back to "assign later" (no driver, no truck). */
export async function removeFromLineup(profileId: string, tripId: number, actor: { role: string; id?: string | null; name?: string | null }) {
  const leg = (await linedUpLegs(profileId)).find((l) => l.id === Number(tripId));
  if (!leg) return lineupOf(profileId);
  const before = { driver_profile_id: leg.driver_profile_id, truck_number: leg.truck_number, status: leg.status, queue_pos: leg.queue_pos };
  await leg.update({
    driver_profile_id: null,
    driver_id_1: null,
    driver_id_2: null,
    channel_id: null,
    truck_id: null,
    truck_number: null,
    queue_pos: null,
    status: "scheduled",
  });
  await ChatTripEvent.create({
    chat_trip_id: leg.id,
    type: "edit",
    from_status: before.status,
    to_status: "scheduled",
    actor_role: actor.role,
    actor_id: actor.id || null,
    actor_name: actor.name || null,
    note: "Taken off the driver's lineup — assign later",
    data: { before, after: { driver_profile_id: null, truck_number: null, queue_pos: null } },
    happened_at: new Date(),
  });
  return lineupOf(profileId);
}
