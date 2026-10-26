import { isStaffRole } from "../middleware/requireRole";
import { Request, Response } from "express";
import multer from "multer";
import { Op, fn, col, QueryTypes } from "sequelize";
import { DocField, DocType } from "../models/DocType";
import { DocTypeExample } from "../models/DocTypeExample";
import { MessageDocument } from "../models/MessageDocument";
import { Flow } from "../models/Flow";
import { FlowRun } from "../models/FlowRun";
import { Message } from "../models/Message";
import { primarySequelize, secondarySequelize } from "../sequelize";
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
import { decideScaleCheck, recordAdjustment, runScaleAgent } from "../services/scaleAgent/run";
import { buildScaleReport } from "../services/scaleAgent/report";
import { isVerified } from "../services/scaleAgent/rules";
import { EquipmentProfile } from "../models/EquipmentProfile";
import { DriverTrip } from "../models/DriverTrip";
import { ScaleCheck } from "../models/ScaleCheck";
import { WeightRuleSet } from "../models/WeightRuleSet";
import { DEFAULT_AI_MODEL, getAiModelSetting, getPrecheckSettings, getScalePolicy, isScaleAgentEnabled, PRECHECK_MODEL, setAiModel, setPrecheckSettings, setScaleAgentEnabled, setScalePolicy } from "../services/documentAi/settings";
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
  const elseIf = body.else_if || [];
  if (!Array.isArray(actions) || !Array.isArray(elseActions) || !Array.isArray(elseIf)) throw new Error("Actions must be a list");
  elseIf.forEach((branch: any, i: number) => {
    const label = `ELSE IF ${i + 1}`;
    if (!branch || !Array.isArray(branch.actions)) throw new Error(`${label}: actions must be a list`);
    if (!branch.actions.length) throw new Error(`${label}: add at least one action`);
    const err = validateConditionTree(branch.conditions || { all: [] });
    if (err) throw new Error(`${label}: ${err}`);
  });
  const branchActions = elseIf.flatMap((b: any) => b.actions);
  if (!actions.length && !elseActions.length && !branchActions.length) throw new Error("Add at least one action");
  for (const action of [...actions, ...elseActions, ...branchActions]) {
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
    else_if: elseIf.map((b: any) => ({ name: String(b.name || "").trim(), conditions: b.conditions || { all: [] }, actions: b.actions })),
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
      // Template-only: generated from the flow's conditions when its actions run
      { path: "flow.reasons", label: "Why this branch ran (e.g. which axle is over)", type: "text", templateOnly: true },
      { path: "flow.checks", label: "All checked values with limits", type: "text", templateOnly: true },
      { path: "flow.failed", label: "Every failed check on the document", type: "text", templateOnly: true },
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
    // The chat shows a scale ticket's check with the document, without a second request per image
    const check = doc && (doc.corrected_doc_type || doc.doc_type_key) === "scale_ticket"
      ? await ScaleCheck.findOne({ where: { message_id: doc.message_id } })
      : null;
    return res.status(200).json({
      status: true,
      data: doc ? { ...doc.toJSON(), scale_check: check ? (await withNames([check]))[0] : null } : null,
    });
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

    // A corrected scale ticket is judged again on the corrected weights (updates its check, no duplicate)
    const message = await Message.findByPk(doc.message_id);
    if (message) {
      await runScaleAgent(message, doc, { reason: "corrected" }).catch((err) =>
        console.error("[scaleAgent] re-check after correction failed:", err?.message || err),
      );
    }

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
    return res.status(200).json({ status: true, data: { role, isAdmin: role === "admin", isStaff: isStaffRole(role) } });
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
        scaleAgent: { enabled: await isScaleAgentEnabled(), ...(await getScalePolicy()) },
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
    const { model, precheckEnabled, scaleAgentEnabled, scaleReleaseRole, scaleWebhookUrl } = req.body || {};
    if (!model && typeof precheckEnabled !== "boolean" && typeof scaleAgentEnabled !== "boolean" && !scaleReleaseRole && scaleWebhookUrl === undefined) {
      throw new Error("Nothing to update");
    }
    if (scaleReleaseRole || scaleWebhookUrl !== undefined) {
      await setScalePolicy({ releaseRole: scaleReleaseRole, webhookUrl: scaleWebhookUrl }, req.user?.id);
    }
    if (typeof scaleAgentEnabled === "boolean") await setScaleAgentEnabled(scaleAgentEnabled, req.user?.id);
    const saved = model ? await setAiModel(String(model), req.user?.id) : undefined;
    const precheck = await setPrecheckSettings({ enabled: precheckEnabled }, req.user?.id);
    return res.status(200).json({ status: true, message: "Settings updated", data: { model: saved, precheck } });
  } catch (err) {
    return fail(res, err);
  }
};

