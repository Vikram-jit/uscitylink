import { Request, Response } from "express";
import multer from "multer";
import { Op, fn, col } from "sequelize";
import { DocField, DocType } from "../models/DocType";
import { DocTypeExample } from "../models/DocTypeExample";
import { MessageDocument } from "../models/MessageDocument";
import { Flow } from "../models/Flow";
import { FlowRun } from "../models/FlowRun";
import { Message } from "../models/Message";
import { UserProfile } from "../models/UserProfile";
import Role from "../models/Role";
import {
  analyzePreparedFile,
  getActiveDocTypes,
} from "../services/documentAi/analyzeDocument";
import {
  getAnalyzableKind,
  loadFileForAnalysis,
  prepareBuffer,
  putS3Object,
} from "../services/documentAi/fileSource";
import { buildDocContext, buildFlowContext } from "../services/flowEngine/context";
import { evaluateFlow } from "../services/flowEngine/runFlows";
import { OPERATORS, validateConditionTree } from "../services/flowEngine/evaluate";
import { ACTION_TYPES, validateAction } from "../services/flowEngine/actions";
import { enqueueDocumentAnalysis } from "../queues/documentAnalysisQueue";
import { cleanKeywords, suggestKeywords } from "../services/documentAi/keywords";
import { buildUsageReport, estimateByModel, estimateCallTokens } from "../services/documentAi/usageReport";
import { getLiveFlowDocTypes } from "../services/flowEngine/liveDocTypes";
import { DEFAULT_AI_MODEL, getAiModelSetting, getPrecheckSettings, PRECHECK_MODEL, setAiModel, setPrecheckSettings } from "../services/documentAi/settings";
import { findRate, RATE_CARD } from "../services/documentAi/pricing";

export const automationUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 20 * 1024 * 1024 },
}).single("file");

const LOW_CONFIDENCE = 0.6;
const KEY_PATTERN = /^[a-z][a-z0-9_]{1,63}$/;
const FIELD_TYPES = ["string", "number", "date", "boolean"];

// Turns raw SDK/API errors into something an admin can act on
const friendlyAiError = (err: any): Error => {
  const message = String(err?.message || err);
  if (/authentication|api[_ ]?key|401/i.test(message)) return new Error("The AI key is missing or invalid. Check ANTHROPIC_API_KEY in server/.env.");
  if (/429|rate.?limit|overloaded/i.test(message)) return new Error("The AI service is busy. Please try again in a minute.");
  if (/credit|billing|balance/i.test(message)) return new Error("The Anthropic account has no credit left. Check billing in the Anthropic console.");
  if (/timeout|timed out|ETIMEDOUT|ECONN/i.test(message)) return new Error("Could not reach the AI service. Check the server's internet connection and try again.");
  return new Error(message.length > 300 ? `${message.slice(0, 300)}…` : message);
};

const fail = (res: Response, err: any, status = 400) =>
  res.status(status).json({ status: false, message: err?.message || String(err) });

const pageParams = (req: Request) => {
  const page = Math.max(1, Number(req.query.page) || 1);
  const pageSize = Math.min(100, Math.max(1, Number(req.query.pageSize) || 20));
  return { page, pageSize, offset: (page - 1) * pageSize };
};

const pagination = (page: number, pageSize: number, total: number) => ({
  currentPage: page,
  pageSize,
  total,
  totalPages: Math.ceil(total / pageSize),
});

// ---------- Doc types ----------

