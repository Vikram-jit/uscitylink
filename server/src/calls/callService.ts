import { randomUUID } from "crypto";
import type { CallStatus, CallType } from "../models/Call";

// The call state machine. The server is the single authority on who is ringing, who answered and
// when a call ends; clients only exchange WebRTC offers/answers/ICE through it (call:signal).
//
// Direct call (dispatch → driver):
//   ringing ──accept──▶ active ──hang up / connection lost──▶ completed
//      ├─decline───────▶ declined     ├─caller cancels─▶ cancelled     └─no answer─▶ missed
//   (driver already on a call ─▶ busy, never rings)
//
// Dispatch call (driver → dispatch), an ACD queue:
//   rings every dispatcher who is online on the channel and not on a call; first to answer wins
//   and the others stop ringing. If every online dispatcher is on a call the driver waits in line
//   ("queued"); the moment one hangs up the oldest waiting call rings everyone who is free.
//   Nobody online at all ─▶ missed (unavailable). Waiting too long ─▶ missed (queue_timeout).
//
// Group call (staff adds staff to an answered call, up to MAX_PARTICIPANTS people):
//   a member invites another staff member ─▶ their phone/dashboard rings ("join request")
//      ├─accept ─▶ joins: everyone connects to them directly (mesh; the joiner sends the offers)
//      ├─decline / no answer / cancelled ─▶ logged, the call carries on
//   Someone hangs up while 3+ are on the call ─▶ only they leave; with 2 left it ends for both.
//
// Transfer (a dispatcher hands the call to another dispatcher; the driver stays connected):
//   a join request marked transfer ─accept─▶ the new dispatcher joins, then the one who
//   transferred leaves automatically ("transferred"). Declined / no answer ─▶ they stay on.
//
// Socket.IO, the database, push and the chat bubble are injected (CallDeps), so this file has no
// I/O of its own and can be exercised directly (scripts/calls/stateMachine.check.ts).
// Calls live in memory; CallStore is the seam for moving them to Redis for several server nodes.

export type Role = "staff" | "driver";

export interface Person {
  id: string;
  name: string;
  role: Role;
}

export type InviteState = "ringing" | "declined" | "missed" | "left";

/** Most people on one call (everyone connects to everyone, so it stays small). */
export const MAX_PARTICIPANTS = 6;

/** Someone on the answered call. leftAt is set when they hang up while the others carry on. */
export interface Member {
  person: Person;
  joinedAt: number;
  leftAt: number | null;
}

/** A request to join an answered call (group call). */
export interface JoinRequest {
  person: Person;
  by: Person;
  at: number;
  /** Transfer: whoever asked leaves once this person joins. */
  transfer: boolean;
  state: "ringing" | "joined" | "declined" | "missed" | "cancelled";
  timer?: NodeJS.Timeout;
}

export interface ActiveCall {
  id: string;
  type: CallType;
  channelId: string;
  channelName: string;
  driverId: string; // whose conversation the call belongs to
  caller: Person;
  /** Driver → dispatch: rings whoever is free, waits in line when nobody is. */
  dispatch: boolean;
  /** Both sides send their audio to the server once answered (callRecorder.ts). */
  recording: boolean;
  invited: Map<string, { person: Person; state: InviteState; at: number }>;
  answeredBy: Person | null;
  /** Everyone who has been on the answered call (caller, answerer, people added later). */
  members: Map<string, Member>;
  /** People asked to join the answered call. */
  joins: Map<string, JoinRequest>;
  /**
   * People on the call whose app/dashboard can do group calls. Driver apps already in the stores
   * can't (a second person's offer would break their call), so nobody is added while one is on it.
   */
  groupCapable: Set<string>;
  /**
   * Video: who can show video (older apps are audio-only), whose camera is on, and whether the
   * recording keeps video too (admin switch; audio is always recorded).
   */
  videoCapable: Set<string>;
  camera: Map<string, boolean>;
  recordVideo: boolean;
  phase: "queued" | "ringing" | "active";
  startedAt: number;
  queuedAt: number | null;
  queuedMs: number;
  ringingAt: number | null;
  answeredAt: number | null;
  muted: Map<string, boolean>;
  ringTimer?: NodeJS.Timeout;
  queueTimer?: NodeJS.Timeout;
  graceTimers: Map<string, NodeJS.Timeout>;
}