// ---------- Scale ticket compliance agent ----------

// Driver and decision-maker names for display
const withNames = async (checks: ScaleCheck[]) => {
  const ids = Array.from(new Set(checks.flatMap((c) => [c.driver_id, c.approved_by]).filter(Boolean))) as string[];
  const profiles = ids.length ? await UserProfile.findAll({ where: { id: ids }, attributes: ["id", "username"] }) : [];
  const name = (id?: string | null) => profiles.find((p) => p.id === id)?.username || null;
  return checks.map((c) => ({ ...c.toJSON(), driver_name: name(c.driver_id), approved_by_name: name(c.approved_by) }));
};

export const listScaleChecks = async (req: Request, res: Response): Promise<any> => {
  try {
    const page = Math.max(1, Number(req.query.page) || 1);
    const pageSize = Math.min(100, Number(req.query.pageSize) || 25);
    const where: any = {};
    if (req.query.status) where.status = String(req.query.status);
    if (req.query.approval) where.approval_status = String(req.query.approval);
    const { rows, count } = await ScaleCheck.findAndCountAll({
      where,
      order: [["createdAt", "DESC"]],
      limit: pageSize,
      offset: (page - 1) * pageSize,
    });
    const pending = await ScaleCheck.count({ where: { approval_status: "pending" } });
    return res.status(200).json({
      status: true,
      data: { checks: await withNames(rows), pending, pagination: { page, pageSize, total: count } },
    });
  } catch (err) {
    return fail(res, err, 500);
  }
};

export const getScaleCheckByMessage = async (req: Request, res: Response): Promise<any> => {
  try {
    const check = await ScaleCheck.findOne({ where: { message_id: req.params.messageId } });
    return res.status(200).json({ status: true, data: check ? (await withNames([check]))[0] : null });
  } catch (err) {
    return fail(res, err, 500);
  }
};

const decide = (decision: "approve" | "reject") => async (req: Request, res: Response): Promise<any> => {
  try {
    const check = await ScaleCheck.findByPk(req.params.id);
    if (!check) return fail(res, "Scale check not found", 404);
    const updated = await decideScaleCheck(check, decision, req.user?.id, req.body?.note);
    return res.status(200).json({
      status: true,
      message: decision === "approve" ? "Released — the driver has been told" : "Rejected — the driver has been told",
      data: (await withNames([updated]))[0],
    });
  } catch (err) {
    return fail(res, err);
  }
};
export const approveScaleCheck = decide("approve");
export const rejectScaleCheck = decide("reject");

export const listRuleSets = async (req: Request, res: Response): Promise<any> => {
  try {
    const ruleSets = await WeightRuleSet.findAll({ order: [["jurisdiction", "ASC"], ["road_class", "ASC"], ["version", "DESC"]] });
    const reviewers = await UserProfile.findAll({
      where: { id: ruleSets.map((r) => r.reviewed_by).filter(Boolean) as string[] },
      attributes: ["id", "username"],
    });
    const now = new Date();
    return res.status(200).json({
      status: true,
      data: ruleSets.map((r) => {
        const due = r.reviewed_at ? new Date(r.reviewed_at) : null;
        if (due) due.setMonth(due.getMonth() + (r.review_months || 12));
        return {
          ...r.toJSON(),
          verified: isVerified(r.toJSON() as any, now),
          review_due: due,
          reviewed_by_name: reviewers.find((u) => u.id === r.reviewed_by)?.username || null,
        };
      }),
    });
  } catch (err) {
    return fail(res, err, 500);
  }
};

const ROAD_CLASSES = ["interstate", "state_highway", "local", "all"];

