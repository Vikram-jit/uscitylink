// Replace the text of a chat message that is already sent — in the database (the staff's copy, every
// truck-chat member's copy, the group message) and live on screens: staff get "message_updated" at once,
// the driver and group members get it in their room (the driver app shows it when its chat reloads).
// Used by Repair (the assistant's old message) and when a typed load is rewritten into the standard layout.

import { Op } from "sequelize";
import { Message } from "../../models/Message";
import GroupMessage from "../../models/GroupMessage";
import GroupUser from "../../models/GroupUser";
import { getSocketInstance } from "../../sockets/socket";
import { userRoom } from "../../sockets/userConnections";
import { alertStaff } from "./tripService";

export async function replaceMessageText(messageId: string, body: string): Promise<{ ids: string[] } | null> {
  const old = await Message.findByPk(messageId);
  if (!old) return null;
  if (String(old.body).trim() === body.trim()) return { ids: [old.id] };
  const copies = await Message.findAll({
    where: old.groupId
      ? { [Op.or]: [{ id: old.id }, { groupId: old.groupId, senderId: old.senderId, body: old.body, messageTimestampUtc: old.messageTimestampUtc }] }
      : { id: old.id },
  });
  await Message.update({ body }, { where: { id: copies.map((c) => c.id) } });
  if (old.groupId) await GroupMessage.update({ body }, { where: { groupId: old.groupId, senderId: old.senderId, body: old.body, messageTimestampUtc: old.messageTimestampUtc } });
  const payload = { id: old.id, ids: copies.map((c) => c.id), body, channelId: old.channelId, groupId: old.groupId };
  alertStaff("message_updated", payload);
  try {
    const io = getSocketInstance();
    const members = old.groupId ? (await GroupUser.findAll({ where: { groupId: old.groupId } })).map((g: any) => g.userProfileId) : [old.userProfileId];
    for (const id of members) io.to(userRoom(String(id))).emit("message_updated", payload);
  } catch {
    // sockets not up (scripts)
  }
  return { ids: copies.map((c) => c.id) };
}
