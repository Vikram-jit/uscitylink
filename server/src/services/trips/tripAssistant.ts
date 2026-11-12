import Anthropic from "@anthropic-ai/sdk";
import { Message } from "../../models/Message";
import { ChatTrip, ChatTripEvent } from "../../models/ChatTrip";
import { loadFromChat } from "./loadService";
import { UserProfile } from "../../models/UserProfile";
import Role from "../../models/Role";
import { isStaffRole } from "../../middleware/requireRole";
import { getSocketInstance } from "../../sockets/socket";
import { userRoom } from "../../sockets/userConnections";
import { PRECHECK_MODEL } from "../documentAi/settings";
import { logUsage } from "../documentAi/usageLog";
import { check, TripAction, TripStatus } from "./lifecycle";
import { looksLikeLoad, parseLoad } from "./parseLoad";
import { Intent, ruleIntent, SMALL_TALK } from "./intents";
import { currentTripFor, offerNextLoad } from "./tripService";

// Reads chat as it's saved (one Message hook covers every send path):
//   dispatch → driver: a typed load becomes a trip (flagged for a check when unsure);
//   driver → dispatch: "next load?" offers the lined-up load; "loaded / arrived / delivered"
//   suggests the matching trip button to the driver. Suggestions only — the driver or dispatch
//   taps to confirm, so the record never holds a guess.
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

async function onDriverMessage(m: Message) {
  const text = String(m.body || "").trim();
  if (!text || SMALL_TALK.test(text)) return;
  let intent = ruleIntent(text);
  const current = await currentTripFor(m.userProfileId);

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

async function onStaffMessage(m: Message) {
  const text = String(m.body || "");
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
    },
    actor
  );
  const driverName = (await UserProfile.findByPk(m.userProfileId))?.username || "the driver";
  getSocketInstance()
    .to(userRoom(String(m.senderId)))
    .emit("load:typed", { ...result, messageId: m.id, driverName });
}

/** Called once at startup. */
export function registerTripHooks() {
  Message.addHook("afterCreate", "trips", (message: any) => {
    const m = message as Message;
    // Automated lines (trip status, assistant replies) and broadcasts never start anything
    if ((m as any).is_automated || (m as any).isBroadcastMessage || (m as any).url || !m.body || !m.userProfileId) return;
    setImmediate(() => {
      const work = m.messageDirection === "S" ? onStaffMessage(m) : m.messageDirection === "R" ? onDriverMessage(m) : null;
      work?.catch((e) => console.warn("[trips] chat hook:", e?.message || e));
    });
  });
}
