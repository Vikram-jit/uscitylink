import Anthropic from "@anthropic-ai/sdk";
import dotenv from "dotenv";
import { DocType } from "../../models/DocType";
import { DocTypeExample } from "../../models/DocTypeExample";
import { buildExtractionSchema, parseFields } from "./buildSchema";
import { buildSystemPrompt } from "./prompt";
import { loadFileForAnalysis, PreparedFile } from "./fileSource";
import { decideDocType, scoreKeywords } from "./keywords";
import { logUsage, UsageContext } from "./usageLog";
import { TokenUsage } from "./pricing";

dotenv.config();

export const AI_MODEL = process.env.AI_MODEL || "claude-opus-5-5";
// Each example photo costs roughly 2,000 input tokens on every analysis (cheap only while cached),
// so these limits are the main cost lever. Override in .env.
export const MAX_EXAMPLES_PER_TYPE = Number(process.env.AI_MAX_EXAMPLES_PER_TYPE ?? 2);
export const MAX_EXAMPLES_TOTAL = Number(process.env.AI_MAX_EXAMPLES_TOTAL ?? 12);

const SUPPORTS_FALLBACK = !/haiku/i.test(AI_MODEL);

const client = new Anthropic();

export interface DocumentAnalysis {
  is_document: boolean;
  doc_type: string;
  confidence: number;
  image_quality: "good" | "poor" | "unreadable";
  notes: string | null;
  fields: Record<string, any>;
  text_found: string[];
  classified_by: "ai" | "keywords" | "ai+keywords";
  matched_keywords: string[];
  model: string;
  input_tokens: number;
  output_tokens: number;
  latency_ms: number;
}

// A refusal or truncated answer will not get better by retrying the same input
export class NonRetryableAnalysisError extends Error {}

const fileBlock = (file: PreparedFile): Anthropic.Beta.BetaContentBlockParam =>
  file.kind === "pdf"
    ? { type: "document", source: { type: "base64", media_type: "application/pdf", data: file.base64 } }
    : { type: "image", source: { type: "base64", media_type: "image/jpeg", data: file.base64 } };

// Example images rarely change; keep them in memory so each analysis does not
// re-download them from S3.
const exampleCache = new Map<string, PreparedFile>();

const buildExampleBlocks = async (docTypes: DocType[]) => {
  const examples = await DocTypeExample.findAll({
    where: { active: true, doc_type_id: docTypes.map((d) => d.id) },
    order: [["updatedAt", "DESC"]],
  });

  const perType = new Map<string, number>();
  const blocks: Anthropic.Beta.BetaContentBlockParam[] = [];
  let used = 0;

  for (const example of examples) {
    if (used >= MAX_EXAMPLES_TOTAL) break;
    const count = perType.get(example.doc_type_id) || 0;
    if (count >= MAX_EXAMPLES_PER_TYPE) continue;
    const docType = docTypes.find((d) => d.id === example.doc_type_id);
    if (!docType) continue;

    try {
      let file = exampleCache.get(example.id + example.updatedAt.getTime());
      if (!file) {
        file = (await loadFileForAnalysis(example.s3_key)) || undefined;
        if (!file) continue;
        exampleCache.set(example.id + example.updatedAt.getTime(), file);
      }
      blocks.push({ type: "text", text: `Example ${used + 1} — this is a "${docType.key}" document:` });
      blocks.push(fileBlock(file));
      blocks.push({
        type: "text",
        text: `Correct extraction for example ${used + 1}: ${JSON.stringify(example.expected_fields)}`,
      });
      perType.set(example.doc_type_id, count + 1);
      used++;
    } catch (err) {
      console.warn(`[documentAi] skipping example ${example.id}:`, (err as Error).message);
    }
  }

  // Cache everything up to and including the examples; only the target image changes per call
  if (blocks.length) {
    (blocks[blocks.length - 1] as any).cache_control = { type: "ephemeral" };
  }
  return blocks;
};

export const getActiveDocTypes = () =>
  DocType.findAll({ where: { active: true }, order: [["key", "ASC"]] });

interface RawResult {
  parsed: any;
  model: string;
  input_tokens: number;
  output_tokens: number;
  latency_ms: number;
  tokens: TokenUsage;
}

