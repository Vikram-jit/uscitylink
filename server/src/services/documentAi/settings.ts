import { AutomationSetting } from "../../models/AutomationSetting";
import { RATE_CARD } from "./pricing";

// Fallback when no admin choice is saved yet (or the settings table is unavailable)
export const DEFAULT_AI_MODEL = process.env.AI_MODEL || "claude-opus-5-5";
export const ALLOWED_MODELS = RATE_CARD.map((r) => r.model);

const KEY_AI_MODEL = "ai_model";
const CACHE_MS = 30_000;
let cached: { model: string; at: number } | null = null;

// Model used for document reading. Read from the DB (admin setting) with a short cache,
// so a change in the panel applies to the next document without a server restart.
export const getAiModel = async (): Promise<string> => {
  if (cached && Date.now() - cached.at < CACHE_MS) return cached.model;
  let model = DEFAULT_AI_MODEL;
  try {
    const row = await AutomationSetting.findByPk(KEY_AI_MODEL);
    if (row?.value && ALLOWED_MODELS.includes(row.value)) model = row.value;
  } catch (err) {
    console.warn("[documentAi] settings unavailable, using default model:", (err as Error).message);
  }
  cached = { model, at: Date.now() };
  return model;
};

export const setAiModel = async (model: string, userId?: string | null): Promise<string> => {
  if (!ALLOWED_MODELS.includes(model)) throw new Error(`Unknown model "${model}"`);
  await AutomationSetting.upsert({ key: KEY_AI_MODEL, value: model, updated_by: userId || null });
  cached = { model, at: Date.now() };
  return model;
};

export const getAiModelSetting = async () => {
  const row = await AutomationSetting.findByPk(KEY_AI_MODEL).catch(() => null);
  return {
    model: await getAiModel(),
    isDefault: !row?.value,
    updatedAt: row?.updatedAt || null,
    updatedBy: row?.updated_by || null,
  };
};

// Haiku models do not offer the server-side refusal fallback
export const supportsFallback = (model: string) => !/haiku/i.test(model);
