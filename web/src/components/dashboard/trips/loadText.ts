// The same rules as the server's load reader (server/src/services/trips/parseLoad.ts), for the chat
// box: a message that looks like a load (addresses + PICKUP / DELIVERY) must carry its Load # so the
// server can make it a load (and the next leg when the number is used again).

const CITY_STATE_ZIP = /^(.+?),?\s+([A-Za-z]{2})\.?,?\s*(\d{5})(?:-\d{4})?[.,]?$/;
const LABEL = /^(?:pick(?:\s*-?\s*up)?|drop|delivery|deliver|del)\s*#?\s*\d*\s*:?\s*$/i;
// LOAD / ORDER / TRIP / INVOICE (and LOAD ORDER) — "ORDER # 0056000" is a load id too
const LOAD_NO =
  /^(?:load\s+order|load|order|ord|trip|invoice|inv)(?:\s*(?:no\.?|id|number|num))?\s*[#:]+\s*([A-Za-z0-9][A-Za-z0-9-]*)\s*$|^(?:load\s+order|load|order|ord|trip|invoice|inv)\s+(?:no\.?|id|number|num)\s+([A-Za-z0-9][A-Za-z0-9-]*)\s*$/i;

// An appointment line: 11/13/2026 12:00PM
const DATE_TIME = /^(\d{1,2})\/(\d{1,2})\/(\d{2,4})\s+(\d{1,2}):(\d{2})\s*([AaPp][Mm])?$/;
const SWITCH = /^go\s+to\b/i;

const lines = (text: string) => text.split(/\r?\n/).map((l) => l.trim());

// Words that mean a load / a stop anywhere in the text (same list as the server)
const LOAD_WORDS = /\b(?:pick\s*-?\s*ups?|pickups?|deliver(?:y|ies|ed|ing)?|del\s*#|drop(?:\s*-?\s*off)?s?|dropped|unload(?:ing)?|shipper|consignee|receiver|loads?|loaded)\b/i;
const STREET = /\b\d{1,6}\s+[A-Za-z0-9][A-Za-z0-9 .'-]*?\s(?:st|street|ave|avenue|rd|road|blvd|boulevard|dr|drive|hwy|highway|pkwy|parkway|ln|lane|way|ct|court|pl|place|cir|circle|fwy|freeway|pike|trl|trail|expy|expressway|ter|terrace|sq|loop)\b/i;
// (capital state letters; states that are also words — OK, IN, ME, OR, HI, ID, OH — need a ZIP after)
const CITY_ST = /[A-Za-z][A-Za-z .'-]*,\s*([A-Z]{2})\b(\.?,?\s*\d{5})?/;
const WORD_STATES = new Set(['OK', 'IN', 'ME', 'OR', 'HI', 'ID', 'OH']);
const US_STATES = new Set('AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA ME MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN TX UT VT VA WA WV WI WY DC'.split(' '));

const hasPlace = (text: string, all: string[]) =>
  all.some((l) => CITY_STATE_ZIP.test(l) || STREET.test(l)) ||
  text.split(/\r?\n/).some((l) => {
    const re = new RegExp(CITY_ST.source, 'g');
    let m: RegExpExecArray | null;
    while ((m = re.exec(l))) if (US_STATES.has(m[1]) && (!WORD_STATES.has(m[1]) || m[2])) return true;
    return false;
  });

/**
 * An address plus any load word (pickup, delivery, drop, … anywhere, any format), or a PICKUP /
 * DELIVERY heading, an appointment time or a LOAD # line → a load: it must carry its Load #.
 */
export function looksLikeLoad(text: string): boolean {
  const all = lines(text);
  if (!hasPlace(text, all)) return false;
  return LOAD_WORDS.test(text) || all.some((l) => LABEL.test(l) || SWITCH.test(l) || DATE_TIME.test(l) || LOAD_NO.test(l));
}

/** A load without its Load #: the chat box must not send it */
export const loadNoMissing = (text: string) => !!text.trim() && looksLikeLoad(text) && !loadNoIn(text);

export const LOAD_NO_MISSING_MESSAGE = 'Not sent — this message has an address and pickup / delivery / drop: it needs its Load #. Add a line like "LOAD # 1011" at the top and send again.';

/** "LOAD # 1011" / "INVOICE #: 55-AB" → "1011" (PU# / PO# don't count) */
export function loadNoIn(text: string): string | null {
  for (const l of lines(text)) {
    const m = LOAD_NO.exec(l);
    if (m) return (m[1] || m[2]).toUpperCase();
  }
  return null;
}