const validateDocTypeBody = (body: any) => {
  if (!body.name?.trim()) throw new Error("Name is required");
  if (!KEY_PATTERN.test(body.key || "")) {
    throw new Error("Key must be lowercase letters, numbers and underscores (e.g. scale_ticket)");
  }
  if (body.key === "other") throw new Error('"other" is reserved');
  const fields: DocField[] = body.fields || [];
  if (!Array.isArray(fields) || !fields.length) throw new Error("Add at least one field");
  const seen = new Set<string>();
  for (const f of fields) {
    if (!KEY_PATTERN.test(f.key || "")) throw new Error(`Field key "${f.key}" is invalid`);
    if (seen.has(f.key)) throw new Error(`Field key "${f.key}" is duplicated`);
    if (!FIELD_TYPES.includes(f.type)) throw new Error(`Field "${f.key}" has an invalid type`);
    seen.add(f.key);
  }
  return {
    key: body.key,
    name: body.name.trim(),
    description: body.description || null,
    identify_hints: body.identify_hints || null,
    keywords: cleanKeywords(body.keywords),
    fields: fields.map((f) => ({
      key: f.key,
      label: f.label || f.key,
      type: f.type,
      description: f.description || "",
      required: !!f.required,
    })),
    active: body.active ?? true,
  };
};

export const listDocTypes = async (req: Request, res: Response): Promise<any> => {
  try {
    const docTypes = await DocType.findAll({ order: [["name", "ASC"]] });
    const exampleCounts = await DocTypeExample.findAll({
      attributes: ["doc_type_id", [fn("COUNT", col("id")), "count"]],
      where: { active: true },
      group: ["doc_type_id"],
      raw: true,
    });
    const counts = new Map(exampleCounts.map((e: any) => [e.doc_type_id, Number(e.count)]));
    return res.status(200).json({
      status: true,
      data: docTypes.map((d) => ({ ...d.toJSON(), exampleCount: counts.get(d.id) || 0 })),
    });
  } catch (err) {
    return fail(res, err, 500);
  }
};

export const getDocType = async (req: Request, res: Response): Promise<any> => {
  try {
    const docType = await DocType.findByPk(req.params.id, {
      include: [{ model: DocTypeExample, as: "examples" }],
    });
    if (!docType) return fail(res, "Document type not found", 404);
    return res.status(200).json({ status: true, data: docType });
  } catch (err) {
    return fail(res, err, 500);
  }
};

export const createDocType = async (req: Request, res: Response): Promise<any> => {
  try {
    const data = validateDocTypeBody(req.body);
    if (await DocType.findOne({ where: { key: data.key } })) throw new Error("Key already exists");
    const docType = await DocType.create(data);
    return res.status(201).json({ status: true, message: "Document type created", data: docType });
  } catch (err) {
    return fail(res, err);
  }
};

export const updateDocType = async (req: Request, res: Response): Promise<any> => {
  try {
    const docType = await DocType.findByPk(req.params.id);
    if (!docType) return fail(res, "Document type not found", 404);
    const data = validateDocTypeBody({ ...req.body, key: docType.key });
    await docType.update({ ...data, version: docType.version + 1 });
    return res.status(200).json({ status: true, message: "Document type updated", data: docType });
  } catch (err) {
    return fail(res, err);
  }
};

// Words that show up on documents of this type (after staff/AI classification) but rarely on
// other types. Lets an admin grow the keyword list from real paperwork with one click.
export const suggestDocTypeKeywords = async (req: Request, res: Response): Promise<any> => {
  try {
    const docType = await DocType.findByPk(req.params.id);
    if (!docType) return fail(res, "Document type not found", 404);
    const docs = await MessageDocument.findAll({
      where: { status: "done", text_found: { [Op.ne]: null } },
      attributes: ["doc_type_key", "corrected_doc_type", "text_found"],
      order: [["createdAt", "DESC"]],
      limit: 1000,
    });
    const typeDocs: string[][] = [];
    const otherDocs: string[][] = [];
    docs.forEach((d) => {
      const type = d.corrected_doc_type || d.doc_type_key;
      (type === docType.key ? typeDocs : otherDocs).push(d.text_found || []);
    });
    const suggestions = suggestKeywords(typeDocs, otherDocs, docType.keywords || []);
    return res.status(200).json({ status: true, data: { documents: typeDocs.length, suggestions } });
  } catch (err) {
    return fail(res, err, 500);
  }
};