export interface CallSummary {
  id: string;
  type: CallType;
  channelId: string;
  channelName: string;
  driverId: string;
  caller: Person;
  answeredBy: Person | null;
  invited: { person: Person; state: InviteState }[];
  status: CallStatus;
  reason: string;
  startedAt: number;
  answeredAt: number | null;
  endedAt: number;
  durationSec: number;
  /** Seconds the driver waited in line because every dispatcher was busy. */
  queuedSec: number;
  /** Seconds from dialling until someone answered (queue + ringing). */
  waitSec: number | null;
  members: Member[];
  joins: { person: Person; by: Person; at: number; transfer: boolean; state: JoinRequest["state"] }[];
}

export interface CallStore {
  get(id: string): ActiveCall | undefined;
  put(call: ActiveCall): void;
  remove(id: string): void;
  all(): ActiveCall[];
}

export class MemoryCallStore implements CallStore {
  private calls = new Map<string, ActiveCall>();
  get = (id: string) => this.calls.get(id);
  put = (call: ActiveCall) => void this.calls.set(call.id, call);
  remove = (id: string) => void this.calls.delete(id);
  all = () => [...this.calls.values()];
}

export interface CallDeps {
  store: CallStore;
  /** Emit to a user's live socket; false when they have none. */
  emit(userId: string, event: string, payload: any): boolean;
  /** Dispatchers who are online (live socket) on a channel right now. */
  dispatchers(channelId: string): Promise<Person[]> | Person[];
  /** Ring phones (push) — used for drivers; dispatchers ring through their live connection. */
  pushIncoming(userIds: string[], call: ActiveCall): Promise<void> | void;
  pushStopRinging(userIds: string[], callId: string, reason: string): Promise<void> | void;
  /** Persist: create on invite, add rung dispatchers, answer, end. */
  persistStart(call: ActiveCall): Promise<void>;
  persistRinging(call: ActiveCall, people: Person[]): Promise<void>;
  persistAnswer(call: ActiveCall): Promise<void>;
  persistEnd(summary: CallSummary): Promise<void>;
  /** Group calls: a join request was sent / answered / not answered; a member left early. */
  pushJoinRequest?(userId: string, call: ActiveCall, by: Person): Promise<void> | void;
  persistJoinRequest?(call: ActiveCall, request: JoinRequest): Promise<void>;
  persistJoinOutcome?(call: ActiveCall, request: JoinRequest): Promise<void>;
  persistLeave?(call: ActiveCall, member: Member): Promise<void>;
  /** Who is on an answered call changed (started, joined, left, ended): live "on call" marks. */
  onCallsChanged?(): void;
  ringTimeoutMs?: number;
  queueTimeoutMs?: number;
  reconnectGraceMs?: number;
  now?: () => number;
}

export type InviteResult =
  | { ok: true; callId: string; ringing: number; queued: boolean; position?: number }
  | { ok: false; error: "already_in_call" | "busy" | "unavailable"; callId?: string };

export const ERRORS: Record<string, string> = {
  already_in_call: "You are already on a call",
  busy: "They are on another call",
  unavailable: "No dispatcher is online right now",
  not_found: "This call has ended",
  not_invited: "This call isn't for you",
  not_in_call: "You are not on this call",
  already_answered: "Someone else answered",
  already_member: "They are already on this call",
  already_ringing: "They are already being asked to join",
  call_full: `A call can have at most ${MAX_PARTICIPANTS} people`,
  already_transferring: "You are already transferring this call",
  staff_only: "Only staff can be added to a call",
  old_app: "Someone on this call has an older app version that can't do group calls",
};

export class CallService {
  private ringTimeoutMs: number;
  private queueTimeoutMs: number;
  private graceMs: number;
  private now: () => number;
  private serving: Promise<void> = Promise.resolve();

  constructor(private deps: CallDeps) {
    this.ringTimeoutMs = deps.ringTimeoutMs ?? 45_000;
    this.queueTimeoutMs = deps.queueTimeoutMs ?? 3 * 60_000;
    this.graceMs = deps.reconnectGraceMs ?? 15_000;
    this.now = deps.now ?? Date.now;
  }

  // ---------- queries ----------

  /** On the call right now: the caller before it's answered, then everyone who joined and hasn't left. */
  isOnCall(call: ActiveCall, userId: string): boolean {
    if (call.phase !== "active") return call.caller.id === userId;
    const m = call.members.get(userId);
    return !!m && m.leftAt === null;
  }

