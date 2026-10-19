import { AutomationSetting } from "../../models/AutomationSetting";
import { RATE_CARD } from "./pricing";

// Fallback when no admin choice is saved yet (or the settings table is unavailable)
export const DEFAULT_AI_MODEL = process.env.AI_MODEL || "claude-opus-5-5";
export const ALLOWED_MODELS = RATE_CARD.map((r) => r.model);

// Cheap model for the quick "is this a document we read?" check before the full read
export const PRECHECK_MODEL = process.env.AI_PRECHECK_MODEL || "claude-haiku-5-5";

const KEY_AI_MODEL = "ai_model";
const KEY_PRECHECK_ENABLED = "precheck_enabled";
const CACHE_MS = 30_000;

// Settings are read from the DB with a short cache, so a change in the panel applies to the
// next document without a server restart.
const cache = new Map<string, { row: AutomationSetting | null; at: number }>();

const readSetting = async (key: string): Promise<AutomationSetting | null> => {
  const hit = cache.get(key);
  if (hit && Date.now() - hit.at < CACHE_MS) return hit.row;
  let row: AutomationSetting | null = null;
  try {
    row = await AutomationSetting.findByPk(key);
  } catch (err) {
    console.warn(`[documentAi] setting "${key}" unavailable, using default:`, (err as Error).message);
  }
  cache.set(key, { row, at: Date.now() });
  return row;
};

const writeSetting = async (key: string, value: string, userId?: string | null) => {
  await AutomationSetting.upsert({ key, value, updated_by: userId || null });
  cache.delete(key);
};

// Model used for the full document read
export const getAiModel = async (): Promise<string> => {
  const row = await readSetting(KEY_AI_MODEL);
  return row?.value && ALLOWED_MODELS.includes(row.value) ? row.value : DEFAULT_AI_MODEL;
};

export const setAiModel = async (model: string, userId?: string | null): Promise<string> => {
  if (!ALLOWED_MODELS.includes(model)) throw new Error(`Unknown model "${model}"`);
  await writeSetting(KEY_AI_MODEL, model, userId);
  return model;
};

export const getAiModelSetting = async () => {
  const row = await readSetting(KEY_AI_MODEL);
  return {
    model: await getAiModel(),
    isDefault: !row?.value,
    updatedAt: row?.updatedAt || null,
    updatedBy: row?.updated_by || null,
  };
};

export interface PrecheckSettings {
  // On: only document types used by live flows are read in full (see flowEngine/liveDocTypes)
  enabled: boolean;
  model: string;
}

export const getPrecheckSettings = async (): Promise<PrecheckSettings> => {
  const enabledRow = await readSetting(KEY_PRECHECK_ENABLED);
  return {
    enabled: enabledRow?.value ? enabledRow.value === "true" : true,
    model: PRECHECK_MODEL,
  };
};

export const setPrecheckSettings = async (input: { enabled?: boolean }, userId?: string | null) => {
  if (typeof input.enabled === "boolean") {
    await writeSetting(KEY_PRECHECK_ENABLED, String(input.enabled), userId);
  }
  return getPrecheckSettings();
};

// Haiku models do not offer the server-side refusal fallback
export const supportsFallback = (model: string) => !/haiku/i.test(model);
