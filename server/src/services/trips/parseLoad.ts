import { isUsState } from "./stateTimezone";

// Reads a load the way dispatchers type it in chat, e.g.
//
//   TEMP # REFER BILLS          PICK #                     DROP # 1
//                               COLD LINK - ELLISVILLE     SYSCO - FREMONT - P050
//                               609 DACETOWN RD            5900 STEWART AVE
//                               ELLISVILLE, MS 39437       FREMONT, CA 94538
//                                                          10/23/2026 09:00AM
//
// Rules only (free, instant). An address is "name / street / City, ST 12345" with an optional
// "MM/DD/YYYY hh:mmAM" line after it. Unlabeled addresses: the first is the pickup, the rest drops.
// Anything uncertain is flagged needsReview for dispatch to check; parseLoadWithAi (loadAi.ts) is
// only asked when the rules can't make sense of a message that still looks like a load.

export type StopType = "pickup" | "drop" | "switch";

export interface ParsedStop {
  type: StopType;
  name: string;
  street: string;
  city: string;
  state: string;
  zip: string;
  /** Local to the stop: "2026-11-06T03:15" (see stateTimezone.ts). */
  appointment: string | null;
}

export interface ParsedLoad {
  /** The load's own number (LOAD # 1011 / INVOICE # 1011) — the same number again is the next leg */
  loadNo: string | null;
  stops: ParsedStop[];
  truck: string | null;
  trailers: string[];
  /** Team drivers named in the message ("JOGA SINGH + JAGTAR SINGH"). */
  team: string[];
  temperature: string | null;
  loadedTrailer: boolean;
  needsReview: boolean;
  /** Why it needs a check, in plain words for dispatch. */
  reasons: string[];
}

