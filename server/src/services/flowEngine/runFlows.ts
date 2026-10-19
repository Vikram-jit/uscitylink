import { Op } from "sequelize";
import { Flow, FlowTrigger } from "../../models/Flow";
import { FlowRun } from "../../models/FlowRun";
import { evaluate, TraceNode } from "./evaluate";
import { FlowContext } from "./context";
import { ActionResult, FlowAction, previewAction, runAction } from "./actions";
import { DocType } from "../../models/DocType";
import { describeTrace } from "./reasons";

export interface BranchInfo {
  kind: "if" | "else_if" | "else" | "none";
  index?: number;
  name?: string;
}

export interface FlowEvaluation {
  flowId: string;
  flowName: string;
  matched: boolean;
  branch?: BranchInfo;
  skippedReason?: string;
  trace: TraceNode;
  actions: ActionResult[];
}

const isOnCooldown = async (flow: Flow, ctx: FlowContext) => {
  if (!flow.cooldown_minutes) return false;
  const since = new Date(Date.now() - flow.cooldown_minutes * 60 * 1000);
  const recent = await FlowRun.count({
    where: {
      flow_id: flow.id,
      driver_id: ctx.driver.id,
      doc_type_key: ctx.doc.type,
      matched: true,
      createdAt: { [Op.gte]: since },
    },
  });
  return recent > 0;
};

const fieldLabels = async (docType: string | null): Promise<Record<string, string>> => {
  if (!docType) return {};
  const type = await DocType.findOne({ where: { key: docType }, attributes: ["fields"] });
  return Object.fromEntries((type?.fields || []).map((f) => [f.key, f.label]));
};

// IF -> each ELSE IF in order -> ELSE; the first branch that matches runs.
// "ELSE IF"/"ELSE" mean: the right kind of document, but the IF checks failed. A flow for scale tickets
// must not reply to a fuel receipt, so a failed top-level document-type condition runs no branch.
const pickBranch = (flow: Flow, trace: TraceNode, ctx: FlowContext): { branch: BranchInfo; actions: FlowAction[]; trace: TraceNode | null } => {
  if (trace.result) return { branch: { kind: "if" }, actions: flow.actions || [], trace: null };
  const wrongDocType =
    trace.type === "all" && (trace.children || []).some((c) => c.type === "condition" && c.field === "doc.type" && !c.result);
  if (wrongDocType) return { branch: { kind: "none" }, actions: [], trace: null };
  const branches = Array.isArray(flow.else_if) ? flow.else_if : [];
  for (let index = 0; index < branches.length; index++) {
    const branchTrace = evaluate(branches[index].conditions, ctx);
    if (branchTrace.result) {
      return { branch: { kind: "else_if", index, name: branches[index].name || `Else if ${index + 1}` }, actions: branches[index].actions || [], trace: branchTrace };
    }
  }
  return { branch: { kind: "else" }, actions: flow.else_actions || [], trace: null };
};

const planned = (actions: FlowAction[], ctx: FlowContext): ActionResult[] =>
  actions.map((a) => ({ type: a.type, ok: true, planned: true, preview: previewAction(a, ctx) }));

// Evaluates one flow. With dryRun nothing is written or sent — used by the flow tester.
export const evaluateFlow = async (
  flow: Flow,
  ctx: FlowContext,
  options: { dryRun?: boolean } = {},
): Promise<FlowEvaluation> => {
  const trace = evaluate(flow.conditions, ctx);
  const decision = pickBranch(flow, trace, ctx);
  const actionsToRun = decision.actions;
  const branchTrace = decision.trace;
  // Recorded with the run so the log and the tester show which branch ran
  const conditionTrace: TraceNode = { ...trace, branch: decision.branch, branch_trace: branchTrace } as TraceNode;
  const matched = decision.branch.kind === "if" || decision.branch.kind === "else_if";
  const base = { flowId: flow.id, flowName: flow.name, matched, branch: decision.branch, trace: conditionTrace };
  // Templates can use {{flow.reasons}} / {{flow.checks}} / {{flow.failed}}, built from this flow's own conditions
  const actionCtx = actionsToRun.length
    ? { ...ctx, flow: describeTrace(trace, await fieldLabels(ctx.doc.type), branchTrace) }
    : ctx;

  if (options.dryRun) {
    return { ...base, actions: planned(actionsToRun, actionCtx) };
  }

  // Job retries must not send the same reply twice
  const existing = await FlowRun.findOne({ where: { flow_id: flow.id, message_id: ctx.message.id } });
  if (existing) {
    return { ...base, skippedReason: "already_ran", actions: existing.action_results || [] };
  }

  if (matched && (await isOnCooldown(flow, ctx))) {
    await FlowRun.create({
      flow_id: flow.id,
      message_id: ctx.message.id,
      driver_id: ctx.driver.id,
      doc_type_key: ctx.doc.type,
      matched: false,
      shadow: flow.shadow_mode,
      skipped_reason: "cooldown",
      context_snapshot: ctx,
      condition_trace: conditionTrace,
      action_results: [],
    });
    return { ...base, matched: false, skippedReason: "cooldown", actions: [] };
  }

  const run = await FlowRun.create({
    flow_id: flow.id,
    message_id: ctx.message.id,
    driver_id: ctx.driver.id,
    doc_type_key: ctx.doc.type,
    matched,
    shadow: flow.shadow_mode,
    context_snapshot: ctx,
    condition_trace: conditionTrace,
  });

  let results: ActionResult[];
  if (flow.shadow_mode) {
    results = planned(actionsToRun, actionCtx);
  } else {
    results = [];
    for (const action of actionsToRun) {
      results.push(
        await runAction(action, actionCtx, { flowId: flow.id, flowName: flow.name, flowRunId: run.id }),
      );
    }
  }

  const failed = results.filter((r) => !r.ok);
  await run.update({
    action_results: results,
    error: failed.length ? failed.map((f) => `${f.type}: ${f.error}`).join("; ") : null,
  });

  return { ...base, actions: results };
};

export const runFlows = async (
  trigger: FlowTrigger,
  ctx: FlowContext,
  options: { dryRun?: boolean; flowId?: string } = {},
): Promise<FlowEvaluation[]> => {
  const flows = await Flow.findAll({
    where: options.flowId ? { id: options.flowId } : { trigger, active: true },
    order: [
      ["priority", "ASC"],
      ["createdAt", "ASC"],
    ],
  });

  const results: FlowEvaluation[] = [];
  for (const flow of flows) {
    try {
      const result = await evaluateFlow(flow, ctx, options);
      results.push(result);
      if (result.matched && flow.stop_on_match) break;
    } catch (err: any) {
      console.error(`[flowEngine] flow ${flow.id} failed:`, err);
      results.push({
        flowId: flow.id,
        flowName: flow.name,
        matched: false,
        skippedReason: "error",
        trace: { result: false, type: "all" },
        actions: [{ type: "flow", ok: false, error: err?.message || String(err) }],
      });
    }
  }
  return results;
};
