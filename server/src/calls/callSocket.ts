import type { CustomSocket } from "../sockets/socket";
import { isStaffRole, STAFF_ROLES } from "../middleware/requireRole";
import { UserProfile } from "../models/UserProfile";
import Role from "../models/Role";
import Channel from "../models/Channel";
import UserChannel from "../models/UserChannel";
import { Call, CallParticipant } from "../models/Call";
import { isCallsEnabled } from "../services/documentAi/settings";
import { CallService, ERRORS, MemoryCallStore, Person } from "./callService";
import { iceServersFor } from "./iceServers";
import { pushCallEnded, pushIncomingCall, pushMissedCall } from "./callPush";
import { writeCallLog } from "./callLog";

// Socket.IO side of calls: who may call whom, and the real dependencies for CallService.
//
// Client → server (all take an ack callback):
//   call:invite  { driverId }               staff calls a driver (in the staff member's channel)
//   call:invite  { channelId? }             driver calls dispatch: rings that channel's staff
//   call:accept / call:decline / call:end   { callId }
//   call:signal  { callId, data }           WebRTC offer / answer / ICE candidate
//   call:media   { callId, muted }
//   call:status  { callId }                 after a push woke the app: is it still ringing?
// Server → client: call:incoming, call:ringing, call:accepted, call:answered_elsewhere, call:signal,
//   call:media, call:peer_reconnecting, call:peer_reconnected, call:resume, call:ended

const profileWithRole = (id: string) => UserProfile.findByPk(id, { include: [{ model: Role, as: "role" }] });

async function pushTo(ids: string[], fn: (p: UserProfile) => Promise<void>) {
  if (!ids.length) return;
  const profiles = await UserProfile.findAll({ where: { id: ids } });
  await Promise.all(profiles.map((p) => fn(p).catch((e) => console.warn("[calls] push:", e?.message || e))));
}

// Every live connection per user (several dashboard tabs, web + phone). The rest of the app keeps
// one socket per user (global.userSockets); calls must ring all of them.
const userSockets = new Map<string, Set<CustomSocket>>();
// The connection that carries a call's audio for each person on it ("callId:userId")
const mediaSockets = new Map<string, CustomSocket>();
// Events that belong to the connection on the call, not every tab
const CALL_SCOPED = new Set(["call:signal", "call:media", "call:peer_reconnecting", "call:peer_reconnected", "call:accepted"]);

const liveSockets = (userId: string) => [...(userSockets.get(userId) || [])].filter((s) => s.connected);
export const isOnline = (userId: string) => liveSockets(userId).length > 0;

const forgetCall = (callId: string) => {
  for (const key of [...mediaSockets.keys()]) if (key.startsWith(`${callId}:`)) mediaSockets.delete(key);
};

