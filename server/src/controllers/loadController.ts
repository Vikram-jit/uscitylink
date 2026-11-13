import { Request, Response } from "express";
import { UserProfile } from "../models/UserProfile";
import Role from "../models/Role";
import { isStaffRole } from "../middleware/requireRole";
import { Actor, addMileage, NO_GPS_NOTE, TripError } from "../services/trips/tripService";
import { addLeg, addLoad, answerTypedLoad, convertMessageToLoad, loadFromText, assignLeg, createLoad, defaultYardStop, getLoad, listLoads, lookupLoad, NeedsAnswer, updateLoad } from "../services/trips/loadService";
import { conflictsFor, driversBoard, trailersBoard, trucksBoard } from "../services/trips/equipment";
import { placeStop, PlacesError, searchPlaces } from "../services/trips/places";
import { lineupOf, removeFromLineup, reorderLineup } from "../services/trips/lineup";
import { refreshLoadStatus } from "../services/trips/legs";
import { ChatTrip } from "../models/ChatTrip";
import { changeType, correctTimes, endLegNow, releaseLeg, setMiles, splitLeg, truckPlace, undoSplit } from "../services/trips/loadControl";
import { milesReport } from "../services/trips/milesReport";
import { deleteLegOfMessage, loadsOfMessage } from "../services/trips/messageLoads";
import { missedLoads, repairApply, repairPreview } from "../services/trips/messageRepair";

// Loads (a load = invoice # + its legs) and the equipment board, for dispatch. The rules live in
// services/trips (loadService, equipment, tripService); this only maps HTTP to them.

async function actorOf(req: Request): Promise<Actor> {
  const profile = await UserProfile.findByPk(req.user?.id, { include: [{ model: Role, as: "role" }] });
  const role = (profile as any)?.role?.name;
  return { role: isStaffRole(role) ? "dispatcher" : "driver", id: profile?.id || req.user?.id || null, name: profile?.username || null };
}

const ok = (res: Response, data: any, message = "OK") => res.json({ status: true, message, data });

function fail(res: Response, err: any) {
  // Dispatch has to answer first (end the previous leg / the driver's current load)
  if (err instanceof NeedsAnswer) return res.status(409).json({ status: false, message: err.message, needs: err.needs, info: err.info });
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
  const body = req.body || {};
  const send = body.send === true;
  // The simple form: one load (Load # decides if it's a new load or the next leg). Old multi-leg body still works.
  if (!Array.isArray(body.legs)) {
    const { send: _s, endPrevious, endDriverCurrent, lineUp, replace, groupId, ...input } = body;
    // groupId: sent from a truck chat — the load message shows in that chat
    const data = await addLoad(input, await actorOf(req), { send, endPrevious: endPrevious === true, endDriverCurrent: endDriverCurrent === true, lineUp: lineUp === true, replace: replace === true, groupId: groupId || null });
    return { data, message: send && !lineUp ? "Load sent" : lineUp ? "Lined up after the driver's current load" : "Load saved" };
  }
  return { data: await createLoad(body, await actorOf(req), { send }), message: send ? "Load sent" : "Load saved" };
});

/** Add-load form: what this Load # is (new, or leg N after …) and whether the driver is busy. */
export const lookupLoadRest = handle(async (req) => ({ data: await lookupLoad(req.query.no as string, (req.query.driver as string) || null) }));

