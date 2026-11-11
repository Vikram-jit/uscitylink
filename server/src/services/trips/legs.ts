import { Op } from "sequelize";
import { ChatLoad, ChatTrip, LoadStatus } from "../../models/ChatTrip";

// A load is moved by legs (chat_trips with the same load_id, in leg_no order). Rules shared by the
// trip actions (tripService) and the Loads screen (loadService): a leg can't go to its driver before
// the leg before it is delivered, and the load's status comes from its legs.

/** The previous leg delivered the trailer (or the load is done with it) */
export const HANDED_OVER = ["ended", "paperwork", "completed", "routed"];
const ON_THE_ROAD = ["planned", "accepted", "started", "rolling", "on_hold"];
const NOT_SENT = ["scheduled", "offered"];

type LegLike = Pick<ChatTrip, "leg_no" | "status" | "driver_profile_id" | "ends_at_yard">;

export const byLeg = <T extends { leg_no: number }>(legs: T[]) => [...legs].sort((a, b) => a.leg_no - b.leg_no);

/**
 * scheduled  nothing sent yet
 * waiting    a driver asked and the next leg waits for dispatch to confirm
 * active     a leg is on the road
 * transfer   a leg handed over (yard / meet point) and the next one hasn't been sent
 * delivered  the last leg is delivered, paperwork / Mark completed to go
 * completed  every leg completed
 * cancelled  every leg cancelled
 */
export function loadStatusOf(legs: LegLike[]): LoadStatus {
  const live = byLeg(legs).filter((l) => l.status !== "cancelled");
  if (!live.length) return "cancelled";
  if (live.every((l) => ["completed", "routed"].includes(l.status))) return "completed";
  const last = live[live.length - 1];
  if (HANDED_OVER.includes(last.status)) return "delivered";
  if (live.some((l) => l.status === "offered")) return "waiting";
  if (live.some((l) => ON_THE_ROAD.includes(l.status))) return "active";
  // Some leg handed over and the next one is still waiting to be sent
  const handed = live.findIndex((l, i) => i < live.length - 1 && HANDED_OVER.includes(l.status) && NOT_SENT.includes(live[i + 1].status));
  if (handed >= 0) return "transfer";
  return "scheduled";
}

/** Legs of the same load (the leg itself included). */
export async function legsOf(trip: Pick<ChatTrip, "id" | "load_id">): Promise<ChatTrip[]> {
  if (!trip.load_id) return [];
  return byLeg(await ChatTrip.findAll({ where: { load_id: trip.load_id } }));
}

/** The leg before this one, still not delivered — this leg can't go to a driver yet. */
export async function blockingLeg(trip: Pick<ChatTrip, "id" | "load_id" | "leg_no">): Promise<ChatTrip | null> {
  if (!trip.load_id || trip.leg_no <= 1) return null;
  const before = await ChatTrip.findAll({
    where: { load_id: trip.load_id, leg_no: { [Op.lt]: trip.leg_no }, status: { [Op.ne]: "cancelled" } },
  });
  return byLeg(before).find((l) => !HANDED_OVER.includes(l.status)) || null;
}

/** The leg after this one (not cancelled). */
export async function nextLeg(trip: Pick<ChatTrip, "id" | "load_id" | "leg_no">): Promise<ChatTrip | null> {
  if (!trip.load_id) return null;
  const after = await ChatTrip.findAll({
    where: { load_id: trip.load_id, leg_no: { [Op.gt]: trip.leg_no }, status: { [Op.ne]: "cancelled" } },
  });
  return byLeg(after)[0] || null;
}

/** Is this the load's last leg (not counting cancelled ones)? */
export async function isLastLeg(trip: Pick<ChatTrip, "id" | "load_id" | "leg_no">): Promise<boolean> {
  return !(await nextLeg(trip));
}

/** Keep chat_loads.status in step with its legs. Returns the load (or null for an old trip). */
export async function refreshLoadStatus(loadId: number | null | undefined): Promise<ChatLoad | null> {
  if (!loadId) return null;
  const load = await ChatLoad.findByPk(loadId);
  if (!load) return null;
  const legs = await ChatTrip.findAll({ where: { load_id: loadId }, attributes: ["id", "leg_no", "status", "driver_profile_id", "ends_at_yard"] });
  const status = loadStatusOf(legs);
  if (status !== load.status) await load.update({ status });
  return load;
}

/** Leg number shown everywhere: the load's number, "-2" from the second leg on. */
export const legTripNo = (loadNo: string, legNo: number) => (legNo > 1 ? `${loadNo}-${legNo}` : loadNo);