  /** People on the answered call right now. */
  currentMembers(call: ActiveCall): Person[] {
    return [...call.members.values()].filter((m) => m.leftAt === null).map((m) => m.person);
  }

  /** The call a user is on: placed it (including waiting in line), answered it, or joined it. */
  activeCallOf(userId: string): ActiveCall | undefined {
    return this.deps.store.all().find((c) => this.isOnCall(c, userId));
  }

  /**
   * Busy = on a call, or the only person a direct call is ringing. A dispatcher whose phone is
   * merely ringing for a dispatch call is still free (several drivers may ring them at once).
   */
  isBusy(userId: string): boolean {
    if (this.activeCallOf(userId)) return true;
    return this.deps.store
      .all()
      .some(
        (c) =>
          (!c.dispatch && c.phase === "ringing" && c.invited.get(userId)?.state === "ringing") ||
          c.joins.get(userId)?.state === "ringing"
      );
  }

  /** Calls the user is on (placed, waiting in line, or answered). */
  activeCallsOf(userId: string): ActiveCall[] {
    return this.deps.store.all().filter((c) => this.isOnCall(c, userId));
  }

  /** Ringing for any call right now (not answered yet). */
  isRinging(userId: string): boolean {
    return this.deps.store
      .all()
      .some((c) => (c.phase === "ringing" && c.invited.get(userId)?.state === "ringing") || c.joins.get(userId)?.state === "ringing");
  }

  get(callId: string) {
    return this.deps.store.get(callId);
  }

  /** Every call in progress (ringing, waiting in line or answered). */
  all(): ActiveCall[] {
    return this.deps.store.all();
  }

  /** Position in the waiting line (1 = next), or 0 when not waiting. */
  queuePosition(callId: string): number {
    const line = this.queued(this.deps.store.get(callId)?.channelId);
    const i = line.findIndex((c) => c.id === callId);
    return i < 0 ? 0 : i + 1;
  }

  publicView(call: ActiveCall) {
    return {
      callId: call.id,
      type: call.type,
      channelId: call.channelId,
      channelName: call.channelName,
      driverId: call.driverId,
      from: call.caller,
      answeredBy: call.answeredBy,
      phase: call.phase,
      dispatch: call.dispatch,
      recording: call.recording,
      position: call.phase === "queued" ? this.queuePosition(call.id) : 0,
      startedAt: call.startedAt,
      answeredAt: call.answeredAt,
      members: this.currentMembers(call),
      pending: [...call.joins.values()].filter((j) => j.state === "ringing").map((j) => j.person),
      maxParticipants: MAX_PARTICIPANTS,
      // Video: whose camera is on / who can show video at all (older apps can't)
      camera: Object.fromEntries([...call.camera].filter(([, on]) => on)),
      muted: Object.fromEntries([...call.muted].filter(([, m]) => m)),
      videoCapable: [...call.videoCapable],
      recordVideo: call.recordVideo,
    };
  }

  // ---------- transitions ----------

  async invite(input: {
    caller: Person;
    channelId: string;
    channelName: string;
    driverId: string;
    /** Direct call: who to ring. Ignored for dispatch calls. */
    targets?: Person[];
    /** Driver → dispatch (ring free dispatchers / wait in line). */
    dispatch?: boolean;
    type?: CallType;
    recording?: boolean;
    /** The caller's app can do group calls. */
    groupCapable?: boolean;
    /** The caller's app can do video. */
    videoCapable?: boolean;
    recordVideo?: boolean;
  }): Promise<InviteResult> {
    if (this.isBusy(input.caller.id)) return { ok: false, error: "already_in_call" };

    const call: ActiveCall = {
      id: randomUUID(),
      type: input.type || "audio",
      channelId: input.channelId,
      channelName: input.channelName,
      driverId: input.driverId,
      caller: input.caller,
      dispatch: !!input.dispatch,
      recording: !!input.recording,
      invited: new Map(),
      answeredBy: null,
      members: new Map(),
      joins: new Map(),
      groupCapable: new Set(input.groupCapable ? [input.caller.id] : []),
      videoCapable: new Set(input.videoCapable ? [input.caller.id] : []),
      // A video call starts with the caller's camera on
      camera: new Map(input.type === "video" ? [[input.caller.id, true]] : []),
      recordVideo: !!input.recordVideo,
      phase: "ringing",
      startedAt: this.now(),
      queuedAt: null,
      queuedMs: 0,
      ringingAt: null,
      answeredAt: null,
      muted: new Map(),
      graceTimers: new Map(),
    };

    if (call.dispatch) {
      const online = (await this.deps.dispatchers(call.channelId)).filter((p) => p.id !== call.caller.id);
      if (!online.length) {
        await this.deps.persistStart(call);
        await this.deps.persistEnd(this.summarize(call, "missed", "no_dispatcher_online"));
        return { ok: false, error: "unavailable", callId: call.id };
      }
      const free = online.filter((p) => !this.isBusy(p.id));
      this.deps.store.put(call);
      await this.deps.persistStart(call);
      if (!free.length) {
        this.enqueue(call);
        return { ok: true, callId: call.id, ringing: 0, queued: true, position: this.queuePosition(call.id) };
      }
      await this.ring(call, free);
      return { ok: true, callId: call.id, ringing: free.length, queued: false };
    }

    const targets = (input.targets || []).filter((t) => t.id !== call.caller.id);
    const free = targets.filter((t) => !this.isBusy(t.id));
    if (!free.length) {
      const error = targets.length ? "busy" : "unavailable";
      await this.deps.persistStart(call);
      await this.deps.persistEnd(this.summarize(call, error === "busy" ? "busy" : "missed", error));
      return { ok: false, error, callId: call.id };
    }
    this.deps.store.put(call);
    await this.deps.persistStart(call);
    await this.ring(call, free);
    return { ok: true, callId: call.id, ringing: free.length, queued: false };
  }

