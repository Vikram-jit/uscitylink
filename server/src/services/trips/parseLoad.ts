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
  /** Everything in the text that isn't a field or an address ("YOUR LONG FOR TOMORROW MORNING."), kept as the load's notes */
  notes: string | null;
  needsReview: boolean;
  /** Why it needs a check, in plain words for dispatch. */
  reasons: string[];
}

// A place or a date dispatch has not confirmed yet: "PENDING", "TBD", "N/A" …  Under a PICKUP / DROP heading it
// means "no address yet"; "DATE PENDING" says the appointment is not set. Both are normal, not errors.
export const PENDING_WORD = /^(?:pending|tbd|tba|tbc|n\/?a|unconfirmed|not\s+confirmed|to\s+be\s+(?:determined|confirmed|advised|announced)|will\s+advise|—+|-{2,}|\?+)\.?$/i;
const DATE_PENDING = /^(?:date|dates|appt|appointment|time|(?:pick\s*-?\s*up|pickup|delivery|drop)\s+(?:date|time|appt))\s*[:#-]?\s*(?:pending|tbd|tba|tbc|n\/?a|unconfirmed|not\s+confirmed)\.?$/i;
const LOADED_TRAILER_LINE = /^loaded\s+trailer\b/i;

const CITY_STATE_ZIP = /^(.+?),?\s+([A-Za-z]{2})\.?,?\s*(\d{5})(?:-\d{4})?[.,]?$/;
const DATE_TIME = /^(\d{1,2})\/(\d{1,2})\/(\d{2,4})\s+(\d{1,2}):(\d{2})\s*([AaPp][Mm])?$/;
const PICK_LABEL = /^pick(?:\s*-?\s*up)?\s*#?\s*\d*\s*:?\s*$/i;
const DROP_LABEL = /^(?:drop|delivery|deliver|del)\s*#?\s*\d*\s*:?\s*$/i;
const SWITCH_LABEL = /^go\s+to\b/i;
// "#" or ":" is required after TRUCK / TRAILER / TEAM, so a company called "TEAM FOODS" stays a name
// "LOAD # 1011", "LOAD ID: 1011", "LOAD NO 1011", "INVOICE # 1011", "INV# 1011" — never "LOADED TRAILER"
// The Load # can be written LOAD / ORDER / TRIP / INVOICE (and LOAD ORDER): "ORDER # 0056000" is a load id
const LOAD_FIELD =
  /^(?:load\s+order|load|order|ord|trip|invoice|inv)(?:\s*(?:no\.?|id|number|num))?\s*[#:]+\s*([A-Za-z0-9][A-Za-z0-9-]*)\s*$|^(?:load\s+order|load|order|ord|trip|invoice|inv)\s+(?:no\.?|id|number|num)\s+([A-Za-z0-9][A-Za-z0-9-]*)\s*$/i;
/** "TRAILER # WILL ADVISE / TBD / later" — no number yet (it comes in a later message) */
export const TRAILER_LATER = /^(will\s+advise|w\/?a|tba|tbd|tbc|later|pending|n\/?a|none|na|-+|\?+|advise\s+later|will\s+send|will\s+update|update\s+later|coming|soon)(?=$|[\s.,!])/i;
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

// Words that mean a load / a stop anywhere in the text: "pickup", "pick up", "PU", "delivery", "deliver",
// "drop", "drop off", "unload", "shipper", "consignee", "receiver", "load"
export const LOAD_WORDS = /\b(?:pick\s*-?\s*ups?|pickups?|deliver(?:y|ies|ed|ing)?|del\s*#|drop(?:\s*-?\s*off)?s?|dropped|unload(?:ing)?|shipper|consignee|receiver|loads?|loaded)\b/i;
// A street address anywhere: "301 AVIATION PARKWAY", "at 575 Northpoint Dr,"
const STREET = /\b\d{1,6}\s+[A-Za-z0-9][A-Za-z0-9 .'-]*?\s(?:st|street|ave|avenue|rd|road|blvd|boulevard|dr|drive|hwy|highway|pkwy|parkway|ln|lane|way|ct|court|pl|place|cir|circle|fwy|freeway|pike|trl|trail|expy|expressway|ter|terrace|sq|loop)\b/i;
// "City, ST" / "City, ST, 76501" anywhere
// (capital state letters; states that are also words — OK, IN, ME, OR, HI, ID, OH — need a ZIP after)
const CITY_ST = /[A-Za-z][A-Za-z .'-]*,\s*([A-Z]{2})\b(\.?,?\s*\d{5})?/g;
const WORD_STATES = new Set(["OK", "IN", "ME", "OR", "HI", "ID", "OH"]);

const hasPlace = (text: string, lines: string[]) =>
  lines.some((l) => isCityStateZip(l) || STREET.test(l)) ||
  [...text.matchAll(CITY_ST)].some((m) => isUsState(m[1]) && (!WORD_STATES.has(m[1]) || !!m[2]));

/**
 * Does this text look like a load (vs. a chat line)? An address plus any load word — pickup,
 * delivery, drop, … anywhere and in any format — or a PICKUP / DELIVERY heading, an appointment
 * date-time or a LOAD # line. Then it needs its Load # (the chat box won't send it without one).
 */
export function looksLikeLoad(text: string): boolean {
  const lines = text.split(/\r?\n/).map((l) => l.trim());
  // A LOAD # line with a PICKUP / DROP heading is a load even before any address is known (both pending)
  if (lines.some((l) => LOAD_FIELD.test(l)) && lines.some((l) => PICK_LABEL.test(l) || DROP_LABEL.test(l))) return true;
  if (!hasPlace(text, lines)) return false;
  return LOAD_WORDS.test(text) || lines.some((l) => PICK_LABEL.test(l) || DROP_LABEL.test(l) || SWITCH_LABEL.test(l) || LOAD_FIELD.test(l) || parseDateTime(l));
}

/**
 * Read a load text. `plan: true` (the "Add to loads" button / Repair) also accepts a text with a Load # but
 * no address at all: it comes back with no stops, as a plan to be filled in later.
 */
export function parseLoad(text: string, opts: { plan?: boolean } = {}): ParsedLoad | null {
  if (!text || (!looksLikeLoad(text) && !opts.plan)) return null;
  const lines = text.split(/\r?\n/).map((l) => l.trim());

  const result: ParsedLoad = {
    stops: [],
    truck: null,
    trailers: [],
    team: [],
    loadNo: null,
    temperature: null,
    loadedTrailer: /\bloaded\s+trailer\b/i.test(text),
    notes: null,
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
      used.add(i);
      continue;
    }
    if (DROP_LABEL.test(line)) {
      nextType = "drop";
      labelled = true;
      used.add(i);
      continue;
    }
    if (SWITCH_LABEL.test(line)) {
      nextType = "switch";
      labelled = true;
      used.add(i);
      continue;
    }

    const loadField = LOAD_FIELD.exec(line);
    if (loadField) {
      result.loadNo = (loadField[1] || loadField[2]).toUpperCase();
      used.add(i);
      continue;
    }

    // "DATE PENDING" / "LOADED TRAILER": understood, nothing to read from them
    if (DATE_PENDING.test(line) || LOADED_TRAILER_LINE.test(line)) {
      used.add(i);
      continue;
    }

    // A PICKUP / DROP heading followed by PENDING: that place is not confirmed yet (no stop). A date under it
    // still counts: the stop is kept with its appointment and no address.
    if (PENDING_WORD.test(line)) {
      used.add(i);
      if (nextType) {
        const next = i + 1 < lines.length ? parseDateTime(lines[i + 1]) : null;
        if (next) {
          result.stops.push({ type: nextType, name: "", street: "", city: "", state: "", zip: "", appointment: next });
          used.add(i + 1);
        }
        nextType = null;
      }
      continue;
    }

    const field = FIELD.exec(line);
    if (field && !isCityStateZip(line)) {
      used.add(i);
      const key = (field[1] || field[2]).toLowerCase();
      const value = clean(field[3]);
      // "WILL ADVISE" / "TBD" / "PENDING" in any header field means "not known yet" — never a truck, team or temp
      const later = TRAILER_LATER.test(value) || PENDING_WORD.test(value);
      if (key === "truck" && value && !later) result.truck = value.replace(/^#/, "").trim();
      else if (key === "trailer" && value && !later) result.trailers.push(...value.split(/[,&/]|\s+and\s+/i).map(clean).filter(Boolean));
      else if (key === "team" && value && !later) result.team = value.split(/\s*(?:\+|&|,|\band\b)\s*/i).map(clean).filter(Boolean);
      else if (key.startsWith("temp") && value && !later) result.temperature = value;
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

  // Anything else dispatch wrote ("YOUR LONG FOR TOMORROW MORNING.") is kept as the load's notes
  const leftovers = lines.filter((l, i) => l && !used.has(i));
  result.notes = leftovers.length ? leftovers.join("\n").slice(0, 400) : null;

  if (!result.stops.length) {
    // Nothing to route, but it has a Load #: a plan-only load (saved, never sent until a pickup or drop is added)
    if (result.loadNo && (opts.plan || labelled || lines.some((l) => PICK_LABEL.test(l) || DROP_LABEL.test(l)))) {
      result.needsReview = true;
      result.reasons.push("No pickup or drop address yet — saved as a plan; add one before sending");
      return result;
    }
    return null;
  }

  // Unlabeled stops after a switch are deliveries ("GO TO … DO THE SWITCHING … DELIVER")
  const sawSwitch = result.stops.some((s) => s.type === "switch");
  if (sawSwitch) {
    let afterSwitch = false;
    for (const s of result.stops) {
      if (s.type === "switch") afterSwitch = true;
      else if (afterSwitch && s.type === "pickup") s.type = "drop";
    }
  }

  // One address and no PICK / DROP labels: it is the delivery (drop). Only when the text itself talks
  // about a pickup and never about a delivery is it the pickup — and then dispatch is asked to check.
  if (result.stops.length === 1 && !labelled) {
    const only = result.stops[0];
    const pickWord = /\bpick\s*-?\s*ups?\b/i.test(text);
    const dropWord = /\b(?:deliver(?:y|ies|ed|ing)?|drops?|dropped|unload(?:ing)?|consignee|receiver)\b/i.test(text);
    if (pickWord && !dropWord && !result.loadedTrailer && !sawSwitch) {
      only.type = "pickup";
      result.reasons.push("Only one address, and the text mentions a pickup — check it is not the delivery");
    } else only.type = "drop";
  }

  // Only a pickup or only a drop is fine (the other is pending); a missing date is "PENDING", not a problem
  if (result.stops.some((s) => !s.name && (s.city || s.street))) result.reasons.push("A stop has no name");

  result.needsReview = result.reasons.length > 0;
  return result;
}

/**
 * A truck and / or a trailer number sent on its own after a load ("truck 24565", "TAKE TRAILER # 16465",
 * "truck 24565 trailer 107065", "TRUCK # 24565\nTRAILER # 107065"): the whole message is only that. It belongs to
 * the load the driver is on. Each number must contain a digit; anything else in the message (a sentence, an
 * address, a LOAD # …) means it is not this.
 */
const EQUIPMENT = /\b(truck|trk|tractor|trailer|trl|trlr)\b\s*(?:#|no\.?|number)?\s*[:\-]?\s*#?\s*([A-Za-z]{0,3}-?\d[A-Za-z0-9-]{1,11})\b/gi;
const FILLER = /\b(?:pls|please|plz|take|use|pick\s*up|hook(?:\s+up)?|grab|get|change(?:\s+it)?\s+to|switch\s+to|new|your|ur|assigned?|the|and|for|on|this|load|is|now|also)\b|[\s,&+;:.!#\-]/gi;

export interface EquipmentUpdate {
  truck: string | null;
  trailer: string | null;
}

export function equipmentOnly(text: string): EquipmentUpdate | null {
  const t = String(text || "").trim();
  if (!t || t.length > 90) return null;
  const found: { kind: "truck" | "trailer"; value: string }[] = [];
  for (const m of t.matchAll(EQUIPMENT)) found.push({ kind: /^(?:truck|trk|tractor)$/i.test(m[1]) ? "truck" : "trailer", value: m[2].replace(/\s+/g, "").toUpperCase() });
  if (!found.length) return null;
  const rest = t.replace(EQUIPMENT, " ").replace(FILLER, "");
  if (rest.trim()) return null;
  const trucks = found.filter((f) => f.kind === "truck");
  const trailers = found.filter((f) => f.kind === "trailer");
  if (trucks.length > 1 || trailers.length > 1) return null;
  return { truck: trucks[0]?.value || null, trailer: trailers[0]?.value || null };
}

/** Only a trailer number ("TAKE TRAILER # 16465"). */
export function trailerOnly(text: string): string | null {
  const e = equipmentOnly(text);
  return e && e.trailer && !e.truck ? e.trailer : null;
}
