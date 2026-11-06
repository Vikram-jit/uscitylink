import { Op } from "sequelize";
import type { CustomSocket } from "../sockets/socket";
import { isStaffRole, STAFF_ROLES } from "../middleware/requireRole";
import { UserProfile } from "../models/UserProfile";
import User from "../models/User";
import Role from "../models/Role";
import Channel from "../models/Channel";
import UserChannel from "../models/UserChannel";
import { Call, CallParticipant } from "../models/Call";
import { isCallMuted } from "../services/staffNotifications";
import { isCallRecordingEnabled, isCallVideoRecordingEnabled, isCallsEnabled } from "../services/documentAi/settings";
import { CallService, ERRORS, MemoryCallStore, Person } from "./callService";
import { iceServersFor } from "./iceServers";
import { pushCallEnded, pushIncomingCall, pushMissedCall } from "./callPush";
import { answerRecordingOffer, finishRecording, startVideoRecording } from "./callRecorder";
import { writeCallLog } from "./callLog";

// Socket.IO side of calls: who may call whom, and the real dependencies for CallService.
//
// Client → server (all take an ack callback):
//   call:invite  { driverId }               staff calls a driver (in the staff member's channel)
//   call:invite  { channelId? }             driver calls dispatch: rings that channel's staff
//   call:accept / call:decline / call:end   { callId }
//   call:signal  { callId, data, to? }      WebRTC offer / answer / ICE to one person on the call
//   call:media   { callId, muted }
//   call:status  { callId }                 after a push woke the app: is it still ringing?
//   call:add / call:add_cancel { callId, userId }   group call: ask a staff member to join
//   call:rec_offer { callId, sdp }          recorded call: this side's microphone to the server
// Server → client: call:incoming (joinRequest: true for a group-call request), call:ringing,
//   call:accepted, call:answered_elsewhere, call:signal { from }, call:media { from },
//   call:peer_reconnecting / call:peer_reconnected { from }, call:resume, call:ended,
//   call:member_joined / call:member_left { person }, call:participants { members, pending }

const profileWithRole = (id: string) => UserProfile.findByPk(id, { include: [{ model: Role, as: "role" }] });

/** A driver's phone number (users.phone_number), shown next to their name on calls. */
export async function driverPhoneOf(profile?: UserProfile | null): Promise<string> {
  if (!profile?.userId) return "";
  const user = await User.findByPk(profile.userId, { attributes: ["id", "phone_number"] }).catch(() => null);
  return String(user?.phone_number || "").trim();
}

async function pushTo(ids: string[], fn: (p: UserProfile) => Promise<void>) {
  if (!ids.length) return;
  const profiles = await UserProfile.findAll({ where: { id: ids } });
  await Promise.all(profiles.map((p) => fn(p).catch((e) => console.warn("[calls] push:", e?.message || e))));
}

// Connections of staff (dashboard tabs, staff app): they get the live "who is on a call" list
const staffSockets = new Set<CustomSocket>();

/** Answered calls right now: which driver, and who is on each — for the "On call" marks in chats. */
function onCallSnapshot() {
  return callService
    .all()
    .filter((c) => c.phase === "active")
    .map((c) => ({
      callId: c.id,
      driverId: c.driverId,
      channelId: c.channelId,
      members: callService.currentMembers(c),
      answeredAt: c.answeredAt,
    }));
}

let broadcastTimer: NodeJS.Timeout | null = null;
/** Tell every staff connection who is on a call (coalesced: one message per burst of changes). */
function broadcastOnCall() {
  if (broadcastTimer) return;
  broadcastTimer = setTimeout(() => {
    broadcastTimer = null;
    const calls = onCallSnapshot();
    for (const s of staffSockets) if (s.connected) s.emit("calls:on_call", { calls });
  }, 100);
}

// Every live connection per user (several dashboard tabs, web + phone). The rest of the app keeps
// one socket per user (global.userSockets); calls must ring all of them.
const userSockets = new Map<string, Set<CustomSocket>>();
// The connection that carries a call's audio for each person on it ("callId:userId")
const mediaSockets = new Map<string, CustomSocket>();
// Events that belong to the connection on the call, not every tab
const CALL_SCOPED = new Set([
  "call:signal",
  "call:media",
  "call:peer_reconnecting",
  "call:peer_reconnected",
  "call:accepted",
  "call:resume",
  "call:member_joined",
  "call:member_left",
  "call:participants",
]);

