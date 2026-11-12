import { QueryTypes } from "sequelize";
import { secondarySequelize } from "../../sequelize";
import type { ChatTrip, ChatTripStop } from "../../models/ChatTrip";
import { elapsedAt, planTrip, truckDriving, type StopKind } from "./hosPlan";

// Where a trip's truck is right now (Samsara) and the road ahead (Google Directions, with traffic):
// miles, drive time and ETA to every remaining stop against its appointment, the route line for the
// map, and the diesel it will take. Shown live in the dispatch trip panel. Keys stay on the server:
// SAMSARA_API_KEY, GOOGLE_PLACES_API_KEY (Directions API enabled on it).

/** The yard's "normal" average (Route List form flags below 6.5 mpg) — used to estimate diesel. */
export const MPG = 6.5;
const SAMSARA_TTL_MS = 30_000;

const ROUTE_TTL_MS = 120_000;
// A truck that moved less than this since the last route keeps that route (no new Google call)
const REROUTE_MILES = 2;

export interface TruckNow {
  lat: number;
  lng: number;
  headingDegrees: number | null;
  speedMph: number | null;
  address: string | null;
  at: string;
  fuelPercent: number | null;
  engine: string | null;
  vehicleName: string | null;
  /** Stopped (speed ≤ 3 mph) since — known once the truck has been watched moving / stopping */
  stoppedSince?: string | null;
}

// When each truck stopped moving (Samsara only says where it is now): remembered while the server runs
const motion = new Map<string, { moving: boolean; since: number }>();
const MOVING_MPH = 3;

/** Marks the truck's stopped-since time; the first sighting of a stopped truck counts from its GPS time. */
export function trackMotion(key: string, truck: TruckNow): TruckNow {
  const moving = (truck.speedMph || 0) > MOVING_MPH;
  const seenAt = new Date(truck.at).getTime() || Date.now();
  const prev = motion.get(key);
  if (!prev || prev.moving !== moving) motion.set(key, { moving, since: seenAt });
  const now = motion.get(key)!;
  return { ...truck, stoppedSince: moving ? null : new Date(now.since).toISOString() };
}

export interface StopEta {
  stopId: number;
  seq: number;
  type: string;
  name: string | null;
  place: string;
  lat: number | null;
  lng: number | null;
  /** From the previous point (the truck for the first) */
  miles: number;
  driveMinutes: number;
  eta: string;
  /** Minutes early (negative) or late (positive) against the appointment; null when none */
  lateMinutes: number | null;
}
// ETAs include every stop the truck has to make on the way (hosPlan.ts: US hours-of-service + fuel)

/** A stop the driver will have to make on the road ahead */
export interface RoadStop {
  kind: StopKind;
  minutes: number;
  /** Miles from the truck's position */
  atMile: number;
  /** Driving done before it (minutes) */
  afterDrivingMinutes: number;
  /** When it starts */
  at: string;
}

/** How the ETA is made up: driving + breaks + rests + fuel stops = total */
export interface EtaPlan {
  /** Google's drive time with traffic, for cars */
  googleMinutes: number;
  /** Truck driving time (never faster than 60 mph average) */
  drivingMinutes: number;
  breakMinutes: number;
  restMinutes: number;
  fuelMinutes: number;
  totalMinutes: number;
  stops: RoadStop[];
}

export interface LiveTrip {
  truck: TruckNow | null;
  truckProblem: string | null;
  stops: StopEta[];
  /** Whole remaining route */
  miles: number | null;
  driveMinutes: number | null;
  /** Breaks, rests and fuel stops added to the ETA (see plan) */
  restMinutes: number | null;
  plan: EtaPlan | null;
  team: boolean;
  eta: string | null;
  fuelGallons: number | null;
  /** [lat, lng] points of the route line */
  path: [number, number][];
  routeProblem: string | null;
  updatedAt: string;
}

const cache = new Map<string, { at: number; value: any }>();
const cached = async <T>(key: string, ttl: number, load: () => Promise<T>): Promise<T> => {
  const hit = cache.get(key);
  if (hit && Date.now() - hit.at < ttl) return hit.value as T;
  const value = await load();
  cache.set(key, { at: Date.now(), value });
  return value;
};

// ---------- Samsara: the truck now ----------

async function samsaraVehicleId(trip: ChatTrip): Promise<string | null> {
  if (trip.truck_id) {
    const rows = await secondarySequelize.query<{ samsara_vehicle_id: string | null }>(`SELECT samsara_vehicle_id FROM trucks WHERE id = :id`, {
      replacements: { id: trip.truck_id },
      type: QueryTypes.SELECT,
    });
    if (rows[0]?.samsara_vehicle_id) return String(rows[0].samsara_vehicle_id);
  }
  return null;
}