export const callService = new CallService({
  store: new MemoryCallStore(),
  emit: (userId, event, payload) => {
    const sockets = liveSockets(userId);
    if (!sockets.length) return false;
    const bound = payload?.callId ? mediaSockets.get(`${payload.callId}:${userId}`) : undefined;
    if (CALL_SCOPED.has(event) && bound?.connected) bound.emit(event, payload);
    else sockets.forEach((s) => s.emit(event, payload));
    return true;
  },
  // Dispatchers working this channel with at least one live connection (dashboard tab or staff app)
  dispatchers: async (channelId) => {
    const ids = [...userSockets.keys()].filter(isOnline);
    if (!ids.length) return [];
    const staffRoles = await Role.findAll({ where: { name: STAFF_ROLES } });
    const staff = await UserProfile.findAll({
      where: { id: ids, role_id: staffRoles.map((r) => r.id), channelId },
      attributes: ["id", "username"],
    });
    return staff.map((s) => ({ id: s.id, name: s.username || "Dispatch", role: "staff" } as Person));
  },
  // Phones ring by push only for dispatch → driver calls; dispatchers ring on their live connection
  pushIncoming: (ids, call) =>
    call.dispatch
      ? undefined
      : pushTo(ids, (p) =>
      pushIncomingCall(p, {
        callId: call.id,
        callerId: call.caller.id,
        callerName: call.caller.name,
        callerRole: call.caller.role,
        channelId: call.channelId,
        channelName: call.channelName,
        type: call.type,
      })
      ),
  pushStopRinging: (ids, callId, reason) => pushTo(ids, (p) => pushCallEnded(p, callId, reason)),
  persistStart: async (call) => {
    const at = new Date(call.startedAt);
    await Call.create({
      id: call.id,
      channel_id: call.channelId,
      driver_id: call.driverId,
      initiator_id: call.caller.id,
      type: call.type,
      kind: call.dispatch ? "dispatch" : "direct",
      status: "ringing",
      started_at: at,
    });
    await CallParticipant.create({
      call_id: call.id,
      user_profile_id: call.caller.id,
      role: "caller",
      state: "joined",
      invited_at: at,
      joined_at: at,
    });
  },
  // Everyone the call rang (each dispatcher in the ring group), with the time it reached them
  persistRinging: async (call, people) => {
    const at = new Date(call.ringingAt || Date.now());
    await CallParticipant.bulkCreate(
      people.map((p) => ({ call_id: call.id, user_profile_id: p.id, role: "callee", state: "invited", invited_at: at }))
    );
  },
  persistAnswer: async (call) => {
    await Call.update(
      { status: "ongoing", answered_by: call.answeredBy?.id, answered_at: new Date(call.answeredAt!) },
      { where: { id: call.id } }
    );
    await CallParticipant.update(
      { state: "joined", joined_at: new Date(call.answeredAt!) },
      { where: { call_id: call.id, user_profile_id: call.answeredBy?.id } }
    );
  },
  persistEnd: async (s) => {
    forgetCall(s.id);
    try {
      const endedAt = new Date(s.endedAt);
      await Call.update(
        {
          status: s.status,
          end_reason: s.reason,
          ended_at: endedAt,
          duration_sec: s.durationSec,
          queued_sec: s.queuedSec,
          wait_sec: s.waitSec,
        },
        { where: { id: s.id } }
      );
      await CallParticipant.update({ state: "left", left_at: endedAt }, { where: { call_id: s.id, state: "joined" } });
      // What each person the call rang did: declined, missed it, or it was answered by someone else
      for (const i of s.invited) {
        if (i.person.id === s.answeredBy?.id) continue;
        await CallParticipant.update(
          { state: i.state === "declined" ? "declined" : i.state === "left" ? "left" : "missed", left_at: endedAt },
          { where: { call_id: s.id, user_profile_id: i.person.id, state: "invited" } }
        );
      }
      const message = await writeCallLog(s);
      if (message) await Call.update({ message_id: message.id }, { where: { id: s.id } });

      // The driver gets a "Missed call" notification when dispatch couldn't reach them
      if (s.caller.role === "staff" && !s.answeredBy && s.status !== "declined") {
        const driver = await UserProfile.findByPk(s.driverId);
        if (driver) await pushMissedCall(driver, s.caller.name, s.channelId);
      }
    } catch (err) {
      console.error("[calls] persistEnd failed:", err);
    }
  },
});

type Ack = (res: any) => void;
const safeAck = (ack: any): Ack => (typeof ack === "function" ? ack : () => undefined);
const fail = (ack: Ack, error: string, extra: Record<string, any> = {}) =>
  ack({ ok: false, error, message: ERRORS[error] || error, ...extra });

// Stops a stuck button or a script from hammering invite
const lastInvite = new Map<string, number>();

async function resolveInvite(callerId: string, payload: any) {
  const caller = await profileWithRole(callerId);
  if (!caller) throw new Error("not_found");
  const callerRole = caller.role?.name;

  if (isStaffRole(callerRole)) {
    const driverId = String(payload?.driverId || "");
    const channelId = String(
      payload?.channelId || global.staffActiveChannel?.[callerId]?.channelId || caller.channelId || ""
    );
    const driver = driverId ? await profileWithRole(driverId) : null;
    if (!driver || driver.role?.name !== "driver") throw new Error("Choose a driver to call");
    const member = await UserChannel.findOne({ where: { userProfileId: driverId, channelId } });
    if (!member) throw new Error("This driver isn't in your current channel");
    const channel = await Channel.findByPk(channelId);
    return {
      caller: { id: caller.id, name: caller.username || "Dispatch", role: "staff" } as Person,
      targets: [{ id: driver.id, name: driver.username || "Driver", role: "driver" } as Person],
      channelId,
      channelName: channel?.name || "",
      driverId: driver.id,
    };
  }

  if (callerRole === "driver") {
    const open = global.driverOpenChat?.find((d) => d?.driverId === callerId);
    let channelId = String(payload?.channelId || open?.channelId || "");
    if (!channelId) {
      const first = await UserChannel.findOne({ where: { userProfileId: callerId } });
      channelId = first?.channelId || "";
    }
    const member = channelId ? await UserChannel.findOne({ where: { userProfileId: callerId, channelId } }) : null;
    if (!member) throw new Error("You aren't in this channel");

    // The dispatch line: CallService rings whoever is online and free, or queues the driver
    const channel = await Channel.findByPk(channelId);
    return {
      caller: { id: caller.id, name: caller.username || "Driver", role: "driver" } as Person,
      dispatch: true,
      channelId,
      channelName: channel?.name || "",
      driverId: caller.id,
    };
  }
  throw new Error("Calls are only between dispatch and drivers");
}