  async accept(callId: string, user: Person, opts: { groupCapable?: boolean; videoCapable?: boolean; video?: boolean } = {}) {
    const call = this.deps.store.get(callId);
    if (!call) return { ok: false as const, error: "not_found" };
    if (opts.groupCapable) call.groupCapable.add(user.id);
    if (opts.videoCapable) call.videoCapable.add(user.id);
    if (opts.video !== undefined) call.camera.set(user.id, !!opts.video);
    const join = call.joins.get(user.id);
    if (join && call.phase === "active") return this.acceptJoin(call, join, user);
    const invite = call.invited.get(user.id);
    if (!invite) return { ok: false as const, error: "not_invited" };
    if (call.phase !== "ringing" || invite.state !== "ringing") {
      return { ok: false as const, error: call.answeredBy ? "already_answered" : "not_found" };
    }
    if (this.activeCallOf(user.id)) return { ok: false as const, error: "already_in_call" };

    clearTimeout(call.ringTimer);
    call.phase = "active";
    call.answeredBy = user;
    call.answeredAt = this.now();
    call.members.set(call.caller.id, { person: call.caller, joinedAt: call.answeredAt, leftAt: null });
    call.members.set(user.id, { person: user, joinedAt: call.answeredAt, leftAt: null });

    // Everyone else who was ringing stops
    const others = [...call.invited.values()].filter((i) => i.person.id !== user.id && i.state === "ringing");
    for (const o of others) {
      o.state = "left";
      this.deps.emit(o.person.id, "call:answered_elsewhere", { callId, by: user });
    }
    await this.deps.pushStopRinging(
      others.map((o) => o.person.id),
      callId,
      "answered_elsewhere"
    );
    const view = this.publicView(call);
    this.deps.emit(call.caller.id, "call:accepted", { callId, by: user, camera: view.camera, videoCapable: view.videoCapable });
    await this.deps.persistAnswer(call);
    await this.stopRingingElsewhere(user, callId);
    this.deps.onCallsChanged?.();
    return { ok: true as const, call: this.publicView(call) };
  }

  /**
   * They answered one call while also ringing for others (several drivers, or a join request):
   * stop those. A call left with nobody ringing goes back into the line (in its original order).
   */
  private async stopRingingElsewhere(user: Person, exceptCallId: string) {
    for (const other of this.deps.store.all()) {
      if (other.id === exceptCallId) continue;
      const join = other.joins.get(user.id);
      if (join?.state === "ringing") await this.endJoinRequest(other, join, "missed");
      const inv = other.invited.get(user.id);
      if (other.phase !== "ringing" || inv?.state !== "ringing") continue;
      inv.state = "left";
      this.deps.emit(user.id, "call:answered_elsewhere", { callId: other.id, by: user });
      if (!this.ringingCount(other)) {
        if (other.dispatch) this.enqueue(other);
        else await this.finish(other.id, "missed", "no_answer");
      } else {
        this.deps.emit(other.caller.id, "call:ringing", { callId: other.id, ringing: this.ringingCount(other) });
      }
    }
  }

