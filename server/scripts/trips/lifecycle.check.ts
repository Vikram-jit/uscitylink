// Run: npx ts-node -T scripts/trips/lifecycle.check.ts
// The trip lifecycle rules (src/services/trips/lifecycle.ts): every allowed move, and that everything
// else is refused.
import assert from "assert";
import { check, nextStep, RULES, StopProgress, TripAction, TripStatus } from "../../src/services/trips/lifecycle";
import { clearStatus, ruleIntent, SMALL_TALK } from "../../src/services/trips/intents";

const results: string[] = [];
const test = (name: string, fn: () => void) => {
  try {
    fn();
    results.push(`ok   ${name}`);
  } catch (e: any) {
    results.push(`FAIL ${name}: ${e.message}`);
  }
};
const to = (action: TripAction, status: TripStatus, role: any = "dispatcher", opts = {}) => {
  const r = check(action, status, role, opts);
  return r.ok ? r.to : `refused: ${r.error}`;
};
const ALL: TripStatus[] = [
  "scheduled", "offered", "planned", "accepted", "started", "rolling", "ended", "paperwork", "completed", "routed", "on_hold", "cancelled",
];

test("the happy path, driver taps + dispatch completes", () => {
  assert.equal(to("offer", "scheduled", "system"), "offered");
  assert.equal(to("send", "offered"), "planned");
  assert.equal(to("accept", "planned", "driver"), "accepted");
  assert.equal(to("start", "accepted", "driver"), "started");
  assert.equal(to("arrive", "started", "driver"), "started");
  assert.equal(to("rolling", "started", "driver"), "rolling");
  assert.equal(to("arrive", "rolling", "driver"), "rolling");
  assert.equal(to("depart", "rolling", "driver"), "rolling");
  assert.equal(to("end", "rolling", "driver"), "ended");
  assert.equal(to("paperwork", "ended", "ai"), "paperwork");
  assert.equal(to("complete", "paperwork"), "completed");
  assert.equal(to("route", "completed", "accountant"), "routed");
});

test("dispatch can send a scheduled load directly, and start without accept", () => {
  assert.equal(to("send", "scheduled"), "planned");
  assert.equal(to("start", "planned", "driver"), "started");
});

test("only dispatch sends loads, completes and cancels", () => {
  for (const a of ["send", "complete", "cancel", "decline_offer", "resume"] as TripAction[]) {
    for (const role of ["driver", "ai", "accountant"]) {
      const from = RULES[a].from[0];
      assert.match(String(to(a, from, role, { note: "x", statusBeforeHold: "rolling" })), /refused/, `${role} ${a}`);
    }
  }
});

test("the AI never moves a trip on the road (it only suggests)", () => {
  for (const a of ["start", "rolling", "arrive", "depart", "end", "accept"] as TripAction[]) {
    assert.match(String(to(a, RULES[a].from[0], "ai")), /refused/, a);
  }
});

test("every move not in the table is refused", () => {
  for (const [action, rule] of Object.entries(RULES) as [TripAction, (typeof RULES)[TripAction]][]) {
    for (const status of ALL) {
      if (rule.from.includes(status)) continue;
      const r = check(action, status, rule.who[0], { note: "x", statusBeforeHold: "rolling" });
      assert.equal(r.ok, false, `${action} from ${status}`);
    }
  }
});

test("hold and resume go back where the trip was", () => {
  assert.equal(to("hold", "rolling"), "on_hold");
  assert.equal(to("resume", "on_hold", "dispatcher", { statusBeforeHold: "rolling" }), "rolling");
  assert.match(String(to("resume", "on_hold", "dispatcher", {})), /Nothing to resume/);
  assert.match(String(to("hold", "completed")), /refused/);
});

test("cancel needs a reason and is impossible once completed", () => {
  assert.match(String(to("cancel", "planned")), /why/);
  assert.equal(to("cancel", "planned", "dispatcher", { note: "Shipper closed" }), "cancelled");
  assert.match(String(to("cancel", "completed", "dispatcher", { note: "x" })), /refused/);
});

test("the driver has three buttons: Got it → Rolling → Delivered", () => {
  const stops: StopProgress[] = [
    { id: 1, seq: 1, type: "pickup", name: "COLD LINK", arrived_at: null, departed_at: null },
    { id: 3, seq: 3, type: "drop", name: "BI RITE", arrived_at: null, departed_at: null },
  ];
  assert.deepEqual(nextStep("planned", stops), { action: "accept", label: "Got it" });
  assert.deepEqual(nextStep("accepted", stops), { action: "rolling", label: "Loaded — rolling" });
  assert.deepEqual(nextStep("rolling", stops), { action: "end", label: "Delivered — end trip", stopId: 3 });
  assert.equal(nextStep("ended", stops), null);
  // Rolling right after Got it (no separate Start)
  assert.equal(to("rolling", "accepted", "driver"), "rolling");
  assert.equal(to("rolling", "planned", "driver"), "rolling");
});

test("what drivers write → trip intent", () => {
  const cases: [string, string][] = [
    ["any next load?", "next_load"],
    ["agla load kithe hai", "next_load"],
    ["what's next", "next_load"],
    ["arrived at shipper", "arrive"],
    ["pahunch gya", "arrive"],
    ["loaded, leaving now", "rolling"],
    ["chal pya", "rolling"],
    ["unloaded", "end"],
    ["delivered, im empty", "end"],
    ["flat tire on I-10", "problem"],
    ["lumper charged 150", "problem"],
    ["how are you", "none"],
  ];
  for (const [text, want] of cases) assert.equal(ruleIntent(text), want, text);
  assert(SMALL_TALK.test("ok") && SMALL_TALK.test("thanks!") && !SMALL_TALK.test("ok loaded"));
});

test("plain status lines move the load by themselves; unclear ones don't", () => {
  const yes: [string, string][] = [
    ["rolling", "rolling"], ["rolling ", "rolling"], ["Loaded", "rolling"], ["loaded rolling", "rolling"], ["picked up", "rolling"],
    ["pickup done", "rolling"], ["left", "rolling"], ["left shipper", "rolling"], ["on my way", "rolling"], ["omw", "rolling"],
    ["en route", "rolling"], ["chal pye", "rolling"], ["nikal gya", "rolling"], ["arrived at shipper, loaded now", "rolling"],
    ["arrived", "arrive"], ["arrived ", "arrive"], ["reached", "arrive"], ["at receiver", "arrive"], ["checked in", "arrive"],
    ["check in done", "arrive"], ["here now", "arrive"], ["pahunch gya", "arrive"], ["aa gya", "arrive"], ["in door", "arrive"],
    ["delivered", "end"], ["unloaded", "end"], ["empty now", "end"], ["unloading done", "end"], ["khali ho gya", "end"], ["delivery done", "end"],
  ];
  for (const [text, want] of yes) assert.equal(clearStatus(text), want, text);
  const no = [
    "not loaded yet", "when will i be loaded?", "rolling?", "will leave at 5", "waiting to get loaded", "still not arrived",
    "arrive by 6", "should i leave", "abhi nahi hua", "I left my phone at the shipper and need to go back for it right now please",
    "ok", "how are you", "lumper charged 150",
  ];
  for (const text of no) assert.equal(clearStatus(text), "none", text);
});

console.log(results.join("\n"));
process.exit(results.some((r) => r.startsWith("FAIL")) ? 1 : 0);
