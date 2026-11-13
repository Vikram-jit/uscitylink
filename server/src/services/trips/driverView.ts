// What a driver's app gets about a load: only what the driver needs to run it and see it afterwards.
// Dispatch-only fields (review notes, the raw pasted text, who added it, internal miles notes, pay /
// Route List ids, lineup order, the full event history with dispatch's notes) never leave the server.

const DONE = ["ended", "paperwork", "completed", "routed"];

const pick = (o: any, keys: string[]) => {
  const out: Record<string, any> = {};
  for (const k of keys) if (o && k in o) out[k] = o[k];
  return out;
};

const TRIP_KEYS = [
  "id",
  "load_id",
  "leg_no",
  "trip_no",
  "invoice_no",
  "status",
  "status_before_hold",
  "driver_profile_id",
  "driver_id_2",
  "truck_number",
  "trailer_numbers",
  "temperature",
  "loaded_trailer",
  "notes",
  "sent_at",
  "started_at",
  "ended_at",
  "completed_at",
  "created_at",
  "channel_id",
];
const STOP_KEYS = ["id", "seq", "type", "name", "street", "city", "state", "zip", "appointment_local", "timezone", "arrived_at", "departed_at"];
const PROBLEM_KEYS = ["id", "kind", "note", "created_at", "resolved_at"];

/** A trip as the driver sees it. Miles show once the load is delivered (not while it's running). */
export function driverTrip(trip: any): Record<string, any> | null {
  if (!trip) return null;
  const t = typeof trip.toJSON === "function" ? trip.toJSON() : trip;
  const done = DONE.includes(t.status);
  const out = pick(t, TRIP_KEYS);
  if (done && t.total_mileage !== null && t.total_mileage !== undefined) out.total_mileage = Number(t.total_mileage);
  out.stops = [...(t.stops || [])]
    .sort((a: any, b: any) => a.seq - b.seq)
    .map((s: any) => ({ ...pick(s, STOP_KEYS), ...(done && s.mileage !== null && s.mileage !== undefined ? { mileage: Number(s.mileage) } : {}) }));
  if (t.problems) out.problems = t.problems.map((p: any) => pick(p, PROBLEM_KEYS));
  return out;
}

/** A response for the driver: a trip, { trip, next }, or { trips } with every trip cleaned. */
export function driverPayload(data: any): any {
  if (!data) return data;
  if (Array.isArray(data)) return data.map(driverTrip);
  if (data.trips && Array.isArray(data.trips)) return { ...data, trips: data.trips.map(driverTrip) };
  if (data.trip) return { ...pick(data, ["next"]), trip: driverTrip(data.trip) };
  if (data.id && data.status) return driverTrip(data);
  return data;
}
