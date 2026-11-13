import Anthropic from "@anthropic-ai/sdk";
import { Message } from "../../models/Message";
import { ChatTrip, ChatTripEvent } from "../../models/ChatTrip";
import { loadFromChat } from "./loadService";
import { systemAlert } from "./reminders";
import { UserProfile } from "../../models/UserProfile";
import Role from "../../models/Role";
import { isStaffRole } from "../../middleware/requireRole";
import { getSocketInstance } from "../../sockets/socket";
import { userRoom } from "../../sockets/userConnections";
import { PRECHECK_MODEL } from "../documentAi/settings";
import { logUsage } from "../documentAi/usageLog";
import { check, TripAction, TripStatus } from "./lifecycle";
import { attachFromChat } from "./paperwork";
import { looksLikeLoad, parseLoad, trailerOnly } from "./parseLoad";
import { clearStatus, Intent, ruleIntent, SMALL_TALK } from "./intents";
import { act, currentTripFor, editTrip, offerNextLoad } from "./tripService";
import { Op } from "sequelize";

// Reads chat as it's saved (one Message hook covers every send path):
//   dispatch → driver: a typed load becomes a trip (flagged for a check when unsure);
//   driver → dispatch: "next load?" offers the lined-up load; a short, plain "rolling / arrived /
//   delivered" (no "not", "yet", "?", "will" …) moves the load as if the driver tapped (applyWords);
//   anything less clear only suggests the button — the driver taps to confirm, and can undo.
// Rules first (free); the low-cost model only for a driver line on a live trip the rules can't place.

const client = new Anthropic();

async function aiIntent(text: string, messageId: string): Promise<Intent> {
  const started = Date.now();
  try {
    const response = await client.beta.messages.create({
      model: PRECHECK_MODEL,
      max_tokens: 1024,
      system:
        "A truck driver on a delivery sent this chat line to dispatch. Classify what it says about the trip. " +
        "next_load: asks for their next load. arrive: arrived at a pickup or delivery. rolling: loaded / left a stop / driving to the next stop. " +
        "end: finished delivering, empty. problem: breakdown, delay, detention, lumper, rejected load, shortage or damage. none: anything else. " +
        "Drivers write in English, Punjabi or Hindi (often in Latin letters).",
      output_config: {
        effort: "low",
        format: {
          type: "json_schema",
          schema: {
            type: "object",
            properties: { intent: { type: "string", enum: ["next_load", "arrive", "rolling", "end", "problem", "none"] } },
            required: ["intent"],
            additionalProperties: false,
          },
        },
      },
      messages: [{ role: "user", content: text.slice(0, 400) }],
    });
    const block = response.content.find((b) => b.type === "text");
    await logUsage(
      { source: "trip", messageId },
      {
        model: response.model,
        tokens: {
          input: response.usage.input_tokens || 0,
          cacheRead: response.usage.cache_read_input_tokens || 0,
          cacheWrite: response.usage.cache_creation_input_tokens || 0,
          output: response.usage.output_tokens || 0,
        },
        latencyMs: Date.now() - started,
      }
    );
    if (response.stop_reason === "refusal" || !block || block.type !== "text") return "none";
    const intent = JSON.parse(block.text)?.intent;
    return ["next_load", "arrive", "rolling", "end", "problem"].includes(intent) ? intent : "none";
  } catch (e: any) {
    console.warn("[trips] intent:", e?.message || e);
    return "none";
  }
}

/** The trip button that matches what the driver said, if it's allowed now. */
function suggestionFor(intent: Intent, status: TripStatus, next: { action: string; label: string; stopId?: number } | null) {
  // Only the driver's three buttons are ever suggested (Got it → Rolling → Delivered)
  const want: Partial<Record<Intent, TripAction[]>> = {
    rolling: ["rolling"],
    end: ["end"],
  };
  const actions = want[intent];
  if (!actions) return null;
  if (next && actions.includes(next.action as TripAction)) return next;
  if (intent === "end" && check("end", status, "driver").ok) return { action: "end", label: "Delivered — end trip" };
  return null;
}

/**
 * The driver wrote that a step happened instead of tapping it: do the taps it takes to get there,
 * in order, as the driver (each posts its usual chat line and History entry, noted "from chat").
 *   rolling: Got it → Rolling; already rolling and parked at a stop → left that stop
 *   arrive:  at the next stop not reached yet (starting the trip if it wasn't)
 *   end:     Rolling (if never tapped) → Delivered
 * Returns false when nothing fits the load's state (then the usual suggestion is tried).
 */
