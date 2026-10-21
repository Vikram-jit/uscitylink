import { RuleLimits } from "./evaluate";

// Which limits control a ticket (spec §5): for every route segment take federal (on Interstate) plus
// the state's rules for that road class, apply valid permits, and keep the LOWEST limit across the
// whole route. A segment without a state rule, or with an unreviewed one, means the route cannot be
// verified (ROUTE_REVIEW_REQUIRED). Pure function: rule rows and the trip are passed in.

export interface RuleRow {
  id: string;
  jurisdiction: string;
  road_class: string;
  version: number;
  single_axle_lb: number;
  tandem_lb: number;
  gross_lb: number;
  steer_target_lb?: number | null;
  sum_tolerance_lb: number;
  min_confidence: number;
  kpra_max_ft?: number | null;
  bridge_formula?: boolean;
  reviewed_at?: Date | string | null;
  review_months?: number;
  citation?: string | null;
  source_url?: string | null;
}

export interface Segment {
  state: string;
  road_class: string;
}

export interface Permit {
  state: string;
  number: string;
  expires_at: string;
  gross_lb?: number | null;
  tandem_lb?: number | null;
  single_axle_lb?: number | null;
}

type LimitKey = "single_axle_lb" | "tandem_lb" | "gross_lb";
const LIMIT_KEYS: LimitKey[] = ["single_axle_lb", "tandem_lb", "gross_lb"];

export interface SegmentRules {
  state: string;
  road_class: string;
  rules: string[];
  missing: boolean;
  unverified: string[];
  permit?: string | null;
  expired_permit?: string | null;
  limits: Partial<Record<LimitKey, number>> & { kpra_max_ft?: number | null };
}

export interface ControllingLimits extends RuleLimits {
  kpra_max_ft: number | null;
  bridge_formula: boolean;
  route_known: boolean;
  segments: SegmentRules[];
  sources: Partial<Record<LimitKey | "kpra_max_ft", string>>;
  missing: string[];
  unverified: string[];
  rule_labels: string[];
}

export const label = (r: RuleRow) => `${r.jurisdiction}${r.road_class !== "interstate" ? ` ${r.road_class}` : ""} v${r.version}`;

// Reviewed, and the review is not older than review_months
export const isVerified = (r: RuleRow, today: Date) => {
  if (!r.reviewed_at) return false;
  const due = new Date(r.reviewed_at);
  due.setMonth(due.getMonth() + (r.review_months || 12));
  return due >= today;
};

const findRule = (rows: RuleRow[], jurisdiction: string, roadClass: string) =>
  rows.find((r) => r.jurisdiction === jurisdiction && r.road_class === roadClass) ||
  rows.find((r) => r.jurisdiction === jurisdiction && r.road_class === "all");

export const resolveLimits = (
  rows: RuleRow[],
  trip: { segments?: Segment[] | null; permits?: Permit[] | null } | null,
  today = new Date(),
): ControllingLimits => {
  const federal = findRule(rows, "FED", "interstate") || rows[0];
  if (!federal) throw new Error("No active weight rule set");
  const base = {
    jurisdiction: "FED",
    steer_target_lb: federal.steer_target_lb,
    sum_tolerance_lb: federal.sum_tolerance_lb,
    min_confidence: federal.min_confidence,
  };
  const todayStr = today.toISOString().slice(0, 10);

  const segmentsIn = (trip?.segments || []).filter((s) => s?.state && s?.road_class);
  if (!segmentsIn.length) {
    // Route unknown: federal Interstate baseline only, and the route must be reviewed
    return {
      ...base,
      single_axle_lb: federal.single_axle_lb,
      tandem_lb: federal.tandem_lb,
      gross_lb: federal.gross_lb,
      kpra_max_ft: federal.kpra_max_ft ?? null,
      bridge_formula: federal.bridge_formula !== false,
      route_known: false,
      segments: [],
      sources: { single_axle_lb: label(federal), tandem_lb: label(federal), gross_lb: label(federal) },
      missing: [],
      unverified: isVerified(federal, today) ? [] : [label(federal)],
      rule_labels: [label(federal)],
    };
  }

  const segments: SegmentRules[] = segmentsIn.map((seg) => {
    const state = seg.state.toUpperCase();
    const applicable: RuleRow[] = [];
    if (seg.road_class === "interstate" && federal) applicable.push(federal);
    const stateRule = findRule(rows, state, seg.road_class);
    if (stateRule) applicable.push(stateRule);
    const limits: SegmentRules["limits"] = {};
    LIMIT_KEYS.forEach((k) => {
      const values = applicable.map((r) => r[k]).filter((v) => Number.isFinite(v));
      if (values.length) limits[k] = Math.min(...values);
    });
    const kpras = applicable.map((r) => r.kpra_max_ft).filter((v): v is number => typeof v === "number");
    limits.kpra_max_ft = kpras.length ? Math.min(...kpras) : null;

    // A valid permit for this state replaces the limits it names (spec §5: permits and expiry)
    const permits = (trip?.permits || []).filter((p) => p.state?.toUpperCase() === state);
    const valid = permits.find((p) => p.expires_at && p.expires_at >= todayStr);
    const expired = permits.find((p) => p.expires_at && p.expires_at < todayStr);
    if (valid) {
      LIMIT_KEYS.forEach((k) => {
        const v = Number(valid[k]);
        if (Number.isFinite(v) && v > 0) limits[k] = v;
      });
    }
    return {
      state,
      road_class: seg.road_class,
      rules: applicable.map(label),
      missing: !stateRule,
      unverified: applicable.filter((r) => !isVerified(r, today)).map(label),
      permit: valid ? valid.number : null,
      expired_permit: !valid && expired ? expired.number : null,
      limits,
    };
  });

  const controlling: Partial<Record<LimitKey, number>> = {};
  const sources: ControllingLimits["sources"] = {};
  LIMIT_KEYS.forEach((k) => {
    segments.forEach((s) => {
      const v = s.limits[k];
      if (v !== undefined && (controlling[k] === undefined || v < (controlling[k] as number))) {
        controlling[k] = v;
        sources[k] = `${s.state} ${s.road_class}${s.permit ? ` (permit ${s.permit})` : ""}: ${s.rules.join(" + ")}`;
      }
    });
  });
  let kpraMax: number | null = null;
  segments.forEach((s) => {
    if (typeof s.limits.kpra_max_ft === "number" && (kpraMax === null || s.limits.kpra_max_ft < kpraMax)) {
      kpraMax = s.limits.kpra_max_ft;
      sources.kpra_max_ft = `${s.state} ${s.road_class}: ${s.rules.join(" + ")}`;
    }
  });

  const used = new Set(segments.flatMap((s) => s.rules));
  return {
    ...base,
    jurisdiction: Array.from(new Set(segments.map((s) => s.state))).join("/"),
    single_axle_lb: controlling.single_axle_lb ?? federal.single_axle_lb,
    tandem_lb: controlling.tandem_lb ?? federal.tandem_lb,
    gross_lb: controlling.gross_lb ?? federal.gross_lb,
    kpra_max_ft: kpraMax,
    bridge_formula: rows.filter((r) => used.has(label(r))).some((r) => r.bridge_formula !== false),
    route_known: true,
    segments,
    sources,
    missing: segments.filter((s) => s.missing).map((s) => `${s.state} ${s.road_class.replace("_", " ")}`),
    unverified: Array.from(new Set(segments.flatMap((s) => s.unverified))),
    rule_labels: Array.from(used),
  };
};
