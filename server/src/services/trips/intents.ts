// What a driver's chat line says about their trip, by keywords (English, Punjabi and Hindi in Latin
// letters). tripAssistant.ts asks the low-cost model only when these find nothing.

export type Intent = "next_load" | "arrive" | "rolling" | "end" | "problem" | "none";

const NEXT_LOAD = /\b(next|new|nxt|agla|agli|another)\s*(load|trip)\b|\bany\s+(load|trip)s?\b|\bload\s+(ready|hai|kidhar|kithe|kab)\b|\bwhat'?s\s+next\b/i;
const ARRIVED =
  /\b(arrived|arriving\s+now|reached|reach(?:ed)?\s+(?:at\s+)?(?:shipper|receiver|consignee|customer|pickup|delivery)|i'?m\s+here|im\s+here|here\s+now|on\s+site|onsite|at\s+(the\s+)?(shipper|receiver|consignee|customer|dock|door|facility|pick\s*up|pickup|delivery)|check(?:ed)?\s*-?\s*in(?:\s+done)?|checkin\s+done|in\s+(the\s+)?door|backed\s+in|got\s+(a\s+)?door|pahunch\w*|puhunch\w*|pohnch\w*|ponch\w*|pahuch\w*|a+\s*gay[ae]|aa?gy[ae]|aa?\s*gya|agya)\b/i;
const ROLLING =
  /\b(loaded|got\s+loaded|load(?:ing)?\s+(?:is\s+)?done|picked\s*up|pick\s*-?\s*up\s+done|pickup\s+done|rolling|roll(?:ing)?\s+now|leaving|just\s+left|left\s+(?:now|from|(?:the\s+)?(?:shipper|pickup|yard|facility|receiver))|departed|on\s+my\s+way|omw|on\s+(the\s+)?road|en\s*-?\s*route|heading\s+(out|to|for)|going\s+to\s+(the\s+)?(receiver|consignee|delivery|customer)|chal\s+p[aeiy]{1,3}|chal\s+di(?:ye|a|ya)|nikal\w*|tur\s+p[aeiy]{1,3}|rawana|ravana|rwana)\b/i;
const DELIVERED =
  /\b(delivered|delivery\s+(is\s+)?done|done\s+delivering|unloaded|unload(?:ing)?\s+(?:is\s+)?done|offloaded|got\s+empty|empty\s+now|i'?m\s+empty|im\s+empty|dropped\s+(the\s+)?(load|trailer)|drop\s+done|khali\s*(ho\s*)?(gay[ae]|gya|hogya)?|khali)\b/i;
const PROBLEM = /\b(break\s*down|broke\s+down|flat\s+tire|accident|detention|lumper|rejected|shortage|damaged?)\b/i;
export const SMALL_TALK = /^(ok|okay|k|thanks|thank\s+you|thx|ty|yes|no|yeah|yep|good|great|👍|🙏)[.!\s]*$/i;

/**
 * Lines that mention a status word but don't say it happened: negations, questions, future or
 * waiting ("not loaded yet", "when will I be loaded?", "will leave at 5", "waiting to get loaded").
 */
const NOT_DONE =
  /\?|\b(not|no|never|n't|dont|didnt|havent|hasnt|isnt|wasnt|cant|nahi|nahin|nai|nhi|ni|yet|still|when|will|gonna|going\s+to\s+be|soon|later|tomorrow|kal|after|before|waiting|wait|until|till|if|once|should|can\s+i|should\s+i|do\s+i|need\s+to|want\s+to|kab|kado|jado|hoyega|hoga|nahi\s+hua|ni\s+hoya|abhi\s+nahi)\b/i;

/** "left" on its own ("left", "left.") — not "I left my phone" */
const LEFT_ALONE = /^\s*(just\s+)?left[.!\s]*$/i;

export function ruleIntent(text: string): Intent {
  if (NEXT_LOAD.test(text)) return "next_load";
  if (DELIVERED.test(text)) return "end";
  if (PROBLEM.test(text)) return "problem";
  // "arrived at shipper, loaded and rolling" → rolling (the later step)
  if (ROLLING.test(text) || LEFT_ALONE.test(text)) return "rolling";
  if (ARRIVED.test(text)) return "arrive";
  return "none";
}

/**
 * A short, plain statement that the step happened ("rolling", "arrived at receiver", "unloaded"):
 * safe to apply to the trip without a tap. Anything else stays a suggestion.
 */
export function clearStatus(text: string): Intent {
  const t = text.trim();
  if (!t || t.length > 80 || t.split(/\s+/).length > 12 || NOT_DONE.test(t)) return "none";
  const intent = ruleIntent(t);
  return intent === "rolling" || intent === "arrive" || intent === "end" ? intent : "none";
}
