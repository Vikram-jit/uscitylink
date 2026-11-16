// The load message the system sends for dispatch is the DISPATCHER's own message (their name, the normal blue
// bubble — not the "Dispatch Assistant" one). A message like that goes through the chat hook like any text
// dispatch types, and would be read as a newly typed load. So the text is registered here BEFORE it is sent,
// and the hook skips it. (No imports: used by tripService and tripAssistant.)

const recent = new Map<string, number>();
const TTL_MS = 60_000;
const key = (text: string) => String(text || "").trim();

export function rememberOwnLoadText(text: string) {
  const now = Date.now();
  for (const [k, until] of recent) if (until < now) recent.delete(k);
  recent.set(key(text), now + TTL_MS);
}

export const isOwnLoadText = (text: string) => (recent.get(key(text)) || 0) > Date.now();