export async function applyWords(trip: ChatTrip, intent: Intent, m: Message): Promise<boolean> {
  const driver = await UserProfile.findByPk(m.userProfileId);
  const actor = { role: "driver" as const, id: m.userProfileId, name: driver?.username || null };
  const note = `From the driver's chat: "${String(m.body || "").trim().slice(0, 80)}"`;
  const at = (m as any).messageTimestampUtc || new Date();
  const status = trip.status as TripStatus;
  const stops = [...(trip.stops || [])].sort((a, b) => a.seq - b.seq);
  const steps: { action: TripAction; stopId?: number }[] = [];

  const parked = [...stops].reverse().find((s) => s.arrived_at && !s.departed_at);
  const isLast = (id?: number) => id === stops[stops.length - 1]?.id;
  if (intent === "rolling") {
    // At a stop (they wrote "arrived" earlier): leaving it; otherwise Rolling
    if ((status === "started" || status === "rolling") && parked && !isLast(parked.id)) steps.push({ action: "depart", stopId: parked.id });
    else if (["planned", "accepted", "started"].includes(status)) steps.push({ action: "rolling" });
  } else if (intent === "arrive") {
    // The next stop after the last one they reached; rolling with none reached = loaded at the
    // pickup already, so the next stop after it
    let lastTouched = -1;
    stops.forEach((s, i) => {
      if (s.arrived_at || s.departed_at) lastTouched = i;
    });
    const from = lastTouched >= 0 ? lastTouched + 1 : status === "rolling" ? 1 : 0;
    const nextStop = parked ? null : stops.slice(from).find((s) => !s.arrived_at);
    if (nextStop && ["planned", "accepted", "started", "rolling"].includes(status)) {
      if (status === "planned" || status === "accepted") steps.push({ action: "start" });
      steps.push({ action: "arrive", stopId: nextStop.id });
    }
  } else if (intent === "end") {
    if (status === "planned" || status === "accepted") steps.push({ action: "rolling" });
    if (["planned", "accepted", "started", "rolling"].includes(status)) steps.push({ action: "end" });
  }
  if (!steps.length) return false;
  for (const s of steps) await act(trip.id, s.action, actor, { stopId: s.stopId, note, at });
  return true;
}

async function onDriverMessage(m: Message) {
  const text = String(m.body || "").trim();
  if (!text || SMALL_TALK.test(text)) return;
  let intent = ruleIntent(text);
  const current = await currentTripFor(m.userProfileId);

  // A plain "rolling" / "arrived" / "delivered": done for them, no tap needed
  const sure = clearStatus(text);
  if (current && sure !== "none") {
    try {
      if (await applyWords(current.trip, sure, m)) return;
    } catch (e: any) {
      console.warn("[trips] driver words:", e?.message || e);
    }
  }

  // Unclear line from a driver on a live trip: ask the low-cost model
  if (intent === "none" && current && text.split(/\s+/).length >= 2 && text.length <= 200) intent = await aiIntent(text, m.id);
  if (intent === "none") return;

  if (intent === "next_load") {
    await offerNextLoad(m.userProfileId, "asked");
    return;
  }
  if (!current) return;
  const { trip, next } = current;
  const io = getSocketInstance();
  if (intent === "problem") {
    io.to(userRoom(m.userProfileId)).emit("trip:suggest", { tripId: trip.id, action: "problem", label: "Report a problem on this trip?", messageId: m.id });
    return;
  }
  const s = suggestionFor(intent, trip.status as TripStatus, next);
  if (!s) return;
  io.to(userRoom(m.userProfileId)).emit("trip:suggest", { tripId: trip.id, ...s, messageId: m.id });
  await ChatTripEvent.create({
    chat_trip_id: trip.id,
    type: "ai_suggestion",
    actor_role: "ai",
    actor_name: "Dispatch Assistant",
    note: `Suggested "${s.label}" from: ${text.slice(0, 200)}`,
    data: { action: s.action, stopId: (s as any).stopId ?? null, intent },
    message_id: m.id,
    happened_at: new Date(),
  });
}

/** Staff sent only a trailer number: it goes on the driver's load just sent (current, else latest sent and open). */
async function trailerFollowUp(m: Message, trailer: string) {
  const sender = await UserProfile.findByPk(m.senderId, { include: [{ model: Role, as: "role" }] });
  if (!isStaffRole((sender as any)?.role?.name)) return;
  const trip =
    (await currentTripFor(m.userProfileId))?.trip ||
    (await ChatTrip.findOne({
      where: { driver_profile_id: m.userProfileId, sent_at: { [Op.ne]: null }, status: { [Op.notIn]: ["completed", "routed", "cancelled"] } },
      order: [["sent_at", "DESC"], ["id", "DESC"]],
    }));
  if (!trip || ["completed", "routed", "cancelled"].includes(trip.status)) return;
  const now = (trip.trailer_numbers || "").split(/,\s*/).filter(Boolean);
  if (now.length === 1 && now[0].toUpperCase() === trailer) return;
  await editTrip(trip.id, { trailerNumbers: [trailer] }, { role: "dispatcher", id: sender?.id || null, name: sender?.username || null }, { quiet: true });
}