const   callModel = async (
  file: PreparedFile,
  docTypes: DocType[],
  exampleBlocks: Anthropic.Beta.BetaContentBlockParam[],
  options: { caption?: string | null; knownType?: string },
): Promise<RawResult> => {

  const started = Date.now();
  const response = await client.beta.messages.create({
    model: AI_MODEL,
    max_tokens: 8000,
    // Server-side refusal fallback is not offered on Haiku models
    ...(SUPPORTS_FALLBACK ? { betas: ["server-side-fallback-2026-07-01"], fallbacks: "default" as const } : {}),
    system: [
      { type: "text", text: buildSystemPrompt(docTypes, options.knownType), cache_control: { type: "ephemeral" } },
    ],
    output_config: {
      effort: "low",
      format: { type: "json_schema", schema: buildExtractionSchema(docTypes) },
    },
    messages: [
      {
        role: "user",
        content: [
          ...exampleBlocks,
          { type: "text", text: "Now classify and extract this document sent by a driver:" },
          fileBlock(file),
          ...(options.caption
            ? [{ type: "text" as const, text: `Driver's caption: ${options.caption}` }]
            : []),
        ],
      },
    ],
  });
  const latency_ms = Date.now() - started;

  if (response.stop_reason === "refusal") {
    throw new NonRetryableAnalysisError("Model declined to analyze this file");
  }
  if (response.stop_reason === "max_tokens") {
    throw new NonRetryableAnalysisError("Model output was cut off (max_tokens)");
  }

  const textBlock = response.content.find((b) => b.type === "text");
  if (!textBlock || textBlock.type !== "text") {
    throw new Error("Model returned no JSON output");
  }
  const parsed = JSON.parse(textBlock.text);

  return {
    parsed,
    model: response.model,
    input_tokens:
      (response.usage.input_tokens || 0) +
      (response.usage.cache_read_input_tokens || 0) +
      (response.usage.cache_creation_input_tokens || 0),
    output_tokens: response.usage.output_tokens || 0,
    latency_ms,
    tokens: {
      input: response.usage.input_tokens || 0,
      cacheRead: response.usage.cache_read_input_tokens || 0,
      cacheWrite: response.usage.cache_creation_input_tokens || 0,
      output: response.usage.output_tokens || 0,
    },
  };
};

export const analyzePreparedFile = async (
  file: PreparedFile,
  options: { docTypes?: DocType[]; caption?: string | null; usage?: UsageContext } = {},
): Promise<DocumentAnalysis> => {
  const docTypes = options.docTypes || (await getActiveDocTypes());
  const exampleBlocks = await buildExampleBlocks(docTypes);

  let raw = await callModel(file, docTypes, exampleBlocks, options);
  const textFound: string[] = Array.isArray(raw.parsed.text_found)
    ? raw.parsed.text_found.map((w: any) => String(w)).slice(0, 40)
    : [];
  const aiConfidence = Math.max(0, Math.min(1, Number(raw.parsed.confidence) || 0));

  // Second opinion from the words on the page: independent of layout and photo style
  const hits = scoreKeywords(textFound, raw.parsed.notes || null, docTypes);
  const decision = decideDocType({ doc_type: raw.parsed.doc_type, confidence: aiConfidence }, hits);

  await logUsage(options.usage, {
    model: raw.model,
    tokens: raw.tokens,
    docType: decision.doc_type,
    latencyMs: raw.latency_ms,
  });

  let tokensIn = raw.input_tokens;
  let tokensOut = raw.output_tokens;
  let latency = raw.latency_ms;
  if (decision.needsReread) {
    // The words point to a different type than the AI chose; read the fields for that type
    const second = await callModel(file, docTypes, exampleBlocks, { ...options, knownType: decision.doc_type });
    await logUsage(options.usage && { ...options.usage, source: "reread" }, {
      model: second.model,
      tokens: second.tokens,
      docType: decision.doc_type,
      latencyMs: second.latency_ms,
    });
    raw = { ...raw, parsed: { ...second.parsed, text_found: textFound } };
    tokensIn += second.input_tokens;
    tokensOut += second.output_tokens;
    latency += second.latency_ms;
  }

  return {
    is_document: decision.doc_type !== "other" || !!raw.parsed.is_document,
    doc_type: decision.doc_type,
    confidence: decision.confidence,
    image_quality: raw.parsed.image_quality,
    notes: raw.parsed.notes ? String(raw.parsed.notes) : null,
    fields: parseFields(
      docTypes.find((d) => d.key === decision.doc_type),
      raw.parsed.fields,
    ),
    text_found: textFound,
    classified_by: decision.classified_by,
    matched_keywords: decision.matched_keywords,
    model: raw.model,
    input_tokens: tokensIn,
    output_tokens: tokensOut,
    latency_ms: latency,
  };
};
