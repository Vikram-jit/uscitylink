import { Op } from "sequelize";
import { ChatTrip, ChatTripEvent, ChatTripStop } from "../../models/ChatTrip";
import { Message } from "../../models/Message";
import { MessageStaff } from "../../models/MessageStaff";
import { UserProfile } from "../../models/UserProfile";
import User from "../../models/User";
import Role from "../../models/Role";
import { STAFF_ROLES } from "../../middleware/requireRole";
import { alertStaff, postToChat, record } from "./tripService";

// Reminders, every few minutes:
//   1. Sent, no "Got it": 30 min after the load was sent the driver is reminded in chat and dispatch
//      gets a System Message; again at 60 min; then it stops.
//   2. "Got it" but not rolling and the pickup appointment has passed: driver and dispatch alerted once.
// Each one is recorded on the trip (type "reminder", data.kind) so it's never sent twice.

const MIN = 60_000;
const FIRST_ACK = 30 * MIN;
const SECOND_ACK = 60 * MIN;
/** Loads sent longer ago than this don't start reminding (no flood after a restart / for old loads) */
const ACK_WINDOW = 3 * 60 * MIN;
/** Pickups more than this late aren't alerted any more (old loads) */
const PICKUP_WINDOW = 24 * 60 * MIN;
const EVERY = 5 * MIN;

type Kind = "ack30" | "ack60" | "pickup_late";

let systemProfileId: string | null | undefined;
/** The "system" user the web's System Messages list shows (driver_number system001) */
async function systemProfile(): Promise<string | null> {
  if (systemProfileId !== undefined) return systemProfileId;
  const p = await UserProfile.findOne({ include: [{ model: User, as: "user", where: { user_type: "driver", driver_number: "system001" }, required: true }] });
  systemProfileId = p?.id || null;
  return systemProfileId;
}

/** A line in dispatch's System Messages (unread for every staff member). */
export async function systemAlert(channelId: string | null, body: string): Promise<string | null> {
  const sys = await systemProfile();
  if (!sys || !channelId) return null;
  const now = new Date();
  const msg = await Message.create({
    channelId,
    userProfileId: sys,
    senderId: sys,
    body,
    messageDirection: "R",
    deliveryStatus: "sent",
    status: "sent",
    messageTimestampUtc: now,
    isRead: false,
    url_upload_type: "with-out-media",
    is_automated: true,
  } as any);
  const staff = await UserProfile.findAll({ include: [{ model: Role, as: "role", where: { name: STAFF_ROLES }, required: true }], attributes: ["id"] });
  if (staff.length) {
    await MessageStaff.bulkCreate(staff.map((s) => ({ messageId: msg.id, staffId: s.id, driverId: sys, status: "un-read", type: "chat" })) as any[]);
  }
  return msg.id;
}

async function alreadySent(tripId: number, kind: Kind) {
  const events = await ChatTripEvent.findAll({ where: { chat_trip_id: tripId, type: "reminder" }, attributes: ["data"] });
  return events.some((e) => e.data?.kind === kind);
}

async function remind(trip: ChatTrip, kind: Kind, driverText: string, dispatchText: string) {
  const messageId = await postToChat(trip, driverText);
  await systemAlert(trip.channel_id, dispatchText).catch((e) => console.warn("[trips] system alert:", e?.message));
  await record(trip, { type: "reminder", actor: { role: "system", name: "Dispatch Assistant" }, note: dispatchText, messageId, data: { kind } });
  alertStaff("trip:reminder", { tripId: trip.id, tripNo: trip.trip_no, kind, text: dispatchText });
}

const driverName = async (trip: ChatTrip) => (trip.driver_profile_id ? (await UserProfile.findByPk(trip.driver_profile_id))?.username || "The driver" : "The driver");
const minutesSince = (d: Date | string, now: number) => Math.round((now - new Date(d).getTime()) / MIN);

/** One pass (exported for tests). */
export async function runReminders(now = Date.now()) {
  // 1. Sent, no "Got it"
  const waiting = await ChatTrip.findAll({
    where: { status: "planned", sent_at: { [Op.lte]: new Date(now - FIRST_ACK), [Op.gte]: new Date(now - ACK_WINDOW) }, driver_profile_id: { [Op.ne]: null } },
  });
  for (const trip of waiting) {
    const age = now - new Date(trip.sent_at!).getTime();
    const kind: Kind | null = age >= SECOND_ACK ? "ack60" : "ack30";
    if (await alreadySent(trip.id, kind)) continue;
    // Late start (e.g. the server was down at 30 min): only the second one, not both
    if (kind === "ack30" || !(await alreadySent(trip.id, "ack60"))) {
      const who = await driverName(trip);
      const mins = minutesSince(trip.sent_at!, now);
      await remind(
        trip,
        kind,
        `⏰ Reminder: trip ${trip.trip_no} was sent to you ${mins} min ago — please open it and tap "Got it"`,
        `⏰ ${who} hasn't tapped "Got it" on trip ${trip.trip_no} (sent ${mins} min ago)${kind === "ack60" ? " — second reminder" : ""}`
      );
    }
  }

  // 2. "Got it" but not rolling, and the pickup time has passed
  const accepted = await ChatTrip.findAll({
    where: { status: "accepted", driver_profile_id: { [Op.ne]: null } },
    include: [{ model: ChatTripStop, as: "stops" }],
  });
  for (const trip of accepted) {
    const pickup = [...(trip.stops || [])].sort((a, b) => a.seq - b.seq).find((s) => s.type === "pickup" && s.appointment_at && !s.arrived_at);
    if (!pickup?.appointment_at) continue;
    const late = now - new Date(pickup.appointment_at).getTime();
    if (late <= 0 || late > PICKUP_WINDOW) continue;
    if (await alreadySent(trip.id, "pickup_late")) continue;
    const who = await driverName(trip);
    const where = [pickup.name, [pickup.city, pickup.state].filter(Boolean).join(", ")].filter(Boolean).join(" · ");
    const appt = pickup.appointment_local ? pickup.appointment_local.replace("T", " ") : "";
    await remind(
      trip,
      "pickup_late",
      `⚠️ Trip ${trip.trip_no}: the pickup time at ${where}${appt ? ` (${appt})` : ""} has passed and the load isn't rolling yet. Tap "Loaded — rolling" when you leave, or tell dispatch if you're delayed`,
      `⚠️ Pickup time passed: ${who} on trip ${trip.trip_no} isn't rolling — pickup ${where}${appt ? ` was ${appt}` : ""} (${minutesSince(pickup.appointment_at, now)} min ago)`
    );
  }
}

let timer: NodeJS.Timeout | null = null;
/** Started once at server start (TRIP_REMINDERS=off turns it off). */
export function startTripReminders() {
  if (timer || process.env.TRIP_REMINDERS === "off") return;
  timer = setInterval(() => {
    runReminders().catch((e) => console.warn("[trips] reminders:", e?.message || e));
  }, EVERY);
}
