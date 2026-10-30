// Run: npx ts-node -T scripts/calls/stateMachine.check.ts
// Exercises the call state machine (direct calls + the dispatch queue) with fake I/O and short timers.
import assert from "assert";
import { CallService, MemoryCallStore, CallSummary, Person } from "../../src/calls/callService";

const staff = (n: number): Person => ({ id: `staff${n}`, name: `Staff ${n}`, role: "staff" });
const drv = (n: number): Person => ({ id: `driver${n}`, name: `Driver ${n}`, role: "driver" });
const driver = drv(1);

function setup(online: Person[] = [staff(1), staff(2), staff(3)]) {
  const events: { to: string; event: string; payload: any }[] = [];
  const ended: CallSummary[] = [];
  const pushed: string[] = [];
  const stopped: string[] = [];
  const rang: string[] = [];
  const state = { online };
  const svc = new CallService({
    store: new MemoryCallStore(),
    emit: (to, event, payload) => (events.push({ to, event, payload }), true),
    dispatchers: () => state.online,
    pushIncoming: (ids, call) => void (call.dispatch ? undefined : pushed.push(...ids)),
    pushStopRinging: (ids) => void stopped.push(...ids),
    persistStart: async () => undefined,
    persistRinging: async (_c, people) => void rang.push(...people.map((p) => p.id)),
    persistAnswer: async () => undefined,
    persistEnd: async (s) => void ended.push(s),
    ringTimeoutMs: 60,
    queueTimeoutMs: 150,
    reconnectGraceMs: 60,
  });
  const got = (to: string, event: string) => events.filter((e) => e.to === to && e.event === event);
  return { svc, events, ended, pushed, stopped, rang, got, state };
}
const base = (d: Person = driver) => ({ channelId: "ch1", channelName: "US CITYLINK", driverId: d.id });
const wait = (ms: number) => new Promise((r) => setTimeout(r, ms));
const results: string[] = [];
const test = async (name: string, fn: () => Promise<void>) => {
  try { await fn(); results.push(`ok   ${name}`); } catch (e: any) { results.push(`FAIL ${name}: ${e.message}`); }
};
const dispatchCall = (t: ReturnType<typeof setup>, d: Person) => t.svc.invite({ ...base(d), caller: d, dispatch: true });