// Rule sets are never edited in place: a change is saved as the next version and the old one retired.
// Without baseId it starts a new jurisdiction/road class (e.g. a state's own rules) at version 1.
// A new version is unreviewed until an admin signs it off (POST /rule-sets/:id/review).
export const createRuleSetVersion = async (req: Request, res: Response): Promise<any> => {
  try {
    const body = req.body || {};
    const base = body.baseId ? await WeightRuleSet.findByPk(body.baseId) : null;
    if (body.baseId && !base) return fail(res, "Rule set not found", 404);
    const jurisdiction = String(base?.jurisdiction || body.jurisdiction || "").trim().toUpperCase();
    const roadClass = String(base?.road_class || body.road_class || "").trim();
    if (!/^[A-Z]{2,3}$/.test(jurisdiction)) throw new Error("Jurisdiction must be a 2-letter state code (or FED)");
    if (!ROAD_CLASSES.includes(roadClass)) throw new Error(`Road class must be one of ${ROAD_CLASSES.join(", ")}`);
    const num = (key: string, min: number, max: number, optional = false) => {
      const raw = body[key] === undefined ? (base as any)?.[key] : body[key];
      if (optional && (raw === null || raw === undefined || raw === "")) return null;
      const v = Number(raw);
      if (!Number.isFinite(v) || v < min || v > max) throw new Error(`${key} must be between ${min} and ${max}`);
      return v;
    };
    if (!String(body.notes || "").trim()) throw new Error("Add a note explaining the change (kept for the audit trail)");
    if (!base && !String(body.citation || "").trim()) throw new Error("Add the legal citation for these limits");
    const next = {
      jurisdiction,
      road_class: roadClass,
      name: String(body.name || base?.name || `${jurisdiction} ${roadClass.replace("_", " ")}`),
      single_axle_lb: num("single_axle_lb", 1000, 100000),
      tandem_lb: num("tandem_lb", 1000, 100000),
      gross_lb: num("gross_lb", 10000, 200000),
      steer_target_lb: num("steer_target_lb", 1000, 100000, true),
      sum_tolerance_lb: num("sum_tolerance_lb", 0, 5000, !!base) ?? 100,
      min_confidence: num("min_confidence", 0, 1, !!base) ?? 0.8,
      kpra_max_ft: num("kpra_max_ft", 20, 80, true),
      bridge_formula: body.bridge_formula === undefined ? base?.bridge_formula ?? true : !!body.bridge_formula,
      review_months: num("review_months", 1, 60, true) ?? base?.review_months ?? 12,
      citation: body.citation ?? base?.citation ?? null,
      source_url: body.source_url ?? base?.source_url ?? null,
      notes: String(body.notes).trim(),
      effective_date: body.effective_date || new Date().toISOString().slice(0, 10),
      reviewed_by: null,
      reviewed_at: null,
    };
    const latest = await WeightRuleSet.max("version", { where: { jurisdiction, road_class: roadClass } });
    const created = await primarySequelize.transaction(async (transaction) => {
      await WeightRuleSet.update({ active: false }, { where: { jurisdiction, road_class: roadClass }, transaction });
      return WeightRuleSet.create({ ...next, version: Number(latest || 0) + 1, active: true }, { transaction });
    });
    return res.status(200).json({
      status: true,
      message: `Saved as ${created.jurisdiction} ${created.road_class} v${created.version} — mark it reviewed once checked against the statute`,
      data: created,
    });
  } catch (err) {
    return fail(res, err);
  }
};

// Named sign-off of a rule version (spec §10: legal review before activation, periodic re-review)
export const reviewRuleSet = async (req: Request, res: Response): Promise<any> => {
  try {
    const rule = await WeightRuleSet.findByPk(req.params.id);
    if (!rule) return fail(res, "Rule set not found", 404);
    await rule.update({ reviewed_by: req.user?.id, reviewed_at: new Date() });
    return res.status(200).json({ status: true, message: `${rule.jurisdiction} v${rule.version} marked reviewed`, data: rule });
  } catch (err) {
    return fail(res, err);
  }
};

// Re-judge a driver's open tickets after their route or equipment changed
const recheckOpenChecks = async (where: any) => {
  const checks = await ScaleCheck.findAll({
    where: { ...where, approval_status: { [Op.notIn]: ["approved", "superseded"] }, createdAt: { [Op.gte]: new Date(Date.now() - 12 * 60 * 60 * 1000) } },
  });
  for (const check of checks) {
    const message = await Message.findByPk(check.message_id);
    const doc = await MessageDocument.findOne({ where: { message_id: check.message_id } });
    if (message && doc) await runScaleAgent(message, doc, { reason: "recheck" }).catch((e) => console.error("[scaleAgent] recheck:", e?.message));
  }
  return checks.length;
};

