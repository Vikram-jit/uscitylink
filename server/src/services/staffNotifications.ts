import { Request, Response } from "express";
import { UserProfile } from "../models/UserProfile";
import { Message } from "../models/Message";

// "Until I turn it back on" is stored as a far-future time so one column covers every option
const FOREVER = new Date("2099-12-31T00:00:00Z");

export function isNotificationMuted(profile?: Pick<UserProfile, "notifications_muted_until"> | null): boolean {
  const until = profile?.notifications_muted_until;
  return !!until && new Date(until).getTime() > Date.now();
}

function muteState(until?: Date | null) {
  const active = !!until && new Date(until).getTime() > Date.now();
  return {
    muted: active,
    mutedUntil: active ? new Date(until!).toISOString() : null,
    forever: active && new Date(until!).getTime() >= FOREVER.getTime(),
  };
}

// GET /user/notification-mute
export async function getNotificationMute(req: Request, res: Response): Promise<any> {
  try {
    const profile = await UserProfile.findByPk(req.user?.id, { attributes: ["id", "notifications_muted_until"] });
    if (!profile) return res.status(404).json({ status: false, message: "Profile not found" });
    return res.status(200).json({ status: true, message: "Notification settings", data: muteState(profile.notifications_muted_until) });
  } catch (err: any) {
    return res.status(500).json({ status: false, message: err.message || "Internal Server Error" });
  }
}

// PUT /user/notification-mute  { minutes: 60 } | { forever: true } | { minutes: null } (unmute)
export async function setNotificationMute(req: Request, res: Response): Promise<any> {
  try {
    const { minutes, forever } = req.body || {};
    let until: Date | null = null;
    if (forever) until = FOREVER;
    else if (minutes !== null && minutes !== undefined) {
      const m = Number(minutes);
      if (!Number.isFinite(m) || m <= 0 || m > 60 * 24 * 365) throw new Error("minutes must be between 1 and 525600");
      until = new Date(Date.now() + m * 60 * 1000);
    }
    await UserProfile.update({ notifications_muted_until: until }, { where: { id: req.user?.id } });
    const state = muteState(until);
    return res.status(200).json({
      status: true,
      message: state.muted ? "Notifications muted" : "Notifications on",
      data: state,
    });
  } catch (err: any) {
    return res.status(400).json({ status: false, message: err.message || "Could not update" });
  }
}

const IMAGE = /\.(jpe?g|png|gif|heic|heif|webp|bmp)$/i;
const VIDEO = /\.(mp4|mov|m4v|avi|mkv|3gp|webm)$/i;
const AUDIO = /\.(m4a|aac|mp3|wav|ogg|opus|amr|caf)$/i;
const DOC = /\.(pdf|docx?|xlsx?|csv|txt|pptx?)$/i;

// What a staff notification shows as its text: the message, or what was attached when there is none
export function notificationText(body?: string | null, url?: string | null): string {
  const text = (body || "").replace(/\s+/g, " ").trim();
  let attachment = "";
  if (url) {
    const path = url.split("?")[0];
    attachment = IMAGE.test(path) ? "📷 Photo" : VIDEO.test(path) ? "🎥 Video" : AUDIO.test(path) ? "🎤 Voice message" : DOC.test(path) ? "📄 Document" : "📎 Attachment";
  }
  const full = attachment && text ? `${attachment} · ${text}` : attachment || text || "New message";
  // FCM payloads are capped at 4 KB; a notification only needs the start of a long message
  return full.length > 500 ? `${full.slice(0, 497)}…` : full;
}

export async function messageNotificationText(messageId?: string | null, fallbackBody?: string | null): Promise<string> {
  if (!messageId) return notificationText(fallbackBody);
  const message = await Message.findByPk(messageId, { attributes: ["body", "url"] }).catch(() => null);
  return notificationText(message?.body ?? fallbackBody, message?.url);
}
