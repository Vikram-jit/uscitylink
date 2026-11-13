// Run: npx ts-node -T scripts/trips/parseLoad.check.ts
// The load messages dispatchers really send (examples from dispatch, 2026-11) and what must be read
// from each. Add new formats here before changing the parser.
import assert from "assert";
import { looksLikeLoad, parseLoad, ParsedLoad, trailerOnly } from "../../src/services/trips/parseLoad";
import { localToDate } from "../../src/services/trips/stateTimezone";

const results: string[] = [];
const test = (name: string, fn: () => void) => {
  try {
    fn();
    results.push(`ok   ${name}`);
  } catch (e: any) {
    results.push(`FAIL ${name}: ${e.message}`);
  }
};
const must = (text: string): ParsedLoad => {
  const load = parseLoad(text);
  assert(load, "not read as a load");
  return load;
};
const stops = (l: ParsedLoad) => l.stops.map((s) => `${s.type}:${s.name}|${s.city},${s.state}|${s.appointment ?? "-"}`);

test("1. TEMP / PICK # / DROP # with one appointment", () => {
  const l = must(`TEMP # REFER BILLS

PICK #
COLD LINK - ELLISVILLE
609 DACETOWN RD
ELLISVILLE, MS 39437

DROP #
COSTCO - MIRA LOMA
11600 RIVERSIDE DR. B
MIRA LOMA, CA 91752
11/06/2026 03:15AM`);
  assert.deepEqual(stops(l), [
    "pickup:COLD LINK - ELLISVILLE|ELLISVILLE,MS|-",
    "drop:COSTCO - MIRA LOMA|MIRA LOMA,CA|2026-11-06T03:15",
  ]);
  assert.equal(l.stops[1].street, "11600 RIVERSIDE DR. B");
  assert.equal(l.stops[1].zip, "91752");
  assert.equal(l.temperature, "REFER BILLS");
  assert.equal(l.needsReview, false, l.reasons.join("; "));
});

test("2. Temperature words / Pickup# / Drop#", () => {
  const l = must(`Temperature refer on bills

Pickup#
BETHLEHEM PROCESSING
107 E STAR STREET
BETHLEHEM, GA 30620

Drop#
JLR WAREHOUSE
380 S PACIFIC HWY 99E
WOODBURN, OR 97071
11/10/2026 07:30AM`);
  assert.deepEqual(stops(l), [
    "pickup:BETHLEHEM PROCESSING|BETHLEHEM,GA|-",
    "drop:JLR WAREHOUSE|WOODBURN,OR|2026-11-10T07:30",
  ]);
  assert.equal(l.temperature, "refer on bills");
  assert.equal(l.needsReview, false, l.reasons.join("; "));
});

test("3. Long load with truck, team, trailer, temp and one unlabelled address = the drop (no flag)", () => {
  const l = must(`YOUR LONG LOAD FOR TOMORROW MORNING.

TRUCK # 23865

TEAM # JOGA SINGH + JAGTAR SINGH

TRAILER # 10265

TEMP # 34 CONT.

TARGET - LAKE CITY
309 NE TAMMY LANE
LAKE CITY, FL 32055
11/05/2026 02:00PM`);
  assert.equal(l.truck, "23865");
  assert.deepEqual(l.team, ["JOGA SINGH", "JAGTAR SINGH"]);
  assert.deepEqual(l.trailers, ["10265"]);
  assert.equal(l.temperature, "34 CONT.");
  assert.deepEqual(stops(l), ["drop:TARGET - LAKE CITY|LAKE CITY,FL|2026-11-05T14:00"]);
  assert.equal(l.needsReview, false, "one address with no PICK/DROP labels is simply the drop");
});

