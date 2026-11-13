// Add to loads / Repair, for a chat message that never became a load or became a wrong one.
//   preview: re-read the load text with today's rules and say what would change (before → after), plus
//            the text that would replace the assistant's old "TRIP #…" message in the chat;
//   apply:   (after dispatch confirms) fix the load's details and replace that assistant message.
// Dispatch's own typed text is never rewritten. A message with no load yet falls through to
// convertMessageToLoad (adds it to Loads, lined up — nothing is sent to the driver).
//   missedLoads: recent chat messages that look like loads but aren't in Loads, or are there wrong.

import { Op } from "sequelize";
import { ChatTrip, ChatTripEvent, ChatTripStop } from "../../models/ChatTrip";
import { Message } from "../../models/Message";
import GroupMessage from "../../models/GroupMessage";
import Group from "../../models/Group";
import GroupUser from "../../models/GroupUser";
import { UserProfile } from "../../models/UserProfile";
import Role from "../../models/Role";
import { isStaffRole } from "../../middleware/requireRole";
import { getSocketInstance } from "../../sockets/socket";
import { userRoom } from "../../sockets/userConnections";
import { looksLikeLoad, parseLoad, ParsedLoad, trailerOnly } from "./parseLoad";
import { formatLoad, loadNoOf } from "./tripMessages";
import { Actor, alertStaff, announce, editTrip, record, teamNamesOf, TripError } from "./tripService";
import { cleanLoadNo, convertMessageToLoad, findLoadByNo, getLoad } from "./loadService";
import { loadsOfMessage, MessageLoad } from "./messageLoads";

const CLOSED = ["completed", "routed", "cancelled"];
const STOP_WORD: Record<string, string> = { pickup: "Pickup", drop: "Drop", switch: "Switch", yard: "Yard" };

export interface RepairChange {
  label: string;
  before: string;
  after: string;
}

export interface RepairPreview {
  messageId: string;
  /** The message's own text (shown in the dialog) */
  text: string;
  /** add: no load yet · repair: something to fix · ok: the load already matches the message */
  mode: "add" | "repair" | "ok";
  /** add: the Load # read from the text (null: dispatch types it), and whether there is no address (plan-only) */
  loadNo: string | null;
  plan: boolean;
  load: MessageLoad | null;
  changes: RepairChange[];
  /** The assistant's message that would be replaced in the chat (null: dispatch's own text stays) */
  message: { before: string; after: string } | null;
  canApply: boolean;
  why: string | null;
}

const stopLine = (s: { type: string; name?: string | null; city?: string | null; state?: string | null }, i: number) =>
  `Stop ${i + 1}${s.name ? ` (${s.name})` : s.city ? ` (${s.city}${s.state ? `, ${s.state}` : ""})` : ""}`;

/** The assistant's own load message (not dispatch's typed text) in the chat. */
const isAssistantLoad = (m?: Message | null) => !!m && !!m.is_automated && /^(?:TRIP|LOAD)\b/i.test(String(m.body || "").trim());

async function leg(messageId: string): Promise<{ load: MessageLoad; trip: ChatTrip } | null> {
  let found = (await loadsOfMessage(messageId))[0];
  if (!found) {
    // Older loads never linked the dispatcher's own message: it is the same load when its Load # exists and
    // that leg kept this exact text (raw_text)
    const m = await Message.findByPk(messageId);
    const text = String(m?.body || "").trim();
    const no = text ? cleanLoadNo(parseLoad(text, { plan: true })?.loadNo) : null;
    const load = no ? await findLoadByNo(no) : null;
    const same = load ? await ChatTrip.findOne({ where: { load_id: load.id, raw_text: text, status: { [Op.ne]: "cancelled" } } }) : null;
    if (same) found = (await loadsOfMessage(same.message_id || messageId)).find((l) => l.legId === same.id) as MessageLoad;
    if (!found && same) {
      found = { loadId: same.load_id!, legId: same.id, legNo: same.leg_no, tripNo: same.trip_no, loadNo: load!.invoice_no || load!.load_no, status: same.status, driverName: null, onlyLeg: true, canDelete: !CLOSED.includes(same.status) && !same.driver_pay_details_id, why: CLOSED.includes(same.status) ? "It's completed — it stays on the load" : null };
    }
  }
  if (!found) return null;
  const trip = await ChatTrip.findByPk(found.legId, { include: [{ model: ChatTripStop, as: "stops" }] });
  return trip ? { load: found, trip } : null;
}

