// The same rules as the server's load reader (server/src/services/trips/parseLoad.ts), for the chat
// box: a message that looks like a load (addresses + PICKUP / DELIVERY) must carry its Load # so the
// server can make it a load (and the next leg when the number is used again).

const CITY_STATE_ZIP = /^(.+?),?\s+([A-Za-z]{2})\.?\s+(\d{5})(?:-\d{4})?$/;
const LABEL = /^(?:pick(?:\s*-?\s*up)?|drop|delivery|deliver|del)\s*#?\s*\d*\s*:?\s*$/i;
const LOAD_NO =
  /^(?:load|invoice|inv)(?:\s*(?:no\.?|id|number))?\s*[#:]+\s*([A-Za-z0-9][A-Za-z0-9-]*)\s*$|^(?:load|invoice|inv)\s+(?:no\.?|id|number)\s+([A-Za-z0-9][A-Za-z0-9-]*)\s*$/i;

const lines = (text: string) => text.split(/\r?\n/).map((l) => l.trim());

export function looksLikeLoad(text: string): boolean {
  const all = lines(text);
  const addresses = all.filter((l) => CITY_STATE_ZIP.test(l)).length;
  if (!addresses) return false;
  return addresses >= 2 || all.some((l) => LABEL.test(l)) || /\bload(ed)?\b/i.test(text);
}

/** "LOAD # 1011" / "INVOICE #: 55-AB" → "1011" (PU# / PO# don't count) */
export function loadNoIn(text: string): string | null {
  for (const l of lines(text)) {
    const m = LOAD_NO.exec(l);
    if (m) return (m[1] || m[2]).toUpperCase();
  }
  return null;
}