test("4. GO TO … switching, then deliver", () => {
  const l = must(`GO TO

Flying J Travel Center
1 Giant Crossing,
Jamestown, NM 87347

DO THE SWITCHING WITH DRIVER AND DELIVER.

TRAILER # 101665

TEMP # 34 CONT.

WCD Franklin Consolidation
4040 Scottsville Rd
Franklin, KY 42134
10/31/2026 12:15AM`);
  assert.deepEqual(stops(l), [
    "switch:Flying J Travel Center|Jamestown,NM|-",
    "drop:WCD Franklin Consolidation|Franklin,KY|2026-10-31T00:15",
  ]);
  assert.equal(l.stops[0].street, "1 Giant Crossing");
  assert.deepEqual(l.trailers, ["101665"]);
});

test("5. Loaded trailer with two deliveries", () => {
  const l = must(`Loaded trailer

ALBERTVILLE PROCESSING
700 MCDONALD AVE
ALBERTVILLE, AL 35950


CARGILL - MANTECA
730 SPRECKELS AVE
MANTECA, CA 95336
11/01/2026 08:00AM

CARGILL - HAYWARD
1693 SABRE ST
HAYWARD, CA 94545
11/02/2026 10:00AM`);
  assert.equal(l.loadedTrailer, true);
  assert.deepEqual(stops(l), [
    "pickup:ALBERTVILLE PROCESSING|ALBERTVILLE,AL|-",
    "drop:CARGILL - MANTECA|MANTECA,CA|2026-11-01T08:00",
    "drop:CARGILL - HAYWARD|HAYWARD,CA|2026-11-02T10:00",
  ]);
  assert.equal(l.needsReview, false, l.reasons.join("; "));
});

test("6. Next long load, loaded trailer in the heading", () => {
  const l = must(`Your next long load for tomorrow Loaded Trailer

MOULTRIE PROCESSING
700 HWY 133 SOUTH
MOULTRIE, GA 31788


WINCO - WOODBURN
400 SOUTH WOODLAND AVE
WOODBURN, OR 97071
10/30/2026 05:00AM`);
  assert.equal(l.loadedTrailer, true);
  assert.deepEqual(stops(l), [
    "pickup:MOULTRIE PROCESSING|MOULTRIE,GA|-",
    "drop:WINCO - WOODBURN|WOODBURN,OR|2026-10-30T05:00",
  ]);
});

test("7. PICKUP with time, DROP# 1 and DROP# 2", () => {
  const l = must(`TEMP #REFFER BILLS

PICKUP
DECATUR COLD STORAGE
110 PLUGS DRIVE
DECATUR, AL 35601
10/19/2026 09:00AM

DROP# 1
SYSCO - FREMONT - P050
5900 STEWART AVE
FREMONT, CA 94538
10/23/2026 09:00AM

DROP# 2
BI RITE - BRISBANE
123 S HILL DR
BRISBANE, CA 94005
10/23/2026 01:00PM`);
  assert.equal(l.temperature, "REFFER BILLS");
  assert.deepEqual(stops(l), [
    "pickup:DECATUR COLD STORAGE|DECATUR,AL|2026-10-19T09:00",
    "drop:SYSCO - FREMONT - P050|FREMONT,CA|2026-10-23T09:00",
    "drop:BI RITE - BRISBANE|BRISBANE,CA|2026-10-23T13:00",
  ]);
  assert.equal(l.needsReview, false, l.reasons.join("; "));
});

test("ordinary chat lines are not loads", () => {
  assert.equal(looksLikeLoad("ok thanks, on my way"), false);
  assert.equal(parseLoad("Fuel at Loves\n123 MAIN ST\nRENO, NV 89501"), null);
  assert.equal(parseLoad("TEAM FOODS is closed today"), null);
  assert.equal(parseLoad(""), null);
});

