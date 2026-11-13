// A truck chat is a group named by its truck number, with the truck's driver(s) in it (one, or a team
// of two). A load sent from that chat is ONE load (on the truck's main driver, the team mate linked)
// and its standard load message shows in the truck chat once — for staff, and once for each member.

import Group from "../../models/Group";
import GroupUser from "../../models/GroupUser";
import { UserProfile } from "../../models/UserProfile";
import Role from "../../models/Role";
import { messageToDriverByTruckGroup } from "../../sockets/messageHandler";
import { getSocketInstance } from "../../sockets/socket";

/** Drivers in a group, by name — the first is the truck's main driver (the same order everywhere). */
export async function driversInGroup(groupId: string) {
  const links = await GroupUser.findAll({ where: { groupId } });
  if (!links.length) return [];
  const profiles = await UserProfile.findAll({
    where: { id: links.map((l: any) => l.userProfileId) },
    include: [{ model: Role, as: "role" }],
    order: [["username", "ASC"]],
  });
  return profiles.filter((p: any) => p.role?.name === "driver").map((p) => ({ id: p.id, name: p.username || "Driver" }));
}

export async function truckGroupById(groupId?: string | null): Promise<Group | null> {
  if (!groupId) return null;
  const group = await Group.findByPk(groupId);
  return group && group.type === "truck" ? group : null;
}

/** The truck chat → who the load is for: the main driver, the team mate, the truck number. */
export async function truckOfGroup(groupId?: string | null) {
  const group = await truckGroupById(groupId);
  if (!group) return null;
  const drivers = await driversInGroup(group.id);
  return { groupId: group.id, truck: String(group.name), driver: drivers[0] || null, team: drivers[1] || null, drivers };
}

/**
 * Post a load message in the truck chat: one message for staff and one for each active member (the
 * same send as typing in the chat). Returns the staff's copy — the one shown in the truck chat.
 */
export async function postToGroup(opts: { groupId: string; senderId: string; channelId: string | null; body: string; automated?: boolean }) {
  const members = await GroupUser.findAll({ where: { groupId: opts.groupId } });
  const ids = members.filter((m: any) => m.userProfileId && (m.status || "active") === "active").map((m: any) => m.userProfileId as string);
  if (!ids.length) return null;
  const socket = { user: { id: opts.senderId } } as any;
  const sent = await messageToDriverByTruckGroup(getSocketInstance(), socket, ids.join(","), opts.groupId, opts.body, "S", null, null, undefined, null, {
    channelId: opts.channelId,
    automated: opts.automated !== false,
  });
  return sent?.staffMessage || null;
}