export const recheckScaleCheck = async (req: Request, res: Response): Promise<any> => {
  try {
    const check = await ScaleCheck.findByPk(req.params.id);
    if (!check) return fail(res, "Scale check not found", 404);
    const message = await Message.findByPk(check.message_id);
    const doc = await MessageDocument.findOne({ where: { message_id: check.message_id } });
    if (!message || !doc) return fail(res, "The ticket message is gone", 404);
    const updated = await runScaleAgent(message, doc, { reason: "recheck" });
    return res.status(200).json({ status: true, message: "Re-checked", data: updated ? (await withNames([updated]))[0] : null });
  } catch (err) {
    return fail(res, err);
  }
};

export const recordScaleAdjustment = async (req: Request, res: Response): Promise<any> => {
  try {
    const check = await ScaleCheck.findByPk(req.params.id);
    if (!check) return fail(res, "Scale check not found", 404);
    const updated = await recordAdjustment(check, req.body || {}, req.user?.id);
    return res.status(200).json({ status: true, message: "Adjustment recorded — the reweigh will be compared with it", data: (await withNames([updated]))[0] });
  } catch (err) {
    return fail(res, err);
  }
};

export const scaleCheckReport = async (req: Request, res: Response): Promise<any> => {
  try {
    const check = await ScaleCheck.findByPk(req.params.id);
    if (!check) return fail(res, "Scale check not found", 404);
    return res.status(200).json({ status: true, data: buildScaleReport(check) });
  } catch (err) {
    return fail(res, err, 500);
  }
};

// ---------- Equipment profiles (admin) ----------

const EQUIPMENT_FIELDS: Record<string, "num" | "int"> = {
  axle_count: "int",
  steer_to_drive_center_ft: "num",
  drive_spread_ft: "num",
  kingpin_to_drive_center_ft: "num",
  fifth_wheel_range_in: "num",
  kpra_ft: "num",
  trailer_spread_ft: "num",
  length_ft: "num",
  hole_spacing_in: "num",
  holes_forward_available: "int",
  holes_back_available: "int",
  steer_rating_lb: "int",
  drive_rating_lb: "int",
  trailer_rating_lb: "int",
  gvwr_lb: "int",
  lb_per_hole: "num",
};

// Standard trailer length: new trailers (add, CSV import, yard sync) start at 53 ft; staff can change it
export const TRAILER_LENGTH_FT = 53;

// Only when the profile is created; an edit or re-import keeps whatever length was entered
const withTrailerDefaults = (data: any) =>
  data.kind === "trailer" && (data.length_ft === undefined || data.length_ft === null)
    ? { ...data, length_ft: TRAILER_LENGTH_FT }
    : data;

const equipmentData = (input: any) => {
  const kind = String(input.kind || "").toLowerCase();
  if (!["tractor", "trailer"].includes(kind)) throw new Error("Kind must be tractor or trailer");
  const unitNumber = String(input.unit_number || "").trim().toUpperCase();
  if (!unitNumber) throw new Error("Unit number is required");
  const data: any = { kind, unit_number: unitNumber, notes: input.notes || null };
  Object.entries(EQUIPMENT_FIELDS).forEach(([key, type]) => {
    const raw = input[key];
    if (raw === undefined) return;
    if (raw === null || raw === "") return (data[key] = null);
    const v = Number(raw);
    if (!Number.isFinite(v) || v < 0) throw new Error(`${unitNumber}: ${key} must be a positive number`);
    data[key] = type === "int" ? Math.round(v) : v;
  });
  return data;
};

export const listEquipment = async (req: Request, res: Response): Promise<any> => {
  try {
    const where: any = { active: true };
    if (req.query.kind) where.kind = String(req.query.kind);
    const profiles = await EquipmentProfile.findAll({ where, order: [["kind", "ASC"], ["unit_number", "ASC"]] });
    return res.status(200).json({ status: true, data: profiles });
  } catch (err) {
    return fail(res, err, 500);
  }
};

export const saveEquipment = async (req: Request, res: Response): Promise<any> => {
  try {
    const data = { ...equipmentData(req.body || {}), active: true, updated_by: req.user?.id };
    const existing = req.params.id
      ? await EquipmentProfile.findByPk(req.params.id)
      : await EquipmentProfile.findOne({ where: { kind: data.kind, unit_number: data.unit_number } });
    const profile = existing ? await existing.update(data) : await EquipmentProfile.create(withTrailerDefaults(data));
    const rechecked = await recheckOpenChecks({ [data.kind === "trailer" ? "trailer_unit" : "tractor_unit"]: data.unit_number });
    return res.status(200).json({ status: true, message: `Saved ${profile.kind} ${profile.unit_number}${rechecked ? ` — re-checked ${rechecked} open ticket(s)` : ""}`, data: profile });
  } catch (err) {
    return fail(res, err);
  }
};

