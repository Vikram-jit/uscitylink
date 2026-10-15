import { Op } from "sequelize";
import { Flow, FlowTrigger } from "../../models/Flow";
import { FlowRun } from "../../models/FlowRun";
import { evaluate, TraceNode } from "./evaluate";
import { FlowContext } from "./context";
import { ActionResult, FlowAction, previewAction, runAction } from "./actions";

export interface FlowEvaluation {
  flowId: string;
  flowName: string;
  matched: boolean;
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

const planned = (actions: FlowAction[], ctx: FlowContext): ActionResult[] =>
  actions.map((a) => ({ type: a.type, ok: true, planned: true, preview: previewAction(a, ctx) }));

// Evaluates one flow. With dryRun nothing is written or sent — used by the flow tester.
export const evaluateFlow = async (
  flow: Flow,
  ctx: FlowContext,
  options: { dryRun?: boolean } = {},
): Promise<FlowEvaluation> => {
  const trace = evaluate(flow.conditions, ctx);
  const actionsToRun: FlowAction[] = (trace.result ? flow.actions : flow.else_actions) || [];
  const base = { flowId: flow.id, flowName: flow.name, matched: trace.result, trace };

  if (options.dryRun) {
    return { ...base, actions: planned(actionsToRun, ctx) };
  }

  // Job retries must not send the same reply twice
  const existing = await FlowRun.findOne({ where: { flow_id: flow.id, message_id: ctx.message.id } });
  if (existing) {
    return { ...base, skippedReason: "already_ran", actions: existing.action_results || [] };
  }

  if (trace.result && (await isOnCooldown(flow, ctx))) {
    await FlowRun.create({
      flow_id: flow.id,
      message_id: ctx.message.id,
      driver_id: ctx.driver.id,
      doc_type_key: ctx.doc.type,
      matched: false,
      shadow: flow.shadow_mode,
      skipped_reason: "cooldown",
      context_snapshot: ctx,
      condition_trace: trace,
      action_results: [],
    });
    return { ...base, matched: false, skippedReason: "cooldown", actions: [] };
  }

  const run = await FlowRun.create({
    flow_id: flow.id,
    message_id: ctx.message.id,
    driver_id: ctx.driver.id,
    doc_type_key: ctx.doc.type,
    matched: trace.result,
    shadow: flow.shadow_mode,
    context_snapshot: ctx,
    condition_trace: trace,
  });

  let results: ActionResult[];
  if (flow.shadow_mode) {
    results = planned(actionsToRun, ctx);
  } else {
    results = [];
    for (const action of actionsToRun) {
      results.push(
        await runAction(action, ctx, { flowId: flow.id, flowName: flow.name, flowRunId: run.id }),
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
