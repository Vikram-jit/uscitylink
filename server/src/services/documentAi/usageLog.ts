import { AiUsageLog, UsageSource } from "../../models/AiUsageLog";
import { computeCost, TokenUsage } from "./pricing";

export interface UsageContext {
  source: UsageSource;
  messageId?: string | null;
  userId?: string | null;
}

// Never throws: losing a usage row must not fail a document analysis.
export const logUsage = async (
  context: UsageContext | undefined,
  data: { model: string; tokens: TokenUsage; docType?: string | null; latencyMs?: number },
) => {
  if (!context) return;
  try {
    await AiUsageLog.create({
      source: context.source,
      message_id: context.messageId || null,
      doc_type_key: data.docType || null,
      model: data.model,
      input_tokens: data.tokens.input,
      cache_read_tokens: data.tokens.cacheRead,
      cache_write_tokens: data.tokens.cacheWrite,
      output_tokens: data.tokens.output,
      cost_usd: computeCost(data.model, data.tokens),
      latency_ms: data.latencyMs ?? null,
      created_by: context.userId || null,
    });
  } catch (err) {
    console.error("[documentAi] could not log usage:", (err as Error).message);
  }
};
