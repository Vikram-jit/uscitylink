import { Request, Response } from "express";
import { UserProfile } from "../models/UserProfile";
import Role from "../models/Role";
import { isStaffRole } from "../middleware/requireRole";
import { Actor, TripError } from "../services/trips/tripService";
import { addLeg, assignLeg, createLoad, defaultYardStop, getLoad, listLoads, updateLoad } from "../services/trips/loadService";
import { conflictsFor, driversBoard, trailersBoard, trucksBoard } from "../services/trips/equipment";
import { placeStop, PlacesError, searchPlaces } from "../services/trips/places";
import { lineupOf, removeFromLineup, reorderLineup } from "../services/trips/lineup";
import { refreshLoadStatus } from "../services/trips/legs";
import { ChatTrip } from "../models/ChatTrip";
import { changeType, correctTimes, releaseLeg, setMiles, splitLeg, truckPlace, undoSplit } from "../services/trips/loadControl";
import { milesReport } from "../services/trips/milesReport";

// Loads (a load = invoice # + its legs) and the equipment board, for dispatch. The rules live in
// services/trips (loadService, equipment, tripService); this only maps HTTP to them.

async function actorOf(req: Request): Promise<Actor> {
  const profile = await UserProfile.findByPk(req.user?.id, { include: [{ model: Role, as: "role" }] });
  const role = (profile as any)?.role?.name;
  return { role: isStaffRole(role) ? "dispatcher" : "driver", id: profile?.id || req.user?.id || null, name: profile?.username || null };
}

const ok = (res: Response, data: any, message = "OK") => res.json({ status: true, message, data });

function fail(res: Response, err: any) {
  if (err instanceof PlacesError) return res.status(400).json({ status: false, message: err.message });
  if (err instanceof TripError) return res.status(err.status).json({ status: false, message: err.message });
  console.error("[loads]", err);
  return res.status(500).json({ status: false, message: "Something went wrong" });
}

const handle = (fn: (req: Request) => Promise<{ data: any; message?: string }>) => async (req: Request, res: Response): Promise<any> => {
  try {
    const { data, message } = await fn(req);
    return ok(res, data, message);
  } catch (err) {
    return fail(res, err);
  }
};

export const listLoadsRest = handle(async (req) => ({
  data: await listLoads({ status: req.query.status as string, q: req.query.q as string, page: Number(req.query.page), limit: Number(req.query.limit) }),
}));

export const showLoadRest = handle(async (req) => ({ data: await getLoad(Number(req.params.id)) }));

export const createLoadRest = handle(async (req) => {
  const send = req.body?.send === true;
  return { data: await createLoad(req.body || { legs: [] }, await actorOf(req), { send }), message: send ? "Load sent" : "Load saved" };
});

export const updateLoadRest = handle(async (req) => ({ data: await updateLoad(Number(req.params.id), req.body || {}, await actorOf(req)), message: "Load updated" }));

export const addLegRest = handle(async (req) => ({ data: await addLeg(Number(req.params.id), req.body || { stops: [] }, await actorOf(req)), message: "Leg added" }));

export const assignLegRest = handle(async (req) => ({
  data: await assignLeg(Number(req.params.id), Number(req.params.legId), req.body || {}, await actorOf(req)),
  message: req.body?.send ? "Leg assigned and sent" : "Leg assigned",
}));

export const yardStopRest = handle(async () => ({ data: await defaultYardStop() }));

export const equipmentRest = handle(async (req) => {
  const kind = String(req.params.kind);
  if (kind === "trucks") return { data: await trucksBoard() };
  if (kind === "trailers") return { data: await trailersBoard() };
  if (kind === "drivers") return { data: await driversBoard() };
  throw new TripError("Unknown equipment kind", 404);
});