(async () => {
  // ---------- direct calls (dispatch → driver) ----------
  await test("staff → driver: accept, talk, hang up = completed, phone pushed", async () => {
    const t = setup();
    const r = await t.svc.invite({ ...base(), caller: staff(1), targets: [driver] });
    assert(r.ok && !r.queued);
    assert.deepEqual(t.pushed, [driver.id]);
    assert((await t.svc.accept(r.callId, driver)).ok);
    assert(t.svc.signal(r.callId, "staff1", { sdp: "offer" }).ok);
    assert(!t.svc.signal(r.callId, "staff9", {}).ok, "outsider cannot signal");
    await t.svc.hangup(r.callId, driver.id);
    assert.equal(t.ended[0].status, "completed");
    assert.equal(t.ended[0].waitSec, 0);
  });

  await test("direct: no answer → missed; decline → declined; busy driver never rings", async () => {
    const t = setup();
    const r = await t.svc.invite({ ...base(), caller: staff(1), targets: [driver] });
    assert(r.ok);
    await wait(90);
    assert.equal(t.ended[0]?.status, "missed");
    const r2 = await t.svc.invite({ ...base(), caller: staff(1), targets: [driver] });
    assert(r2.ok);
    await t.svc.decline(r2.callId, driver.id);
    assert.equal(t.ended[1].status, "declined");
    const r3 = await t.svc.invite({ ...base(), caller: staff(1), targets: [driver] });
    assert(r3.ok);
    await t.svc.accept(r3.callId, driver);
    const r4 = await t.svc.invite({ ...base(), caller: staff(2), targets: [driver] });
    assert(!r4.ok && r4.error === "busy");
  });

  // ---------- dispatch line ----------
  await test("3 dispatchers free: driver call rings all 3 (no push), first answer wins", async () => {
    const t = setup();
    const r = await dispatchCall(t, drv(1));
    assert(r.ok && r.ringing === 3 && !r.queued);
    assert.deepEqual(t.pushed, [], "dispatchers ring on their live connection only");
    assert.deepEqual(t.rang.sort(), ["staff1", "staff2", "staff3"]);
    assert((await t.svc.accept(r.callId, staff(2))).ok);
    const late = await t.svc.accept(r.callId, staff(3));
    assert(!late.ok && late.error === "already_answered");
    assert.equal(t.got("staff1", "call:answered_elsewhere").length, 1);
  });

  await test("1 busy → next driver rings only the 2 free; 2 busy → only 1; all busy → waits in line", async () => {
    const t = setup();
    const a = await dispatchCall(t, drv(1));
    assert(a.ok); await t.svc.accept(a.callId, staff(1));
    const b = await dispatchCall(t, drv(2));
    assert(b.ok && b.ringing === 2);
    assert.equal(t.got("staff1", "call:incoming").length, 1, "busy dispatcher not rung again");
    await t.svc.accept(b.callId, staff(2));
    const c = await dispatchCall(t, drv(3));
    assert(c.ok && c.ringing === 1);
    await t.svc.accept(c.callId, staff(3));
    const d = await dispatchCall(t, drv(4));
    assert(d.ok && d.queued && d.position === 1, "everyone busy → queued #1");
    const e = await dispatchCall(t, drv(5));
    assert(e.ok && e.queued && e.position === 2, "second waiting caller is #2");
    assert(t.got("driver4", "call:queued").length >= 1);
  });

  await test("dispatcher hangs up → oldest waiting call rings them; positions move up", async () => {
    const t = setup([staff(1)]);
    const a = await dispatchCall(t, drv(1));
    assert(a.ok); await t.svc.accept(a.callId, staff(1));
    const w1 = await dispatchCall(t, drv(2));
    const w2 = await dispatchCall(t, drv(3));
    assert(w1.ok && w1.queued && w2.ok && w2.queued);
    await t.svc.hangup(a.callId, drv(1).id);
    await t.svc.serveQueue();
    assert.equal(t.got("staff1", "call:incoming").filter((e) => e.payload.callId === w1.callId).length, 1, "first in line rings");
    assert.equal(t.got("staff1", "call:incoming").filter((e) => e.payload.callId === w2.callId).length, 0, "second keeps waiting");
    assert.equal(t.got("driver2", "call:ringing").length, 1);
    const moved = t.got("driver3", "call:queued").pop();
    assert.equal(moved?.payload.position, 1, "#2 moved up to #1");
    await t.svc.accept(w1.callId, staff(1));
    await wait(5);
    await t.svc.hangup(w1.callId, staff(1).id);
    assert.equal(t.ended.find((s) => s.id === w1.callId)!.queuedSec >= 0, true);
    assert.notEqual(t.ended.find((s) => s.id === w1.callId)!.waitSec, null);
  });

  await test("dispatcher comes online → waiting call rings them", async () => {
    const t = setup([staff(1)]);
    const a = await dispatchCall(t, drv(1));
    assert(a.ok); await t.svc.accept(a.callId, staff(1));
    const w = await dispatchCall(t, drv(2));
    assert(w.ok && w.queued);
    t.state.online = [staff(1), staff(2)];
    t.svc.onConnected("staff2");
    await t.svc.serveQueue();
    assert.equal(t.got("staff2", "call:incoming").filter((e) => e.payload.callId === w.callId).length, 1);
  });

  await test("waiting too long → missed (queue_timeout); caller can leave the line", async () => {
    const t = setup([staff(1)]);
    const a = await dispatchCall(t, drv(1));
    assert(a.ok); await t.svc.accept(a.callId, staff(1));
    const w = await dispatchCall(t, drv(2));
    const w2 = await dispatchCall(t, drv(3));
    assert(w.ok && w2.ok);
    await t.svc.hangup(w2.callId, drv(3).id);
    assert.equal(t.ended.find((s) => s.id === w2.callId)?.status, "cancelled");
    await wait(200);
    const timedOut = t.ended.find((s) => s.id === w.callId);
    assert.equal(timedOut?.status, "missed");
    assert.equal(timedOut?.reason, "queue_timeout");
    assert(timedOut!.queuedSec >= 0);
  });

  await test("no dispatcher online → unavailable, logged as missed", async () => {
    const t = setup([]);
    const r = await dispatchCall(t, driver);
    assert(!r.ok && r.error === "unavailable");
    assert.equal(t.ended[0].reason, "no_dispatcher_online");
  });

  await test("ring group outcome per dispatcher: one declines, others miss", async () => {
    const t = setup();
    const r = await dispatchCall(t, driver);
    assert(r.ok);
    await t.svc.decline(r.callId, "staff1");
    await wait(90);
    const s = t.ended[0];
    assert.equal(s.status, "missed");
    const byId = Object.fromEntries(s.invited.map((i) => [i.person.id, i.state]));
    assert.deepEqual(byId, { staff1: "declined", staff2: "missed", staff3: "missed" });
  });

  await test("a ringing dispatcher can be rung by two drivers at once", async () => {
    const t = setup([staff(1)]);
    const a = await dispatchCall(t, drv(1));
    const b = await dispatchCall(t, drv(2));
    assert(a.ok && a.ringing === 1 && b.ok && b.ringing === 1, "both ring the free dispatcher");
    await t.svc.accept(a.callId, staff(1));
    const late = await t.svc.accept(b.callId, staff(1));
    assert(!late.ok, "can't take a second call while on one");
  });

  await test("dispatcher ringing for 2 drivers answers one → the other goes back in line, first", async () => {
    const t = setup([staff(1)]);
    const a = await dispatchCall(t, drv(1));
    const b = await dispatchCall(t, drv(2));
    assert(a.ok && b.ok && b.ringing === 1);
    await t.svc.accept(a.callId, staff(1));
    assert.equal(t.got("staff1", "call:answered_elsewhere").filter((e) => e.payload.callId === b.callId).length, 1);
    assert.equal(t.svc.get(b.callId)?.phase, "queued");
    const c = await dispatchCall(t, drv(3));
    assert(c.ok && c.queued && c.position === 2, "a later caller queues behind driver 2");
    await t.svc.hangup(a.callId, staff(1).id);
    await t.svc.serveQueue();
    assert.equal(t.svc.get(b.callId)?.phase, "ringing", "driver 2 rings first");
    assert.equal(t.svc.get(c.callId)?.phase, "queued");
  });

  // ---------- connection ----------
  await test("network drop: reconnect within grace keeps the call", async () => {
    const t = setup();
    const r = await t.svc.invite({ ...base(), caller: staff(1), targets: [driver] });
    assert(r.ok);
    await t.svc.accept(r.callId, driver);
    t.svc.onDisconnected(driver.id);
    await wait(20);
    t.svc.onConnected(driver.id);
    await wait(80);
    assert.equal(t.ended.length, 0);
    assert.equal(t.got("staff1", "call:peer_reconnected").length, 1);
  });

  await test("network drop: no reconnect → completed/connection_lost; waiting caller then served", async () => {
    const t = setup([staff(1)]);
    const a = await dispatchCall(t, drv(1));
    assert(a.ok); await t.svc.accept(a.callId, staff(1));
    const w = await dispatchCall(t, drv(2));
    assert(w.ok && w.queued);
    t.svc.onDisconnected(drv(1).id);
    await wait(90);
    await t.svc.serveQueue();
    assert.equal(t.ended[0].reason, "connection_lost");
    assert.equal(t.got("staff1", "call:incoming").filter((e) => e.payload.callId === w.callId).length, 1);
  });

  await test("finish runs once (hang up racing the ring timeout)", async () => {
    const t = setup();
    const r = await t.svc.invite({ ...base(), caller: staff(1), targets: [driver] });
    assert(r.ok);
    await Promise.all([t.svc.hangup(r.callId, "staff1"), t.svc.finish(r.callId, "missed", "x")]);
    await wait(90);
    assert.equal(t.ended.length, 1);
  });

  console.log(results.join("\n"));
  process.exit(results.some((r) => r.startsWith("FAIL")) ? 1 : 0);
})();