const liveSockets = (userId: string) => [...(userSockets.get(userId) || [])].filter((s) => s.connected);
const isBrowser = (s: CustomSocket) => /mozilla/i.test(String(s.handshake.headers["user-agent"] || ""));
/** Has the web dashboard open (not just the app). */
const onDashboard = (userId: string) => liveSockets(userId).some(isBrowser);
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
  // Dispatchers working this channel who can be reached: a live connection (dashboard tab, staff app
  // open) or the staff app installed and logged in (push token) — a closed or backgrounded staff app
  // rings by push like a driver's phone. Logging out clears the token, so logged-out phones don't ring.
  dispatchers: async (channelId) => {
    const online = [...userSockets.keys()].filter(isOnline);
    const staffRoles = await Role.findAll({ where: { name: STAFF_ROLES } });
    const staff = await UserProfile.findAll({
      where: {
        role_id: staffRoles.map((r) => r.id),
        channelId,
        [Op.or]: [
          ...(online.length ? [{ id: online }] : []),
          { voip_token: { [Op.ne]: null } },
          { device_token: { [Op.ne]: null }, platform: { [Op.in]: ["ios", "android"] } },
        ],
      },
      attributes: ["id", "username", "calls_muted_until"],
    });
    // "Mute call alerts" (staff app setting) silences their phone only: they're still rung while
    // their web dashboard is open
    return staff
      .filter((s) => !isCallMuted(s) || onDashboard(s.id))
      .map((s) => ({ id: s.id, name: s.username || "Dispatch", role: "staff" } as Person));
  },
  // Everyone rung also gets a push: drivers' phones, and dispatchers' staff app (an open dashboard
  // has no push token, so it rings on its connection only)
  pushIncoming: (ids, call) =>
    pushTo(ids, (p) =>
      pushIncomingCall(p, {
        callId: call.id,
        callerId: call.caller.id,
        callerName: call.caller.name,
        callerRole: call.caller.role,
        channelId: call.channelId,
        channelName: call.channelName,
        type: call.type,
        driverPhone: call.driverPhone,
      })
      ),
  pushStopRinging: (ids, callId, reason) => pushTo(ids, (p) => pushCallEnded(p, callId, reason)),
  // Group call: a staff member asked to join rings like an incoming call from whoever asked
  pushJoinRequest: (userId, call, by) =>
    pushTo([userId], (p) =>
      pushIncomingCall(p, {
        callId: call.id,
        callerId: by.id,
        callerName: by.name,
        callerRole: "staff",
        channelId: call.channelId,
        channelName: call.channelName,
        type: call.type,
        driverPhone: call.driverPhone,
      })
    ),
  persistJoinRequest: async (call, r) => {
    await CallParticipant.create({
      call_id: call.id,
      user_profile_id: r.person.id,
      role: "added",
      state: "invited",
      invited_at: new Date(r.at),
      invited_by: r.by.id,
      join_type: r.transfer ? "transfer" : "add",
    });
  },
  persistJoinOutcome: async (call, r) => {
    const where = { call_id: call.id, user_profile_id: r.person.id, role: "added", state: "invited" };
    if (r.state === "joined") await CallParticipant.update({ state: "joined", joined_at: new Date() }, { where });
    else await CallParticipant.update({ state: r.state, left_at: new Date() }, { where });
  },
  onCallsChanged: () => broadcastOnCall(),
  persistLeave: async (call, m) => {
    await CallParticipant.update(
      { state: "left", left_at: new Date(m.leftAt || Date.now()) },
      { where: { call_id: call.id, user_profile_id: m.person.id, state: "joined" } }
    );
  },
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
    const how = (id: string) => (liveSockets(id).length ? (onDashboard(id) ? "web" : "app") : "push only");
    console.log(
      `[calls] ${call.id}: ${call.caller.name} (${call.caller.role}) ${call.type} call ringing ${people.length}: ` +
        people.map((p) => `${p.name} [${how(p.id)}]`).join(", ")
    );
    await CallParticipant.bulkCreate(
      people.map((p) => ({ call_id: call.id, user_profile_id: p.id, role: "callee", state: "invited", invited_at: at }))
    );
  },
  persistAnswer: async (call) => {
    console.log(`[calls] ${call.id}: answered by ${call.answeredBy?.name} (${call.answeredBy?.id})`);
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
    const declined = s.invited.filter((i) => i.state === "declined").map((i) => i.person.name);
    console.log(
      `[calls] ${s.id}: ended ${s.status} (${s.reason}) after ${Math.round((s.endedAt - s.startedAt) / 1000)}s` +
        (s.answeredBy ? `, answered by ${s.answeredBy.name}, talked ${s.durationSec}s` : "") +
        (declined.length ? `, declined by ${declined.join(", ")}` : "")
    );
    // Recorded call: mix both voices and upload (runs on its own, never delays the call log)
    void finishRecording(s.id);
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
          { where: { call_id: s.id, user_profile_id: i.person.id, role: "callee", state: "invited" } }
        );
      }
      // Join requests still ringing when the call ended
      for (const j of s.joins) {
        if (j.state === "joined") continue;
        await CallParticipant.update(
          { state: j.state, left_at: endedAt },
          { where: { call_id: s.id, user_profile_id: j.person.id, role: "added", state: "invited" } }
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
      driverPhone: await driverPhoneOf(driver),
      channelId,
      channelName: channel?.name || "",
      driverId: driver.id,
    };
  }

  if (callerRole === "driver") {
    const open = global.driverOpenChat?.find((d) => d?.driverId === callerId);
    let channelId = String(payload?.channelId || open?.channelId || "");
    let member = channelId ? await UserChannel.findOne({ where: { userProfileId: callerId, channelId } }) : null;
    if (!member) {
      // Asked for a channel they aren't in (e.g. an old app's dashboard channel): use their own
      member = await UserChannel.findOne({ where: { userProfileId: callerId }, order: [["createdAt", "ASC"]] });
      channelId = member?.channelId || "";
    }
    if (!member) throw new Error("You aren't in any channel yet — ask dispatch to add you");

    // The dispatch line: CallService rings whoever is online and free, or queues the driver
    const channel = await Channel.findByPk(channelId);
    return {
      caller: { id: caller.id, name: caller.username || "Driver", role: "driver" } as Person,
      driverPhone: await driverPhoneOf(caller),
      dispatch: true,
      channelId,
      channelName: channel?.name || "",
      driverId: caller.id,
    };
  }
  throw new Error("Calls are only between dispatch and drivers");
}