/** What re-reading the load text changes on a stored leg (stop types, temp, trailers, truck, team, stops of a plan). */
function diffLeg(trip: ChatTrip, parsed: ParsedLoad) {
  const stops = [...(trip.stops || [])].sort((a, b) => a.seq - b.seq);
  const changes: RepairChange[] = [];
  const stopTypes: { id: number; type: string }[] = [];
  let fillStops = false;
  if (!stops.length && parsed.stops.length) {
    fillStops = true;
    changes.push({ label: "Stops", before: "none (plan only)", after: parsed.stops.map((s) => `${STOP_WORD[s.type] || s.type} ${s.name || s.city}`).join(" → ") });
  } else if (stops.length === parsed.stops.length) {
    stops.forEach((s, i) => {
      const want = parsed.stops[i].type;
      if (s.type !== want && (s.city || "").toUpperCase() === (parsed.stops[i].city || "").toUpperCase()) {
        stopTypes.push({ id: s.id, type: want });
        changes.push({ label: stopLine(s, i), before: STOP_WORD[s.type] || s.type, after: STOP_WORD[want] || want });
      }
    });
  }
  const temp = (parsed.temperature || "").trim();
  if (temp && temp !== (trip.temperature || "")) changes.push({ label: "Temperature", before: trip.temperature || "—", after: temp });
  const trailers = parsed.trailers.join(", ");
  if (trailers && trailers !== (trip.trailer_numbers || "")) changes.push({ label: "Trailer", before: trip.trailer_numbers || "—", after: trailers });
  if (parsed.truck && parsed.truck !== (trip.truck_number || "")) changes.push({ label: "Truck", before: trip.truck_number || "—", after: parsed.truck });
  if (parsed.team.length > 1 && !trip.driver_id_2) changes.push({ label: "Team", before: "—", after: parsed.team.join(" + ") });
  return { changes, stopTypes, fillStops };
}

export async function repairPreview(messageId: string): Promise<RepairPreview> {
  const m = await Message.findByPk(messageId);
  if (!m || !m.body) throw new TripError("Message not found", 404);
  const linked = await leg(messageId);

  if (!linked) {
    const parsed = parseLoad(String(m.body), { plan: true });
    return {
      messageId,
      text: String(m.body),
      mode: "add",
      loadNo: parsed?.loadNo || null,
      plan: !!parsed && !parsed.stops.length,
      load: null,
      changes: [],
      message: null,
      canApply: true,
      why: null,
    };
  }

  const { load, trip } = linked;
  const why = !load.canDelete ? load.why : CLOSED.includes(trip.status) ? "This load is closed" : null;
  // The text the load was made from: the typed text kept on the leg, else dispatch's own message here
  const sourceText = trip.raw_text || (isAssistantLoad(m) ? null : String(m.body));
  const parsed = sourceText ? parseLoad(sourceText, { plan: true }) : null;
  const d = parsed ? diffLeg(trip, parsed) : { changes: [] as RepairChange[], stopTypes: [], fillStops: false };

  // The assistant's message for this leg, re-laid in today's wording with the corrected details
  let message: RepairPreview["message"] = null;
  const asst = trip.message_id ? await Message.findByPk(trip.message_id) : null;
  if (isAssistantLoad(asst) && (trip.stops || []).length) {
    const stops = [...(trip.stops || [])].sort((a, b) => a.seq - b.seq).map((s) => ({ ...s.toJSON(), type: d.stopTypes.find((x) => x.id === s.id)?.type || s.type }));
    const team = parsed && parsed.team.length > 1 ? parsed.team : await teamNamesOf(trip);
    const after = formatLoad(
      { ...trip.toJSON(), temperature: parsed?.temperature || trip.temperature, trailer_numbers: parsed?.trailers.length ? parsed.trailers.join(", ") : trip.trailer_numbers, truck_number: parsed?.truck || trip.truck_number } as any,
      stops as any,
      team
    );
    if (after.trim() !== String(asst!.body).trim()) message = { before: String(asst!.body), after };
  }

  const nothing = !d.changes.length && !message;
  return { messageId, text: String(m.body), mode: nothing ? "ok" : "repair", loadNo: loadNoOf(trip) || null, plan: false, load, changes: d.changes, message, canApply: !why && !nothing, why };
}