async function onStaffMessage(m: Message) {
  const text = String(m.body || "");
  const trailer = trailerOnly(text);
  if (trailer) return trailerFollowUp(m, trailer);
  if (!looksLikeLoad(text)) return;
  if (await ChatTrip.findOne({ where: { message_id: m.id } })) return;
  const sender = await UserProfile.findByPk(m.senderId, { include: [{ model: Role, as: "role" }] });
  if (!isStaffRole((sender as any)?.role?.name)) return;
  const load = parseLoad(text);
  if (!load) return;

  // Treated like Add load → Send now: Load # required, same number = next leg, the driver gets the
  // standard load message; questions (previous leg open / driver busy) go to the dispatcher's screen
  const actor = { role: "dispatcher" as const, id: sender?.id || null, name: sender?.username || null };
  const result = await loadFromChat(
    {
      loadNo: load.loadNo,
      driverProfileId: m.userProfileId,
      truckNumber: load.truck,
      teamNames: load.team,
      trailerNumbers: load.trailers,
      temperature: load.temperature,
      loadedTrailer: load.loadedTrailer,
      channelId: m.channelId,
      stops: load.stops,
      needsReview: load.needsReview,
      reviewNotes: load.reasons,
      rawText: text,
      sourceMessageId: m.id,
    },
    actor
  );
  const driverName = (await UserProfile.findByPk(m.userProfileId))?.username || "the driver";
  getSocketInstance()
    .to(userRoom(String(m.senderId)))
    .emit("load:typed", { ...result, messageId: m.id, driverName });
  // A load text with no Load # makes no load: say so where it can't be missed (System Messages, unread
  // for staff) — the pop-up above only reaches an open dashboard, not the staff app or a closed tab
  if (result.kind === "noLoadNo") {
    const sentBy = sender?.username || "Dispatch";
    await systemAlert(
      m.channelId,
      `⚠️ Load NOT created: ${sentBy} sent a load to ${driverName} with no Load # (message of ${new Date(m.messageTimestampUtc || Date.now()).toISOString().slice(0, 16).replace("T", " ")} UTC). Add a line "LOAD # 1234" and send it again, or use Add load.`
    ).catch((e) => console.warn("[trips] system alert:", e?.message));
  }
  // A question (driver already on a load / previous leg open / already lined up) only pops up on the
  // sender's open dashboard; if nobody answers, nothing is made — so leave a note that can't be missed
  if (result.kind === "question") {
    const sentBy = sender?.username || "Dispatch";
    const what =
      result.needs === "driverBusy"
        ? `${driverName} still has load #${result.info?.current?.tripNo || "?"} open (${result.info?.current?.status || "not ended"}) — end it or line this one up`
        : result.needs === "endPrevious"
          ? `the previous leg (#${result.info?.prev?.tripNo || "?"}) isn't ended yet`
          : `Load ${result.loadNo} is already lined up — replace it or keep it`;
    await systemAlert(
      m.channelId,
      `⚠️ Load ${result.loadNo || ""} NOT created yet: ${sentBy} typed it to ${driverName}, but ${what}. Answer the pop-up, or open Loads → Add load with LOAD # ${result.loadNo || ""}.`
    ).catch((e) => console.warn("[trips] system alert:", e?.message));
  }
}

/** Called once at startup. */
export function registerTripHooks() {
  Message.addHook("afterCreate", "trips", (message: any) => {
    const m = message as Message;
    // Automated lines (trip status, assistant replies) and broadcasts never start anything
    if ((m as any).is_automated || (m as any).isBroadcastMessage || !m.userProfileId) return;
    // A driver's photo / PDF (BOL, POD …) goes on their load — no button needed
    if ((m as any).url) {
      if (m.messageDirection === "R") setImmediate(() => attachFromChat(m).catch((e) => console.warn("[trips] paperwork:", e?.message || e)));
      return;
    }
    if (!m.body) return;
    setImmediate(() => {
      const work = m.messageDirection === "S" ? onStaffMessage(m) : m.messageDirection === "R" ? onDriverMessage(m) : null;
      work?.catch((e) => console.warn("[trips] chat hook:", e?.message || e));
    });
  });
}
