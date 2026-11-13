// A leg's real times from the truck's Samsara GPS trail, for when the driver didn't tap (Rolling /
// Arrived / Delivered) or dispatch ended the load late. Every truck has Samsara GPS, so the trail
// says when the truck reached and left each stop:
//   - arrived = first GPS point within NEAR_MI of the stop, left = the truck moves out of that circle
//   - no address on the map (or the truck parked just outside) → the truck's stops (dwells) are used
//   - a handover between two trucks with no address → where both trucks were together
// Loaded miles: from leaving the first stop to arriving at the last one (tripMileage reads the
// odometer at those times).

import { GpsPoint } from "./samsara";

export const NEAR_MI = 0.5;
const DWELL_MPH = 5;
const DWELL_MIN = 15;
const MEET_MI = 0.3;
/** Two trucks "together": GPS points this close in time */
const MEET_SKEW_MS = 10 * 60_000;
/** A dwell used for a stop that has an address must be this close to it */
const DWELL_NEAR_MI = 5;

export interface LatLng {
  lat: number;
  lng: number;
}

export const milesApart = (a: LatLng, b: LatLng) => {
  const rad = (d: number) => (d * Math.PI) / 180;
  const h = Math.sin(rad(b.lat - a.lat) / 2) ** 2 + Math.cos(rad(a.lat)) * Math.cos(rad(b.lat)) * Math.sin(rad(b.lng - a.lng) / 2) ** 2;
  return 3958.8 * 2 * Math.asin(Math.min(1, Math.sqrt(h)));
};

export interface Dwell extends LatLng {
  from: number;
  to: number;
}

/** Where the truck stood still (under DWELL_MPH within a small area) for DWELL_MIN or more. */
export function dwellsOf(trail: GpsPoint[]): Dwell[] {
  const out: Dwell[] = [];
  let i = 0;
  while (i < trail.length) {
    if (trail[i].mph > DWELL_MPH) {
      i++;
      continue;
    }
    const start = trail[i];
    let j = i;
    while (j + 1 < trail.length && trail[j + 1].mph <= DWELL_MPH && milesApart(start, trail[j + 1]) <= MEET_MI) j++;
    if (trail[j].t - start.t >= DWELL_MIN * 60_000) out.push({ lat: start.lat, lng: start.lng, from: start.t, to: trail[j].t });
    i = j + 1;
  }
  return out;
}

export interface StopFix {
  arrivedAt: Date | null;
  /** null: the truck was still there when the trail ends */
  departedAt: Date | null;
  how: "geofence" | "dwell";
  lat: number;
  lng: number;
}

/**
 * Each stop's arrival / departure from the trail, in order (a stop is looked for after the one
 * before was left). [places]: the stop's point when known. [endBy]: the time dispatch ended the leg —
 * the last stop is the truck's last stop before that when its place isn't known.
 */
export function matchStops(trail: GpsPoint[], places: (LatLng | null)[], opts: { endBy?: Date | null } = {}): (StopFix | null)[] {
  const out: (StopFix | null)[] = [];
  if (!trail.length) return places.map(() => null);
  const dwells = dwellsOf(trail);
  const lastT = trail[trail.length - 1].t;
  let cursor = trail[0].t;
  const endBy = opts.endBy ? new Date(opts.endBy).getTime() : null;

  places.forEach((place, i) => {
    const isLast = i === places.length - 1;
    let fix: StopFix | null = null;
    if (place) {
      const k = trail.findIndex((p) => p.t >= cursor && milesApart(p, place) <= NEAR_MI);
      if (k >= 0) {
        let j = k;
        while (j + 1 < trail.length && milesApart(trail[j + 1], place) <= NEAR_MI) j++;
        fix = {
          arrivedAt: new Date(trail[k].t),
          departedAt: j + 1 < trail.length ? new Date(trail[j].t) : null,
          how: "geofence",
          lat: trail[k].lat,
          lng: trail[k].lng,
        };
      }
    }
    if (!fix) {
      const after = dwells.filter((d) => d.to >= cursor);
      let d: Dwell | undefined;
      if (place) d = after.find((x) => milesApart(x, place) <= DWELL_NEAR_MI);
      else if (isLast) {
        const before = endBy ? after.filter((x) => x.from <= endBy) : after;
        d = before[before.length - 1];
      } else if (i === 0) d = after[0];
      if (d) fix = { arrivedAt: new Date(Math.max(d.from, cursor)), departedAt: d.to >= lastT ? null : new Date(d.to), how: "dwell", lat: d.lat, lng: d.lng };
    }
    out.push(fix);
    if (fix) cursor = (fix.departedAt || fix.arrivedAt || new Date(cursor)).getTime();
  });
  return out;
}

/** The first place two trucks were together (handover with no address), after [after]. */
export function meetPoint(a: GpsPoint[], b: GpsPoint[], after = 0): (LatLng & { at: Date }) | null {
  let j = 0;
  for (const p of a) {
    if (p.t < after) continue;
    while (j + 1 < b.length && Math.abs(b[j + 1].t - p.t) <= Math.abs(b[j].t - p.t)) j++;
    const q = b[j];
    if (q && Math.abs(q.t - p.t) <= MEET_SKEW_MS && milesApart(p, q) <= MEET_MI) return { lat: p.lat, lng: p.lng, at: new Date(p.t) };
  }
  return null;
}

/** The GPS point closest to a time (where the truck was then). */
export function pointAt(trail: GpsPoint[], at: Date): GpsPoint | null {
  const t = at.getTime();
  let best: GpsPoint | null = null;
  for (const p of trail) if (!best || Math.abs(p.t - t) < Math.abs(best.t - t)) best = p;
  return best && Math.abs(best.t - t) <= 30 * 60_000 ? best : null;
}