/** Confirmed: fix the load's details and replace the assistant's old message in the chat. */
export async function repairApply(messageId: string, actor: Actor, opts: { loadNo?: string | null } = {}) {
  forgetMissed();
  const pv = await repairPreview(messageId);
  if (pv.mode === "add") {
    const out = await convertMessageToLoad(messageId, actor, { loadNo: opts.loadNo || null });
    return { data: out.data, message: out.already ? `Load ${out.loadNo} is already in Loads` : out.plan ? `Load ${out.loadNo} added as a plan — add the stops from Loads` : `Load ${out.loadNo} added to Loads — not sent to the driver`, replaced: false };
  }
  if (!pv.load) throw new TripError("This message has no load", 404);
  if (pv.why) throw new TripError(pv.why);
  if (pv.mode === "ok") return { data: await getLoad(pv.load.loadId), message: "Nothing to repair — the load already matches the message", replaced: false };

  const trip = (await ChatTrip.findByPk(pv.load.legId, { include: [{ model: ChatTripStop, as: "stops" }] }))!;
  const m = (await Message.findByPk(messageId))!;
  const sourceText = trip.raw_text || (isAssistantLoad(m) ? null : String(m.body));
  const parsed = sourceText ? parseLoad(sourceText, { plan: true }) : null;
  const d = parsed ? diffLeg(trip, parsed) : { changes: [], stopTypes: [], fillStops: false };

  // Stop types change in place, so arrival / departure times survive
  for (const s of d.stopTypes) await ChatTripStop.update({ type: s.type as any }, { where: { id: s.id } });
  // People, temperature, trailers — and the stops themselves when this was a plan with none
  if (parsed && (d.fillStops || d.changes.some((c) => ["Temperature", "Trailer", "Truck", "Team"].includes(c.label)))) {
    await editTrip(
      trip.id,
      {
        ...(d.fillStops ? { stops: parsed.stops } : {}),
        ...(d.changes.some((c) => c.label === "Temperature") ? { temperature: parsed.temperature } : {}),
        ...(d.changes.some((c) => c.label === "Trailer") ? { trailerNumbers: parsed.trailers } : {}),
        ...(d.changes.some((c) => c.label === "Truck") ? { truckNumber: parsed.truck } : {}),
        ...(d.changes.some((c) => c.label === "Team") ? { teamNames: parsed.team } : {}),
        ...(parsed.reasons.length ? {} : { needsReview: false }),
      },
      actor,
      { quiet: true }
    );
  } else if (d.stopTypes.length && !parsed!.reasons.length) {
    await trip.update({ needs_review: false, review_notes: null });
  }

  // The assistant's old message → the corrected text (and its truck-chat copies)
  let replaced = false;
  if (pv.message && trip.message_id) {
    const old = (await Message.findByPk(trip.message_id))!;
    const copies = await Message.findAll({
      where: old.groupId
        ? { [Op.or]: [{ id: old.id }, { groupId: old.groupId, senderId: old.senderId, body: old.body, messageTimestampUtc: old.messageTimestampUtc }] }
        : { id: old.id },
    });
    await Message.update({ body: pv.message.after }, { where: { id: copies.map((c) => c.id) } });
    if (old.groupId) await GroupMessage.update({ body: pv.message.after }, { where: { groupId: old.groupId, senderId: old.senderId, body: old.body, messageTimestampUtc: old.messageTimestampUtc } });
    replaced = true;
    const payload = { id: old.id, ids: copies.map((c) => c.id), body: pv.message.after, channelId: old.channelId, groupId: old.groupId };
    alertStaff("message_updated", payload);
    try {
      const io = getSocketInstance();
      const members = old.groupId ? (await GroupUser.findAll({ where: { groupId: old.groupId } })).map((g: any) => g.userProfileId) : [old.userProfileId];
      for (const id of members) io.to(userRoom(String(id))).emit("message_updated", payload);
    } catch {
      // sockets not up (scripts)
    }
  }

  await record(trip, {
    type: "repair",
    actor,
    note: `Repaired from the chat message${pv.changes.length ? `: ${pv.changes.map((c) => `${c.label} ${c.before} → ${c.after}`).join(", ")}` : ""}${replaced ? " · message text replaced" : ""}`,
    messageId,
    data: { changes: pv.changes, message: pv.message },
  });
  announce(trip.id);
  return { data: await getLoad(pv.load.loadId), message: `Load ${pv.load.loadNo || ""} repaired${replaced ? " — the message was replaced" : ""}`.replace("  ", " "), replaced };
}