test("any message with an address and a pickup / delivery / drop word is a load (needs its Load #)", () => {
  const waco =
    "AFTER GETTING EMPTY, GO TO WACO, TX AND PICKUP EMPTY TRAILER# 13065 AND DROP IT TO NEARBY THERMO KING. \n\nADDRESS FOR WACO, TX\n\nWACO PROCESSING\n301 AVIATION PARKWAY\nWACO, TX 76705\n\n\nTRAILER# 13065\n\nTHERMO KING ADDRESS : \n\nConvoy Servicing - Thermo King of Temple\n575 Northpoint Dr, \nTemple, TX, 76501";
  assert.equal(looksLikeLoad(waco), true);
  // both addresses are read: Waco is the pickup, Thermo King (written "Temple, TX, 76501") the drop
  const w = must(waco);
  assert.deepEqual(
    w.stops.map((s) => [s.type, s.name, s.street, s.city, s.state, s.zip]),
    [
      ["pickup", "WACO PROCESSING", "301 AVIATION PARKWAY", "WACO", "TX", "76705"],
      ["drop", "Convoy Servicing - Thermo King of Temple", "575 Northpoint Dr", "Temple", "TX", "76501"],
    ]
  );
  assert.deepEqual(w.trailers, ["13065"]);
  assert.equal(looksLikeLoad("pickup at Walmart Fresno, CA tomorrow 5am then deliver to Reno, NV"), true);
  assert.equal(looksLikeLoad("Drop the trailer at 575 Northpoint Dr"), true);
  assert.equal(looksLikeLoad("LOAD # 1011\n" + waco), true);
  // chat without an address is never a load
  assert.equal(looksLikeLoad("Did you deliver yet?"), false);
  assert.equal(looksLikeLoad("Delivered, OK thanks"), false);
  assert.equal(looksLikeLoad("drop the trailer at the yard and go home"), false);
});

test("12 AM / 12 PM and local time zones", () => {
  const l = must("PICK #\nA\n1 ST\nRENO, NV 89501\n01/02/2026 12:05AM\n\nDROP #\nB\n2 ST\nBOISE, ID 83702\n01/02/2026 12:30PM");
  assert.deepEqual(l.stops.map((s) => s.appointment), ["2026-01-02T00:05", "2026-01-02T12:30"]);
  // 03:15 in Mira Loma on 2026-11-06 is PST (daylight saving ended 2026-11-01): UTC-8
  assert.equal(localToDate("2026-11-06T03:15", "America/Los_Angeles").toISOString(), "2026-11-06T11:15:00.000Z");
  assert.equal(localToDate("2026-07-01T09:00", "America/New_York").toISOString(), "2026-07-01T13:00:00.000Z");
});

test("TRAILER # WILL ADVISE is no trailer; a later \"TAKE TRAILER # 16465\" is just the number", () => {
  const load = parseLoad("LOAD # 0056034\n\nTRAILER # WILL ADVISE\n\nTEMP # REFER BILLS\n\nPICK #\n4Earth Farms / WCD\n5555 E Olympic Blvd\nCommerce, CA 90022\n11/12/2026 07:00PM\n\nDROP #\nWCD Franklin Consolidation\n4040 Scottsville Rd\nFranklin, KY 42134\n11/15/2026 12:01AM")!;
  assert.deepEqual(load.trailers, []);
  assert.equal(load.stops.length, 2);
  for (const t of ["TBD", "tba", "will advise later", "N/A", "--"]) assert.deepEqual(parseLoad(`LOAD # 1\nTRAILER # ${t}\nPICK\nA\n1 Main St\nWaco, TX 76701`)!.trailers, [], t);
  const yes: [string, string][] = [
    ["TAKE TRAILER # 16465", "16465"], ["trailer 16465", "16465"], ["Trailer#: 16465", "16465"], ["pls take trailer # 16465", "16465"],
    ["hook trailer 5309", "5309"], ["TRAILER # UST-1234", "UST-1234"], ["use trailer 16465 for this load", "16465"], ["TRL 16465", "16465"],
  ];
  for (const [text, want] of yes) assert.equal(trailerOnly(text), want, text);
  for (const text of ["trailer 16465 is broken", "TRAILER # WILL ADVISE", "where is trailer?", "LOAD # 1\nTRAILER # 16465", "take trailer"]) assert.equal(trailerOnly(text), null, text);
});

