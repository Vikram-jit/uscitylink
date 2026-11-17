import { readSetting, writeSetting } from "../documentAi/settings";
import { getSocketInstance } from "../../sockets/socket";

/**
 * Admin switches for the load features (web: Settings → Loads). Each part of the load work can be
 * turned off and back on later without a code change; the server enforces them, the apps hide what's off.
 * Saved in automation_settings (key "loads.<name>"), read with a short cache.
 */
export const LOAD_FEATURES = [
  { key: "driver_loads", default: true, title: "Loads in the driver app", help: "The driver's Loads tab, the load card on the dashboard and in the chat, and the My loads button. Off: drivers see no loads at all." },
  { key: "driver_buttons", default: true, title: "Driver load buttons", help: "Accept / Reject, Loaded — rolling and Delivered — end trip on the driver's load card. Off: drivers see the load but can't tap; dispatch moves it." },
  { key: "driver_upcoming", default: true, title: "Upcoming loads for drivers", help: "The driver's list of lined-up loads with Accept / Reject." },
  { key: "driver_chat_lines", default: true, title: "Driver tap messages in the chat", help: "When the driver taps Accept / Rolling / Delivered, a line (\"Got it\", \"Rolling\", \"Delivered\") is posted in their chat." },
  { key: "driver_chat_words", default: true, title: "Driver chat words move the load", help: "A driver typing \"rolling\", \"arrived\" or \"delivered\" in the chat moves their load as if they tapped." },
  { key: "driver_paperwork", default: true, title: "Driver photos / PDFs → load paperwork", help: "A photo or PDF the driver sends in the chat (BOL, POD …) is attached to their load." },
  { key: "auto_send_next", default: true, title: "Send the next lined-up load automatically", help: "When the driver delivers, their #1 lined-up load goes out to them by itself." },
  { key: "loads_from_chat", default: false, title: "Loads from chat messages", help: "A load typed or pasted in a driver / truck chat becomes a load (plus Add to loads / Repair and Missed loads). Off: loads only from the Loads form." },
] as const;

export type LoadFeatureKey = (typeof LOAD_FEATURES)[number]["key"];
export type LoadFeatures = Record<LoadFeatureKey, boolean>;

const settingKey = (k: LoadFeatureKey) => `loads.${k}`;

export async function getLoadFeatures(): Promise<LoadFeatures> {
  const out = {} as LoadFeatures;
  for (const f of LOAD_FEATURES) {
    const row = await readSetting(settingKey(f.key));
    out[f.key] = row?.value ? row.value === "true" : f.default;
  }
  // LOADS_FROM_CHAT in .env overrides the panel (used by the test scripts)
  if (process.env.LOADS_FROM_CHAT !== undefined) out.loads_from_chat = process.env.LOADS_FROM_CHAT === "true";
  return out;
}

export async function loadFeature(key: LoadFeatureKey): Promise<boolean> {
  return (await getLoadFeatures())[key];
}

/** Saves the switches given; every open app / dashboard hears it at once (loads:features). */
export async function setLoadFeatures(input: Partial<Record<string, unknown>>, userId?: string | null): Promise<LoadFeatures> {
  for (const f of LOAD_FEATURES) {
    const v = input[f.key];
    if (typeof v === "boolean") await writeSetting(settingKey(f.key), String(v), userId);
  }
  const now = await getLoadFeatures();
  try {
    getSocketInstance().emit("loads:features", now);
  } catch {
    // sockets not up (scripts)
  }
  return now;
}
