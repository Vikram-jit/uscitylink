import { Op } from "sequelize";
import { ChatLoad, ChatTrip, ChatTripEvent, ChatTripProblem, ChatTripStop, newTrackToken, uniqueTrackCode } from "../../models/ChatTrip";
import { byLeg } from "./legs";
import { liveTrip } from "./liveTrip";

// The public tracking page for shippers / customers (/track/<token>, no login). Only what a customer
// should see: load #, where it is, ETA, stops with appointment and actual times, and an activity feed
// in plain words. Never driver names / phones, internal notes, problems or pay. Once the load is
// completed or cancelled the link only says so (expired).

const ON_THE_WAY = ["accepted", "started", "rolling", "on_hold"];
const CACHE_MS = 30_000;
const cache = new Map<string, { at: number; value: any }>();

export class TrackingNotFound extends Error {}

/** The load's tracking token (made the first time for loads from before tracking links) */
export async function trackToken(load: ChatLoad): Promise<string> {
  const changes: Record<string, string> = {};
  if (!load.track_token) changes.track_token = newTrackToken();
  if (!load.track_code) changes.track_code = await uniqueTrackCode();
  if (Object.keys(changes).length) await load.update(changes);
  return load.track_token!;
}

/**
 * The app's "Track a load": the customer types the load number exactly as on their order (or one
 * of the older random codes) and gets the same view as the link.
 */
export async function trackingByCode(code: string) {
  const clean = String(code || "").trim().toUpperCase().replace(/[^A-Z0-9-]/g, "");
  if (clean.length < 3) throw new TrackingNotFound("No load with that tracking code");
  let load = await ChatLoad.findOne({ where: { track_code: clean } });
  if (!load) {
    // That exact load number; active loads first, then the latest
    load = await ChatLoad.findOne({
      where: { invoice_no: clean, status: { [Op.ne]: "cancelled" } },
      order: [[ChatLoad.sequelize!.literal("status = 'completed'"), "ASC"], ["id", "DESC"]],
    });
  }
  if (!load) throw new TrackingNotFound("No load with that tracking code");
  return trackingView(await trackToken(load));
}

// Load numbers are guessable, so one device can only try so many numbers
const tries = new Map<string, { n: number; resetAt: number }>();
export const MAX_TRIES = 30;
const WINDOW_MS = 10 * 60_000;
/** false once [who] (an IP) has tried too many codes in 10 minutes */
export function allowLookup(who: string, now = Date.now()): boolean {
  const t = tries.get(who);
  if (!t || now > t.resetAt) {
    tries.set(who, { n: 1, resetAt: now + WINDOW_MS });
    if (tries.size > 5000) for (const [k, v] of tries) if (now > v.resetAt) tries.delete(k);
    return true;
  }
  t.n += 1;
  return t.n <= MAX_TRIES;
}

const placeOf = (s: ChatTripStop) => [s.city, s.state].filter(Boolean).join(", ");
const iso = (d?: Date | string | null) => (d ? new Date(d).toISOString() : null);

type Phase = "booked" | "dispatched" | "picked_up" | "in_transit" | "delivered";

const HOLD_REASON: Record<string, string> = {
  delay: "Delayed",
  breakdown: "Truck issue — being fixed",
  detention: "Waiting at the dock",
  lumper: "Unloading",
  rejected: "Load being checked",
  shortage: "Load being checked",
  damage: "Load being checked",
  other: "Delayed",
};

const miles = (a: { lat: number; lng: number }, b: { lat: number; lng: number }) => {
  const r = (d: number) => (d * Math.PI) / 180;
  const h = Math.sin(r(b.lat - a.lat) / 2) ** 2 + Math.cos(r(a.lat)) * Math.cos(r(b.lat)) * Math.sin(r(b.lng - a.lng) / 2) ** 2;
  return 3958.8 * 2 * Math.asin(Math.sqrt(h));
};