  // ---------- group calls ----------

  /**
   * A member asks another staff member to join the answered call; it rings them. With
   * [transfer], the one asking hands the call over: they leave as soon as the other joins.
   */
  async addParticipant(callId: string, by: Person, target: Person, opts: { transfer?: boolean } = {}) {
    const transfer = !!opts.transfer;
    const call = this.deps.store.get(callId);
    if (!call || call.phase !== "active") return { ok: false as const, error: "not_found" };
    if (!this.isOnCall(call, by.id)) return { ok: false as const, error: "not_in_call" };
    if (target.role !== "staff") return { ok: false as const, error: "staff_only" };
    if (this.isOnCall(call, target.id)) return { ok: false as const, error: "already_member" };
    if (call.joins.get(target.id)?.state === "ringing") return { ok: false as const, error: "already_ringing" };
    const ringing = [...call.joins.values()].filter((j) => j.state === "ringing");
    if (transfer && ringing.some((j) => j.transfer && j.by.id === by.id)) return { ok: false as const, error: "already_transferring" };
    // A transfer replaces whoever asks, so it fits even when the call is otherwise full
    if (this.currentMembers(call).length + ringing.length - (transfer ? 1 : 0) >= MAX_PARTICIPANTS) {
      return { ok: false as const, error: "call_full" };
    }
    if (this.isBusy(target.id)) return { ok: false as const, error: "busy" };
    const oldApp = this.currentMembers(call).find((p) => !call.groupCapable.has(p.id));
    if (oldApp) return { ok: false as const, error: "old_app", who: oldApp.name };

    const request: JoinRequest = { person: target, by, at: this.now(), state: "ringing", transfer };
    call.joins.set(target.id, request);
    request.timer = setTimeout(() => void this.endJoinRequest(call, request, "missed"), this.ringTimeoutMs);
    this.deps.emit(target.id, "call:incoming", { ...this.publicView(call), joinRequest: true, transfer, invitedBy: by });
    this.announceRoster(call);
    await this.deps.persistJoinRequest?.(call, request);
    await this.deps.pushJoinRequest?.(target.id, call, by);
    return { ok: true as const, call: this.publicView(call) };
  }

  /** Whoever asked can take a join request back while it still rings. */
  async cancelJoinRequest(callId: string, byId: string, targetId: string) {
    const call = this.deps.store.get(callId);
    const request = call?.joins.get(targetId);
    if (!call || !request || request.state !== "ringing") return { ok: false as const, error: "not_found" };
    if (!this.isOnCall(call, byId)) return { ok: false as const, error: "not_in_call" };
    await this.endJoinRequest(call, request, "cancelled");
    return { ok: true as const };
  }

  private async acceptJoin(call: ActiveCall, request: JoinRequest, user: Person) {
    if (request.state !== "ringing") return { ok: false as const, error: "not_found" };
    if (this.activeCallOf(user.id)) return { ok: false as const, error: "already_in_call" };
    // A transfer replaces whoever asked (they leave right after), so it fits a full call
    const leaving = request.transfer && this.isOnCall(call, request.by.id) ? 1 : 0;
    if (this.currentMembers(call).length - leaving >= MAX_PARTICIPANTS) {
      await this.endJoinRequest(call, request, "missed");
      return { ok: false as const, error: "call_full" };
    }
    clearTimeout(request.timer);
    request.state = "joined";
    const member: Member = { person: user, joinedAt: this.now(), leftAt: null };
    call.members.set(user.id, member);
    // Everyone already on the call gets ready for the joiner's offer
    for (const p of this.currentMembers(call)) {
      if (p.id !== user.id) this.deps.emit(p.id, "call:member_joined", { callId: call.id, person: user });
    }
    this.announceRoster(call);
    await this.deps.persistJoinOutcome?.(call, request);
    await this.stopRingingElsewhere(user, call.id);
    // Transfer: the dispatcher who handed the call over drops off now that the new one is on
    if (request.transfer && this.isOnCall(call, request.by.id)) {
      this.deps.emit(request.by.id, "call:transferred", { callId: call.id, to: user });
      await this.leave(call, request.by.id, "transferred");
    }
    this.deps.onCallsChanged?.();
    return { ok: true as const, call: this.publicView(call) };
  }

