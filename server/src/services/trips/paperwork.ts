// Paperwork from the chat: drivers rarely use the load's "Send BOL / POD" button — they just send the
// photo / PDF in the chat. Every attachment a driver sends goes on their load:
//   1. a delivered load still waiting for paperwork (ended / paperwork), newest first
//   2. else the load they're on now (pickup BOL, lumper receipt …)
//   3. else a load completed in the last 3 days (paperwork sent after dispatch closed it)
// The first one on a delivered load moves it to "Paperwork check". Dispatch sees them on the load
// (documents) and in its History; nothing is shown to the driver beyond their own chat.

import { Op } from "sequelize";
import { Message } from "../../models/Message";
import { ChatTrip, ChatTripEvent } from "../../models/ChatTrip";
import { MessageDocument } from "../../models/MessageDocument";
import { act, announce, record } from "./tripService";

const RECENT_DONE_MS = 3 * 24 * 3600_000;

export async function paperworkTripFor(profileId: string): Promise<ChatTrip | null> {
  const newest = [["ended_at", "DESC"], ["sent_at", "DESC"], ["id", "DESC"]] as any;
  return (
    (await ChatTrip.findOne({ where: { driver_profile_id: profileId, status: { [Op.in]: ["ended", "paperwork"] } }, order: newest })) ||
    (await ChatTrip.findOne({
      where: { driver_profile_id: profileId, status: { [Op.in]: ["planned", "accepted", "started", "rolling", "on_hold"] } },
      order: [["sent_at", "DESC"], ["id", "DESC"]],
    })) ||
    (await ChatTrip.findOne({
      where: { driver_profile_id: profileId, status: { [Op.in]: ["completed", "routed"] }, completed_at: { [Op.gte]: new Date(Date.now() - RECENT_DONE_MS) } },
      order: [["completed_at", "DESC"], ["id", "DESC"]],
    }))
  );
}

/** A driver's attachment in the chat → on their load. Returns the trip it went on. */
export async function attachFromChat(m: Message): Promise<ChatTrip | null> {
  if (!m.url || !m.userProfileId || m.messageDirection !== "R") return null;
  if (await ChatTripEvent.findOne({ where: { type: "document", message_id: m.id } })) return null;
  const trip = await paperworkTripFor(m.userProfileId);
  if (!trip) return null;
  const caption = String(m.body || "").trim() || null;
  await record(trip, {
    type: "document",
    actor: { role: "driver", id: m.userProfileId, name: null },
    note: caption ? `Document from the chat: ${caption.slice(0, 120)}` : "Document from the chat",
    messageId: m.id,
    at: (m as any).messageTimestampUtc || new Date(),
    data: { url: m.url, thumbnail: (m as any).thumbnail || null, uploadType: (m as any).url_upload_type || null, caption },
  });
  if (trip.status === "ended") {
    await act(trip.id, "paperwork", { role: "system", id: null, name: "Paperwork" }, { note: "BOL / POD sent in the chat" }).catch((e) =>
      console.warn("[trips] paperwork status:", e?.message || e)
    );
  }
  announce(trip.id);
  return trip;
}

export interface LoadDocument {
  messageId: string;
  at: Date;
  legNo: number;
  tripNo: string | null;
  url: string;
  thumbnail: string | null;
  uploadType: string | null;
  caption: string | null;
  /** What the document reader made of it (bol, pod, scale_ticket, lumper …), when it read it */
  docType: string | null;
}

/** Every document on these legs, oldest first, with the reader's type when known. */
export async function documentsOf(legs: ChatTrip[]): Promise<LoadDocument[]> {
  const out: LoadDocument[] = [];
  for (const l of legs) {
    for (const e of (l as any).events || []) {
      if (e.type !== "document" || !e.message_id || !e.data?.url) continue;
      out.push({
        messageId: e.message_id,
        at: new Date(e.happened_at || e.created_at),
        legNo: l.leg_no,
        tripNo: l.trip_no,
        url: e.data.url,
        thumbnail: e.data.thumbnail || null,
        uploadType: e.data.uploadType || null,
        caption: e.data.caption || null,
        docType: null,
      });
    }
  }
  if (out.length) {
    const read = await MessageDocument.findAll({ where: { message_id: out.map((d) => d.messageId) } }).catch(() => []);
    for (const d of out) {
      const r: any = read.find((x: any) => x.message_id === d.messageId);
      const type = r?.corrected_doc_type || r?.doc_type_key;
      d.docType = type && type !== "other" ? type : null;
    }
  }
  return out.sort((a, b) => a.at.getTime() - b.at.getTime());
}