export function registerCallHandlers(socket: CustomSocket) {
  const me = () => socket.user?.id || "";
  const userId = me();
  if (!userId) return;
  if (!userSockets.has(userId)) userSockets.set(userId, new Set());
  userSockets.get(userId)!.add(socket);
  const bind = (callId: string) => mediaSockets.set(`${callId}:${userId}`, socket);

  // A call this person is on carries on over this (new) connection
  for (const call of callService.activeCallsOf(userId)) bind(call.id);

  socket.on("disconnect", () => {
    const set = userSockets.get(userId);
    set?.delete(socket);
    if (set && !set.size) userSockets.delete(userId);
    // The call only waits for a reconnect when this was the connection carrying it
    for (const call of callService.activeCallsOf(userId)) {
      if (mediaSockets.get(`${call.id}:${userId}`) === socket && !isOnline(userId)) callService.onDisconnected(userId);
    }
  });
  const person = async (): Promise<Person> => {
    const p = await profileWithRole(me());
    return { id: me(), name: p?.username || socket.user?.name || "", role: isStaffRole(p?.role?.name) ? "staff" : "driver" };
  };

  // A reconnect resumes the call; an app woken by a push gets the ringing invite again
  callService.onConnected(me());

  socket.on("call:invite", async (payload, ackFn) => {
    const ack = safeAck(ackFn);
    try {
      if (!(await isCallsEnabled())) return fail(ack, "Calling is turned off");
      const last = lastInvite.get(me()) || 0;
      if (Date.now() - last < 2000) return fail(ack, "Please wait a moment before calling again");
      lastInvite.set(me(), Date.now());

      const plan = await resolveInvite(me(), payload);
      const result = await callService.invite({ ...plan, type: payload?.type === "video" ? "video" : "audio" });
      if (!result.ok) return fail(ack, result.error, { callId: result.callId });
      bind(result.callId);
      const live = callService.get(result.callId);
      ack({
        ok: true,
        callId: result.callId,
        ringing: result.ringing,
        queued: result.queued,
        position: result.position || 0,
        ...iceServersFor(me()),
        call: live ? callService.publicView(live) : null,
      });
    } catch (err: any) {
      fail(ack, err?.message || "Could not start the call");
    }
  });

  socket.on("call:accept", async ({ callId } = {}, ackFn) => {
    const ack = safeAck(ackFn);
    bind(String(callId));
    const res = await callService.accept(String(callId), await person());
    if (!res.ok) {
      mediaSockets.delete(`${callId}:${userId}`);
      return fail(ack, res.error);
    }
    // The same person's other tabs/devices stop ringing
    for (const other of liveSockets(userId)) if (other !== socket) other.emit("call:answered_elsewhere", { callId, by: res.call.answeredBy });
    ack({ ok: true, call: res.call, ...iceServersFor(me()) });
  });

  socket.on("call:decline", async ({ callId } = {}, ackFn) => {
    const res = await callService.decline(String(callId), me());
    safeAck(ackFn)(res.ok ? { ok: true } : { ok: false, error: res.error, message: ERRORS[res.error] });
  });

  socket.on("call:end", async ({ callId } = {}, ackFn) => {
    const res = await callService.hangup(String(callId), me());
    safeAck(ackFn)(res.ok ? { ok: true } : { ok: false, error: res.error, message: ERRORS[res.error] });
  });

  socket.on("call:signal", ({ callId, data } = {}, ackFn) => {
    const res = callService.signal(String(callId), me(), data);
    safeAck(ackFn)(res.ok ? { ok: true } : { ok: false, error: res.error });
  });

  socket.on("call:media", ({ callId, muted } = {}, ackFn) => {
    const res = callService.media(String(callId), me(), { muted: !!muted });
    safeAck(ackFn)(res.ok ? { ok: true } : { ok: false, error: res.error });
  });

  socket.on("call:status", async ({ callId } = {}, ackFn) => {
    const ack = safeAck(ackFn);
    const live = callService.get(String(callId));
    if (live) {
      const mine = live.caller.id === me() || live.answeredBy?.id === me();
      const ringingMe = live.phase === "ringing" && live.invited.get(me())?.state === "ringing";
      return ack({ ok: true, live: true, ringing: ringingMe, onCall: mine, call: callService.publicView(live), ...iceServersFor(me()) });
    }
    const row = await Call.findByPk(String(callId));
    ack({ ok: true, live: false, status: row?.status || "unknown" });
  });
}

/** Kept for socket.ts; disconnects are handled per connection in registerCallHandlers. */
export function callsOnDisconnect(_userId: string) {
  // no-op
}