  /** A join request stopped ringing without them joining. */
  private async endJoinRequest(call: ActiveCall, request: JoinRequest, state: "declined" | "missed" | "cancelled") {
    if (request.state !== "ringing") return;
    clearTimeout(request.timer);
    request.state = state;
    // Transfer that didn't go through: whoever asked is still on the call
    if (request.transfer && state !== "cancelled") {
      this.deps.emit(request.by.id, "call:transfer_failed", { callId: call.id, person: request.person, reason: state });
    }
    if (state !== "declined") {
      this.deps.emit(request.person.id, "call:ended", { callId: call.id, status: "missed", reason: `join_${state}`, durationSec: 0 });
      await this.deps.pushStopRinging([request.person.id], call.id, `join_${state}`);
    }
    this.announceRoster(call);
    await this.deps.persistJoinOutcome?.(call, request);
  }

  /** One person leaves while at least two others carry on talking. */
  private async leave(call: ActiveCall, userId: string, reason: string) {
    const member = call.members.get(userId);
    if (!member || member.leftAt !== null) return;
    member.leftAt = this.now();
    clearTimeout(call.graceTimers.get(userId));
    call.graceTimers.delete(userId);
    const talked = Math.max(0, Math.round((member.leftAt - member.joinedAt) / 1000));
    this.deps.emit(userId, "call:ended", { callId: call.id, status: "completed", reason, durationSec: talked });
    for (const p of this.currentMembers(call)) this.deps.emit(p.id, "call:member_left", { callId: call.id, person: member.person, reason });
    this.announceRoster(call);
    await this.deps.persistLeave?.(call, member);
    this.deps.onCallsChanged?.();
  }

  /** Who is on the call and who is being asked to join — to everyone on it. */
  private announceRoster(call: ActiveCall) {
    if (call.phase !== "active") return;
    const view = this.publicView(call);
    for (const p of this.currentMembers(call)) {
      this.deps.emit(p.id, "call:participants", {
        callId: call.id,
        members: view.members,
        pending: view.pending,
        max: MAX_PARTICIPANTS,
        camera: view.camera,
        muted: view.muted,
        videoCapable: view.videoCapable,
      });
    }
  }

  async decline(callId: string, userId: string) {
    const call = this.deps.store.get(callId);
    if (!call) return { ok: false as const, error: "not_found" };
    const join = call.joins.get(userId);
    if (join?.state === "ringing") {
      await this.endJoinRequest(call, join, "declined");
      return { ok: true as const };
    }
    const invite = call.invited.get(userId);
    if (!invite || call.phase !== "ringing" || invite.state !== "ringing") return { ok: false as const, error: "not_invited" };
    invite.state = "declined";
    if (!this.ringingCount(call)) await this.finish(callId, "declined", "declined");
    else this.deps.emit(call.caller.id, "call:ringing", { callId, ringing: this.ringingCount(call) });
    return { ok: true as const };
  }

  /** Caller hangs up before anyone answered (ringing or in line), or anyone on the call hangs up. */
  async hangup(callId: string, userId: string) {
    const call = this.deps.store.get(callId);
    if (!call) return { ok: false as const, error: "not_found" };
    if (!this.isOnCall(call, userId)) {
      if (call.invited.has(userId) || call.joins.get(userId)?.state === "ringing") return this.decline(callId, userId);
      return { ok: false as const, error: "not_in_call" };
    }
    // Group call: they leave, the others carry on
    if (call.phase === "active" && this.currentMembers(call).length > 2) {
      await this.leave(call, userId, "hung_up");
      return { ok: true as const };
    }
    if (call.phase !== "active") await this.finish(callId, "cancelled", "caller_cancelled");
    else await this.finish(callId, "completed", call.caller.id === userId ? "caller_hung_up" : "callee_hung_up");
    return { ok: true as const };
  }

  /**
   * WebRTC offer/answer/ICE between two people on the answered call. [toId] picks who (group
   * calls); without it — older apps on a 1-to-1 call — it goes to the only other person.
   */
  signal(callId: string, fromId: string, data: any, toId?: string) {
    const call = this.deps.store.get(callId);
    if (!call || call.phase !== "active") return { ok: false as const, error: "not_found" };
    if (!this.isOnCall(call, fromId)) return { ok: false as const, error: "not_in_call" };
    const others = this.currentMembers(call).filter((p) => p.id !== fromId);
    const to = toId ? others.find((p) => p.id === toId) : others.length === 1 ? others[0] : undefined;
    if (!to) return { ok: false as const, error: "not_in_call" };
    this.deps.emit(to.id, "call:signal", { callId, from: fromId, data });
    return { ok: true as const };
  }

