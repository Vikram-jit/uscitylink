// Who may place calls. Calling is on for everyone only while the admin's global switch is on; on top of
// that, a DRIVER places calls only when staff turned calling on for them (users.calls_enabled, off by
// default). Staff can always call, to any driver — the flag never stops staff, and a driver without it
// can still receive and answer calls from staff.

import { UserProfile } from "../models/UserProfile";
import User from "../models/User";
import Role from "../models/Role";
import { isStaffRole } from "../middleware/requireRole";
import { isCallsEnabled } from "../services/documentAi/settings";

export interface CallingAccess {
  /** What the app shows: the call buttons and the right to start a call */
  enabled: boolean;
  /** The admin's global switch */
  global: boolean;
  staff: boolean;
  /** The driver's own flag (always false for staff) */
  flag: boolean;
}

export async function callingFor(profileId: string): Promise<CallingAccess> {
  const global = await isCallsEnabled();
  const profile = await UserProfile.findByPk(profileId, { include: [{ model: Role, as: "role" }] });
  const staff = isStaffRole((profile as any)?.role?.name);
  if (staff) return { enabled: global, global, staff: true, flag: false };
  const user = profile?.userId ? await User.findByPk(profile.userId, { attributes: ["id", "calls_enabled"] }) : null;
  const flag = !!user?.calls_enabled;
  return { enabled: global && flag, global, staff: false, flag };
}

/** Turn calling on or off for one driver. Returns false when the profile isn't a driver. */
export async function setDriverCallingFlag(profileId: string, enabled: boolean): Promise<{ ok: boolean; reason?: string }> {
  const profile = await UserProfile.findByPk(profileId, { include: [{ model: Role, as: "role" }] });
  if (!profile) return { ok: false, reason: "Driver not found" };
  if ((profile as any).role?.name !== "driver") return { ok: false, reason: "Calling is switched on for drivers only — staff can always call" };
  if (!profile.userId) return { ok: false, reason: "This driver has no login" };
  await User.update({ calls_enabled: enabled }, { where: { id: profile.userId } });
  return { ok: true };
}

/** Why this person may not start a call right now (null = they may). Used by call:invite. */
export async function inviteBlocked(profileId: string): Promise<string | null> {
  const access = await callingFor(profileId);
  if (!access.global) return "Calling is turned off";
  if (!access.staff && !access.flag) return "Calling isn't turned on for your account — ask dispatch";
  return null;
}
