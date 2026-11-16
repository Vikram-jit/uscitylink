// Run: npx ts-node -T scripts/trips/format.check.ts
// The one load pattern (tripMessages.formatLoad / LOAD_TEMPLATE) and the reader that understands it
// (parseLoad): exact text for each case, PENDING for places and dates not confirmed, nothing duplicated
// when there is one address, and format → parse gives the same load back. No database.
import assert from "assert";
import fs from "fs";
import path from "path";
import { formatLoad, LOAD_TEMPLATE } from "../../src/services/trips/tripMessages";
import { looksLikeLoad, parseLoad } from "../../src/services/trips/parseLoad";

const results: string[] = [];
const test = (name: string, fn: () => void) => {
  try {
    fn();
    results.push(`ok   ${name}`);
  } catch (e: any) {
    results.push(`FAIL ${name}: ${e.message}`);
  }
};

const trip = (o: any = {}): any => ({ trip_no: "0056000", invoice_no: "0056000", truck_number: null, trailer_numbers: null, temperature: null, loaded_trailer: false, notes: null, ...o });
const stop = (seq: number, type: string, o: any = {}): any => ({ seq, type, name: null, street: null, city: null, state: null, zip: null, appointment_local: null, ref: null, ...o });
const FRESH = { name: "FreshPoint Atlanta", street: "1200 Oakley Industrial Blvd B", city: "FAIRBURN", state: "GA", zip: "30213" };
const ECHO = { name: "Echo Cold", street: "9 Dock Rd", city: "Fresno", state: "CA", zip: "93701" };

test("full load: header lines, pickup and drop with their dates", () => {
  const text = formatLoad(
    trip({ truck_number: "35865", trailer_numbers: "107065", temperature: "34 CONT." }),
    [stop(1, "pickup", { ...ECHO, appointment_local: "2026-11-15T07:00" }), stop(2, "drop", { ...FRESH, appointment_local: "2026-11-16T06:00" })],
    ["ABBY", "AMIT"]
  );
  assert.equal(
    text,
    [
      "LOAD # 0056000", "", "TRUCK # 35865", "", "TEAM # ABBY + AMIT", "", "TRAILER # 107065", "", "TEMP # 34 CONT.",
      "", "PICKUP", "Echo Cold", "9 Dock Rd", "Fresno, CA 93701", "11/15/2026 07:00AM",
      "", "DROP", "FreshPoint Atlanta", "1200 Oakley Industrial Blvd B", "FAIRBURN, GA 30213", "11/16/2026 06:00AM",
    ].join("\n")
  );
});

test("one address with no pickup: no PICKUP section is sent to the driver (and the address is not written twice)", () => {
  const withDate = formatLoad(trip(), [stop(1, "drop", { ...FRESH, appointment_local: "2026-11-16T06:00" })]);
  assert.equal(withDate, ["LOAD # 0056000", "", "DROP", "FreshPoint Atlanta", "1200 Oakley Industrial Blvd B", "FAIRBURN, GA 30213", "11/16/2026 06:00AM"].join("\n"));
  assert(!withDate.includes("PICKUP"), "a pending pickup is not sent");
  assert.equal((withDate.match(/FreshPoint/g) || []).length, 1, "the address appears once");
  const noDate = formatLoad(trip(), [stop(1, "drop", FRESH)]);
  assert(noDate.endsWith("FAIRBURN, GA 30213\nDATE PENDING"), noDate);
});

test("nothing known yet (a plan): only the header; only the pickup known: no DROP section; a pending stop with nothing on it is left out", () => {
  assert.equal(formatLoad(trip(), []), "LOAD # 0056000");
  assert.equal(formatLoad(trip({ truck_number: "35865" }), [stop(1, "pickup"), stop(2, "drop")]), "LOAD # 0056000\n\nTRUCK # 35865", "stops with no address and no date are pending → not sent");
  const pickOnly = formatLoad(trip(), [stop(1, "pickup", ECHO)]);
  assert(pickOnly.includes("PICKUP\nEcho Cold") && pickOnly.endsWith("Fresno, CA 93701\nDATE PENDING") && !pickOnly.includes("DROP"), pickOnly);
  const dropPending = formatLoad(trip(), [stop(1, "pickup", { ...ECHO, appointment_local: "2026-11-15T07:00" }), stop(2, "drop")]);
  assert(!dropPending.includes("DROP") && !dropPending.includes("PENDING"), dropPending);
});

test("a place not confirmed but a date known: PENDING then the date; a loaded trailer needs no pickup", () => {
  const t = formatLoad(trip(), [stop(1, "drop", { appointment_local: "2026-11-16T06:00" })]);
  assert(t.endsWith("DROP\nPENDING\n11/16/2026 06:00AM"), t);
  const loaded = formatLoad(trip({ loaded_trailer: true }), [stop(1, "drop", FRESH)]);
  assert(!loaded.includes("PICKUP") && loaded.includes("LOADED TRAILER"), loaded);
});

test("several drops are numbered; a switch and the yard keep their headings; notes come last", () => {
  const t = formatLoad(trip({ notes: "YOUR LONG FOR TOMORROW MORNING." }), [stop(1, "pickup", ECHO), stop(2, "drop", FRESH), stop(3, "drop", { ...ECHO, name: "Second" }), stop(4, "yard", { city: "Fontana", state: "CA" })]);
  assert(t.includes("DROP # 1\nFreshPoint Atlanta") && t.includes("DROP # 2\nSecond") && t.includes("DROP AT YARD\nFontana, CA"), t);
  assert(t.endsWith("\n\nYOUR LONG FOR TOMORROW MORNING."), t);
});