/** The truck isn't moving: since when, where, and why when we know (at a stop, a reported delay, resting). */
async function stoppedInfo(leg: ChatTrip, lt: Awaited<ReturnType<typeof liveTrip>>) {
  const t = lt.truck!;
  const since = t.stoppedSince || null;
  const minutes = since ? Math.max(0, Math.round((Date.now() - new Date(since).getTime()) / 60000)) : null;
  let reason: string | null = null;
  // A reported problem that put the trip on hold (kind only — never the note)
  if (leg.status === "on_hold") {
    const p = (leg as any).problems?.find?.((x: any) => !x.resolved_at);
    reason = HOLD_REASON[p?.kind] || "Delayed — dispatch is on it";
  }
  // At (or very near) one of the stops
  if (!reason) {
    const near = lt.stops.find((s) => s.lat !== null && s.lng !== null && miles(t, { lat: s.lat!, lng: s.lng! }) < 1);
    if (near) reason = near.type === "pickup" ? "At the pickup" : near.type === "drop" ? "At the delivery" : "At the transfer point";
  }
  if (!reason && minutes !== null) {
    if (minutes >= 120 && (t.engine === "Off" || t.engine === null)) reason = "Rest stop (driver hours-of-service)";
    else if (minutes >= 25) reason = "Break";
    else reason = "Short stop";
  }
  return { since, minutes, address: t.address, reason };
}