  /** Mute / camera changes, relayed to everyone else on the call (always both, as stored). */
  media(callId: string, fromId: string, state: { muted?: boolean; video?: boolean }) {
    const call = this.deps.store.get(callId);
    if (!call) return { ok: false as const, error: "not_found" };
    if (!this.isOnCall(call, fromId) || call.phase !== "active") return { ok: false as const, error: "not_in_call" };
    if (typeof state.muted === "boolean") call.muted.set(fromId, state.muted);
    if (typeof state.video === "boolean") call.camera.set(fromId, state.video);
    const payload = { callId, from: fromId, muted: !!call.muted.get(fromId), video: !!call.camera.get(fromId) };
    for (const p of this.currentMembers(call)) {
      if (p.id !== fromId) this.deps.emit(p.id, "call:media", payload);
    }
    return { ok: true as const };
  }

  // ---------- connection loss ----------

  /** Socket dropped: keep the call for a short grace period so a network switch doesn't end it. */
  onDisconnected(userId: string) {
    for (const call of this.deps.store.all()) {
      if (!this.isOnCall(call, userId) || call.graceTimers.has(userId)) continue;
      for (const p of this.currentMembers(call)) {
        if (p.id !== userId) this.deps.emit(p.id, "call:peer_reconnecting", { callId: call.id, from: userId });
      }
      call.graceTimers.set(
        userId,
        setTimeout(() => {
          // Group call: only they drop off; otherwise the call ends
          if (call.phase === "active" && this.currentMembers(call).length > 2) void this.leave(call, userId, "connection_lost");
          else void this.finish(call.id, call.phase === "active" ? "completed" : "cancelled", "connection_lost");
        }, this.graceMs)
      );
    }
  }

  /** Socket (re)connected: resume the user's call, re-deliver ringing invites, serve the line. */
  onConnected(userId: string) {
    for (const call of this.deps.store.all()) {
      const grace = call.graceTimers.get(userId);
      if (grace) {
        clearTimeout(grace);
        call.graceTimers.delete(userId);
      }
      if (this.isOnCall(call, userId)) {
        this.deps.emit(userId, "call:resume", this.publicView(call));
        if (grace) {
          for (const p of this.currentMembers(call)) {
            if (p.id !== userId) this.deps.emit(p.id, "call:peer_reconnected", { callId: call.id, from: userId });
          }
        }
      } else if (call.phase === "ringing" && call.invited.get(userId)?.state === "ringing") {
        // e.g. the app was woken by a push and just connected
        this.deps.emit(userId, "call:incoming", this.publicView(call));
      } else if (call.joins.get(userId)?.state === "ringing") {
        const request = call.joins.get(userId)!;
        this.deps.emit(userId, "call:incoming", { ...this.publicView(call), joinRequest: true, transfer: request.transfer, invitedBy: request.by });
      }
    }
    // A dispatcher just came online: drivers waiting in line can ring them
    void this.serveQueue();
  }

  // ---------- queue ----------

  private queued(channelId?: string): ActiveCall[] {
    return this.deps.store
      .all()
      .filter((c) => c.phase === "queued" && (!channelId || c.channelId === channelId))
      .sort((a, b) => a.startedAt - b.startedAt); // first to dial is first in line
  }

  private enqueue(call: ActiveCall) {
    call.phase = "queued";
    call.queuedAt = this.now();
    clearTimeout(call.ringTimer);
    call.queueTimer = setTimeout(() => void this.finish(call.id, "missed", "queue_timeout"), this.queueTimeoutMs);
    this.announcePositions(call.channelId);
  }

  private announcePositions(channelId: string) {
    this.queued(channelId).forEach((c, i) =>
      this.deps.emit(c.caller.id, "call:queued", { callId: c.id, position: i + 1 })
    );
  }