export const deleteDocType = async (req: Request, res: Response): Promise<any> => {
  try {
    const docType = await DocType.findByPk(req.params.id);
    if (!docType) return fail(res, "Document type not found", 404);
    await docType.destroy();
    return res.status(200).json({ status: true, message: "Document type deleted" });
  } catch (err) {
    return fail(res, err, 500);
  }
};

// ---------- Training examples ----------

// Step 1 of adding an example: upload a sample, get the model's current reading back
export const extractSample = async (req: Request, res: Response): Promise<any> => {
  try {
    if (!req.file) throw new Error("Attach an image or PDF");
    const kind = getAnalyzableKind(req.file.originalname);
    if (!kind) throw new Error("Only images and PDFs can be analyzed");
    const started = Date.now();
    // Read the document first: nothing is uploaded to S3 if the AI call fails
    const analysis = await analyzePreparedFile(await prepareBuffer(req.file.buffer, kind), {
      usage: { source: "sample", userId: req.user?.id },
    });
    const safeName = req.file.originalname.replace(/[^a-zA-Z0-9._-]/g, "_");
    const s3Key = await putS3Object(
      `uscitylink/automation-examples/${Date.now()}-${safeName}`,
      req.file.buffer,
      req.file.mimetype,
    );
    return res
      .status(200)
      .json({ status: true, data: { s3_key: s3Key, analysis, elapsed_ms: Date.now() - started } });
  } catch (err: any) {
    console.error("[automation] extract failed:", err?.message || err);
    return fail(res, friendlyAiError(err));
  }
};

// Step 2: save the admin-corrected values as a training example
export const createExample = async (req: Request, res: Response): Promise<any> => {
  try {
    const docType = await DocType.findByPk(req.params.id);
    if (!docType) return fail(res, "Document type not found", 404);
    const { s3_key, expected_fields } = req.body;
    if (!s3_key) throw new Error("s3_key is required");
    const example = await DocTypeExample.create({
      doc_type_id: docType.id,
      s3_key,
      expected_fields: expected_fields || {},
      source: "upload",
      active: true,
      created_by: req.user?.id,
    });
    return res.status(201).json({ status: true, message: "Example saved", data: example });
  } catch (err) {
    return fail(res, err);
  }
};

export const updateExample = async (req: Request, res: Response): Promise<any> => {
  try {
    const example = await DocTypeExample.findByPk(req.params.exampleId);
    if (!example) return fail(res, "Example not found", 404);
    const { expected_fields, active, doc_type_id } = req.body;
    await example.update({
      ...(expected_fields !== undefined && { expected_fields }),
      ...(active !== undefined && { active: !!active }),
      ...(doc_type_id && { doc_type_id }),
    });
    return res.status(200).json({ status: true, message: "Example updated", data: example });
  } catch (err) {
    return fail(res, err);
  }
};

export const deleteExample = async (req: Request, res: Response): Promise<any> => {
  try {
    await DocTypeExample.destroy({ where: { id: req.params.exampleId } });
    return res.status(200).json({ status: true, message: "Example deleted" });
  } catch (err) {
    return fail(res, err, 500);
  }
};

export const listCandidateExamples = async (req: Request, res: Response): Promise<any> => {
  try {
    const examples = await DocTypeExample.findAll({
      where: { source: "correction", active: false },
      include: [{ model: DocType, as: "docType", attributes: ["id", "key", "name"] }],
      order: [["createdAt", "DESC"]],
      limit: 100,
    });
    return res.status(200).json({ status: true, data: examples });
  } catch (err) {
    return fail(res, err, 500);
  }
};

// ---------- Flows ----------

