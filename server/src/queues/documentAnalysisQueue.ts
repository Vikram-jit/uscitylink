import Queue, { Job } from "bull";
import { redisHost, redisPassword, redisPort } from "../redis";
import { Message } from "../models/Message";
import { MessageDocument } from "../models/MessageDocument";
import { getSocketInstance } from "../sockets/socket";
import {
  analyzePreparedFile,
  NonRetryableAnalysisError,
} from "../services/documentAi/analyzeDocument";
import { getAnalyzableKind, loadFileForAnalysis } from "../services/documentAi/fileSource";
import { buildFlowContext } from "../services/flowEngine/context";
import { runFlows } from "../services/flowEngine/runFlows";

export const isAutomationEnabled = () =>
  process.env.AUTOMATION_ENABLED === "true" && !!process.env.ANTHROPIC_API_KEY;

export const documentAnalysisQueue = new Queue<{ messageId: string }>("documentAnalysisQueue", {
  redis: {
    host: redisHost,
    port: redisPort,
    password: redisPassword,
    maxRetriesPerRequest: null,
    enableReadyCheck: false,
    retryStrategy: (times) => Math.min(times * 50, 2000),
  },
});

// Safe to call from any upload path: never throws, dedupes by message id
export const enqueueDocumentAnalysis = (messageId?: string | null, options: { force?: boolean } = {}) => {
  if (!messageId || !isAutomationEnabled()) return;
  documentAnalysisQueue
    .add(
      { messageId },
      {
        // A forced re-run needs a fresh job id; bull ignores duplicates of a kept job
        jobId: options.force ? `doc-${messageId}-${Date.now()}` : `doc-${messageId}`,
        attempts: 3,
        backoff: { type: "exponential", delay: 5000 },
        removeOnComplete: 1000,
        removeOnFail: 1000,
      },
    )
    .catch((err) => console.error("[documentAnalysis] enqueue failed:", err));
};

const emitToStaff = (event: string, payload: any) => {
  const io = getSocketInstance();
  Object.keys(global.staffActiveChannel || {}).forEach((staffId) => {
    const socket = global.userSockets[staffId];
    if (socket) io.to(socket.id).emit(event, payload);
  });
};

export const processDocumentAnalysis = async (job: Job<{ messageId: string }>) => {
  const message = await Message.findByPk(job.data.messageId);
  // Only driver → staff attachments are analyzed
  if (!message || !message.url || message.messageDirection !== "R" || message.is_automated) return;

  const kind = getAnalyzableKind(message.url);
  const [doc] = await MessageDocument.findOrCreate({
    where: { message_id: message.id },
    defaults: { message_id: message.id, media_key: message.url, status: "pending" },
  });

  if (job.attemptsMade === 0) {
    const attachmentCtx = await buildFlowContext(message, null);
    await runFlows("attachment_received", attachmentCtx);
  }

  if (!kind) {
    await doc.update({ status: "skipped", error: "Not an image or PDF" });
    return;
  }
  if (doc.status === "done") return;

  try {
    const file = await loadFileForAnalysis(message.url);
    if (!file) {
      await doc.update({ status: "skipped", error: "Unsupported file" });
      return;
    }
    const analysis = await analyzePreparedFile(file, {
      caption: message.body,
      usage: { source: "message", messageId: message.id },
    });
    await doc.update({
      status: "done",
      doc_type_key: analysis.doc_type,
      confidence: analysis.confidence,
      image_quality: analysis.image_quality,
      fields: analysis.fields,
      notes: analysis.notes,
      text_found: analysis.text_found,
      classified_by: analysis.classified_by,
      matched_keywords: analysis.matched_keywords,
      error: null,
      model: analysis.model,
      input_tokens: analysis.input_tokens,
      output_tokens: analysis.output_tokens,
      latency_ms: analysis.latency_ms,
    });
  } catch (err: any) {
    const isLastAttempt =
      err instanceof NonRetryableAnalysisError || job.attemptsMade + 1 >= (job.opts.attempts || 1);
    if (isLastAttempt) {
      await doc.update({ status: "failed", error: err?.message || String(err) });
      emitToStaff("document_analyzed", doc.toJSON());
    }
    if (err instanceof NonRetryableAnalysisError) {
      await job.discard();
    }
    throw err;
  }

  emitToStaff("document_analyzed", doc.toJSON());

  const ctx = await buildFlowContext(message, doc);
  await runFlows("document_analyzed", ctx);
};

documentAnalysisQueue.process(3, processDocumentAnalysis);
documentAnalysisQueue.on("failed", (job, err) => {
  console.error(`[documentAnalysis] job ${job.id} failed:`, err?.message);
});
documentAnalysisQueue.on("error", (err) => {
  console.error("[documentAnalysis] queue error:", err);
});
