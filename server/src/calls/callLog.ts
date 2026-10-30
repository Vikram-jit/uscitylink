import moment from "moment";
import { Sequelize } from "sequelize";
import { getSocketInstance } from "../sockets/socket";
import SocketEvents from "../sockets/socketEvents";
import { Message } from "../models/Message";
import { UserProfile } from "../models/UserProfile";
import UserChannel from "../models/UserChannel";
import type { CallSummary } from "./callService";

// The call bubble in the driver's conversation ("Voice call · 3:42", "Missed voice call").
// Delivered live the same way as other messages (see sendSystemMessageToDriver in
// sockets/messageHandler.ts). Old app builds just show the text.

export const formatDuration = (sec: number) => {
  const h = Math.floor(sec / 3600);
  const m = Math.floor((sec % 3600) / 60);
  const s = sec % 60;
  return h ? `${h}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}` : `${m}:${String(s).padStart(2, "0")}`;
};

export const callLogText = (s: CallSummary) => {
  const kind = s.type === "video" ? "video call" : "voice call";
  switch (s.status) {
    case "completed":
      return `${kind[0].toUpperCase()}${kind.slice(1)} · ${formatDuration(s.durationSec)}`;
    case "declined":
      return `Declined ${kind}`;
    case "failed":
      return `${kind[0].toUpperCase()}${kind.slice(1)} failed`;
    default:
      return `Missed ${kind}`; // missed, cancelled, busy, unavailable
  }
};

export async function writeCallLog(summary: CallSummary): Promise<Message | null> {
  const driverWasCalled = summary.caller.role === "staff";
  const driverMissedIt = driverWasCalled && !summary.answeredBy;

  const saved = await Message.create({
    channelId: summary.channelId,
    userProfileId: summary.driverId,
    senderId: summary.caller.id,
    body: callLogText(summary),
    messageDirection: driverWasCalled ? "S" : "R",
    deliveryStatus: "sent",
    messageTimestampUtc: new Date(summary.endedAt),
    isRead: !driverMissedIt,
    status: "sent",
    url: null,
    thumbnail: null,
    url_upload_type: "with-out-media",
    call_id: summary.id,
  });
  const message = await Message.findOne({
    where: { id: saved.id },
    include: [{ model: UserProfile, as: "sender", attributes: ["id", "username", "isOnline"] }],
  });

  let io: any = null;
  try {
    io = getSocketInstance();
  } catch {
    // no socket server (scripts)
  }
  if (io && message) {
    const driverSocket = global.userSockets[summary.driverId];
    const driverOpen = global.driverOpenChat.find((d) => d?.driverId === summary.driverId);
    if (driverSocket) {
      if (driverOpen?.channelId === summary.channelId) io.to(driverSocket.id).emit(SocketEvents.RECEIVE_MESSAGE_BY_CHANNEL, message);
      else io.to(driverSocket.id).emit("update_user_channel_list", message);
    }
    Object.entries(global.staffOpenChat || {}).forEach(([staffId, open]: [string, any]) => {
      if (open?.channelId === summary.channelId && open?.userId === summary.driverId) {
        const s = global.userSockets[staffId];
        if (s) io.to(s.id).emit(SocketEvents.RECEIVE_MESSAGE_BY_CHANNEL, message);
      }
    });
  }

  await UserChannel.update(
    {
      last_message_id: saved.id,
      last_message_utc: moment.utc().toDate(),
      ...(driverMissedIt ? { recieve_message_count: Sequelize.literal("recieve_message_count + 1") } : {}),
    } as any,
    { where: { userProfileId: summary.driverId, channelId: summary.channelId } }
  );
  return message;
}