const validateFlowBody = (body: any) => {
  if (!body.name?.trim()) throw new Error("Name is required");
  if (!["document_analyzed", "attachment_received"].includes(body.trigger)) {
    throw new Error("Invalid trigger");
  }
  const conditionError = validateConditionTree(body.conditions || { all: [] });
  if (conditionError) throw new Error(conditionError);
  const actions = body.actions || [];
  const elseActions = body.else_actions || [];
  if (!Array.isArray(actions) || !Array.isArray(elseActions)) throw new Error("Actions must be a list");
  if (!actions.length && !elseActions.length) throw new Error("Add at least one action");
  for (const action of [...actions, ...elseActions]) {
    const err = validateAction(action);
    if (err) throw new Error(err);
  }
  return {
    name: body.name.trim(),
    description: body.description || null,
    trigger: body.trigger,
    priority: Number(body.priority) || 100,
    active: !!body.active,
    shadow_mode: body.shadow_mode ?? true,
    conditions: body.conditions || { all: [] },
    actions,
    else_actions: elseActions,
    cooldown_minutes: Math.max(0, Number(body.cooldown_minutes) || 0),
    stop_on_match: !!body.stop_on_match,
  };
};

export const listFlows = async (req: Request, res: Response): Promise<any> => {
  try {
    const flows = await Flow.findAll({ order: [["priority", "ASC"], ["createdAt", "ASC"]] });
    const since = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const runStats = await FlowRun.findAll({
      attributes: ["flow_id", "matched", [fn("COUNT", col("id")), "count"]],
      where: { createdAt: { [Op.gte]: since } },
      group: ["flow_id", "matched"],
      raw: true,
    });
    const stats: Record<string, { matched: number; total: number }> = {};
    runStats.forEach((r: any) => {
      stats[r.flow_id] = stats[r.flow_id] || { matched: 0, total: 0 };
      stats[r.flow_id].total += Number(r.count);
      if (r.matched) stats[r.flow_id].matched += Number(r.count);
    });
    return res.status(200).json({
      status: true,
      data: flows.map((f) => ({ ...f.toJSON(), last7Days: stats[f.id] || { matched: 0, total: 0 } })),
    });
  } catch (err) {
    return fail(res, err, 500);
  }
};

export const getFlow = async (req: Request, res: Response): Promise<any> => {
  try {
    const flow = await Flow.findByPk(req.params.id);
    if (!flow) return fail(res, "Flow not found", 404);
    return res.status(200).json({ status: true, data: flow });
  } catch (err) {
    return fail(res, err, 500);
  }
};

export const createFlow = async (req: Request, res: Response): Promise<any> => {
  try {
    const flow = await Flow.create({
      ...validateFlowBody(req.body),
      created_by: req.user?.id,
      updated_by: req.user?.id,
    });
    return res.status(201).json({ status: true, message: "Flow created", data: flow });
  } catch (err) {
    return fail(res, err);
  }
};

export const updateFlow = async (req: Request, res: Response): Promise<any> => {
  try {
    const flow = await Flow.findByPk(req.params.id);
    if (!flow) return fail(res, "Flow not found", 404);
    await flow.update({ ...validateFlowBody(req.body), updated_by: req.user?.id });
    return res.status(200).json({ status: true, message: "Flow updated", data: flow });
  } catch (err) {
    return fail(res, err);
  }
};

export const toggleFlow = async (req: Request, res: Response): Promise<any> => {
  try {
    const flow = await Flow.findByPk(req.params.id);
    if (!flow) return fail(res, "Flow not found", 404);
    const { active, shadow_mode } = req.body;
    await flow.update({
      ...(active !== undefined && { active: !!active }),
      ...(shadow_mode !== undefined && { shadow_mode: !!shadow_mode }),
      updated_by: req.user?.id,
    });
    return res.status(200).json({ status: true, message: "Flow updated", data: flow });
  } catch (err) {
    return fail(res, err);
  }
};

export const deleteFlow = async (req: Request, res: Response): Promise<any> => {
  try {
    await Flow.destroy({ where: { id: req.params.id } });
    return res.status(200).json({ status: true, message: "Flow deleted" });
  } catch (err) {
    return fail(res, err, 500);
  }
};

