// The driver answers a load: Accept / Reject.
//   - A load that was just sent (planned): Accept = the usual "Got it"; Reject sends it back to dispatch.
//   - An UPCOMING load (lined up, not sent yet): Accept is remembered (driver_response) — dispatch sees
//     "Driver accepted", and when the current load ends it goes out as already accepted; Reject sends it back.
//   - Once the driver has accepted and started it, Reject is no longer offered (tell dispatch instead).
// Reject = one tap, no questions: the load goes back to dispatch with no driver, flagged "Rejected by <driver>"
// (a reason is kept when one is sent). Dispatch gets a live alert, a System Message and a line in the driver's
// chat ("❌ <driver> rejected load X"); it is in the load's History, and the load leaves the driver's app.

import { ChatTrip } from "../../models/ChatTrip";
import { getSocketInstance } from "../../sockets/socket";
import { userRoom } from "../../sockets/userConnections";
import { refreshLoadStatus } from "./legs";
import { nextPosition } from "./lineup";
import { systemAlert } from "./reminders";
import { act, Actor, alertStaff, announce, getTrip, isTripDriver, postToChat, profileName, record, TripError, withStops } from "./tripService";
import { statusLine } from "./tripMessages";

const REJECTABLE = ["scheduled", "offered", "planned"];

export async function respondToLoad(id: number, actor: Actor, response: "accept" | "reject", note?: string | null) {
  const trip = await ChatTrip.findByPk(id, withStops);
  if (!trip) throw new TripError("Load not found", 404);
  if (actor.role !== "driver" || !(await isTripDriver(trip, actor.id))) throw new TripError("This isn't your load", 403);
  const name = actor.name || (await profileName(actor.id)) || "The driver";

  if (response === "accept") {
    if (trip.status === "planned") return act(id, "accept", actor); // the load just sent: the usual Got it
    if (trip.status === "scheduled" || trip.status === "offered") {
      if (trip.driver_response !== "accepted") {
        await trip.update({ driver_response: "accepted", driver_response_at: new Date(), driver_response_note: null });
        await record(trip, { type: "driver_response", actor, note: `${name} accepted the upcoming load` });
        alertStaff("trip:driver_response", { tripId: trip.id, tripNo: trip.trip_no, response: "accepted", driverName: name, driverProfileId: actor.id });
        announce(trip.id);
      }
      return getTrip(id);
    }
    return getTrip(id); // already accepted / on the road: nothing more to answer
  }

  // Reject
  if (!REJECTABLE.includes(trip.status)) throw new TripError("You've already accepted this load — tell dispatch if it can't be done");
  const why = String(note || "").trim().slice(0, 250);
  const text = `Rejected by ${name}${why ? `: ${why}` : ""}`;
  const was = trip.status;
  const channelId = trip.channel_id;
  const driverId = trip.driver_profile_id!;
  const review = [trip.review_notes, text].filter(Boolean).join("\n");
  // The driver's own tap, so it is said in their chat (dispatch reads it there) — before the load loses its driver
  await postToChat(trip, statusLine.rejected(trip, name), { driverTap: true });
  await trip.update({
    driver_profile_id: null,
    driver_id_1: null,
    driver_id_2: null,
    status: "scheduled",
    sent_at: null,
    queue_pos: null,
    auto_send: false,
    driver_response: "rejected",
    driver_response_at: new Date(),
    driver_response_note: why || null,
    needs_review: true,
    review_notes: review,
  });
  await record(trip, { type: "rejected", from: was, to: "scheduled", actor, note: text, data: { driverProfileId: driverId, reason: why || null } });
  await refreshLoadStatus(trip.load_id).catch(() => undefined);
  await nextPosition(driverId).catch(() => undefined);
  alertStaff("trip:rejected", { tripId: trip.id, tripNo: trip.trip_no, driverName: name, driverProfileId: driverId, reason: why || null });
  await systemAlert(channelId, `⚠️ ${name} rejected load ${trip.trip_no || trip.invoice_no || `#${trip.id}`}${why ? `: ${why}` : ""} — it is back with dispatch, no driver yet`).catch((e) => console.warn("[trips] system alert:", e?.message));
  // The driver's app drops it now (announce tells the staff screens; the load has no driver any more)
  try {
    getSocketInstance().to(userRoom(driverId)).emit("trip:updated", { tripId: trip.id, status: "scheduled", driverProfileId: driverId });
  } catch {
    // sockets not up (scripts)
  }
  announce(trip.id);
  return getTrip(id);
}