export const deleteEquipment = async (req: Request, res: Response): Promise<any> => {
  try {
    await EquipmentProfile.update({ active: false, updated_by: req.user?.id }, { where: { id: req.params.id } });
    return res.status(200).json({ status: true, message: "Removed" });
  } catch (err) {
    return fail(res, err);
  }
};

// Equipment → "Sync from yard": adds every active truck (as a tractor) and trailer from the yard
// database (yard_management) that has no profile yet, with all measurements empty for staff to fill
// in. Existing profiles are never changed, and units staff removed stay removed.
export const syncEquipmentFromYard = async (req: Request, res: Response): Promise<any> => {
  try {
    const yard = async (sql: string) =>
      (await secondarySequelize.query<{ number: string }>(sql, { type: QueryTypes.SELECT }))
        .map((r) => String(r.number ?? "").trim())
        .filter(Boolean);
    const units: Record<"tractor" | "trailer", string[]> = {
      tractor: await yard("SELECT number FROM trucks WHERE status = 1 AND deleted_at IS NULL"),
      trailer: await yard("SELECT number FROM trailers WHERE is_active = 1 AND deleted_at IS NULL"),
    };

    const existing = await EquipmentProfile.findAll({ attributes: ["kind", "unit_number", "active"] });
    const known = new Map(existing.map((p) => [`${p.kind}:${p.unit_number}`, p.active]));

    const summary: Record<string, { inYard: number; added: number; alreadyThere: number; removedByStaff: number }> = {};
    const rows: any[] = [];
    for (const kind of ["tractor", "trailer"] as const) {
      const unique = [...new Set(units[kind])];
      const s = { inYard: unique.length, added: 0, alreadyThere: 0, removedByStaff: 0 };
      for (const unit_number of unique) {
        const state = known.get(`${kind}:${unit_number}`);
        if (state === undefined) {
          rows.push({
            kind,
            unit_number,
            active: true,
            updated_by: req.user?.id || null,
            ...(kind === "trailer" ? { length_ft: TRAILER_LENGTH_FT } : {}),
          });
          s.added++;
        } else if (state) s.alreadyThere++;
        else s.removedByStaff++;
      }
      summary[kind] = s;
    }
    // ignoreDuplicates: two staff pressing Sync at once can't fail on the (kind, unit_number) key
    if (rows.length) await EquipmentProfile.bulkCreate(rows, { ignoreDuplicates: true });

    const added = summary.tractor.added + summary.trailer.added;
    return res.status(200).json({
      status: true,
      message: added
        ? `Added ${summary.tractor.added} tractor${summary.tractor.added === 1 ? "" : "s"} and ${summary.trailer.added} trailer${summary.trailer.added === 1 ? "" : "s"} — fill in their measurements`
        : "Everything is already in sync",
      data: summary,
    });
  } catch (err) {
    return fail(res, err);
  }
};

// CSV with a header row using the field names above (kind,unit_number,kpra_ft,...)
export const importEquipment = async (req: Request, res: Response): Promise<any> => {
  try {
    const text = String(req.body?.csv || "").trim();
    const lines = text.split(/\r?\n/).filter((l) => l.trim());
    if (lines.length < 2) throw new Error("Paste a header row and at least one row");
    const split = (l: string) => l.split(",").map((c) => c.trim().replace(/^"|"$/g, ""));
    const header = split(lines[0]).map((h) => h.toLowerCase());
    if (!header.includes("kind") || !header.includes("unit_number")) throw new Error("The header must include kind and unit_number");
    const rows = lines.slice(1).map((l, i) => {
      const cells = split(l);
      const obj: any = {};
      header.forEach((h, j) => (obj[h] = cells[j] ?? ""));
      try {
        return { ok: true as const, data: equipmentData(obj) };
      } catch (e: any) {
        return { ok: false as const, error: `Row ${i + 2}: ${e.message}` };
      }
    });
    const errors = rows.filter((r) => !r.ok).map((r: any) => r.error);
    if (errors.length) return res.status(400).json({ status: false, message: errors.slice(0, 10).join("\n") });
    let saved = 0;
    for (const r of rows as any[]) {
      const existing = await EquipmentProfile.findOne({ where: { kind: r.data.kind, unit_number: r.data.unit_number } });
      const data = { ...r.data, active: true, updated_by: req.user?.id };
      if (existing) await existing.update(data);
      else await EquipmentProfile.create(withTrailerDefaults(data));
      saved++;
    }
    return res.status(200).json({ status: true, message: `Imported ${saved} profile(s)` });
  } catch (err) {
    return fail(res, err);
  }
};

