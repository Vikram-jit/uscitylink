import { Op } from "sequelize";
import { Message } from "../../models/Message";
import { MessageDocument } from "../../models/MessageDocument";
import { ScaleCheck } from "../../models/ScaleCheck";
import { WeightRuleSet } from "../../models/WeightRuleSet";
import { EquipmentProfile } from "../../models/EquipmentProfile";
import { DriverTrip } from "../../models/DriverTrip";
import { UserProfile } from "../../models/UserProfile";
import Role from "../../models/Role";
import { getSocketInstance } from "../../sockets/socket";
import { buildFlowContext, FlowContext } from "../flowEngine/context";
import { runAction, sendWebhook } from "../flowEngine/actions";
import { getScalePolicy, isScaleAgentEnabled } from "../documentAi/settings";
import { Equipment, evaluateScaleTicket, Weights } from "./evaluate";
import { buildDriverMessage, buildStaffAlert } from "./messages";
import { resolveLimits, RuleRow } from "./rules";
import { buildLayout } from "./bridge";
import { comparePrediction, updateLbPerHole } from "./prediction";
import { buildScaleReport } from "./report";

// Orchestrates one scale ticket: read the (corrected) weights, load the driver's route, the
// tractor/trailer profiles and the rules for every segment, judge the ticket, save the audit row,
// link and compare reweighs, message the driver, alert dispatch and post the report.

export const SCALE_DOC_TYPE = "scale_ticket";
// A new ticket from the same driver within this window is treated as a reweigh of the last one
const REWEIGH_WINDOW_MS = 12 * 60 * 60 * 1000;
const AGENT_INFO = { flowId: "scale-agent", flowName: "Scale ticket agent", flowRunId: null };
// Statuses a dispatcher may release; the review ones need a note (they take responsibility)
export const RELEASABLE = ["PASS_PRELIMINARY", "ROUTE_REVIEW_REQUIRED", "BRIDGE_REVIEW"];

const toNumber = (v: any): number | null => {
  if (v === null || v === undefined || v === "") return null;
  const n = typeof v === "number" ? v : Number(String(v).replace(/[^0-9.\-]/g, ""));
  return Number.isFinite(n) ? n : null;
};

const unit = (v: any) => (v === null || v === undefined ? "" : String(v).trim().toUpperCase());

export const weightsFrom = (fields: Record<string, any>): Weights => ({
  steer: toNumber(fields.steer_axle_lb),
  drive: toNumber(fields.drive_axle_lb),
  trailer: toNumber(fields.trailer_axle_lb),
  gross: toNumber(fields.gross_lb),
});

export const getActiveRuleSets = async (): Promise<RuleRow[]> =>
  (await WeightRuleSet.findAll({ where: { active: true }, order: [["version", "DESC"]] })).map((r) => r.toJSON() as RuleRow);

export const getActiveTrip = (driverId: string) =>
  DriverTrip.findOne({ where: { driver_id: driverId, status: "active" }, order: [["createdAt", "DESC"]] });

const findProfile = async (kind: "tractor" | "trailer", ...candidates: any[]) => {
  for (const c of candidates.map(unit).filter(Boolean)) {
    const profile = await EquipmentProfile.findOne({ where: { kind, unit_number: c, active: true } });
    if (profile) return profile;
  }
  return null;
};

export const emitScaleCheck = (check: ScaleCheck) => {
  const io = getSocketInstance();
  Object.keys(global.staffActiveChannel || {}).forEach((staffId) => {
    const socket = global.userSockets[staffId];
    if (socket) io.to(socket.id).emit("scale_check_updated", check.toJSON());
  });
};

export const notifyDriver = (ctx: FlowContext, body: string) =>
  runAction({ type: "reply_driver", template: body }, ctx, AGENT_INFO);

// Spec §9 report to the client's system, if a webhook is configured (never blocks the check)
const postReport = async (check: ScaleCheck, event: string) => {
  const { webhookUrl } = await getScalePolicy();
  if (!webhookUrl) return;
  sendWebhook(webhookUrl, { event, report: buildScaleReport(check), sent_at: new Date().toISOString() }).catch((err) =>
    console.error("[scaleAgent] report webhook failed:", err?.message || err),
  );
};

