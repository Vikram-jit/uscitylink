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

export interface ActiveCall {
  id: string;
  type: CallType;
  channelId: string;
  channelName: string;
  driverId: string; // whose conversation the call belongs to
  caller: Person;
  /** Driver → dispatch: rings whoever is free, waits in line when nobody is. */
  dispatch: boolean;
  invited: Map<string, { person: Person; state: InviteState; at: number }>;
  answeredBy: Person | null;
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

  /** The call a user is on: placed it (including waiting in line) or answered it. */
  activeCallOf(userId: string): ActiveCall | undefined {
    return this.deps.store.all().find((c) => c.caller.id === userId || c.answeredBy?.id === userId);
  }

  /**
   * Busy = on a call, or the only person a direct call is ringing. A dispatcher whose phone is
   * merely ringing for a dispatch call is still free (several drivers may ring them at once).
   */
  isBusy(userId: string): boolean {
    if (this.activeCallOf(userId)) return true;
    return this.deps.store
      .all()
      .some((c) => !c.dispatch && c.phase === "ringing" && c.invited.get(userId)?.state === "ringing");
  }

  /** Calls the user is on (placed, waiting in line, or answered). */
  activeCallsOf(userId: string): ActiveCall[] {
    return this.deps.store.all().filter((c) => c.caller.id === userId || c.answeredBy?.id === userId);
  }

  /** Ringing for any call right now (not answered yet). */
  isRinging(userId: string): boolean {
    return this.deps.store.all().some((c) => c.phase === "ringing" && c.invited.get(userId)?.state === "ringing");
  }

  get(callId: string) {
    return this.deps.store.get(callId);
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
      position: call.phase === "queued" ? this.queuePosition(call.id) : 0,
      startedAt: call.startedAt,
      answeredAt: call.answeredAt,
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
      invited: new Map(),
      answeredBy: null,
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

  async accept(callId: string, user: Person) {
    const call = this.deps.store.get(callId);
    if (!call) return { ok: false as const, error: "not_found" };
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
    this.deps.emit(call.caller.id, "call:accepted", { callId, by: user });
    await this.deps.persistAnswer(call);

    // They were also ringing for other drivers: stop that. A call left with nobody ringing goes
    // back into the line (in its original order) instead of being lost.
    for (const other of this.deps.store.all()) {
      const inv = other.invited.get(user.id);
      if (other.id === callId || other.phase !== "ringing" || inv?.state !== "ringing") continue;
      inv.state = "left";
      this.deps.emit(user.id, "call:answered_elsewhere", { callId: other.id, by: user });
      if (!this.ringingCount(other)) {
        if (other.dispatch) this.enqueue(other);
        else await this.finish(other.id, "missed", "no_answer");
      } else {
        this.deps.emit(other.caller.id, "call:ringing", { callId: other.id, ringing: this.ringingCount(other) });
      }
    }
    return { ok: true as const, call: this.publicView(call) };
  }

  async decline(callId: string, userId: string) {
    const call = this.deps.store.get(callId);
    if (!call) return { ok: false as const, error: "not_found" };
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
    const onCall = call.caller.id === userId || call.answeredBy?.id === userId;
    if (!onCall) {
      if (call.invited.has(userId)) return this.decline(callId, userId);
      return { ok: false as const, error: "not_in_call" };
    }
    if (call.phase !== "active") await this.finish(callId, "cancelled", "caller_cancelled");
    else await this.finish(callId, "completed", call.caller.id === userId ? "caller_hung_up" : "callee_hung_up");
    return { ok: true as const };
  }

  /** WebRTC offer/answer/ICE: relayed only between the two people on an answered call. */
  signal(callId: string, fromId: string, data: any) {
    const call = this.deps.store.get(callId);
    if (!call || call.phase !== "active") return { ok: false as const, error: "not_found" };
    const peer = this.peerOf(call, fromId);
    if (!peer) return { ok: false as const, error: "not_in_call" };
    this.deps.emit(peer.id, "call:signal", { callId, from: fromId, data });
    return { ok: true as const };
  }

  media(callId: string, fromId: string, state: { muted?: boolean }) {
    const call = this.deps.store.get(callId);
    if (!call) return { ok: false as const, error: "not_found" };
    const peer = this.peerOf(call, fromId);
    if (!peer) return { ok: false as const, error: "not_in_call" };
    if (typeof state.muted === "boolean") call.muted.set(fromId, state.muted);
    this.deps.emit(peer.id, "call:media", { callId, from: fromId, muted: !!state.muted });
    return { ok: true as const };
  }

  // ---------- connection loss ----------

  /** Socket dropped: keep the call for a short grace period so a network switch doesn't end it. */
  onDisconnected(userId: string) {
    for (const call of this.deps.store.all()) {
      const onCall = call.caller.id === userId || call.answeredBy?.id === userId;
      if (!onCall || call.graceTimers.has(userId)) continue;
      const peer = this.peerOf(call, userId);
      if (peer) this.deps.emit(peer.id, "call:peer_reconnecting", { callId: call.id });
      call.graceTimers.set(
        userId,
        setTimeout(() => {
          void this.finish(call.id, call.phase === "active" ? "completed" : "cancelled", "connection_lost");
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
      const onCall = call.caller.id === userId || call.answeredBy?.id === userId;
      if (onCall) {
        this.deps.emit(userId, "call:resume", this.publicView(call));
        const peer = this.peerOf(call, userId);
        if (peer && grace) this.deps.emit(peer.id, "call:peer_reconnected", { callId: call.id });
      } else if (call.phase === "ringing" && call.invited.get(userId)?.state === "ringing") {
        // e.g. the app was woken by a push and just connected
        this.deps.emit(userId, "call:incoming", this.publicView(call));
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

  private peerOf(call: ActiveCall, userId: string): Person | null {
    if (call.caller.id === userId) return call.answeredBy;
    if (call.answeredBy?.id === userId) return call.caller;
    return null;
  }

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
    const stillRinging = [...call.invited.values()].filter((i) => i.state === "ringing").map((i) => i.person.id);
    stillRinging.forEach(tell);
    await this.deps.pushStopRinging(stillRinging, callId, reason);
    await this.deps.persistEnd(summary);

    // A dispatcher may be free now (or a waiting caller left the line)
    if (this.queued(call.channelId).length) await this.serveQueue();
    return summary;
  }
}