/** Which device a call action came from, for the log ("several devices on one account" issues). */
const device = (socket: CustomSocket) => {
  const ua = String(socket.handshake.headers["user-agent"] || "");
  const kind = /dart/i.test(ua) ? "app" : /mozilla/i.test(ua) ? "browser" : ua.slice(0, 40) || "unknown";
  return `${kind}, ${socket.handshake.address}`;
};

export function registerCallHandlers(socket: CustomSocket) {
  const me = () => socket.user?.id || "";
  const userId = me();
  if (!userId) return;
  if (!userSockets.has(userId)) userSockets.set(userId, new Set());
  userSockets.get(userId)!.add(socket);
  const bind = (callId: string) => mediaSockets.set(`${callId}:${userId}`, socket);

  // A call this person is on carries on over this (new) connection — unless the connection carrying
  // it is still up: then this is another tab or device of the same account (the dashboard opening
  // while the phone is on the call), and taking the call over would leave the phone with no audio
  const carried = new Set<string>();
  for (const call of callService.activeCallsOf(userId)) {
    const carrier = mediaSockets.get(`${call.id}:${userId}`);
    if (carrier && carrier !== socket && carrier.connected) continue;
    bind(call.id);
    carried.add(call.id);
  }

  // Staff see who is on a call (chat list "On call" marks): current list now, then live updates
  void profileWithRole(userId).then((p) => {
    if (!isStaffRole(p?.role?.name) || !socket.connected) return;
    staffSockets.add(socket);
    socket.emit("calls:on_call", { calls: onCallSnapshot() });
  });
  socket.on("calls:on_call_get", (_payload: any, ackFn: any) => safeAck(ackFn)({ ok: true, calls: onCallSnapshot() }));

  socket.on("disconnect", () => {
    staffSockets.delete(socket);
    const set = userSockets.get(userId);
    set?.delete(socket);
    if (set && !set.size) userSockets.delete(userId);
    // The call waits for a reconnect when this was the connection carrying it, even if the same
    // account is still open elsewhere (that other tab or device isn't on the call)
    for (const call of callService.activeCallsOf(userId)) {
      if (mediaSockets.get(`${call.id}:${userId}`) === socket) callService.onDisconnected(userId);
    }
  });
  const person = async (): Promise<Person> => {
    const p = await profileWithRole(me());
    return { id: me(), name: p?.username || socket.user?.name || "", role: isStaffRole(p?.role?.name) ? "staff" : "driver" };
  };

  // A reconnect resumes the call; an app woken by a push gets the ringing invite again
  callService.onConnected(me(), (callId) => carried.has(callId));

  socket.on("call:invite", async (payload, ackFn) => {
    const ack = safeAck(ackFn);
    try {
      if (!(await isCallsEnabled())) return fail(ack, "Calling is turned off");
      const last = lastInvite.get(me()) || 0;
      if (Date.now() - last < 2000) return fail(ack, "Please wait a moment before calling again");
      lastInvite.set(me(), Date.now());

      const plan = await resolveInvite(me(), payload);
      const result = await callService.invite({
        ...plan,
        type: payload?.type === "video" ? "video" : "audio",
        recording: await isCallRecordingEnabled(),
        groupCapable: payload?.group === true,
        videoCapable: payload?.video === true,
        recordVideo: await isCallVideoRecordingEnabled(),
      });
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

  socket.on("call:accept", async ({ callId, group, videoCapable, camera } = {}, ackFn) => {
    const ack = safeAck(ackFn);
    bind(String(callId));
    // Answered before the caller is told (see CallService.accept): the caller's offer follows on
    // this same connection, so it can't overtake the answer and get dropped as an unknown call
    let answered = false;
    const res = await callService.accept(String(callId), await person(), {
      groupCapable: group === true,
      videoCapable: videoCapable === true,
      video: typeof camera === "boolean" ? camera : undefined,
      onAnswered: (call) => {
        answered = true;
        ack({ ok: true, call, ...iceServersFor(me()) });
      },
    });
    if (!res.ok) {
      mediaSockets.delete(`${callId}:${userId}`);
      return fail(ack, res.error);
    }
    // The same person's other tabs/devices stop ringing
    for (const other of liveSockets(userId)) if (other !== socket) other.emit("call:answered_elsewhere", { callId, by: res.call.answeredBy });
    if (!answered) ack({ ok: true, call: res.call, ...iceServersFor(me()) });
  });

  socket.on("call:decline", async ({ callId } = {}, ackFn) => {
    console.log(`[calls] ${callId}: declined by ${socket.user?.name || me()} (${device(socket)})`);
    const res = await callService.decline(String(callId), me());
    safeAck(ackFn)(res.ok ? { ok: true } : { ok: false, error: res.error, message: ERRORS[res.error] });
  });

  socket.on("call:end", async ({ callId, reason } = {}, ackFn) => {
    // reason: newer apps say why (end_button, logout, connection_failed, native_call_ended)
    const why = typeof reason === "string" ? `, ${reason.slice(0, 40)}` : "";
    console.log(`[calls] ${callId}: hung up by ${socket.user?.name || me()} (${device(socket)}${why})`);
    const res = await callService.hangup(String(callId), me());
    safeAck(ackFn)(res.ok ? { ok: true } : { ok: false, error: res.error, message: ERRORS[res.error] });
  });

  socket.on("call:signal", ({ callId, data, to } = {}, ackFn) => {
    const res = callService.signal(String(callId), me(), data, to ? String(to) : undefined);
    safeAck(ackFn)(res.ok ? { ok: true } : { ok: false, error: res.error });
  });

  socket.on("call:media", ({ callId, muted, video } = {}, ackFn) => {
    const res = callService.media(String(callId), me(), {
      muted: typeof muted === "boolean" ? muted : undefined,
      video: typeof video === "boolean" ? video : undefined,
    });
    safeAck(ackFn)(res.ok ? { ok: true } : { ok: false, error: res.error });
  });

  // Group call: someone on the call asks another staff member to join (it rings them)
  socket.on("call:add", async ({ callId, userId: targetId } = {}, ackFn) => {
    const ack = safeAck(ackFn);
    try {
      const by = await person();
      if (by.role !== "staff") return fail(ack, "staff_only");
      const target = await profileWithRole(String(targetId || ""));
      if (!target) return fail(ack, "Choose someone to add");
      const res = await callService.addParticipant(String(callId), by, {
        id: target.id,
        name: target.username || "Staff",
        role: isStaffRole(target.role?.name) ? "staff" : "driver",
      });
      if (!res.ok) {
        const who = "who" in res && res.who ? res.who : null;
        return who
          ? ack({ ok: false, error: res.error, message: `${who} has an older app version that can't do group calls — ask them to update` })
          : fail(ack, res.error);
      }
      ack({ ok: true, call: res.call });
    } catch (err: any) {
      fail(ack, err?.message || "Could not add them");
    }
  });

  // Transfer: hand the call to another staff member; this person leaves once they pick up
  socket.on("call:transfer", async ({ callId, userId: targetId } = {}, ackFn) => {
    const ack = safeAck(ackFn);
    try {
      const by = await person();
      if (by.role !== "staff") return fail(ack, "staff_only");
      const target = await profileWithRole(String(targetId || ""));
      if (!target) return fail(ack, "Choose someone to transfer to");
      const res = await callService.addParticipant(
        String(callId),
        by,
        { id: target.id, name: target.username || "Staff", role: isStaffRole(target.role?.name) ? "staff" : "driver" },
        { transfer: true }
      );
      if (!res.ok) {
        const who = "who" in res && res.who ? res.who : null;
        return who
          ? ack({ ok: false, error: res.error, message: `${who} has an older app version that can't take transferred calls — ask them to update` })
          : fail(ack, res.error);
      }
      ack({ ok: true, call: res.call });
    } catch (err: any) {
      fail(ack, err?.message || "Could not transfer the call");
    }
  });

  socket.on("call:add_cancel", async ({ callId, userId: targetId } = {}, ackFn) => {
    const res = await callService.cancelJoinRequest(String(callId), me(), String(targetId || ""));
    safeAck(ackFn)(res.ok ? { ok: true } : { ok: false, error: res.error, message: ERRORS[res.error] });
  });

  // Recorded call, once answered: this side sends its microphone to the server (callRecorder.ts)
  socket.on("call:rec_offer", async ({ callId, sdp } = {}, ackFn) => {
    const ack = safeAck(ackFn);
    try {
      const live = callService.get(String(callId));
      if (!live || live.phase !== "active" || !callService.isOnCall(live, me())) return fail(ack, "not_in_call");
      if (!live.recording) return fail(ack, "This call isn't recorded");
      if (typeof sdp !== "string" || !sdp.includes("m=audio")) return fail(ack, "Invalid recording offer");
      ack({ ok: true, sdp: await answerRecordingOffer(live.id, me(), sdp, { video: live.recordVideo }) });
    } catch (err: any) {
      console.warn("[recording] offer failed:", err?.message || err);
      fail(ack, err?.message || "Recording could not start");
    }
  });

  // Staff turn on video recording mid-call (audio is always recorded)
  socket.on("call:record_video", async ({ callId } = {}, ackFn) => {
    const ack = safeAck(ackFn);
    try {
      const by = await person();
      const res = callService.startVideoRecording(String(callId), by);
      if (!res.ok) {
        if (res.error === "not_recorded") return fail(ack, "This call isn't being recorded");
        if (res.error === "staff_only") return fail(ack, "Only staff can record video");
        return fail(ack, res.error);
      }
      if (!res.already) {
        startVideoRecording(String(callId));
        console.log(`[call] ${callId}: ${by.name} (${by.id}) started video recording`);
      }
      ack({ ok: true });
    } catch (err: any) {
      fail(ack, err?.message || "Could not start video recording");
    }
  });

  socket.on("call:status", async ({ callId } = {}, ackFn) => {
    const ack = safeAck(ackFn);
    const live = callService.get(String(callId));
    if (live) {
      const mine = callService.isOnCall(live, me());
      const ringingMe =
        (live.phase === "ringing" && live.invited.get(me())?.state === "ringing") || live.joins.get(me())?.state === "ringing";
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

/**
 * Staff who can be asked to join a call: online (live connection) and not on or ringing for
 * another call. For the "Add to call" list.
 */
export async function availableStaff(exceptId: string) {
  const ids = [...userSockets.keys()].filter((id) => id !== exceptId && isOnline(id));
  if (!ids.length) return [];
  const staffRoles = await Role.findAll({ where: { name: STAFF_ROLES } });
  const staff = await UserProfile.findAll({
    where: { id: ids, role_id: staffRoles.map((r) => r.id) },
    attributes: ["id", "username"],
    order: [["username", "ASC"]],
  });
  return staff.map((s) => ({ id: s.id, name: s.username || "Staff", busy: callService.isBusy(s.id) }));
}
