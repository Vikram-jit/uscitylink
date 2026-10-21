// Regression check for the scale agent engine (client spec §7 examples and §9 test cases).
// Run: npx ts-node --transpile-only scripts/scale-agent-cases.ts
import { Equipment, evaluateScaleTicket } from "../src/services/scaleAgent/evaluate";
import { buildDriverMessage } from "../src/services/scaleAgent/messages";
import { resolveLimits, RuleRow } from "../src/services/scaleAgent/rules";
import { comparePrediction } from "../src/services/scaleAgent/prediction";

const reviewed = new Date();
const rule = (jurisdiction: string, extra: Partial<RuleRow> = {}): RuleRow => ({
  id: jurisdiction,
  jurisdiction,
  road_class: "interstate",
  version: 1,
  single_axle_lb: 20000,
  tandem_lb: 34000,
  gross_lb: 80000,
  steer_target_lb: 12000,
  sum_tolerance_lb: 100,
  min_confidence: 0.8,
  kpra_max_ft: null,
  bridge_formula: true,
  reviewed_at: reviewed,
  review_months: 12,
  ...extra,
});
const RULES = [rule("FED"), rule("CA", { kpra_max_ft: 40 })];
const UNREVIEWED = [rule("FED", { reviewed_at: null }), rule("CA", { kpra_max_ft: 40 })];
const CA_TRIP = { segments: [{ state: "CA", road_class: "interstate" }], permits: [] };

// Typical 5-axle tractor-semitrailer, 53 ft trailer with tandems at 40 ft KPRA
const TRACTOR = { steer_to_drive_center_ft: 18, drive_spread_ft: 4.33, kingpin_to_drive_center_ft: 1 };
const TRAILER = { kpra_ft: 40, trailer_spread_ft: 4.08, axle_count: 2, hole_spacing_in: 6, holes_forward_available: 8, holes_back_available: 8 };
const EQ: Equipment = { tractor: TRACTOR, trailer: TRAILER };
const EQ_K: Equipment = { tractor: TRACTOR, trailer: { ...TRAILER, lb_per_hole: 250 } };

const W = (steer: any, drive: any, trailer: any, gross: any) => ({ steer, drive, trailer, gross });
const ok = { confidence: 0.95, quality: "good" };

type Case = {
  name: string;
  weights: ReturnType<typeof W>;
  rules?: RuleRow[];
  trip?: any;
  equipment?: Equipment | null;
  read?: any;
  status: string;
  actions?: string[];
  flags?: string[];
  check?: (r: ReturnType<typeof evaluateScaleTicket>) => string | null;
};