const CITY_STATE_ZIP = /^(.+?),?\s+([A-Za-z]{2})\.?\s+(\d{5})(?:-\d{4})?$/;
const DATE_TIME = /^(\d{1,2})\/(\d{1,2})\/(\d{2,4})\s+(\d{1,2}):(\d{2})\s*([AaPp][Mm])?$/;
const PICK_LABEL = /^pick(?:\s*-?\s*up)?\s*#?\s*\d*\s*:?\s*$/i;
const DROP_LABEL = /^(?:drop|delivery|deliver|del)\s*#?\s*\d*\s*:?\s*$/i;
const SWITCH_LABEL = /^go\s+to\b/i;
// "#" or ":" is required after TRUCK / TRAILER / TEAM, so a company called "TEAM FOODS" stays a name
// "LOAD # 1011", "LOAD ID: 1011", "LOAD NO 1011", "INVOICE # 1011", "INV# 1011" — never "LOADED TRAILER"
const LOAD_FIELD =
  /^(?:load|invoice|inv)(?:\s*(?:no\.?|id|number))?\s*[#:]+\s*([A-Za-z0-9][A-Za-z0-9-]*)\s*$|^(?:load|invoice|inv)\s+(?:no\.?|id|number)\s+([A-Za-z0-9][A-Za-z0-9-]*)\s*$/i;
const FIELD = /^(?:(truck|trailer|team)\s*[#:]|(temp(?:erature)?)\b\s*[#:]?)\s*(.*)$/i;

const clean = (s: string) => s.replace(/\s+/g, " ").replace(/[,\s]+$/, "").trim();

function parseDateTime(line: string): string | null {
  const m = DATE_TIME.exec(line.trim());
  if (!m) return null;
  const [, mo, da, yr, hh, mi, ap] = m;
  let h = Number(hh);
  if (ap) {
    const pm = ap.toUpperCase() === "PM";
    if (h === 12) h = pm ? 12 : 0;
    else if (pm) h += 12;
  }
  const year = yr.length === 2 ? 2000 + Number(yr) : Number(yr);
  const month = Number(mo);
  const day = Number(da);
  if (month < 1 || month > 12 || day < 1 || day > 31 || h > 23 || Number(mi) > 59) return null;
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${year}-${pad(month)}-${pad(day)}T${pad(h)}:${mi}`;
}

const isCityStateZip = (line: string) => {
  const m = CITY_STATE_ZIP.exec(line.trim());
  return !!m && isUsState(m[2]);
};

/** Does this text look like a load at all (vs. a chat line that happens to contain an address)? */
export function looksLikeLoad(text: string): boolean {
  const lines = text.split(/\r?\n/).map((l) => l.trim());
  const addresses = lines.filter(isCityStateZip).length;
  if (!addresses) return false;
  const signals =
    lines.some((l) => PICK_LABEL.test(l) || DROP_LABEL.test(l) || SWITCH_LABEL.test(l) || FIELD.test(l) || parseDateTime(l)) ||
    /\bload(ed)?\b/i.test(text);
  return addresses >= 2 || signals;
}

export function parseLoad(text: string): ParsedLoad | null {
  if (!text || !looksLikeLoad(text)) return null;
  const lines = text.split(/\r?\n/).map((l) => l.trim());

  const result: ParsedLoad = {
    stops: [],
    truck: null,
    trailers: [],
    team: [],
    loadNo: null,
    temperature: null,
    loadedTrailer: /\bloaded\s+trailer\b/i.test(text),
    needsReview: false,
    reasons: [],
  };

  // Lines that belong to an address (so they aren't read as labels or fields)
  const used = new Set<number>();
  let nextType: StopType | null = null;
  let labelled = false;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!line || used.has(i)) continue;

    if (PICK_LABEL.test(line)) {
      nextType = "pickup";
      labelled = true;
      continue;
    }
    if (DROP_LABEL.test(line)) {
      nextType = "drop";
      labelled = true;
      continue;
    }
    if (SWITCH_LABEL.test(line)) {
      nextType = "switch";
      labelled = true;
      continue;
    }

    const loadField = LOAD_FIELD.exec(line);
    if (loadField) {
      result.loadNo = (loadField[1] || loadField[2]).toUpperCase();
      continue;
    }

    const field = FIELD.exec(line);
    if (field && !isCityStateZip(line)) {
      const key = (field[1] || field[2]).toLowerCase();
      const value = clean(field[3]);
      if (key === "truck" && value) result.truck = value.replace(/^#/, "").trim();
      else if (key === "trailer" && value) result.trailers.push(...value.split(/[,&/]|\s+and\s+/i).map(clean).filter(Boolean));
      else if (key === "team" && value) result.team = value.split(/\s*(?:\+|&|,|\band\b)\s*/i).map(clean).filter(Boolean);
      else if (key.startsWith("temp") && value) result.temperature = value;
      continue;
    }

    if (!isCityStateZip(line)) continue;

    // An address: the street is the line above, the name the line above that (when it's not a
    // label, a field, blank or part of another address)
    const m = CITY_STATE_ZIP.exec(line)!;
    const above = (k: number) => {
      const j = i - k;
      if (j < 0 || used.has(j)) return null;
      const l = lines[j];
      if (!l || PICK_LABEL.test(l) || DROP_LABEL.test(l) || SWITCH_LABEL.test(l) || FIELD.test(l) || LOAD_FIELD.test(l) || parseDateTime(l)) return null;
      return j;
    };
    const streetAt = above(1);
    const nameAt = streetAt !== null ? above(2) : null;
    const dateAt = i + 1 < lines.length ? parseDateTime(lines[i + 1]) : null;

    for (const j of [streetAt, nameAt, i]) if (j !== null) used.add(j);
    if (dateAt) used.add(i + 1);

    result.stops.push({
      type: nextType ?? (result.stops.length === 0 ? "pickup" : "drop"),
      name: nameAt !== null ? clean(lines[nameAt]) : streetAt !== null ? clean(lines[streetAt]) : "",
      street: nameAt !== null && streetAt !== null ? clean(lines[streetAt]) : "",
      city: clean(m[1]),
      state: m[2].toUpperCase(),
      zip: m[3],
      appointment: dateAt,
    });
    // A label applies to the address right after it (DROP# 1 / DROP# 2 each have their own)
    nextType = null;
  }

  if (!result.stops.length) return null;

  // Unlabeled stops after a switch are deliveries ("GO TO … DO THE SWITCHING … DELIVER")
  const sawSwitch = result.stops.some((s) => s.type === "switch");
  if (sawSwitch) {
    let afterSwitch = false;
    for (const s of result.stops) {
      if (s.type === "switch") afterSwitch = true;
      else if (afterSwitch && s.type === "pickup") s.type = "drop";
    }
  }

  // One address only: was it the pickup or the delivery? With a loaded trailer or a switch it's
  // the delivery; otherwise dispatch must say
  if (result.stops.length === 1) {
    const only = result.stops[0];
    if (!labelled) only.type = result.loadedTrailer || sawSwitch || /\blong\s+load\b/i.test(text) ? "drop" : "pickup";
    result.reasons.push("Only one address — check whether it is the pickup or the delivery");
  }

  if (!result.stops.some((s) => s.type === "drop")) result.reasons.push("No delivery found");
  if (!result.stops.some((s) => s.appointment)) result.reasons.push("No appointment date/time found");
  const deliveriesWithoutTime = result.stops.filter((s) => s.type === "drop" && !s.appointment).length;
  if (deliveriesWithoutTime) result.reasons.push(`${deliveriesWithoutTime} delivery without an appointment time`);
  if (result.stops.some((s) => !s.name)) result.reasons.push("A stop has no name");

  result.needsReview = result.reasons.length > 0;
  return result;
}