export async function trackingView(token: string) {
  const hit = cache.get(token);
  if (hit && Date.now() - hit.at < CACHE_MS) return hit.value;

  const load = await ChatLoad.findOne({ where: { track_token: token } });
  if (!load) throw new TrackingNotFound("Tracking link not found");
  const legs = byLeg(
    await ChatTrip.findAll({
      where: { load_id: load.id },
      include: [
        { model: ChatTripStop, as: "stops" },
        { model: ChatTripEvent, as: "events" },
        { model: ChatTripProblem, as: "problems" },
      ],
    })
  ).filter((l) => l.status !== "cancelled");
  const loadNo = load.invoice_no || load.load_no;
  const last = legs[legs.length - 1];
  const deliveredAt = last?.ended_at ? iso(last.ended_at) : null;

  // Expired: the load is done — the link says so and nothing more
  if (["completed", "cancelled"].includes(load.status)) {
    const value = { expired: true, loadNo, status: load.status, deliveredAt };
    cache.set(token, { at: Date.now(), value });
    return value;
  }

  // Stops across legs; a later leg's first stop is where the previous one handed over (shown once)
  const stops: any[] = [];
  legs.forEach((leg, i) => {
    const list = [...(leg.stops || [])].sort((a, b) => a.seq - b.seq);
    list.forEach((s, j) => {
      if (i > 0 && j === 0 && (s.type === "switch" || s.type === "yard")) return;
      stops.push({
        id: s.id,
        type: s.type === "switch" || s.type === "yard" ? "transfer" : s.type,
        name: s.type === "switch" || s.type === "yard" ? null : s.name,
        place: placeOf(s),
        address: s.type === "switch" || s.type === "yard" ? null : [s.street, [s.city, [s.state, s.zip].filter(Boolean).join(" ")].filter(Boolean).join(", ")].filter(Boolean).join(", "),
        appointment: s.appointment_local,
        timezone: s.timezone,
        arrivedAt: iso(s.arrived_at),
        departedAt: iso(s.departed_at),
        lat: null,
        lng: null,
      });
    });
  });
  // Rolling means the pickups are done (the driver isn't asked to tap each one)
  const firstRolling = legs.find((l) => l.started_at);
  if (firstRolling) for (const s of stops) if (s.type === "pickup" && !s.departedAt && legs.indexOf(firstRolling) >= 0) s.departedAt = s.departedAt || iso(firstRolling.started_at);
  const nextIdx = stops.findIndex((s) => !s.arrivedAt && !(s.type === "pickup" && s.departedAt));
  stops.forEach((s, i) => (s.state = i < nextIdx || nextIdx < 0 ? "done" : i === nextIdx ? "next" : "upcoming"));

  // Phase for the steps
  const anySent = legs.some((l) => l.sent_at);
  const pickedUp = legs.some((l) => l.started_at);
  const delivered = !!last && ["ended", "paperwork"].includes(last.status);
  const phase: Phase = delivered ? "delivered" : pickedUp ? "in_transit" : anySent ? "dispatched" : "booked";

  // Live: the leg that has the load now
  const current = legs.find((l) => ON_THE_WAY.includes(l.status)) || null;
  let live: any = null;
  if (current) {
    try {
      const lt = await liveTrip(current, current.stops || []);
      live = {
        truck: lt.truck
          ? { lat: lt.truck.lat, lng: lt.truck.lng, headingDegrees: lt.truck.headingDegrees, speedMph: lt.truck.speedMph, address: lt.truck.address, at: lt.truck.at, fuelPercent: null, engine: lt.truck.engine, vehicleName: current.truck_number }
          : null,
        stops: lt.stops.map((s) => ({ ...s, name: s.type === "switch" || s.type === "yard" ? "Transfer point" : s.name })),
        path: lt.path,
        miles: lt.miles,
        eta: lt.eta,
        updatedAt: lt.updatedAt,
        // Breaks / rests / fuel the ETA already counts (US hours-of-service + fuel every 1,000 mi)
        breaks: (lt.plan?.stops || []).map((b) => ({ kind: b.kind, minutes: b.minutes, at: b.at, atMile: b.atMile })),
        stopped: lt.truck && (lt.truck.speedMph || 0) <= 3 ? await stoppedInfo(current, lt) : null,
      };
    } catch {
      live = null;
    }
  }
  // Late / on time against the delivery appointment
  const lastStop = [...stops].reverse().find((s) => s.type === "drop") || stops[stops.length - 1];
  const lastAppt = last ? [...(last.stops || [])].sort((a, b) => a.seq - b.seq).pop()?.appointment_at : null;
  const etaAt = live?.eta ? new Date(live.eta) : null;
  const lateMinutes = etaAt && lastAppt ? Math.round((etaAt.getTime() - new Date(lastAppt).getTime()) / 60000) : null;

  // Activity in plain words (no names, notes or problems)
  const activity: { at: string; text: string }[] = [];
  activity.push({ at: iso(load.created_at)!, text: "Load booked" });
  legs.forEach((leg, i) => {
    const handsOver = leg.id !== last?.id;
    const stopsOf = new Map((leg.stops || []).map((s) => [s.id, s]));
    for (const e of leg.events || []) {
      const at = iso(e.happened_at || e.created_at)!;
      const stop = e.stop_id ? stopsOf.get(Number(e.stop_id)) : null;
      if (e.type === "status") {
        if (e.to_status === "planned" && i === 0) activity.push({ at, text: "Dispatched to the driver" });
        else if (e.to_status === "accepted") activity.push({ at, text: i === 0 ? "Driver confirmed the load" : "Next driver confirmed the load" });
        else if (e.to_status === "rolling") activity.push({ at, text: i === 0 ? "Picked up — in transit" : "In transit with the next truck" });
        else if (e.to_status === "ended") activity.push({ at, text: handsOver ? "Arrived at the transfer point" : "Delivered" });
        else if (e.to_status === "on_hold") {
          const p = (leg.problems || []).find((x) => Math.abs(new Date(x.created_at).getTime() - new Date(at).getTime()) < 5 * 60_000);
          activity.push({ at, text: p ? `${HOLD_REASON[p.kind] || "Delayed"} — dispatch is on it` : "Delayed — dispatch is on it" });
        }
        else if (e.from_status === "on_hold") activity.push({ at, text: "Moving again" });
      } else if (e.type === "stop_arrived" && stop) activity.push({ at, text: `Arrived at ${stop.type === "switch" || stop.type === "yard" ? "the transfer point" : stop.name || placeOf(stop)}` });
      else if (e.type === "stop_departed" && stop) activity.push({ at, text: `Departed ${stop.type === "switch" || stop.type === "yard" ? "the transfer point" : stop.name || placeOf(stop)}` });
      else if (e.type === "transfer" && e.data?.transferTo) activity.push({ at, text: "Handed over to another truck" });
    }
  });
  activity.sort((a, b) => new Date(b.at).getTime() - new Date(a.at).getTime());

  const value = {
    expired: false,
    loadNo,
    phase,
    status: load.status,
    legs: legs.length,
    equipment: current || last ? { truck: (current || last)!.truck_number, trailer: (current || last)!.trailer_numbers, temperature: (current || last)!.temperature } : null,
    stops,
    nextStop: nextIdx >= 0 ? stops[nextIdx] : null,
    live,
    eta: live?.eta || null,
    lateMinutes,
    deliveredAt,
    lastStopName: lastStop ? lastStop.name || lastStop.place : null,
    activity,
    updatedAt: new Date().toISOString(),
  };
  cache.set(token, { at: Date.now(), value });
  return value;
}