const cases: Case[] = [
  // Phase 1 behaviour with a verified CA route and full equipment
  { name: "Client ticket 11,740/31,880/33,980/77,600 on a verified CA route", weights: W(11740, 31880, 33980, 77600), trip: CA_TRIP, equipment: EQ, status: "PASS_PRELIMINARY" },
  { name: "Spec A: drives 35,000 → tandems forward", weights: W(12200, 35000, 32000, 79200), trip: CA_TRIP, equipment: EQ, status: "ADJUST_AND_REWEIGH", actions: ["tandems_forward"] },
  { name: "Spec B: trailer 35,000 → tandems backward (blocked: KPRA already at 40 ft)", weights: W(12000, 33000, 35000, 80000), trip: CA_TRIP, equipment: EQ_K, status: "ADJUST_AND_REWEIGH", actions: ["rework_cargo"], flags: ["NO_FEASIBLE_SLIDE"] },
  { name: "Spec B without KPRA rule (FED only) → tandems backward", weights: W(12000, 33000, 35000, 80000), trip: { segments: [{ state: "AZ", road_class: "interstate" }] }, rules: [rule("FED"), rule("AZ")], equipment: EQ, status: "ADJUST_AND_REWEIGH", actions: ["tandems_backward"] },
  { name: "Spec C: gross 81,000 → no slide fix", weights: W(12000, 34500, 34500, 81000), trip: CA_TRIP, equipment: EQ, status: "OVER_GROSS", actions: ["rework_cargo"] },
  // §9 test cases
  { name: "OCR transposition (33,980 read as 38,980)", weights: W(11740, 31880, 38980, 77600), status: "OCR_UNCERTAIN" },
  { name: "Weights not summing / missing drive", weights: W(11740, null, 33980, 77600), status: "OCR_UNCERTAIN" },
  { name: "Steer rating below 12,000 (rated 11,500)", weights: W(11740, 31880, 33980, 77600), trip: CA_TRIP, equipment: { tractor: { ...TRACTOR, steer_rating_lb: 11500 }, trailer: TRAILER }, status: "ADJUST_AND_REWEIGH", flags: ["EQUIPMENT_LIMIT"], actions: ["fifth_wheel_back"] },
  { name: "Gross over 80,000", weights: W(12000, 34000, 34200, 80200), trip: CA_TRIP, equipment: EQ, status: "OVER_GROSS" },
  { name: "Drive over, steer has room", weights: W(11000, 34600, 33600, 79200), trip: CA_TRIP, equipment: EQ, status: "ADJUST_AND_REWEIGH", actions: ["fifth_wheel_forward"] },
  { name: "Both tandems over", weights: W(11000, 34200, 34300, 79500), trip: CA_TRIP, equipment: EQ, status: "ADJUST_AND_REWEIGH", actions: ["rework_cargo"] },
  { name: "KPRA exactly at the 40 ft boundary → passes", weights: W(11740, 31880, 33980, 77600), trip: CA_TRIP, equipment: EQ, status: "PASS_PRELIMINARY" },
  { name: "KPRA 40.5 ft in CA → slide forward 1 hole", weights: W(11740, 31880, 33980, 77600), trip: CA_TRIP, equipment: { tractor: TRACTOR, trailer: { ...TRAILER, kpra_ft: 40.5 } }, status: "ADJUST_AND_REWEIGH", flags: ["KPRA_VIOLATION"], check: (r) => (r.adjustments.find((a) => a.reason === "kpra")?.holes === 1 ? null : "expected 1 hole for KPRA") },
  { name: "Unknown lb-per-hole → direction only, no hole count", weights: W(12200, 35000, 32000, 79200), trip: CA_TRIP, equipment: EQ, status: "ADJUST_AND_REWEIGH", check: (r) => (r.adjustments.every((a) => a.holes == null) ? null : "hole count invented") },
  { name: "Measured 250 lb/hole, drives 1,000 over → about 4 holes", weights: W(11000, 35000, 32000, 78000), trip: CA_TRIP, equipment: EQ_K, status: "ADJUST_AND_REWEIGH", check: (r) => (r.adjustments.find((a) => a.action === "tandems_forward")?.holes === 4 ? null : "expected 4 holes") },
  { name: "Bridge failure despite legal CAT groups (short wheelbase + 30 ft KPRA)", weights: W(12000, 34000, 34000, 80000), trip: { segments: [{ state: "AZ", road_class: "interstate" }] }, rules: [rule("FED"), rule("AZ")], equipment: { tractor: { steer_to_drive_center_ft: 13, drive_spread_ft: 4.33, kingpin_to_drive_center_ft: 0 }, trailer: { ...TRAILER, kpra_ft: 30 } }, status: "ADJUST_AND_REWEIGH", flags: ["BRIDGE_VIOLATION", "NO_FEASIBLE_SLIDE"] },
  { name: "Interstate → local road with no CA local rules on file", weights: W(11740, 31880, 33980, 77600), trip: { segments: [{ state: "CA", road_class: "interstate" }, { state: "CA", road_class: "local" }] }, equipment: EQ, status: "ROUTE_REVIEW_REQUIRED" },
  { name: "Valid CA permit (gross 84,000 / tandem 35,000) covers 82,000", weights: W(12000, 35000, 35000, 82000), trip: { ...CA_TRIP, permits: [{ state: "CA", number: "P-1", expires_at: "2099-01-01", gross_lb: 84000, tandem_lb: 35000 }] }, equipment: EQ, status: "PASS_PRELIMINARY" },
  { name: "Same permit expired → over gross", weights: W(12000, 35000, 35000, 82000), trip: { ...CA_TRIP, permits: [{ state: "CA", number: "P-1", expires_at: "2020-01-01", gross_lb: 84000, tandem_lb: 35000 }] }, equipment: EQ, status: "OVER_GROSS" },
  { name: "Route not entered → route review", weights: W(11740, 31880, 33980, 77600), equipment: EQ, status: "ROUTE_REVIEW_REQUIRED" },
  { name: "Rules not reviewed → route review", weights: W(11740, 31880, 33980, 77600), rules: UNREVIEWED, trip: CA_TRIP, equipment: EQ, status: "ROUTE_REVIEW_REQUIRED" },
  { name: "No axle spacing on file → bridge review", weights: W(11740, 31880, 33980, 77600), trip: CA_TRIP, equipment: null, status: "BRIDGE_REVIEW" },
  { name: "Low confidence read", weights: W(11740, 31880, 33980, 77600), read: { confidence: 0.55 }, status: "OCR_UNCERTAIN" },
];

let fails = 0;
for (const c of cases) {
  const limits = resolveLimits(c.rules || RULES, c.trip || null);
  const r = evaluateScaleTicket(c.weights as any, limits, { ...ok, ...(c.read || {}) }, c.equipment === undefined ? null : c.equipment);
  const got = r.adjustments.map((a) => a.action);
  const problems: string[] = [];
  if (r.status !== c.status) problems.push(`status ${r.status}, expected ${c.status}`);
  (c.actions || []).forEach((a) => !got.includes(a as any) && problems.push(`missing move ${a}`));
  (c.flags || []).forEach((f) => !r.flags.includes(f) && problems.push(`missing flag ${f}`));
  const extra = c.check?.(r);
  if (extra) problems.push(extra);
  const msg = buildDriverMessage(r, c.weights as any, limits);
  if (/good to go|\blegal\b/i.test(msg)) problems.push("message contains forbidden wording");
  if (problems.length) fails++;
  console.log(`${problems.length ? "FAIL" : "PASS"}  ${c.name}\n      -> ${r.status} [${got.join(", ") || "no moves"}]${problems.length ? `  !! ${problems.join("; ")}` : ""}`);
}

// Reweigh feedback
const p1 = comparePrediction({ trailer: 32000 }, { trailer: 31800 }, { action: "tandems_forward", holes: 4 }, 250);
const p2 = comparePrediction({ trailer: 32000 }, { trailer: 33000 }, { action: "tandems_forward", holes: 4 }, null);
const predictionOk = p1.mismatch && p1.direction_ok === false && !p2.mismatch && p2.learned_lb_per_hole === 250;
if (!predictionOk) fails++;
console.log(`${predictionOk ? "PASS" : "FAIL"}  New reweigh contradicts prediction (trailer fell after tandems forward) + learns 250 lb/hole\n      -> ${p1.note} | learned ${p2.learned_lb_per_hole}`);

const total = cases.length + 1;
console.log(`\n${total - fails}/${total} cases pass`);
process.exit(fails ? 1 : 0);