// Dry run: evaluates a saved or unsaved flow against an uploaded file or an existing
// chat message. Nothing is written or sent.
export const testFlow = async (req: Request, res: Response): Promise<any> => {
  try {
    const body = typeof req.body.flow === "string" ? JSON.parse(req.body.flow) : req.body.flow;
    const flow = req.body.flowId
      ? await Flow.findByPk(req.body.flowId)
      : Flow.build({ ...validateFlowBody(body || {}), id: "unsaved" });
    if (!flow) return fail(res, "Flow not found", 404);

    let ctx;
    let analysis = null;
    if (req.file) {
      const kind = getAnalyzableKind(req.file.originalname);
      if (!kind) throw new Error("Only images and PDFs can be analyzed");
      analysis = await analyzePreparedFile(await prepareBuffer(req.file.buffer, kind), {
        usage: { source: "test", userId: req.user?.id },
      });
      ctx = {
        doc: buildDocContext({
          doc_type_key: analysis.doc_type,
          confidence: analysis.confidence,
          image_quality: analysis.image_quality,
          fields: analysis.fields,
          notes: analysis.notes,
        }),
        driver: { id: "test", name: "Test Driver", number: "0000", phone: null, truck: "0000", yard_id: null },
        message: { id: "test", channel_id: "test", caption: null, url: null },
        time: { hour: new Date().getHours(), weekday: "", date: new Date().toISOString().slice(0, 10) },
      };
    } else if (req.body.messageId) {
      const message = await Message.findByPk(req.body.messageId);
      if (!message) return fail(res, "Message not found", 404);
      let doc: any = await MessageDocument.findOne({ where: { message_id: message.id } });
      if (!doc && message.url) {
        const file = await loadFileForAnalysis(message.url);
        if (file) {
          analysis = await analyzePreparedFile(file, {
            caption: message.body,
            usage: { source: "test", messageId: message.id, userId: req.user?.id },
          });
          doc = {
            doc_type_key: analysis.doc_type,
            confidence: analysis.confidence,
            image_quality: analysis.image_quality,
            fields: analysis.fields,
            notes: analysis.notes,
          };
        }
      }
      ctx = await buildFlowContext(message, doc);
    } else {
      throw new Error("Upload a file or choose a message to test with");
    }

    const result = await evaluateFlow(flow, ctx as any, { dryRun: true });
    return res.status(200).json({ status: true, data: { context: ctx, analysis, result } });
  } catch (err) {
    return fail(res, err);
  }
};

// ---------- Logs, review, stats ----------

export const listRuns = async (req: Request, res: Response): Promise<any> => {
  try {
    const { page, pageSize, offset } = pageParams(req);
    const where: any = {};
    if (req.query.flowId) where.flow_id = req.query.flowId;
    if (req.query.matched !== undefined && req.query.matched !== "") {
      where.matched = req.query.matched === "true";
    }
    if (req.query.errorsOnly === "true") where.error = { [Op.ne]: null };
    const { rows, count } = await FlowRun.findAndCountAll({
      where,
      include: [{ model: Flow, as: "flow", attributes: ["id", "name"] }],
      order: [["createdAt", "DESC"]],
      limit: pageSize,
      offset,
    });
    return res.status(200).json({
      status: true,
      data: { runs: rows, pagination: pagination(page, pageSize, count) },
    });
  } catch (err) {
    return fail(res, err, 500);
  }
};

export const reviewQueue = async (req: Request, res: Response): Promise<any> => {
  try {
    const { page, pageSize, offset } = pageParams(req);
    const { rows, count } = await MessageDocument.findAndCountAll({
      where: {
        corrected_by: null,
        [Op.or]: [
          { status: "failed" },
          { status: "done", confidence: { [Op.lt]: LOW_CONFIDENCE } },
          { status: "done", image_quality: { [Op.ne]: "good" } },
        ],
      },
      include: [
        {
          model: Message,
          as: "message",
          attributes: ["id", "url", "thumbnail", "body", "channelId", "userProfileId", "messageTimestampUtc"],
          include: [{ model: UserProfile, as: "sender", attributes: ["id", "username"] }],
        },
      ],
      order: [["createdAt", "DESC"]],
      limit: pageSize,
      offset,
    });
    return res.status(200).json({
      status: true,
      data: { documents: rows, pagination: pagination(page, pageSize, count) },
    });
  } catch (err) {
    return fail(res, err, 500);
  }
};