/** Dispatch ends a leg the driver didn't end. */
export const endLegRest = handle(async (req) => {
  await endLegNow(Number(req.params.legId), await actorOf(req), { at: req.body?.at ?? null });
  return { data: await getLoad(Number(req.params.id)), message: "Load ended" };
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

/** Dispatch answers the pop-up about a load typed in chat (End & send / Line up). */
export const answerTypedRest = handle(async (req) => {
  const b = req.body || {};
  const data = await answerTypedLoad(String(req.params.pendingId), { endPrevious: b.endPrevious === true, endDriverCurrent: b.endDriverCurrent === true, lineUp: b.lineUp === true, replace: b.replace === true }, await actorOf(req));
  return { data, message: data.kind === "sent" ? `Load ${data.loadNo} sent` : "One more question" };
});

/** Read the leg's times and miles from the truck's GPS again (Samsara had a gap / the driver didn't tap). */
export const matchGpsRest = handle(async (req) => {
  const legId = Number(req.params.legId);
  const leg = await ChatTrip.findByPk(legId);
  if (!leg || leg.load_id !== Number(req.params.id)) throw new TripError("Leg not found", 404);
  if (!leg.ended_at) throw new TripError("This leg hasn't ended yet — miles are read when it ends");
  if (leg.miles_source === "manual") throw new TripError("These miles were typed — use Samsara again in Miles first");
  await addMileage(legId, { forceGps: true });
  const fresh = await ChatTrip.findByPk(legId);
  return {
    data: await getLoad(Number(req.params.id)),
    message: fresh?.miles_note === NO_GPS_NOTE ? "Still no GPS match — check the times or type the miles" : `Miles re-checked from the truck's GPS: ${fresh?.total_mileage ?? "—"} mi`,
  };
});

/**
 * A load pasted / typed in a driver's chat box. The chat box sends it here instead of as a chat
 * message, so nothing reaches the driver until it's really sent: same questions as Add load (409),
 * Send → the driver gets the standard load message; Line up → the driver gets nothing yet.
 */
export const fromTextRest = handle(async (req) => {
  const b = req.body || {};
  const answers = { endPrevious: b.endPrevious === true, endDriverCurrent: b.endDriverCurrent === true, lineUp: b.lineUp === true, replace: b.replace === true };
  const { data, loadNo } = await loadFromText(String(b.text || ""), String(b.driverProfileId || "") || null, await actorOf(req), answers, b.channelId || null, b.groupId || null);
  return { data, message: answers.lineUp && !answers.endDriverCurrent ? `Load ${loadNo} lined up — it goes to the driver when their current load is delivered` : `Load ${loadNo} sent to the driver` };
});

/** Before deleting a chat message: the load(s) it made, so the app can ask "delete the load too?" */
export const loadsOfMessageRest = handle(async (req) => ({ data: await loadsOfMessage(String(req.params.messageId)) }));

/** Confirmed: delete the leg this message made (the whole load when it's the only leg). */
export const deleteLoadOfMessageRest = handle(async (req) => {
  const res = await deleteLegOfMessage(String(req.params.messageId), Number(req.params.legId), await actorOf(req));
  return { data: res, message: res.deletedLoad ? "Load deleted" : "Leg deleted" };
});

/** "Convert to load" on a chat message: adds it to Loads (lined up) — nothing is sent to the driver. */
export const convertMessageRest = handle(async (req) => {
  const out = await convertMessageToLoad(String(req.params.messageId), await actorOf(req), { loadNo: req.body?.loadNo ?? null });
  return {
    data: out.data,
    message: out.already
      ? `Load ${out.loadNo} is already in Loads`
      : out.plan
        ? `Load ${out.loadNo} added as a plan — no address was found; add the stops from Loads`
        : `Load ${out.loadNo} added to Loads — not sent to the driver`,
  };
});

/** Repair / Add to loads, step 1: what re-reading the message would change (nothing is changed). */
export const repairPreviewRest = handle(async (req) => ({ data: await repairPreview(String(req.params.messageId)) }));

/** Step 2, after dispatch confirms: fix the load and replace the assistant's old message text. */
export const repairApplyRest = handle(async (req) => {
  const out = await repairApply(String(req.params.messageId), await actorOf(req), { loadNo: req.body?.loadNo ?? null });
  return { data: { load: out.data, replaced: out.replaced }, message: out.message };
});

/** Recent chat messages that look like loads but aren't in Loads, and loads made from them wrongly. */
export const missedLoadsRest = handle(async (req) => ({ data: await missedLoads(Number(req.query.days) || 14) }));
