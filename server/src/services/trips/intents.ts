// What a driver's chat line says about their trip, by keywords (English, Punjabi and Hindi in Latin
// letters). tripAssistant.ts asks the low-cost model only when these find nothing.

export type Intent = "next_load" | "arrive" | "rolling" | "end" | "problem" | "none";

const NEXT_LOAD = /\b(next|new|nxt|agla|agli|another)\s*(load|trip)\b|\bany\s+(load|trip)s?\b|\bload\s+(ready|hai|kidhar|kithe|kab)\b|\bwhat'?s\s+next\b/i;
const ARRIVED = /\b(arrived|reached|i'?m\s+here|im\s+here|at\s+(the\s+)?(shipper|receiver|customer|dock)|pahunch\w*|puhunch\w*)\b/i;
const ROLLING = /\b(loaded|rolling|leaving|left|departed|on\s+my\s+way|heading\s+out|chal\s+p[ae]?y?a|nikal\w*)\b/i;
const DELIVERED = /\b(delivered|unloaded|empty\s+now|i'?m\s+empty|got\s+empty|khali|done\s+delivering|delivery\s+done)\b/i;
const PROBLEM = /\b(break\s*down|broke\s+down|flat\s+tire|accident|detention|lumper|rejected|shortage|damaged?)\b/i;
export const SMALL_TALK = /^(ok|okay|k|thanks|thank\s+you|thx|ty|yes|no|yeah|yep|good|great|👍|🙏)[.!\s]*$/i;

export function ruleIntent(text: string): Intent {
  if (NEXT_LOAD.test(text)) return "next_load";
  if (DELIVERED.test(text)) return "end";
  if (PROBLEM.test(text)) return "problem";
  if (ARRIVED.test(text)) return "arrive";
  if (ROLLING.test(text)) return "rolling";
  return "none";
}