export const automationStats = async (req: Request, res: Response): Promise<any> => {
  try {
    const days = Math.min(90, Number(req.query.days) || 7);
    const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
    const byType = await MessageDocument.findAll({
      attributes: [
        "doc_type_key",
        "status",
        [fn("COUNT", col("id")), "count"],
        [fn("AVG", col("confidence")), "avgConfidence"],
        [fn("SUM", col("input_tokens")), "inputTokens"],
        [fn("SUM", col("output_tokens")), "outputTokens"],
      ],
      where: { createdAt: { [Op.gte]: since } },
      group: ["doc_type_key", "status"],
      raw: true,
    });
    const corrections = await MessageDocument.count({
      where: { createdAt: { [Op.gte]: since }, corrected_by: { [Op.ne]: null } },
    });
    const runs = await FlowRun.count({ where: { createdAt: { [Op.gte]: since }, matched: true } });
    return res.status(200).json({ status: true, data: { days, byType, corrections, matchedRuns: runs } });
  } catch (err) {
    return fail(res, err, 500);
  }
};

// Everything the flow builder needs to render its pickers
export const builderMeta = async (req: Request, res: Response): Promise<any> => {
  try {
    const docTypes = await getActiveDocTypes();
    const contextFields = [
      { path: "doc.type", label: "Document type", type: "enum", options: [...docTypes.map((d) => d.key), "other"] },
      { path: "doc.confidence", label: "AI confidence (0–1)", type: "number" },
      { path: "doc.quality", label: "Photo quality", type: "enum", options: ["good", "poor", "unreadable"] },
      { path: "doc.is_document", label: "Is paperwork", type: "boolean" },
      { path: "doc.notes", label: "AI notes", type: "string" },
      { path: "driver.name", label: "Driver name", type: "string" },
      { path: "driver.number", label: "Driver number", type: "string" },
      { path: "driver.truck", label: "Truck number", type: "string" },
      { path: "message.caption", label: "Driver caption", type: "string" },
      { path: "time.hour", label: "Hour of day (0–23)", type: "number" },
      { path: "time.weekday", label: "Weekday", type: "enum", options: ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"] },
      ...docTypes.flatMap((d) =>
        (d.fields || []).map((f) => ({
          path: `doc.fields.${f.key}`,
          label: `${d.name} › ${f.label}`,
          type: f.type,
          docType: d.key,
        })),
      ),
    ];
    return res.status(200).json({
      status: true,
      data: { operators: OPERATORS, actionTypes: ACTION_TYPES, contextFields },
    });
  } catch (err) {
    return fail(res, err, 500);
  }
};

// ---------- Staff-level: per-message document data and corrections ----------

export const getMessageDocument = async (req: Request, res: Response): Promise<any> => {
  try {
    const doc = await MessageDocument.findOne({ where: { message_id: req.params.messageId } });
    return res.status(200).json({ status: true, data: doc });
  } catch (err) {
    return fail(res, err, 500);
  }
};

export const getMessageDocuments = async (req: Request, res: Response): Promise<any> => {
  try {
    const ids = String(req.query.messageIds || "").split(",").filter(Boolean).slice(0, 200);
    const docs = ids.length ? await MessageDocument.findAll({ where: { message_id: ids } }) : [];
    return res.status(200).json({ status: true, data: docs });
  } catch (err) {
    return fail(res, err, 500);
  }
};

export const correctMessageDocument = async (req: Request, res: Response): Promise<any> => {
  try {
    const doc = await MessageDocument.findByPk(req.params.id);
    if (!doc) return fail(res, "Document not found", 404);
    const { doc_type_key, fields, save_as_example } = req.body;
    await doc.update({
      corrected_by: req.user?.id,
      corrected_doc_type: doc_type_key || doc.doc_type_key,
      corrected_fields: fields || null,
    });

    // Corrections become inactive candidate examples; a admin promotes the good ones
    if (save_as_example && doc.media_key) {
      const docType = await DocType.findOne({ where: { key: doc_type_key || doc.doc_type_key } });
      if (docType) {
        await DocTypeExample.create({
          doc_type_id: docType.id,
          s3_key: doc.media_key,
          expected_fields: { ...(doc.fields || {}), ...(fields || {}) },
          source: "correction",
          active: false,
          created_by: req.user?.id,
        });
      }
    }
    return res.status(200).json({ status: true, message: "Correction saved", data: doc });
  } catch (err) {
    return fail(res, err);
  }
};

export const reanalyzeMessage = async (req: Request, res: Response): Promise<any> => {
  try {
    const doc = await MessageDocument.findOne({ where: { message_id: req.params.messageId } });
    if (doc && doc.status !== "pending") await doc.update({ status: "pending", error: null });
    enqueueDocumentAnalysis(req.params.messageId, { force: true });
    return res.status(200).json({ status: true, message: "Queued for analysis" });
  } catch (err) {
    return fail(res, err, 500);
  }
};

export const automationMe = async (req: Request, res: Response): Promise<any> => {
  try {
    const profile = await UserProfile.findByPk(req.user?.id, {
      include: [{ model: Role, as: "role" }],
    });
    const role = profile?.role?.name || null;
    return res.status(200).json({ status: true, data: { role, isAdmin: role === "admin" } });
  } catch (err) {
    return fail(res, err, 500);
  }
};

export const usageReport = async (req: Request, res: Response): Promise<any> => {
  try {
    const days = [7, 30, 90].includes(Number(req.query.days)) ? Number(req.query.days) : 30;
    return res.status(200).json({ status: true, data: await buildUsageReport(days) });
  } catch (err) {
    return fail(res, err, 500);
  }
};

// ---------- Settings: which AI model reads documents ----------

export const getAutomationSettings = async (req: Request, res: Response): Promise<any> => {
  try {
    const estimate = await estimateCallTokens();
    const perDoc = estimateByModel(estimate);
    return res.status(200).json({
      status: true,
      data: {
        ai: { ...(await getAiModelSetting()), envDefault: DEFAULT_AI_MODEL },
        precheck: {
          ...(await getPrecheckSettings()),
          docTypes: (await getActiveDocTypes()).map((d) => ({ key: d.key, name: d.name })),
          live: await getLiveFlowDocTypes(),
          // ~1,100 input tokens (768px photo + short prompt) and ~30 output tokens per quick check
          estimatedPerCheck: (() => {
            const r = findRate(PRECHECK_MODEL).rate;
            return Math.round(((1100 * r.input + 30 * r.output) / 1_000_000) * 1_000_000) / 1_000_000;
          })(),
        },
        models: RATE_CARD.map((r) => {
          const e = perDoc.find((m) => m.model === r.model)!;
          // Realistic per-document cost with the current prompt/examples
          const perDocument = estimate.cachingLikely ? (e.warm * 7 + e.cold * 3) / 10 : e.uncached;
          return { ...r, estimatedPerDocument: Math.round(perDocument * 1_000_000) / 1_000_000 };
        }),
      },
    });
  } catch (err) {
    return fail(res, err, 500);
  }
};

export const updateAutomationSettings = async (req: Request, res: Response): Promise<any> => {
  try {
    const { model, precheckEnabled } = req.body || {};
    if (!model && typeof precheckEnabled !== "boolean") throw new Error("Nothing to update");
    const saved = model ? await setAiModel(String(model), req.user?.id) : undefined;
    const precheck = await setPrecheckSettings({ enabled: precheckEnabled }, req.user?.id);
    return res.status(200).json({ status: true, message: "Settings updated", data: { model: saved, precheck } });
  } catch (err) {
    return fail(res, err);
  }
};