export const runScaleAgent = async (
  message: Message,
  doc: MessageDocument,
  options: { reason?: "analyzed" | "corrected" | "recheck" } = {},
): Promise<ScaleCheck | null> => {
  if (!(await isScaleAgentEnabled())) return null;
  const ctx = await buildFlowContext(message, doc);
  if (ctx.doc.type !== SCALE_DOC_TYPE) return null;

  const fields = ctx.doc.fields || {};
  const weights = weightsFrom(fields);
  const trip = await getActiveTrip(ctx.driver.id);
  const tractor = await findProfile("tractor", fields.tractor_number, ctx.driver.truck, trip?.truck);
  const trailer = await findProfile("trailer", fields.trailer_number, trip?.trailer);
  const equipment: Equipment = { tractor: tractor?.toJSON() as any, trailer: trailer?.toJSON() as any };

  const rows = await getActiveRuleSets();
  if (!rows.length) throw new Error("No active weight rule set (run the scale agent migration)");
  const limits = resolveLimits(rows, trip ? { segments: trip.segments, permits: trip.permits } : null);
  const result = evaluateScaleTicket(weights, limits, { confidence: ctx.doc.confidence, quality: ctx.doc.quality }, equipment);
  const layout = buildLayout(equipment.tractor, equipment.trailer);

  const existing = await ScaleCheck.findOne({ where: { message_id: message.id } });
  // A reweigh: the driver's most recent check that dispatch has not released yet
  const previous = existing
    ? existing.previous_check_id
      ? await ScaleCheck.findByPk(existing.previous_check_id)
      : null
    : await ScaleCheck.findOne({
        where: {
          driver_id: ctx.driver.id,
          message_id: { [Op.ne]: message.id },
          approval_status: { [Op.ne]: "approved" },
          createdAt: { [Op.gte]: new Date(Date.now() - REWEIGH_WINDOW_MS) },
        },
        order: [["createdAt", "DESC"]],
      });

  // Reweigh feedback: did the recorded adjustment do what was predicted? Learn lb-per-hole from it.
  let prediction = null;
  if (previous?.adjustment_made && previous.measured_weights) {
    prediction = comparePrediction(previous.measured_weights, weights, previous.adjustment_made, trailer?.lb_per_hole ?? null);
    if (prediction.mismatch) result.flags.push("PREDICTION_MISMATCH");
    if (prediction.learned_lb_per_hole && trailer && !existing) {
      await trailer.update(updateLbPerHole(trailer.lb_per_hole, trailer.lb_per_hole_samples, prediction.learned_lb_per_hole));
    }
  }

  const driverMessage = buildDriverMessage(result, weights, limits, {
    reweigh: !!previous,
    predictionNote: prediction?.mismatch ? prediction.note : null,
  });
  const data = {
    message_id: message.id,
    message_document_id: doc.id,
    driver_id: ctx.driver.id,
    channel_id: ctx.message.channel_id,
    truck: ctx.driver.truck,
    ticket_number: fields.ticket_number ? String(fields.ticket_number) : null,
    measured_weights: weights,
    confidence: ctx.doc.confidence,
    image_quality: ctx.doc.quality,
    rule_set_id: rows.find((r) => r.jurisdiction === "FED")?.id || rows[0].id,
    rule_set_version: limits.rule_labels.join(" + ").slice(0, 64),
    model: doc.model || null,
    status: result.status,
    flags: Array.from(new Set(result.flags)),
    group_overages_lb: result.overages,
    headroom_lb: result.headroom,
    feasible_adjustments: result.adjustments,
    assumptions: result.assumptions,
    required_actions: result.required_actions,
    driver_message: driverMessage,
    previous_check_id: previous?.id || null,
    trip_id: trip?.id || null,
    tractor_unit: tractor?.unit_number || unit(fields.tractor_number) || ctx.driver.truck || null,
    trailer_unit: trailer?.unit_number || unit(fields.trailer_number) || trip?.trailer || null,
    controlling_rules: {
      route_known: limits.route_known,
      segments: limits.segments,
      limits: {
        single_axle_lb: limits.single_axle_lb,
        tandem_lb: limits.tandem_lb,
        gross_lb: limits.gross_lb,
        steer_target_lb: limits.steer_target_lb,
        kpra_max_ft: limits.kpra_max_ft,
      },
      sources: limits.sources,
      rule_labels: limits.rule_labels,
      missing: limits.missing,
      unverified: limits.unverified,
      axle_positions_ft: "positions" in layout ? layout.positions.map((p) => Math.round(p * 100) / 100) : null,
      equipment_missing: "missing" in layout ? layout.missing : [],
      image_url: ctx.message.url
        ? `https://${process.env.BUCKET_NAME || "ciity-sms"}.s3.us-west-1.amazonaws.com/${ctx.message.url}`
        : null,
    },
    bridge_results: result.bridge.groups,
    kpra: result.kpra,
    prediction,
    // Re-judged (e.g. after a correction): any earlier release decision no longer applies
    approval_status: RELEASABLE.includes(result.status) ? ("pending" as const) : ("not_required" as const),
    approved_by: null,
    approved_at: null,
    approval_note: null,
  };

  const statusChanged = !existing || existing.status !== result.status || existing.driver_message !== driverMessage;
  const check = existing ? await existing.update(data) : await ScaleCheck.create(data);
  // The reweigh replaces the earlier ticket: it no longer waits for a release decision
  if (previous && previous.reweigh_check_id !== check.id) {
    await previous.update({
      reweigh_check_id: check.id,
      ...(previous.approval_status === "pending" ? { approval_status: "superseded" as const } : {}),
    });
    emitScaleCheck(previous);
  }

  // Tell the driver and dispatch only when the outcome is new, so a correction that changes nothing stays quiet
  if (statusChanged) {
    await notifyDriver(ctx, driverMessage);
    const alert = buildStaffAlert(result, weights, ctx.driver.name, ctx.driver.truck);
    await runAction({ type: "alert_staff", severity: alert.severity, title: alert.title, template: alert.body }, ctx, AGENT_INFO);
    const tags =
      result.status === "PASS_PRELIMINARY"
        ? ["scale-awaiting-approval"]
        : ["OCR_UNCERTAIN", "ROUTE_REVIEW_REQUIRED", "BRIDGE_REVIEW"].includes(result.status)
          ? ["scale-review"]
          : ["overweight"];
    await runAction({ type: "tag", tags }, ctx, AGENT_INFO);
  }

  emitScaleCheck(check);
  await postReport(
    check,
    options.reason === "corrected" ? "scale_check.corrected" : options.reason === "recheck" ? "scale_check.rechecked" : "scale_check.created",
  );
  return check;
};

