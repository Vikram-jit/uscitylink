import { Request, Response } from "express";
import { Op } from "sequelize";
import { ChatTrip, ChatTripStop } from "../models/ChatTrip";
import { UserProfile } from "../models/UserProfile";
import Role from "../models/Role";
import { isStaffRole } from "../middleware/requireRole";
import { parseLoad } from "../services/trips/parseLoad";
import { blockingLeg, legsOf } from "../services/trips/legs";
import { liveTrip } from "../services/trips/liveTrip";
import { TripAction } from "../services/trips/lifecycle";
import {
  act,
  Actor,
  assignmentOfDriver,
  truckAssignments,
  addProblem,
  createTrip,
  currentTripFor,
  tripsForDriver,
  upcomingFor,
  declineOffer,
  editTrip,
  getTrip,
  resolveProblem,
  sendLoad,
  syncPriced,
  TripError,
  undo,
} from "../services/trips/tripService";

// Trips (loads sent to drivers). Dispatch: Loads screen / Send load / trip panel. Driver app: the
// current trip card. Rules and the record live in services/trips; this only maps HTTP to them.

async function actorOf(req: Request): Promise<Actor> {
  const profile = await UserProfile.findByPk(req.user?.id, { include: [{ model: Role, as: "role" }] });
  const role = (profile as any)?.role?.name;
  return { role: isStaffRole(role) ? "dispatcher" : "driver", id: profile?.id || req.user?.id || null, name: profile?.username || null };
}

function fail(res: Response, err: any) {
  if (err instanceof TripError) return res.status(err.status).json({ status: false, message: err.message });
  console.error("[trips]", err);
  return res.status(500).json({ status: false, message: "Something went wrong" });
}

const ok = (res: Response, data: any, message = "OK") => res.json({ status: true, message, data });

/** Driver names for a list of trips, by chat profile id. */
async function namesFor(trips: ChatTrip[]) {
  const ids = [...new Set(trips.map((t) => t.driver_profile_id).filter(Boolean))] as string[];
  const profiles = ids.length ? await UserProfile.findAll({ where: { id: ids }, attributes: ["id", "username"] }) : [];
  return Object.fromEntries(profiles.map((p) => [p.id, p.username]));
}

export async function listTrips(req: Request, res: Response): Promise<any> {
  try {
    const where: any = {};
    const status = String(req.query.status || "").trim();
    if (status) where.status = { [Op.in]: status.split(",") };
    if (req.query.driverProfileId) where.driver_profile_id = String(req.query.driverProfileId);
    const q = String(req.query.q || "").trim();
    if (q) {
      const drivers = await UserProfile.findAll({ where: { username: { [Op.like]: `%${q}%` } }, attributes: ["id"] });
      where[Op.or] = [
        { truck_number: { [Op.like]: `%${q}%` } },
        { trip_no: { [Op.like]: `%${q}%` } },
        { trailer_numbers: { [Op.like]: `%${q}%` } },
        ...(drivers.length ? [{ driver_profile_id: drivers.map((d) => d.id) }] : []),
      ];
    }
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(req.query.limit) || 30));
    const { rows, count } = await ChatTrip.findAndCountAll({
      where,
      include: [{ model: ChatTripStop, as: "stops" }],
      // Waiting for dispatch first, then newest
      order: [
        [ChatTrip.sequelize!.literal("status = 'offered'"), "DESC"],
        ["id", "DESC"],
        [{ model: ChatTripStop, as: "stops" }, "seq", "ASC"],
      ] as any,
      distinct: true,
      limit,
      offset: (page - 1) * limit,
    });
    await syncPriced(rows);
    // How many loads are in each status, for the tab counts
    const counts = Object.fromEntries(
      ((await ChatTrip.count({ group: ["status"] })) as unknown as { status: string; count: number }[]).map((c) => [c.status, Number(c.count)])
    );
    return ok(res, { trips: rows, total: count, page, counts, driverNames: await namesFor(rows) });
  } catch (err) {
    return fail(res, err);
  }
}

export async function showTrip(req: Request, res: Response): Promise<any> {
  try {
    let trip = await getTrip(req.params.id);
    if (!trip) return res.status(404).json({ status: false, message: "Trip not found" });
    if (trip.status === "completed") {
      await syncPriced([trip]);
      trip = (await getTrip(req.params.id))!;
    }
    const actor = await actorOf(req);
    if (actor.role === "driver" && trip.driver_profile_id !== actor.id) return res.status(403).json({ status: false, message: "Not your trip" });
    // Which leg of its load, and whether the leg before still has the load (then it can't be sent yet)
    const siblings = (await legsOf(trip)).filter((l) => l.status !== "cancelled");
    const blocking = await blockingLeg(trip);
    const blockingDriver = blocking?.driver_profile_id ? (await UserProfile.findByPk(blocking.driver_profile_id))?.username || null : null;
    const handover = blocking ? (await ChatTripStop.findAll({ where: { chat_trip_id: blocking.id } })).sort((a, b) => b.seq - a.seq)[0] : null;
    return ok(res, {
      trip,
      driverNames: await namesFor([trip]),
      leg: {
        count: siblings.length || 1,
        isLast: !siblings.some((l) => l.leg_no > trip.leg_no),
        blockedBy: blocking
          ? {
              legNo: blocking.leg_no,
              tripNo: blocking.trip_no,
              status: blocking.status,
              endsAtYard: blocking.ends_at_yard,
              driverName: blockingDriver,
              place: handover ? [handover.name, [handover.city, handover.state].filter(Boolean).join(", ")].filter(Boolean).join(" · ") : null,
            }
          : null,
      },
    });
  } catch (err) {
    return fail(res, err);
  }
}