export interface MissedLoad {
  kind: "missing" | "fixable";
  messageId: string;
  at: Date;
  driverName: string | null;
  loadNo: string | null;
  firstLine: string;
  changes: string[];
}

// The scan reads a few hundred messages, so the board's badge reuses the last answer for a minute
let missedCache: { at: number; days: number; rows: MissedLoad[] } | null = null;
export const forgetMissed = () => {
  missedCache = null;
};

/** Recent chat messages that look like loads but aren't in Loads ("missing"), and loads made from them wrongly ("fixable"). */
export async function missedLoads(days = 14): Promise<MissedLoad[]> {
  if (missedCache && missedCache.days === days && Date.now() - missedCache.at < 60_000) return missedCache.rows;
  const rows = await scanMissed(days);
  missedCache = { at: Date.now(), days, rows };
  return rows;
}

async function scanMissed(days: number): Promise<MissedLoad[]> {
  const since = new Date(Date.now() - Math.max(1, Math.min(60, days)) * 86400_000);
  const out: MissedLoad[] = [];
  const names = new Map<string, string | null>();
  const nameOf = async (m: Message) => {
    const key = m.groupId || m.userProfileId;
    if (!names.has(key)) names.set(key, m.groupId ? ((await Group.findByPk(m.groupId))?.name || null) : ((await UserProfile.findByPk(m.userProfileId))?.username || null));
    return names.get(key)!;
  };
  const staffCache = new Map<string, boolean>();
  const isStaff = async (id: string) => {
    if (!staffCache.has(id)) staffCache.set(id, isStaffRole(((await UserProfile.findByPk(id, { include: [{ model: Role, as: "role" }] })) as any)?.role?.name));
    return staffCache.get(id)!;
  };

  // 1. Dispatch's load texts with no load
  const rows = await Message.findAll({
    where: {
      messageDirection: "S",
      createdAt: { [Op.gte]: since },
      url: null,
      type: { [Op.ne]: "truck_group" },
      is_automated: { [Op.or]: [false, null] },
      [Op.or]: ["%LOAD%", "%ORDER%", "%PICK%", "%DROP%", "%DELIVER%", "%TRIP%"].map((p) => ({ body: { [Op.like]: p } })),
    } as any,
    order: [["createdAt", "DESC"]],
    limit: 400,
  });
  const seenTrips = new Set<number>();
  for (const m of rows) {
    const body = String(m.body || "");
    if (!looksLikeLoad(body) || trailerOnly(body)) continue;
    if (!(await isStaff(m.senderId))) continue;
    const linked = await leg(m.id);
    if (linked) continue; // handled by the fixable pass below
    const no = parseLoad(body)?.loadNo || null;
    if (no && cleanLoadNo(no) && (await findLoadByNo(cleanLoadNo(no)!))) continue; // already in Loads some other way
    out.push({ kind: "missing", messageId: m.id, at: m.messageTimestampUtc as any, driverName: await nameOf(m), loadNo: no, firstLine: body.split(/\r?\n/).find((l) => l.trim()) || "", changes: [] });
    if (out.length >= 100) return out;
  }

  // 2. Loads made in the window whose details or assistant message don't match today's reading
  const trips = await ChatTrip.findAll({
    where: { createdAt: { [Op.gte]: since }, status: { [Op.notIn]: CLOSED }, message_id: { [Op.ne]: null } } as any,
    include: [{ model: ChatTripStop, as: "stops" }],
    order: [["createdAt", "DESC"]],
    limit: 300,
  });
  for (const t of trips) {
    if (seenTrips.has(t.id)) continue;
    seenTrips.add(t.id);
    const pv = await repairPreview(t.message_id!).catch(() => null);
    if (!pv || pv.mode !== "repair" || !pv.canApply) continue;
    const m = (await Message.findByPk(t.message_id!))!;
    out.push({
      kind: "fixable",
      messageId: t.message_id!,
      at: m.messageTimestampUtc as any,
      driverName: await nameOf(m),
      loadNo: pv.load?.loadNo || null,
      firstLine: `Load ${pv.load?.loadNo || ""}`.trim(),
      changes: [...pv.changes.map((c) => `${c.label}: ${c.before} → ${c.after}`), ...(pv.message ? ["Message text will be replaced"] : [])],
    });
    if (out.length >= 100) break;
  }
  return out;
}