const roleOf = async (profileId: string) => {
  const profile = await UserProfile.findByPk(profileId, { include: [{ model: Role, as: "role" }] });
  return (profile as any)?.role?.name || null;
};

// Dispatcher decision on a check. Only releasable statuses; the review statuses need a note;
// the release role comes from Automation settings (spec §9: role-based approvals).
export const decideScaleCheck = async (
  check: ScaleCheck,
  decision: "approve" | "reject",
  staffId: string,
  note?: string | null,
): Promise<ScaleCheck> => {
  if (check.approval_status === "superseded") {
    throw new Error("This ticket was replaced by a reweigh. Review the newer ticket instead.");
  }
  if (decision === "approve" && !RELEASABLE.includes(check.status)) {
    throw new Error("Only a ticket within the weight limits can be released. Ask the driver for a new ticket.");
  }
  if (decision === "approve" && check.status !== "PASS_PRELIMINARY" && !note?.trim()) {
    throw new Error("The route or axle spacing is not verified. Add a note saying what you checked before releasing.");
  }
  if (decision === "reject" && !note?.trim()) throw new Error("Add a note for the driver explaining what to do");
  const { releaseRole } = await getScalePolicy();
  if (decision === "approve" && releaseRole === "admin" && (await roleOf(staffId)) !== "admin") {
    throw new Error("Only admins can release loads (Automation → Settings).");
  }

  await check.update({
    approval_status: decision === "approve" ? "approved" : "rejected",
    approved_by: staffId,
    approved_at: new Date(),
    approval_note: note?.trim() || null,
  });

  const message = await Message.findByPk(check.message_id);
  const doc = message ? await MessageDocument.findOne({ where: { message_id: message.id } }) : null;
  if (message) {
    const ctx = await buildFlowContext(message, doc);
    await notifyDriver(
      ctx,
      decision === "approve"
        ? `✅ Dispatch reviewed your scale ticket and released you to depart.${note?.trim() ? `\n\nNote: ${note.trim()}` : ""}`
        : `⛔ Dispatch did not release this scale ticket.\n\n${note!.trim()}\n\nDo not depart until dispatch confirms.`,
    );
  }
  emitScaleCheck(check);
  await postReport(check, decision === "approve" ? "scale_check.released" : "scale_check.rejected");
  return check;
};

// Dispatch records what the driver changed (spec §8 step 9) so the reweigh can be compared with it
export const recordAdjustment = async (
  check: ScaleCheck,
  input: { action: string; holes?: number | string | null; parked_confirmed: boolean },
  staffId: string,
) => {
  const actions = ["tandems_forward", "tandems_backward", "fifth_wheel_forward", "fifth_wheel_back", "rework_cargo"];
  if (!actions.includes(input.action)) throw new Error("Choose what was adjusted");
  if (!input.parked_confirmed) throw new Error("Confirm the driver was parked and the vehicle secured before adjusting");
  const holes = input.holes === null || input.holes === undefined || input.holes === "" ? null : Number(input.holes);
  if (holes !== null && (!Number.isInteger(holes) || holes < 0 || holes > 30)) throw new Error("Holes must be a whole number");
  await check.update({
    adjustment_made: { action: input.action, holes, parked_confirmed: true, by: staffId, at: new Date().toISOString() },
  });
  emitScaleCheck(check);
  await postReport(check, "scale_check.adjustment_recorded");
  return check;
};