test("ORDER # / TRIP # / LOAD ORDER # are the Load #; temp, trailer and team come with it", () => {
  const text = `YOUR LONG FOR TOMORROW MORNING.\n\nTRUCK # 35865\n\nTEAM # ABBY + AMIT\n\nTRAILER # 107065\n\nTEMP # 34 CONT.\n\nORDER # 0056000\n\nFreshPoint Atlanta\n1200 Oakley Industrial Blvd B\nFAIRBURN, GA 30213\n11/16/2026 06:00AM`;
  assert(looksLikeLoad(text));
  const l = parseLoad(text)!;
  assert.equal(l.loadNo, "0056000", "ORDER # is the Load #");
  assert.equal(l.truck, "35865");
  assert.deepEqual(l.team, ["ABBY", "AMIT"]);
  assert.deepEqual(l.trailers, ["107065"]);
  assert.equal(l.temperature, "34 CONT.");
  assert.equal(l.stops.length, 1);
  assert.equal(l.stops[0].city, "FAIRBURN");
  assert.equal(l.stops[0].type, "drop", "no pickup / drop labels → the one address is the drop");
  assert.equal(l.needsReview, false);
  const addr = "PICK\nA\n1 Main St\nWaco, TX 76701\n11/16/2026 06:00AM";
  for (const [label, want] of [
    ["LOAD ORDER # 5501", "5501"], ["TRIP # 0056034", "0056034"], ["TRIP NO 77", "77"], ["ORD: 88", "88"], ["ORDER NO. 9-1", "9-1"],
    ["ORDER ID 4", "4"], ["LOAD # 1011", "1011"], ["INVOICE # 55-AB", "55-AB"], ["Order number 312", "312"],
  ] as [string, string][]) assert.equal(parseLoad(`${label}\n${addr}`)?.loadNo, want, label);
  // Not a load id
  for (const label of ["PO # 5501", "PU # 5501", "ORDER OF ARRIVAL", "TRIP SHEET", "BOL # 22"]) assert.equal(parseLoad(`${label}\n${addr}`)?.loadNo ?? null, null, label);
});

test("one address: a labelled PICKUP stays a pickup; unlabelled with only pickup words is flagged; none → plan-only with a Load #", () => {
  const addr = "Waco Foods\n1 Main St\nWaco, TX 76701\n11/16/2026 06:00AM";
  assert.equal(parseLoad(`LOAD # 7\nPICKUP\n${addr}`)!.stops[0].type, "pickup", "labelled");
  assert.equal(parseLoad(`LOAD # 7\nDROP\n${addr}`)!.stops[0].type, "drop", "labelled");
  const loose = parseLoad(`LOAD # 7 - we pick up tomorrow morning\n${addr}`);
  assert.equal(loose!.loadNo, null, "'LOAD # 7 - …' on one line is not a Load # line");
  const sentence = parseLoad(`LOAD # 7\nthey need a pick up tomorrow\n${addr}`)!;
  assert.equal(sentence.stops[0].type, "pickup", "talks about a pickup, never a delivery");
  assert(sentence.needsReview && sentence.reasons.some((r) => /mentions a pickup/.test(r)));
  // Plan-only: nothing to route, but a Load #
  assert.equal(parseLoad("LOAD # 9\nTRUCK # 11\nTEMP # 34"), null, "chat messages without an address are not loads");
  const plan = parseLoad("ORDER # 0056000\nTRUCK # 35865\nTRAILER # 107065\nTEMP # 34 CONT.", { plan: true })!;
  assert.equal(plan.loadNo, "0056000");
  assert.deepEqual(plan.stops, []);
  assert.equal(plan.truck, "35865");
  assert.equal(plan.needsReview, true);
  assert.equal(parseLoad("TRUCK # 11\nTEMP # 34", { plan: true }), null, "no Load # → nothing to plan");
});

console.log(results.join("\n"));
process.exit(results.some((r) => r.startsWith("FAIL")) ? 1 : 0);