async function truckNow(trip: ChatTrip): Promise<{ truck: TruckNow | null; problem: string | null }> {
  if (!process.env.SAMSARA_API_KEY) return { truck: null, problem: "Samsara isn't set up on the server" };
  const vehicleId = await samsaraVehicleId(trip);
  // Samsara names vehicles by truck number: the fallback when the yard has no Samsara id
  const byName = !vehicleId && trip.truck_number ? trip.truck_number : null;
  if (!vehicleId && !byName) return { truck: null, problem: "No truck on this trip" };
  return cached(`truck:${vehicleId || byName}`, SAMSARA_TTL_MS, async () => {
    const url = new URL("https://api.samsara.com/fleet/vehicles/stats");
    url.searchParams.set("types", "gps,fuelPercents,engineStates");
    if (vehicleId) url.searchParams.set("vehicleIds", vehicleId);
    try {
      let data: any[] = [];
      let after = "";
      // By name: page through the fleet's latest stats (one call per ~512 trucks)
      for (let page = 0; page < 5; page++) {
        if (after) url.searchParams.set("after", after);
        const res = await fetch(url, { headers: { Authorization: `Bearer ${process.env.SAMSARA_API_KEY}`, Accept: "application/json" } });
        if (!res.ok) return { truck: null, problem: `Samsara answered ${res.status}` };
        const json: any = await res.json();
        data = data.concat(json?.data || []);
        if (vehicleId || data.some((v) => String(v?.name).trim() === byName) || !json?.pagination?.hasNextPage) break;
        after = json.pagination.endCursor;
      }
      const v = vehicleId ? data[0] : data.find((x) => String(x?.name).trim() === byName);
      if (!v?.gps) return { truck: null, problem: `Samsara has no location for truck ${trip.truck_number || ""}`.trim() };
      return {
        truck: {
          lat: Number(v.gps.latitude),
          lng: Number(v.gps.longitude),
          headingDegrees: v.gps.headingDegrees ?? null,
          speedMph: v.gps.speedMilesPerHour ?? null,
          address: v.gps.reverseGeo?.formattedLocation || null,
          at: v.gps.time,
          fuelPercent: v.fuelPercent?.value ?? null,
          engine: v.engineState?.value ?? null,
          vehicleName: v.name ?? null,
        },
        problem: null,
      };
    } catch (e: any) {
      return { truck: null, problem: `Samsara unreachable: ${e?.message || e}` };
    }
  });
}

// ---------- Google: the road ahead ----------

const address = (s: ChatTripStop) => [s.street, s.city, [s.state, s.zip].filter(Boolean).join(" ")].filter(Boolean).join(", ");
const place = (s: ChatTripStop) => [s.city, s.state].filter(Boolean).join(", ");

/** Stops still ahead: everything before Rolling; after it the deliveries (the load is on). */
function remainingStops(trip: ChatTrip, stops: ChatTripStop[]): ChatTripStop[] {
  const ordered = [...stops].sort((a, b) => a.seq - b.seq);
  if (["ended", "paperwork", "completed", "routed", "cancelled"].includes(trip.status)) return [];
  const notArrived = ordered.filter((s) => !s.arrived_at);
  if (trip.status === "rolling") return notArrived.filter((s) => s.type !== "pickup");
  return notArrived;
}

