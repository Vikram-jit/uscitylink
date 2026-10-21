import { ScaleCheck } from "../../models/ScaleCheck";

// The spec §9 JSON output contract for one scale check, with the audit fields the spec asks to log
// (source image, extracted values, model and rule-set versions, calculations, suggested moves,
// driver actions, dispatcher decision).
export const buildScaleReport = (check: ScaleCheck, extra: { approval_user?: string | null; reweigh_ticket_id?: string | null } = {}) => {
  const rules = check.controlling_rules || {};
  return {
    ticket_id: check.ticket_number || null,
    scale_check_id: check.id,
    message_id: check.message_id,
    image_url: rules.image_url || null,
    measured_weights: check.measured_weights,
    confidence: check.confidence,
    image_quality: check.image_quality,
    route_segments: rules.segments || [],
    route_known: !!rules.route_known,
    controlling_rules_with_sources: {
      limits: rules.limits || null,
      sources: rules.sources || {},
      rule_sets: rules.rule_labels || [],
      missing_rules: rules.missing || [],
      unreviewed_rules: rules.unverified || [],
    },
    axle_spacing: rules.axle_positions_ft || null,
    bridge_groups: check.bridge_results || [],
    kpra_ft: check.kpra?.kpra_ft ?? null,
    kpra_limit_ft: check.kpra?.max_ft ?? null,
    group_overages_lb: check.group_overages_lb || {},
    headroom_lb: check.headroom_lb || {},
    feasible_adjustments: check.feasible_adjustments || [],
    assumptions: check.assumptions || [],
    required_actions: check.required_actions || [],
    status: check.status,
    flags: check.flags || [],
    driver_message: check.driver_message,
    adjustment_made: check.adjustment_made || null,
    prediction: check.prediction || null,
    approval_status: check.approval_status,
    approval_user: extra.approval_user ?? check.approved_by ?? null,
    approved_at: check.approved_at || null,
    approval_note: check.approval_note || null,
    previous_check_id: check.previous_check_id || null,
    reweigh_ticket_id: extra.reweigh_ticket_id ?? check.reweigh_check_id ?? null,
    tractor_unit: check.tractor_unit || null,
    trailer_unit: check.trailer_unit || null,
    trip_id: check.trip_id || null,
    model_version: check.model || null,
    rule_set_version: check.rule_set_version || null,
    created_at: check.createdAt,
    updated_at: check.updatedAt,
  };
};
