import { AutomationSetting } from "../../models/AutomationSetting";
import { RATE_CARD } from "./pricing";

// Fallback when no admin choice is saved yet (or the settings table is unavailable)
export const DEFAULT_AI_MODEL = process.env.AI_MODEL || "claude-opus-5-5";
export const ALLOWED_MODELS = RATE_CARD.map((r) => r.model);

// Cheap model for the quick "is this a document we read?" check before the full read
export const PRECHECK_MODEL = process.env.AI_PRECHECK_MODEL || "claude-haiku-5-5";

const KEY_AI_MODEL = "ai_model";
const KEY_PRECHECK_ENABLED = "precheck_enabled";
const KEY_SCALE_AGENT = "scale_agent_enabled";
const KEY_SCALE_RELEASE_ROLE = "scale_release_role";
const KEY_SCALE_WEBHOOK = "scale_webhook_url";
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

// Scale ticket compliance agent (services/scaleAgent); on unless an admin turns it off
export const isScaleAgentEnabled = async (): Promise<boolean> => {
  const row = await readSetting(KEY_SCALE_AGENT);
  return row?.value ? row.value === "true" : true;
};

export const setScaleAgentEnabled = async (enabled: boolean, userId?: string | null) => {
  await writeSetting(KEY_SCALE_AGENT, String(enabled), userId);
  return enabled;
};

// Who may release a load after a scale check (spec §9: role-based approvals), and where the
// spec §9 report is posted on every check and decision
export interface ScalePolicy {
  releaseRole: "staff" | "admin";
  webhookUrl: string | null;
}

export const getScalePolicy = async (): Promise<ScalePolicy> => {
  const role = (await readSetting(KEY_SCALE_RELEASE_ROLE))?.value;
  const url = (await readSetting(KEY_SCALE_WEBHOOK))?.value;
  return { releaseRole: role === "admin" ? "admin" : "staff", webhookUrl: url ? url : null };
};

export const setScalePolicy = async (input: Partial<ScalePolicy>, userId?: string | null) => {
  if (input.releaseRole) await writeSetting(KEY_SCALE_RELEASE_ROLE, input.releaseRole === "admin" ? "admin" : "staff", userId);
  if (input.webhookUrl !== undefined) {
    const url = (input.webhookUrl || "").trim();
    if (url && !/^https:\/\//i.test(url)) throw new Error("Webhook URL must start with https://");
    await writeSetting(KEY_SCALE_WEBHOOK, url, userId);
  }
  return getScalePolicy();
};

// Haiku models do not offer the server-side refusal fallback
export const supportsFallback = (model: string) => !/haiku/i.test(model);