/** Google's encoded polyline → [lat, lng] points. */
export function decodePolyline(encoded: string): [number, number][] {
  const points: [number, number][] = [];
  let i = 0;
  let lat = 0;
  let lng = 0;
  while (i < encoded.length) {
    for (const which of [0, 1]) {
      let shift = 0;
      let result = 0;
      let byte: number;
      do {
        byte = encoded.charCodeAt(i++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      const delta = result & 1 ? ~(result >> 1) : result >> 1;
      if (which === 0) lat += delta;
      else lng += delta;
    }
    points.push([lat / 1e5, lng / 1e5]);
  }
  return points;
}

const milesBetween = (a: { lat: number; lng: number }, b: { lat: number; lng: number }) => {
  const rad = (d: number) => (d * Math.PI) / 180;
  const h = Math.sin(rad(b.lat - a.lat) / 2) ** 2 + Math.cos(rad(a.lat)) * Math.cos(rad(b.lat)) * Math.sin(rad(b.lng - a.lng) / 2) ** 2;
  return 3958.8 * 2 * Math.asin(Math.sqrt(h));
};

async function routeAhead(trip: ChatTrip, origin: { lat: number; lng: number } | null, ahead: ChatTripStop[]) {
  const key = process.env.GOOGLE_PLACES_API_KEY;
  if (!key) return { problem: "Google Maps isn't set up on the server" };
  if (!ahead.length) return { problem: null, legs: [] as any[], path: [] as [number, number][] };
  // No truck position yet: plan from the first stop instead
  const from = origin ? `${origin.lat},${origin.lng}` : address(ahead[0]);
  const targets = origin ? ahead : ahead.slice(1);
  if (!targets.length) return { problem: null, legs: [], path: [] };

  const prev = cache.get(`route:${trip.id}`);
  if (
    prev &&
    Date.now() - prev.at < ROUTE_TTL_MS &&
    prev.value.stopsKey === ahead.map((s) => s.id).join(",") &&
    (!origin || !prev.value.origin || milesBetween(origin, prev.value.origin) < REROUTE_MILES)
  ) {
    return prev.value.result;
  }

  const url = new URL("https://maps.googleapis.com/maps/api/directions/json");
  url.searchParams.set("origin", from);
  url.searchParams.set("destination", address(targets[targets.length - 1]));
  if (targets.length > 1) url.searchParams.set("waypoints", targets.slice(0, -1).map(address).join("|"));
  url.searchParams.set("departure_time", "now");
  url.searchParams.set("units", "imperial");
  url.searchParams.set("key", key);
  let result: any;
  try {
    const json: any = await (await fetch(url)).json();
    if (json.status !== "OK") {
      result = { problem: `Google couldn't plan the route (${json.status}${json.error_message ? `: ${json.error_message}` : ""})` };
    } else {
      const route = json.routes[0];
      result = { problem: null, legs: route.legs, path: decodePolyline(route.overview_polyline?.points || ""), targets: targets.map((s) => s.id) };
    }
  } catch (e: any) {
    result = { problem: `Google unreachable: ${e?.message || e}` };
  }
  cache.set(`route:${trip.id}`, { at: Date.now(), value: { result, stopsKey: ahead.map((s) => s.id).join(","), origin } });
  return result;
}

// ---------- together ----------

export async function liveTrip(trip: ChatTrip, stops: ChatTripStop[]): Promise<LiveTrip> {
  const now = Date.now();
  const seen = await truckNow(trip);
  const truck = seen.truck ? trackMotion(String(seen.truck.vehicleName || trip.truck_number || trip.id), seen.truck) : null;
  const truckProblem = seen.problem;
  const ahead = remainingStops(trip, stops);
  const route = await routeAhead(trip, truck ? { lat: truck.lat, lng: truck.lng } : null, ahead);

  const etas: StopEta[] = [];
  const team = !!trip.driver_id_2;
  const legs: any[] = route.legs || [];
  const targetIds: number[] = route.targets || [];

  // Each leg as a truck drives it, then one plan of stops over the whole road ahead
  const timed = legs
    .map((leg, i) => {
      const stop = ahead.find((s) => s.id === targetIds[i]);
      const legMiles = (leg.distance?.value || 0) / 1609.344;
      const googleMinutes = ((leg.duration_in_traffic || leg.duration)?.value || 0) / 60;
      return stop ? { leg, stop, legMiles, googleMinutes, legMinutes: truckDriving(legMiles, googleMinutes) } : null;
    })
    .filter(Boolean) as { leg: any; stop: ChatTripStop; legMiles: number; googleMinutes: number; legMinutes: number }[];
  const miles = timed.reduce((a, t) => a + t.legMiles, 0);
  const minutes = timed.reduce((a, t) => a + t.legMinutes, 0);
  const googleMinutes = timed.reduce((a, t) => a + t.googleMinutes, 0);
  const plan = planTrip(miles, minutes, team);

  let driven = 0;
  let clock = now;
  for (const { leg, stop, legMiles, legMinutes } of timed) {
    driven += legMinutes;
    clock = now + elapsedAt(plan, driven) * 60_000;
    const appt = stop.appointment_at ? new Date(stop.appointment_at).getTime() : null;
    etas.push({
      stopId: stop.id,
      seq: stop.seq,
      type: stop.type,
      name: stop.name,
      place: place(stop),
      lat: leg.end_location?.lat ?? null,
      lng: leg.end_location?.lng ?? null,
      miles: Math.round(legMiles * 10) / 10,
      driveMinutes: Math.round(legMinutes),
      eta: new Date(clock).toISOString(),
      lateMinutes: appt ? Math.round((clock - appt) / 60_000) : null,
    });
  }

  const hasRoute = etas.length > 0;
  return {
    truck,
    truckProblem,
    stops: etas,
    miles: hasRoute ? Math.round(miles) : null,
    driveMinutes: hasRoute ? Math.round(minutes) : null,
    restMinutes: hasRoute ? plan.breakMinutes + plan.restMinutes + plan.fuelMinutes : null,
    plan: hasRoute
      ? {
          googleMinutes: Math.round(googleMinutes),
          drivingMinutes: plan.drivingMinutes,
          breakMinutes: plan.breakMinutes,
          restMinutes: plan.restMinutes,
          fuelMinutes: plan.fuelMinutes,
          totalMinutes: plan.totalMinutes,
          stops: plan.stops.map((p) => ({
            kind: p.kind,
            minutes: p.minutes,
            atMile: p.atMile,
            afterDrivingMinutes: p.afterDrivingMinutes,
            at: new Date(now + p.startsAfter * 60_000).toISOString(),
          })),
        }
      : null,
    team,
    eta: hasRoute ? new Date(clock).toISOString() : null,
    fuelGallons: hasRoute ? Math.round(miles / MPG) : null,
    path: route.path || [],
    routeProblem: route.problem || null,
    updatedAt: new Date(now).toISOString(),
  };
}
