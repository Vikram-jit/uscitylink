import Anthropic from "@anthropic-ai/sdk";
import sharp from "sharp";
import { DocType } from "../../models/DocType";
import { PreparedFile } from "./fileSource";
import { TokenUsage } from "./pricing";
import { logUsage, UsageContext } from "./usageLog";

// Quick, cheap screen before the full read: a small copy of the photo goes to the low-cost model,
// which only answers "is this one of the document types we read?". Only a yes continues to the full
// read with the admin-selected model, so photos of trucks, selfies and other paperwork cost a
// fraction of a cent instead of a full read.

const client = new Anthropic();

// Big enough to recognise the kind of document, small enough to keep the call cheap
const PRECHECK_MAX_EDGE = 768;
// "other" below this confidence still gets the full read: missing a scale ticket costs more than a read
const SKIP_MIN_CONFIDENCE = 0.6;

export interface PrecheckResult {
  pass: boolean;
  doc_type: string;
  confidence: number;
  model: string;
  input_tokens: number;
  output_tokens: number;
  latency_ms: number;
}

const smallBlock = async (file: PreparedFile): Promise<Anthropic.Beta.BetaContentBlockParam> => {
  if (file.kind === "pdf") {
    return { type: "document", source: { type: "base64", media_type: "application/pdf", data: file.base64 } };
  }
  const small = await sharp(Buffer.from(file.base64, "base64"))
    .resize({ width: PRECHECK_MAX_EDGE, height: PRECHECK_MAX_EDGE, fit: "inside", withoutEnlargement: true })
    .jpeg({ quality: 70 })
    .toBuffer();
  return { type: "image", source: { type: "base64", media_type: "image/jpeg", data: small.toString("base64") } };
};

const buildPrompt = (targets: DocType[]) => {
  const list = targets
    .map((d) =>
      [
        `- ${d.key}: ${d.name}`,
        d.description ? `  What it is: ${d.description}` : "",
        d.identify_hints ? `  How to recognize it: ${d.identify_hints}` : "",
        d.keywords?.length ? `  Words that identify it: ${d.keywords.join(", ")}` : "",
      ]
        .filter(Boolean)
        .join("\n"),
    )
    .join("\n");
  return `You screen photos that truck drivers send to dispatch. Decide only whether the photo is one of the document types below. Do not read field values.

Decide by the words and content on the page, not by layout or logo style; photos may be rotated, blurry or partly cut off. Answer "other" for any other paperwork (bills of lading, receipts, permits, logs) and for photos that are not paperwork.

Document types:
${list}`;
};

export const precheckDocument = async (
  file: PreparedFile,
  targets: DocType[],
  options: { model: string; caption?: string | null; usage?: UsageContext },
): Promise<PrecheckResult> => {
  const started = Date.now();
  const response = await client.beta.messages.create({
    model: options.model,
    max_tokens: 300,
    system: buildPrompt(targets),
    output_config: {
      format: {
        type: "json_schema",
        schema: {
          type: "object",
          properties: {
            doc_type: { type: "string", enum: [...targets.map((d) => d.key), "other"] },
            confidence: { type: "number", description: "0 to 1. How sure you are about doc_type." },
          },
          required: ["doc_type", "confidence"],
          additionalProperties: false,
        },
      },
    },
    messages: [
      {
        role: "user",
        content: [
          await smallBlock(file),
          ...(options.caption ? [{ type: "text" as const, text: `Driver's caption: ${options.caption}` }] : []),
        ],
      },
    ],
  });
  const latency_ms = Date.now() - started;

  const textBlock = response.content.find((b) => b.type === "text");
  if (!textBlock || textBlock.type !== "text") throw new Error("Pre-check returned no answer");
  const parsed = JSON.parse(textBlock.text);
  const docType = String(parsed.doc_type || "other");
  const confidence = Math.max(0, Math.min(1, Number(parsed.confidence) || 0));

  const tokens: TokenUsage = {
    input: response.usage.input_tokens || 0,
    cacheRead: response.usage.cache_read_input_tokens || 0,
    cacheWrite: response.usage.cache_creation_input_tokens || 0,
    output: response.usage.output_tokens || 0,
  };
  await logUsage(options.usage && { ...options.usage, source: "precheck" }, {
    model: response.model,
    tokens,
    docType,
    latencyMs: latency_ms,
  });

  return {
    pass: docType !== "other" || confidence < SKIP_MIN_CONFIDENCE,
    doc_type: docType,
    confidence,
    model: response.model,
    input_tokens: tokens.input + tokens.cacheRead + tokens.cacheWrite,
    output_tokens: tokens.output,
    latency_ms,
  };
};