/** Driver app: the trip I'm on and what my big button does. */
export async function myCurrentTrip(req: Request, res: Response): Promise<any> {
  try {
    return ok(res, await currentTripFor(String(req.user?.id)));
  } catch (err) {
    return fail(res, err);
  }
}

/** Dispatch pastes a typed load into the form: read it so they only check the fields. */
export async function parseTripText(req: Request, res: Response): Promise<any> {
  const load = parseLoad(String(req.body?.text || ""));
  if (!load) return res.status(422).json({ status: false, message: "Couldn't find a pickup or delivery address in that text" });
  return ok(res, load);
}

export async function createTripRest(req: Request, res: Response): Promise<any> {
  try {
    const trip = await createTrip({ ...req.body, source: "form" }, await actorOf(req), { send: req.body?.send === true });
    return ok(res, trip, req.body?.send ? "Load sent" : "Load saved");
  } catch (err) {
    return fail(res, err);
  }
}

export async function editTripRest(req: Request, res: Response): Promise<any> {
  try {
    return ok(res, await editTrip(Number(req.params.id), req.body || {}, await actorOf(req)), "Trip updated");
  } catch (err) {
    return fail(res, err);
  }
}

export async function sendTripRest(req: Request, res: Response): Promise<any> {
  try {
    return ok(res, await sendLoad(Number(req.params.id), await actorOf(req)), "Load sent to the driver");
  } catch (err) {
    return fail(res, err);
  }
}

export async function declineOfferRest(req: Request, res: Response): Promise<any> {
  try {
    return ok(res, await declineOffer(Number(req.params.id), await actorOf(req)));
  } catch (err) {
    return fail(res, err);
  }
}

const ACTIONS: TripAction[] = ["accept", "start", "rolling", "arrive", "depart", "end", "paperwork", "complete", "hold", "resume", "cancel"];

export async function tripActionRest(req: Request, res: Response): Promise<any> {
  try {
    const action = String(req.body?.action || "") as TripAction;
    if (!ACTIONS.includes(action)) return res.status(400).json({ status: false, message: "Unknown action" });
    const { stopId, note, lat, lng, at, invoiceNo } = req.body || {};
    return ok(res, await act(Number(req.params.id), action, await actorOf(req), { stopId, note, lat, lng, at, invoiceNo }));
  } catch (err) {
    return fail(res, err);
  }
}

export async function undoTripRest(req: Request, res: Response): Promise<any> {
  try {
    return ok(res, await undo(Number(req.params.id), await actorOf(req)), "Undone");
  } catch (err) {
    return fail(res, err);
  }
}

export async function addProblemRest(req: Request, res: Response): Promise<any> {
  try {
    const { kind, note, amount, hold } = req.body || {};
    return ok(res, await addProblem(Number(req.params.id), { kind, note, amount, hold: hold === true }, await actorOf(req)), "Problem added");
  } catch (err) {
    return fail(res, err);
  }
}

export async function resolveProblemRest(req: Request, res: Response): Promise<any> {
  try {
    const actor = await actorOf(req);
    if (actor.role !== "dispatcher") return res.status(403).json({ status: false, message: "Dispatch resolves problems" });
    return ok(res, await resolveProblem(Number(req.params.id), Number(req.params.problemId), actor), "Resolved");
  } catch (err) {
    return fail(res, err);
  }
}

/** Truck picker: trucks matching the search, each with its assigned driver(s). */
export async function listTruckAssignments(req: Request, res: Response): Promise<any> {
  try {
    return ok(res, await truckAssignments(String(req.query.q || "")));
  } catch (err) {
    return fail(res, err);
  }
}

/** Send load from a driver's chat: their truck (and team) is filled in. */
export async function driverAssignment(req: Request, res: Response): Promise<any> {
  try {
    return ok(res, await assignmentOfDriver(String(req.params.profileId)));
  } catch (err) {
    return fail(res, err);
  }
}

/** Trip panel map: the truck now (Samsara) and the road ahead with ETAs (Google). Staff only. */
export async function liveTripRest(req: Request, res: Response): Promise<any> {
  try {
    const trip = await getTrip(req.params.id);
    if (!trip) return res.status(404).json({ status: false, message: "Trip not found" });
    return ok(res, await liveTrip(trip, trip.stops || []));
  } catch (err) {
    return fail(res, err);
  }
}

/** Driver app Loads screen: my loads, newest first. */
export async function myTrips(req: Request, res: Response): Promise<any> {
  try {
    const page = Math.max(1, Number(req.query.page) || 1);
    return ok(res, await tripsForDriver(String(req.user?.id), page));
  } catch (err) {
    return fail(res, err);
  }
}

/** Driver app: loads lined up for me, not sent yet (read-only "Up next"). */
export async function myUpcoming(req: Request, res: Response): Promise<any> {
  try {
    return ok(res, await upcomingFor(String(req.user?.id)));
  } catch (err) {
    return fail(res, err);
  }
}