  /** Ring free dispatchers for waiting calls, oldest first. Runs one at a time. */
  serveQueue(): Promise<void> {
    this.serving = this.serving.then(async () => {
      const channels = new Set(this.queued().map((c) => c.channelId));
      for (const channelId of channels) {
        const online = await this.deps.dispatchers(channelId);
        for (const call of this.queued(channelId)) {
          if (!this.deps.store.get(call.id)) continue;
          // A dispatcher already ringing for a call takes that one first: the next caller keeps
          // their place in line instead of ringing the same person twice
          const free = online.filter((p) => p.id !== call.caller.id && !this.isBusy(p.id) && !this.isRinging(p.id));
          if (!free.length) break; // still everyone busy: keep waiting in order
          clearTimeout(call.queueTimer);
          call.queuedMs += this.now() - (call.queuedAt || this.now());
          await this.ring(call, free);
        }
        this.announcePositions(channelId);
      }
    }).catch((err) => console.error("[calls] serveQueue:", err));
    return this.serving;
  }

  private async ring(call: ActiveCall, people: Person[]) {
    call.phase = "ringing";
    call.ringingAt = this.now();
    const at = this.now();
    for (const p of people) call.invited.set(p.id, { person: p, state: "ringing", at });
    await this.deps.persistRinging(call, people);

    const incoming = this.publicView(call);
    for (const p of people) this.deps.emit(p.id, "call:incoming", incoming);
    this.deps.emit(call.caller.id, "call:ringing", { callId: call.id, ringing: people.length });
    await this.deps.pushIncoming(
      people.map((p) => p.id),
      call
    );
    clearTimeout(call.ringTimer);
    call.ringTimer = setTimeout(() => void this.finish(call.id, "missed", "no_answer"), this.ringTimeoutMs);
  }

  // ---------- internals ----------

  private ringingCount = (call: ActiveCall) => [...call.invited.values()].filter((i) => i.state === "ringing").length;

  private summarize(call: ActiveCall, status: CallStatus, reason: string): CallSummary {
    const endedAt = this.now();
    const queuedMs = call.queuedMs + (call.phase === "queued" && call.queuedAt ? endedAt - call.queuedAt : 0);
    return {
      id: call.id,
      type: call.type,
      channelId: call.channelId,
      channelName: call.channelName,
      driverId: call.driverId,
      caller: call.caller,
      answeredBy: call.answeredBy,
      invited: [...call.invited.values()].map((i) => ({
        person: i.person,
        state: i.state === "ringing" ? "missed" : i.state,
      })),
      status,
      reason,
      startedAt: call.startedAt,
      answeredAt: call.answeredAt,
      endedAt,
      durationSec: call.answeredAt ? Math.max(0, Math.round((endedAt - call.answeredAt) / 1000)) : 0,
      queuedSec: Math.round(queuedMs / 1000),
      waitSec: call.answeredAt ? Math.round((call.answeredAt - call.startedAt) / 1000) : null,
      members: [...call.members.values()].map((m) => ({ ...m, leftAt: m.leftAt ?? endedAt })),
      joins: [...call.joins.values()].map((j) => ({
        person: j.person,
        by: j.by,
        at: j.at,
        transfer: j.transfer,
        state: j.state === "ringing" ? "missed" : j.state,
      })),
    };
  }

  /** Ends a call exactly once, tells everyone involved, persists it, and serves the line. */
  async finish(callId: string, status: CallStatus, reason: string): Promise<CallSummary | null> {
    const call = this.deps.store.get(callId);
    if (!call) return null;
    this.deps.store.remove(callId);
    clearTimeout(call.ringTimer);
    clearTimeout(call.queueTimer);
    call.graceTimers.forEach((t) => clearTimeout(t));
    call.joins.forEach((j) => clearTimeout(j.timer));

    const summary = this.summarize(call, status, reason);
    const payload = { callId, status, reason, durationSec: summary.durationSec };
    const notified = new Set<string>();
    const tell = (id?: string) => {
      if (!id || notified.has(id)) return;
      notified.add(id);
      this.deps.emit(id, "call:ended", payload);
    };
    tell(call.caller.id);
    tell(call.answeredBy?.id);
    this.currentMembers(call).forEach((p) => tell(p.id));
    const stillRinging = [
      ...[...call.invited.values()].filter((i) => i.state === "ringing").map((i) => i.person.id),
      ...[...call.joins.values()].filter((j) => j.state === "ringing").map((j) => j.person.id),
    ];
    stillRinging.forEach(tell);
    await this.deps.pushStopRinging(stillRinging, callId, reason);
    if (call.phase === "active") this.deps.onCallsChanged?.();
    await this.deps.persistEnd(summary);

    // A dispatcher may be free now (or a waiting caller left the line)
    if (this.queued(call.channelId).length) await this.serveQueue();
    return summary;
  }
}
