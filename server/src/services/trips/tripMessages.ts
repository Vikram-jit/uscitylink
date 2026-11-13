import type { ChatTrip, ChatTripStop } from "../../models/ChatTrip";
import { stateTimezone } from "./stateTimezone";

// Everything trips write into the driver's chat, in one place: the load itself (same layout
// dispatchers already type, so drivers read it the way they always have) and the status lines.

const sorted = (stops: ChatTripStop[]) => [...stops].sort((a, b) => a.seq - b.seq);

/** "11/06/2026 03:15AM" in the stop's own time, as dispatch writes it. */
export function stopTime(s: Pick<ChatTripStop, "appointment_local">): string | null {
  const v = s.appointment_local;
  if (!v) return null;
  const [d, t = "00:00"] = v.split("T");
  const [y, m, day] = d.split("-");
  let [h, min] = t.split(":").map(Number);
  const ap = h >= 12 ? "PM" : "AM";
  h = h % 12 || 12;
  return `${m}/${day}/${y} ${String(h).padStart(2, "0")}:${String(min).padStart(2, "0")}${ap}`;
}

/** A real moment shown in a stop's time zone: "02:58 AM". */
export function clock(at: Date, state?: string | null): string {
  return new Intl.DateTimeFormat("en-US", { timeZone: stateTimezone(state), hour: "2-digit", minute: "2-digit" }).format(at);
}

const place = (s: ChatTripStop) => [s.name, [s.city, s.state].filter(Boolean).join(", ")].filter(Boolean).join(", ");

export const tripNo = (trip: ChatTrip) => `#${trip.trip_no || trip.id}`;

export function formatLoad(trip: ChatTrip, stops: ChatTripStop[], teamNames: string[] = []): string {
  const lines: string[] = [`TRIP ${tripNo(trip)}`];
  if (trip.truck_number) lines.push(`TRUCK # ${trip.truck_number}`);
  if (teamNames.length > 1) lines.push(`TEAM # ${teamNames.join(" + ")}`);
  if (trip.trailer_numbers) lines.push(`TRAILER # ${trip.trailer_numbers}`);
  if (trip.temperature) lines.push(`TEMP # ${trip.temperature}`);
  if (trip.loaded_trailer) lines.push("LOADED TRAILER");

  const drops = sorted(stops).filter((s) => s.type === "drop").length;
  let dropNo = 0;
  for (const s of sorted(stops)) {
    lines.push("");
    if (s.type === "pickup") lines.push("PICKUP");
    else if (s.type === "switch") lines.push("GO TO (SWITCH TRAILER)");
    else if (s.type === "yard") lines.push("DROP AT YARD");
    else lines.push(drops > 1 ? `DROP # ${++dropNo}` : "DROP");
    if (s.name) lines.push(s.name);
    if (s.street) lines.push(s.street);
    lines.push(`${s.city || ""}, ${s.state || ""} ${s.zip || ""}`.trim());
    const t = stopTime(s);
    if (t) lines.push(t);
    if (s.ref) lines.push(`REF # ${s.ref}`);
  }
  if (trip.notes) lines.push("", trip.notes);
  return lines.join("\n");
}

/** "(17 min early)" / "(1 h 05 min late)" against the appointment. */
function punctuality(stop: ChatTripStop, at: Date): string {
  if (!stop.appointment_at) return "";
  const diff = Math.round((at.getTime() - new Date(stop.appointment_at).getTime()) / 60000);
  if (Math.abs(diff) < 5) return " (on time)";
  const abs = Math.abs(diff);
  const text = abs >= 60 ? `${Math.floor(abs / 60)} h ${String(abs % 60).padStart(2, "0")} min` : `${abs} min`;
  return ` (${text} ${diff < 0 ? "early" : "late"})`;
}

const nextAfter = (stops: ChatTripStop[], stop?: ChatTripStop | null) => {
  const list = sorted(stops);
  const i = stop ? list.findIndex((s) => s.id === stop.id) : -1;
  return list.slice(i + 1).find((s) => !s.arrived_at) || null;
};

const towards = (next: ChatTripStop | null) =>
  next ? ` → ${place(next)}${stopTime(next) ? ` · appointment ${stopTime(next)}` : ""}` : "";

export const PROBLEM_KINDS: Record<string, string> = {
  delay: "Delay",
  breakdown: "Breakdown",
  detention: "Detention",
  lumper: "Lumper",
  rejected: "Load rejected",
  shortage: "Shortage",
  damage: "Damage",
  other: "Problem",
};

export const statusLine = {
  accept: (trip: ChatTrip, who: string) => `👍 ${who} accepted trip ${tripNo(trip)}`,
  start: (trip: ChatTrip, at: Date, first?: ChatTripStop | null) =>
    `🚚 Trip ${tripNo(trip)} started · ${clock(at, first?.state)}${first ? ` — heading to ${place(first)}` : ""}`,
  arrive: (stop: ChatTripStop, at: Date) => `📍 Arrived at ${place(stop)} · ${clock(at, stop.state)}${punctuality(stop, at)}`,
  rolling: (trip: ChatTrip, stops: ChatTripStop[], stop?: ChatTripStop | null) =>
    `🛣️ Loaded — rolling${towards(nextAfter(stops, stop))}`,
  depart: (stop: ChatTripStop, stops: ChatTripStop[], at: Date) =>
    `🛣️ Departed ${place(stop)} · ${clock(at, stop.state)}${towards(nextAfter(stops, stop))}`,
  end: (trip: ChatTrip, stop?: ChatTripStop | null) =>
    stop?.type === "yard"
      ? `🅿️ Trip ${tripNo(trip)} dropped at the yard${stop ? ` (${place(stop)})` : ""} — thank you, dispatch has the next move`
      : stop?.type === "switch"
        ? `🔁 Trip ${tripNo(trip)} handed over at ${place(stop)} — thank you`
        : `✅ Trip ${tripNo(trip)} delivered${stop ? ` at ${place(stop)}` : ""} — please send the BOL / POD photos`,
  paperwork: (trip: ChatTrip, summary: string) => `📄 Paperwork for trip ${tripNo(trip)}: ${summary} — waiting for dispatch to confirm`,
  complete: (trip: ChatTrip, who: string) => `✅ Trip ${tripNo(trip)} completed — paperwork confirmed by ${who}`,
  hold: (trip: ChatTrip, note?: string | null) => `⏸️ Trip ${tripNo(trip)} on hold${note ? `: ${note}` : ""}`,
  resume: (trip: ChatTrip) => `▶️ Trip ${tripNo(trip)} resumed`,
  cancel: (trip: ChatTrip, note?: string | null) => `❌ Trip ${tripNo(trip)} cancelled${note ? `: ${note}` : ""}`,
  problem: (trip: ChatTrip, kind: string, who: string, note?: string | null, amount?: number | null) =>
    `⚠️ ${PROBLEM_KINDS[kind] || "Problem"} on trip ${tripNo(trip)}${amount ? ` ($${amount.toFixed(2)})` : ""}${note ? `: ${note}` : ""} — added by ${who}`,
  resolved: (trip: ChatTrip, kind: string, who: string) => `✔️ ${PROBLEM_KINDS[kind] || "Problem"} on trip ${tripNo(trip)} resolved by ${who}`,
  askScaleTicket: (trip: ChatTrip) => `⚖️ Please send the scale ticket for trip ${tripNo(trip)} here`,
  offered: () => "Thanks 👍 — dispatch will send your next load here",
  noLoad: () => "No next load is planned yet — dispatch has been told, they'll send it to you soon",
  declined: () => "Dispatch is updating your next load — they'll send it to you here",
};
