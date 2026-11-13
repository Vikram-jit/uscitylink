// Trip mileage from the truck's own odometer (Samsara), the same source the yard's Route List form
// reads (Yard-M AccountantLoginController::getOdometer). Needs SAMSARA_API_KEY; without it, or
// without readings, mileage is simply left for the accountant.

const API = "https://api.samsara.com/fleet/vehicles/stats/history";
const METERS_TO_MILES = 0.000621371;

interface Reading {
  time: string;
  value: number;
}

async function readings(vehicleId: string, from: Date, to: Date, type: string): Promise<Reading[]> {
  const key = process.env.SAMSARA_API_KEY;
  if (!key) return [];
  const url = new URL(API);
  url.searchParams.set("vehicleIds", vehicleId);
  url.searchParams.set("types", type);
  url.searchParams.set("startTime", from.toISOString());
  url.searchParams.set("endTime", to.toISOString());
  try {
    const res = await fetch(url, { headers: { Authorization: `Bearer ${key}`, Accept: "application/json" } });
    if (!res.ok) return [];
    const json: any = await res.json();
    const list = json?.data?.[0]?.[type];
    return Array.isArray(list) ? list.filter((r: any) => Number.isFinite(Number(r?.value))) : [];
  } catch {
    return [];
  }
}

/** Odometer (meters) closest to [at]: a narrow window first, wider when the engine was off. */
async function odometerAt(vehicleId: string, at: Date): Promise<number | null> {
  for (const minutes of [10, 120]) {
    const from = new Date(at.getTime() - minutes * 60_000);
    const to = new Date(at.getTime() + minutes * 60_000);
    for (const type of ["obdOdometerMeters", "gpsOdometerMeters"]) {
      const list = await readings(vehicleId, from, to, type);
      if (!list.length) continue;
      const nearest = list.reduce((a, b) =>
        Math.abs(new Date(a.time).getTime() - at.getTime()) <= Math.abs(new Date(b.time).getTime() - at.getTime()) ? a : b
      );
      return Number(nearest.value);
    }
  }
  return null;
}

const miles = (meters: number) => Math.round(meters * METERS_TO_MILES * 100) / 100;

/**
 * Miles from trip start to end, and per stop from the previous point (start → stop 1 → stop 2 …),
 * using the moments the driver tapped Start / Arrived / End.
 */
export async function tripMileage(
  vehicleId: string,
  startedAt: Date,
  endedAt: Date,
  arrivals: (Date | null)[]
): Promise<{ total: number; legs: (number | null)[] } | null> {
  if (!process.env.SAMSARA_API_KEY) return null;
  const start = await odometerAt(vehicleId, new Date(startedAt));
  const end = await odometerAt(vehicleId, new Date(endedAt));
  if (start === null || end === null || end < start) return null;

  const legs: (number | null)[] = [];
  let previous: number | null = start;
  for (const arrived of arrivals) {
    const here = arrived ? await odometerAt(vehicleId, new Date(arrived)) : null;
    legs.push(here !== null && previous !== null && here >= previous ? miles(here - previous) : null);
    if (here !== null) previous = here;
  }
  return { total: miles(end - start), legs };
}

// ---------- the truck's GPS trail (where it was, minute by minute) ----------

export interface GpsPoint {
  /** ms since epoch */
  t: number;
  lat: number;
  lng: number;
  mph: number;
}

/** Samsara GPS history for a truck between two times, oldest first. null when Samsara can't answer. */
export async function gpsTrail(vehicleId: string, from: Date, to: Date): Promise<GpsPoint[] | null> {
  const key = process.env.SAMSARA_API_KEY;
  if (!key) return null;
  const out: GpsPoint[] = [];
  let after = "";
  try {
    for (let page = 0; page < 40; page++) {
      const url = new URL(API);
      url.searchParams.set("vehicleIds", vehicleId);
      url.searchParams.set("types", "gps");
      url.searchParams.set("startTime", from.toISOString());
      url.searchParams.set("endTime", to.toISOString());
      if (after) url.searchParams.set("after", after);
      const res = await fetch(url, { headers: { Authorization: `Bearer ${key}`, Accept: "application/json" } });
      if (!res.ok) return out.length ? out : null;
      const json: any = await res.json();
      for (const p of json?.data?.[0]?.gps || []) {
        const lat = Number(p?.latitude);
        const lng = Number(p?.longitude);
        const t = new Date(p?.time).getTime();
        if (Number.isFinite(lat) && Number.isFinite(lng) && Number.isFinite(t)) out.push({ t, lat, lng, mph: Number(p?.speedMilesPerHour) || 0 });
      }
      if (!json?.pagination?.hasNextPage || !json?.pagination?.endCursor) break;
      after = String(json.pagination.endCursor);
    }
  } catch {
    return out.length ? out : null;
  }
  return out.sort((a, b) => a.t - b.t);
}