test("the reader understands the pattern: format → parse gives the same load (no phantom stops for PENDING)", () => {
  for (const stops of [
    [stop(1, "pickup", { ...ECHO, appointment_local: "2026-11-15T07:00" }), stop(2, "drop", { ...FRESH, appointment_local: "2026-11-16T06:00" })],
    [stop(1, "drop", FRESH)],
    [stop(1, "pickup", ECHO)],
    [],
  ]) {
    const text = formatLoad(trip({ truck_number: "35865", temperature: "34", trailer_numbers: "107065" }), stops, stops.length ? ["ABBY", "AMIT"] : []);
    const back = parseLoad(text, { plan: true })!;
    assert(back, text);
    assert.equal(back.loadNo, "0056000");
    assert.equal(back.truck, "35865");
    assert.deepEqual(back.trailers, ["107065"]);
    assert.equal(back.temperature, "34");
    assert.deepEqual(back.stops.map((s) => `${s.type}:${s.city}`), stops.map((s: any) => `${s.type}:${s.city}`), text);
    assert.equal(back.notes, null, `nothing left over in ${text}`);
  }
});

test("pending in what dispatch types: PENDING under a heading is no stop; PENDING + a date keeps the date; DATE PENDING is understood", () => {
  const a = parseLoad("LOAD # 7\nPICKUP\nPENDING\n\nDROP\nFreshPoint Atlanta\n1200 Oakley Industrial Blvd B\nFAIRBURN, GA 30213\nDATE PENDING")!;
  assert.deepEqual(a.stops.map((s) => s.type), ["drop"]);
  assert.equal(a.stops[0].appointment, null);
  assert.equal(a.notes, null);
  const b = parseLoad("LOAD # 7\nPICKUP\nTBD\n11/15/2026 07:00AM\n\nDROP\nFreshPoint Atlanta\n1200 Oakley Industrial Blvd B\nFAIRBURN, GA 30213")!;
  assert.deepEqual(b.stops.map((s) => `${s.type}:${s.city || "-"}:${s.appointment || "-"}`), ["pickup:-:2026-11-15T07:00", "drop:FAIRBURN:-"]);
  assert.equal(b.needsReview, false, "pending is normal, not something to check");
});

test("everything else dispatch wrote is kept as notes: the FreshPoint message", () => {
  const l = parseLoad("YOUR LONG FOR TOMORROW MORNING.\n\nTRUCK # 35865\n\nTEAM # ABBY + AMIT\n\nTRAILER # 107065\n\nTEMP # 34 CONT.\n\nORDER # 0056000\n\nFreshPoint Atlanta\n1200 Oakley Industrial Blvd B\nFAIRBURN, GA 30213\n11/16/2026 06:00AM")!;
  assert.equal(l.notes, "YOUR LONG FOR TOMORROW MORNING.");
  assert.deepEqual(l.stops.map((s) => s.type), ["drop"]);
  const text = formatLoad(trip({ truck_number: l.truck, trailer_numbers: l.trailers.join(", "), temperature: l.temperature, notes: l.notes }), [stop(1, "drop", { ...FRESH, appointment_local: l.stops[0].appointment })], l.team);
  assert(text.endsWith("11/16/2026 06:00AM\n\nYOUR LONG FOR TOMORROW MORNING."), text);
});

test("the blank template: not a load until it has a Load #; with one it is a plan (both pending)", () => {
  assert.equal(looksLikeLoad(LOAD_TEMPLATE), false);
  const filled = LOAD_TEMPLATE.replace("LOAD #", "LOAD # 5501");
  assert.equal(looksLikeLoad(filled), true, "a Load # and PICKUP / DROP headings");
  const plan = parseLoad(filled)!;
  assert.equal(plan.loadNo, "5501");
  assert.deepEqual(plan.stops, []);
  assert.equal(plan.notes, null, "the empty TRUCK # / TEAM # lines and the PENDING words are not notes");
  // filling in a drop on the template
  const drop = filled.replace("DROP\nPENDING", "DROP\nFreshPoint Atlanta\n1200 Oakley Industrial Blvd B\nFAIRBURN, GA 30213\n11/16/2026 06:00AM");
  const l = parseLoad(drop)!;
  assert.deepEqual(l.stops.map((s) => s.type), ["drop"]);
  assert.equal(l.stops[0].appointment, "2026-11-16T06:00");
});

test("the template is the same text on the server, the web and the app", () => {
  const root = path.resolve(__dirname, "../../..");
  const web = fs.readFileSync(path.join(root, "web/src/components/dashboard/trips/loadFormat.ts"), "utf8");
  const app = fs.readFileSync(path.join(root, "uscitylink/lib/utils/load_format.dart"), "utf8");
  // web: ['LOAD #', '', ...].join('\n')   app: 'LOAD #\n\nTRUCK #...'
  const webLines = [...(/LOAD_TEMPLATE = \[([^\]]*)\]/.exec(web)?.[1] || "").matchAll(/'([^']*)'/g)].map((m) => m[1]);
  const appText = /kLoadTemplate = '([^']*)'/.exec(app)?.[1] || "";
  assert(webLines.length > 5, "found the web template");
  assert(appText.length > 20, "found the app template");
  assert.equal(webLines.join("\n"), LOAD_TEMPLATE, "web template differs from the server's");
  assert.equal(appText.replace(/\\n/g, "\n"), LOAD_TEMPLATE, "app template differs from the server's");
});

console.log(results.join("\n"));
process.exit(results.some((r) => r.startsWith("FAIL")) ? 1 : 0);