export const conflictsRest = handle(async (req) => {
  const list = (v: any) => (Array.isArray(v) ? v : String(v || "").split(",")).map((x: string) => x.trim()).filter(Boolean);
  return {
    data: await conflictsFor({
      truckNumber: (req.query.truck as string) || null,
      trailerNumbers: list(req.query.trailers),
      driverProfileIds: list(req.query.drivers),
      loadId: req.query.loadId ? Number(req.query.loadId) : null,
      tripId: req.query.tripId ? Number(req.query.tripId) : null,
    }),
  };
});

/** Stop address search (Google Places, key on the server). */
export const searchPlacesRest = handle(async (req) => ({ data: await searchPlaces(String(req.query.q || ""), (req.query.session as string) || undefined) }));
export const placeStopRest = handle(async (req) => ({ data: await placeStop(String(req.params.placeId), (req.query.session as string) || undefined) }));

/** A driver's lineup: the load they're on and the ones lined up next, in order. */
export const lineupRest = handle(async (req) => ({ data: await lineupOf(String(req.params.profileId)) }));

export const reorderLineupRest = handle(async (req) => {
  const ids = Array.isArray(req.body?.tripIds) ? req.body.tripIds.map(Number) : [];
  return { data: await reorderLineup(String(req.params.profileId), ids, await actorOf(req)), message: "Lineup order saved" };
});

export const removeFromLineupRest = handle(async (req) => {
  const trip = await ChatTrip.findByPk(Number(req.params.tripId));
  const data = await removeFromLineup(String(req.params.profileId), Number(req.params.tripId), await actorOf(req));
  await refreshLoadStatus(trip?.load_id);
  return { data, message: "Taken off the lineup — the load waits for a driver" };
});

// ---------- full control of a load ----------

/** The leg's truck position as a stop (default handover place). */
export const truckPlaceRest = handle(async (req) => ({ data: await truckPlace(Number(req.params.legId)) }));

export const splitLegRest = handle(async (req) => {
  const res = await splitLeg(Number(req.params.legId), req.body || {}, await actorOf(req));
  return { data: await getLoad(Number(req.params.id)), message: res ? "Load handed over" : "Done" };
});

export const undoSplitRest = handle(async (req) => {
  await undoSplit(Number(req.params.legId), await actorOf(req));
  return { data: await getLoad(Number(req.params.id)), message: "Handover undone" };
});

export const changeTypeRest = handle(async (req) => {
  await changeType(Number(req.params.id), req.body || {}, await actorOf(req));
  return { data: await getLoad(Number(req.params.id)), message: "Load type changed" };
});

export const correctTimesRest = handle(async (req) => {
  const { reason, ...times } = req.body || {};
  await correctTimes(Number(req.params.legId), times, String(reason || ""), await actorOf(req));
  return { data: await getLoad(Number(req.params.id)), message: "Times corrected" };
});

export const setMilesRest = handle(async (req) => {
  const miles = req.body?.miles === null || req.body?.miles === "" || req.body?.miles === undefined ? null : Number(req.body.miles);
  await setMiles(Number(req.params.legId), miles, req.body?.note ?? null, await actorOf(req));
  return { data: await getLoad(Number(req.params.id)), message: miles === null ? "Miles back to Samsara" : "Miles saved" };
});

/** Miles by driver / by truck in a date range (pay, maintenance). */
export const milesRest = handle(async (req) => {
  const to = req.query.to ? new Date(String(req.query.to)) : new Date();
  const from = req.query.from ? new Date(String(req.query.from)) : new Date(to.getTime() - 7 * 86400000);
  if (!Number.isFinite(from.getTime()) || !Number.isFinite(to.getTime())) throw new TripError("Pick valid dates");
  return { data: await milesReport({ by: req.query.by === "truck" ? "truck" : "driver", from, to, q: (req.query.q as string) || "" }) };
});

/** The handover happened (the driver before didn't tap it): mark it and send this leg to its driver. */
export const releaseLegRest = handle(async (req) => {
  await releaseLeg(Number(req.params.legId), { at: req.body?.at ?? null }, await actorOf(req));
  return { data: await getLoad(Number(req.params.id)), message: "Handed over — sent to the driver" };
});
