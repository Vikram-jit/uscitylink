// Run: npx ts-node -T scripts/trips/hosPlan.check.ts
// Trip ETAs with US hours-of-service and the company's fuel stops (src/services/trips/hosPlan.ts).
import assert from "assert";
import { elapsedAt, planTrip, truckDriving } from "../../src/services/trips/hosPlan";

const results: string[] = [];
const test = (name: string, fn: () => void) => {
  try {
    fn();
    results.push(`ok   ${name}`);
  } catch (e: any) {
    results.push(`FAIL ${name}: ${e.message}`);
  }
};
const kinds = (p: ReturnType<typeof planTrip>) => p.stops.map((s) => `${s.kind}@${Math.round(s.afterDrivingMinutes / 60)}h`).join(" ");

test("short run: no stops", () => {
  const p = planTrip(300, 5 * 60, false);
  assert.equal(p.stops.length, 0);
  assert.equal(p.totalMinutes, 300);
});

test("9 hours driving: one 30-minute break after 8 hours", () => {
  const p = planTrip(540, 9 * 60, false);
  assert.equal(kinds(p), "break@8h");
  assert.equal(p.totalMinutes, 9 * 60 + 30);
});

test("a fuel stop counts as the 30-minute break", () => {
  // 70 mph average: 1,000 miles is reached at about 14.3 h — but at 60 mph it's at 16.7 h; use 125 mph to put fuel at 8 h
  const p = planTrip(1100, 8.8 * 60, false);
  assert.equal(p.stops.filter((s) => s.kind === "break").length, 0, kinds(p));
  assert.equal(p.stops[0].kind, "fuel");
});

test("30 hours driving, solo: breaks, 10-hour rests, fuel every 1,000 miles", () => {
  const p = planTrip(1800, 30 * 60, false);
  // Day 1: drive 8 → break → drive 3 → rest (11 h driving). Day 2 same. Day 3: 8 h, fuel at mile 1000 (16.7 h driven) etc.
  assert(p.stops.some((s) => s.kind === "rest"), kinds(p));
  assert.equal(p.stops.filter((s) => s.kind === "fuel").length, 1, "one fuel stop at mile 1,000 (1,800 mi)");
  // Never more than 11 h driving between rests, never more than 8 h without a 30-min stop
  let sinceRest = 0;
  let sinceBreak = 0;
  let last = 0;
  for (const s of p.stops) {
    const drove = s.afterDrivingMinutes - last;
    sinceRest += drove;
    sinceBreak += drove;
    assert(sinceRest <= 11 * 60 + 1, `drove ${sinceRest} min without rest`);
    assert(sinceBreak <= 8 * 60 + 1, `drove ${sinceBreak} min without a break`);
    if (s.kind === "rest") sinceRest = 0;
    sinceBreak = 0;
    last = s.afterDrivingMinutes;
  }
  assert.equal(p.totalMinutes, 30 * 60 + p.breakMinutes + p.restMinutes + p.fuelMinutes);
  assert(p.restMinutes >= 2 * 600, "at least two 10-hour rests");
});

test("14-hour window: rest even before 11 hours of driving when stops ate the window", () => {
  // Slow trip with fuel stops: on-duty time hits 14 h first
  const p = planTrip(3000, 50 * 60, false);
  let onDuty = 0;
  let prev = 0;
  for (const s of p.stops) {
    onDuty += s.startsAfter - prev;
    assert(onDuty <= 14 * 60 + 1, `on duty ${onDuty} min before a rest`);
    onDuty = s.kind === "rest" ? 0 : onDuty + s.minutes;
    prev = s.startsAfter + s.minutes;
  }
});

test("team: only fuel stops, every 1,000 miles", () => {
  const p = planTrip(2300, 34 * 60, true);
  assert.deepEqual(p.stops.map((s) => s.kind), ["fuel", "fuel"]);
  assert.deepEqual(p.stops.map((s) => s.atMile), [1000, 2000]);
  assert.equal(p.totalMinutes, 34 * 60 + 120);
});

test("stop ETAs include only the stops before them", () => {
  const p = planTrip(540, 9 * 60, false); // break at 8 h
  assert.equal(elapsedAt(p, 4 * 60), 4 * 60);
  assert.equal(elapsedAt(p, 9 * 60), 9 * 60 + 30);
});

test("truck pace: never faster than 60 mph on average", () => {
  assert.equal(truckDriving(1200, 17 * 60), 20 * 60); // Google says 17 h; a truck needs 20
  assert.equal(truckDriving(100, 150), 150);
});

console.log(results.join("\n"));
process.exit(results.some((r) => r.startsWith("FAIL")) ? 1 : 0);