// ---------- Driver trips (dispatch) ----------

const US_STATES = new Set(
  "AL AZ AR CA CO CT DE FL GA ID IL IN IA KS KY LA ME MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN TX UT VT VA WA WV WI WY DC".split(" "),
);

const tripData = (input: any) => {
  const segments = (Array.isArray(input.segments) ? input.segments : []).map((s: any, i: number) => {
    const state = String(s?.state || "").trim().toUpperCase();
    if (!US_STATES.has(state)) throw new Error(`Segment ${i + 1}: "${s?.state}" is not a state code`);
    if (!["interstate", "state_highway", "local"].includes(s?.road_class)) throw new Error(`Segment ${i + 1}: choose the road type`);
    return { state, road_class: s.road_class, note: s?.note ? String(s.note) : undefined };
  });
  if (!segments.length) throw new Error("Add at least one route segment (state + road type)");
  const permits = (Array.isArray(input.permits) ? input.permits : []).map((p: any, i: number) => {
    const state = String(p?.state || "").trim().toUpperCase();
    if (!US_STATES.has(state)) throw new Error(`Permit ${i + 1}: "${p?.state}" is not a state code`);
    if (!String(p?.number || "").trim()) throw new Error(`Permit ${i + 1}: permit number is required`);
    if (!/^\d{4}-\d{2}-\d{2}$/.test(String(p?.expires_at || ""))) throw new Error(`Permit ${i + 1}: expiry date is required`);
    const n = (v: any) => (v === null || v === undefined || v === "" ? null : Number(v));
    return { state, number: String(p.number).trim(), expires_at: p.expires_at, gross_lb: n(p.gross_lb), tandem_lb: n(p.tandem_lb), single_axle_lb: n(p.single_axle_lb) };
  });
  return {
    truck: input.truck ? String(input.truck).trim().toUpperCase() : null,
    trailer: input.trailer ? String(input.trailer).trim().toUpperCase() : null,
    origin: input.origin || null,
    destination: input.destination || null,
    cargo: input.cargo || null,
    notes: input.notes || null,
    segments,
    permits,
  };
};

export const getDriverTrip = async (req: Request, res: Response): Promise<any> => {
  try {
    const trip = await DriverTrip.findOne({ where: { driver_id: req.params.driverId, status: "active" }, order: [["createdAt", "DESC"]] });
    return res.status(200).json({ status: true, data: trip });
  } catch (err) {
    return fail(res, err, 500);
  }
};

export const listTrips = async (req: Request, res: Response): Promise<any> => {
  try {
    const trips = await DriverTrip.findAll({ where: { status: "active" }, order: [["updatedAt", "DESC"]], limit: 200 });
    const drivers = await UserProfile.findAll({ where: { id: trips.map((t) => t.driver_id) }, attributes: ["id", "username"] });
    return res.status(200).json({
      status: true,
      data: trips.map((t) => ({ ...t.toJSON(), driver_name: drivers.find((d) => d.id === t.driver_id)?.username || null })),
    });
  } catch (err) {
    return fail(res, err, 500);
  }
};

// One active trip per driver: saving replaces the current one, then open tickets are re-checked
export const saveDriverTrip = async (req: Request, res: Response): Promise<any> => {
  try {
    const driverId = req.params.driverId;
    const data = tripData(req.body || {});
    const current = await DriverTrip.findOne({ where: { driver_id: driverId, status: "active" } });
    const trip = current
      ? await current.update(data)
      : await DriverTrip.create({ ...data, driver_id: driverId, status: "active", created_by: req.user?.id });
    const rechecked = await recheckOpenChecks({ driver_id: driverId });
    return res.status(200).json({ status: true, message: `Route saved${rechecked ? ` — re-checked ${rechecked} open ticket(s)` : ""}`, data: trip });
  } catch (err) {
    return fail(res, err);
  }
};

export const closeDriverTrip = async (req: Request, res: Response): Promise<any> => {
  try {
    await DriverTrip.update({ status: "closed", closed_at: new Date() }, { where: { driver_id: req.params.driverId, status: "active" } });
    return res.status(200).json({ status: true, message: "Trip closed" });
  } catch (err) {
    return fail(res, err);
  }
};
