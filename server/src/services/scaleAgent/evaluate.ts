// Deterministic scale ticket check (client spec "AI CAT Scale Agent Training Spec" v1.0).
// Pure arithmetic: no AI and no database here. The AI only reads the ticket; every number and
// decision below is reproducible from the stored inputs (weights, rules, route, equipment).
//
// Order of checks:
//   1. Can the reading be trusted?             -> OCR_UNCERTAIN
//   2. Gross over the controlling limit?        -> OVER_GROSS (no slide can fix it)
//   3. Axle / rating / bridge / KPRA violation  -> ADJUST_AND_REWEIGH (with a feasible move, or rework)
//   4. Weights fine, but route/rules unverified -> ROUTE_REVIEW_REQUIRED
//      ... or bridge formula not checkable       -> BRIDGE_REVIEW
//   5. Everything verified                      -> PASS_PRELIMINARY
// Even a pass is preliminary: a dispatcher must release the load.

import { BridgeGroup, buildLayout, checkBridge, TractorLayout, TrailerLayout } from "./bridge";

export type Group = "steer" | "drive" | "trailer" | "gross";
export const GROUPS: Group[] = ["steer", "drive", "trailer", "gross"];
export const GROUP_LABELS: Record<Group, string> = {
  steer: "Steer axle",
  drive: "Drive axle",
  trailer: "Trailer axle",
  gross: "Gross weight",
};

export type Weights = Record<Group, number | null>;

export interface RuleLimits {
  jurisdiction: string;
  single_axle_lb: number;
  tandem_lb: number;
  gross_lb: number;
  steer_target_lb?: number | null;
  sum_tolerance_lb: number;
  min_confidence: number;
  // Present when resolved from a route (see rules.ts)
  kpra_max_ft?: number | null;
  bridge_formula?: boolean;
  route_known?: boolean;
  missing?: string[];
  unverified?: string[];
}

export interface Equipment {
  tractor?: (TractorLayout & { steer_rating_lb?: number | null; drive_rating_lb?: number | null }) | null;
  trailer?:
    | (TrailerLayout & {
        trailer_rating_lb?: number | null;
        hole_spacing_in?: number | null;
        holes_forward_available?: number | null;
        holes_back_available?: number | null;
        lb_per_hole?: number | null;
      })
    | null;
}

export type ScaleStatus =
  | "PASS_PRELIMINARY"
  | "OVER_GROSS"
  | "ADJUST_AND_REWEIGH"
  | "OCR_UNCERTAIN"
  | "ROUTE_REVIEW_REQUIRED"
  | "BRIDGE_REVIEW";

export interface Issue {
  group: Group | "sum" | "bridge" | "kpra";
  kind:
    | "missing"
    | "over_limit"
    | "over_rating"
    | "over_target"
    | "sum_mismatch"
    | "low_confidence"
    | "poor_image"
    | "bridge"
    | "kpra";
  value?: number | null;
  limit?: number;
  over?: number;
  detail?: string;
}

export type AdjustmentAction = "tandems_forward" | "tandems_backward" | "fifth_wheel_forward" | "fifth_wheel_back" | "rework_cargo";

export interface Adjustment {
  action: AdjustmentAction;
  from?: Group;
  to?: Group;
  needed_lb?: number;
  available_lb?: number;
  // Only when this trailer's lb-per-hole has been measured (never invented, spec §6)
  holes?: number | null;
  kpra_after_ft?: number | null;
  reason?: "weight" | "kpra";
}

export interface KpraResult {
  required: boolean;
  max_ft: number | null;
  kpra_ft: number | null;
  over_ft: number | null;
  verified: boolean;
}

export interface ScaleResult {
  status: ScaleStatus;
  flags: string[];
  issues: Issue[];
  overages: Partial<Record<Group, number>>;
  headroom: Partial<Record<Group, number>>;
  adjustments: Adjustment[];
  feasible: boolean;
  assumptions: string[];
  required_actions: string[];
  sum_of_groups: number | null;
  bridge: { checked: boolean; missing: string[]; groups: BridgeGroup[] };
  kpra: KpraResult;
}

const ratingFor = (group: Group, eq?: Equipment | null) =>
  group === "steer" ? eq?.tractor?.steer_rating_lb : group === "drive" ? eq?.tractor?.drive_rating_lb : group === "trailer" ? eq?.trailer?.trailer_rating_lb : null;

const legalFor = (group: Group, rules: RuleLimits) =>
  group === "gross" ? rules.gross_lb : group === "steer" ? rules.single_axle_lb : rules.tandem_lb;

const assumptionsFor = (rules: RuleLimits, bridgeChecked: boolean, kpra: KpraResult, eq?: Equipment | null, holesKnown?: boolean) => {
  const list: string[] = [];
  if (!rules.route_known) list.push("Route not entered: judged against the federal Interstate baseline only.");
  if (rules.missing?.length) list.push(`No state rules on file for: ${rules.missing.join(", ")}.`);
  if (rules.unverified?.length) list.push(`Rules not reviewed (or review overdue): ${rules.unverified.join(", ")}.`);
  if (!bridgeChecked) list.push("Federal Bridge Formula not evaluated (axle spacing unknown).");
  else list.push("Bridge formula uses an even split within each tandem (the ticket only shows group totals).");
  if (kpra.required && !kpra.verified) list.push("Kingpin-to-rear-axle (KPRA) not verified (trailer data missing).");
  if (!rules.route_known) list.push("KPRA and state length rules depend on the route.");
  if (!eq?.tractor?.steer_rating_lb && !eq?.tractor?.drive_rating_lb && !eq?.trailer?.trailer_rating_lb) {
    list.push("Axle, tire and wheel ratings not on file.");
  }
  if (!holesKnown) list.push("Weight shift per tandem hole not measured for this trailer: no hole count given.");
  return list;
};

export const evaluateScaleTicket = (
  weights: Weights,
  rules: RuleLimits,
  read: { confidence: number | null; quality: string | null },
  equipment?: Equipment | null,
): ScaleResult => {
  const issues: Issue[] = [];
  const flags = new Set<string>();
  const routeKnown = rules.route_known === true;
  const routeIssues = !routeKnown || !!rules.missing?.length || !!rules.unverified?.length;

  // KPRA: required when any rule on the route limits it; unknown route = cannot be ruled out
  const kpraMax = rules.kpra_max_ft ?? null;
  const kpraFt = equipment?.trailer?.kpra_ft ?? null;
  const kpra: KpraResult = {
    required: kpraMax !== null || !routeKnown,
    max_ft: kpraMax,
    kpra_ft: kpraFt,
    over_ft: kpraMax !== null && kpraFt !== null && kpraFt > kpraMax ? Math.round((kpraFt - kpraMax) * 100) / 100 : null,
    verified: kpraMax === null ? routeKnown : kpraFt !== null,
  };
  const lbPerHole = equipment?.trailer?.lb_per_hole || null;
  const empty = { checked: false, missing: [] as string[], groups: [] as BridgeGroup[] };

  // 1. Can the reading be trusted? Never guess (spec §1): uncertain input stops here.
  GROUPS.forEach((group) => {
    if (weights[group] === null || !Number.isFinite(weights[group] as number)) issues.push({ group, kind: "missing" });
  });
  if (read.confidence !== null && read.confidence < rules.min_confidence) {
    issues.push({ group: "sum", kind: "low_confidence", value: read.confidence, limit: rules.min_confidence });
  }
  if (read.quality === "poor" || read.quality === "unreadable") issues.push({ group: "sum", kind: "poor_image" });
  const complete = GROUPS.every((g) => weights[g] !== null);
  const sum = complete ? (weights.steer as number) + (weights.drive as number) + (weights.trailer as number) : null;
  if (sum !== null && Math.abs(sum - (weights.gross as number)) > rules.sum_tolerance_lb) {
    // Catches misread digits (e.g. 33,980 read as 38,980): the three groups must add up to gross
    issues.push({ group: "sum", kind: "sum_mismatch", value: sum, limit: weights.gross as number, over: sum - (weights.gross as number) });
  }
  if (issues.length) {
    ["OCR_UNCERTAIN", "HUMAN_REVIEW"].forEach((f) => flags.add(f));
    return {
      status: "OCR_UNCERTAIN",
      flags: [...flags],
      issues,
      overages: {},
      headroom: {},
      adjustments: [],
      feasible: false,
      assumptions: assumptionsFor(rules, false, kpra, equipment, !!lbPerHole),
      required_actions: ["Send a clear photo of the whole ticket", "Dispatch reviews the ticket", "Do not depart until dispatch confirms"],
      sum_of_groups: sum,
      bridge: empty,
      kpra,
    };
  }

  // 2. Axle groups against the controlling legal limit and the equipment rating (lowest wins)
  const w = weights as Record<Group, number>;
  const overages: Partial<Record<Group, number>> = {};
  const headroom: Partial<Record<Group, number>> = {};
  GROUPS.forEach((group) => {
    const legal = legalFor(group, rules);
    const rating = ratingFor(group, equipment);
    const limit = rating && rating < legal ? rating : legal;
    if (w[group] > legal) {
      overages[group] = w[group] - Math.min(legal, limit);
      issues.push({ group, kind: "over_limit", value: w[group], limit: legal, over: w[group] - legal });
    } else if (w[group] > limit) {
      overages[group] = w[group] - limit;
      issues.push({ group, kind: "over_rating", value: w[group], limit, over: w[group] - limit });
      flags.add("EQUIPMENT_LIMIT");
    } else {
      headroom[group] = limit - w[group];
    }
  });
  // The steer planning target is company policy, not law (spec §1); it narrows steer headroom
  const steerTarget = rules.steer_target_lb || null;
  if (steerTarget && !overages.steer) {
    if (w.steer > steerTarget) {
      issues.push({ group: "steer", kind: "over_target", value: w.steer, limit: steerTarget, over: w.steer - steerTarget });
      flags.add("STEER_OVER_TARGET");
      delete headroom.steer;
    } else {
      headroom.steer = Math.min(headroom.steer ?? Infinity, steerTarget - w.steer);
    }
  }

  // Gross over: no slide can fix it (spec §1, example C)
  if (overages.gross) {
    flags.add("OVER_GROSS");
    return {
      status: "OVER_GROSS",
      flags: [...flags],
      issues,
      overages,
      headroom,
      adjustments: [{ action: "rework_cargo", needed_lb: overages.gross }],
      feasible: false,
      assumptions: assumptionsFor(rules, false, kpra, equipment, !!lbPerHole),
      sum_of_groups: sum,
      required_actions: ["Do not drive on public roads", "Contact dispatch to remove or rework cargo", "Send a new CAT ticket", "Dispatch approval required"],
      bridge: empty,
      kpra,
    };
  }

  // 3. Bridge formula on every axle group (needs the axle layout)
  const bridge = { ...empty };
  if (rules.bridge_formula !== false) {
    const layout = buildLayout(equipment?.tractor, equipment?.trailer);
    if ("positions" in layout) {
      bridge.checked = true;
      bridge.groups = checkBridge(layout.positions, { steer: w.steer, drive: w.drive, trailer: w.trailer }, rules);
      bridge.groups
        .filter((g) => g.over_lb > 0)
        .forEach((g) =>
          issues.push({ group: "bridge", kind: "bridge", value: g.weight_lb, limit: g.limit_lb, over: g.over_lb, detail: `axles ${g.axles}, ${g.length_ft} ft` }),
        );
      if (bridge.groups.some((g) => g.over_lb > 0)) flags.add("BRIDGE_VIOLATION");
    } else {
      bridge.missing = layout.missing;
      flags.add("BRIDGE_REVIEW");
    }
  }

  // KPRA over the route's limit: the tandems must come forward (spec §4)
  if (kpra.over_ft !== null) {
    issues.push({ group: "kpra", kind: "kpra", value: kpra.kpra_ft, limit: kpra.max_ft as number, over: kpra.over_ft });
    flags.add("KPRA_VIOLATION");
  } else if (!kpra.verified) {
    flags.add("KPRA_NOT_VERIFIED");
  }

  const steerExcess = overages.steer || issues.find((i) => i.kind === "over_target")?.over || 0;
  const hasViolation = issues.some((i) => i.kind !== "over_target") || !!steerExcess;
  if (routeIssues) flags.add("ROUTE_REVIEW_REQUIRED");

  if (!hasViolation) {
    const status: ScaleStatus = routeIssues ? "ROUTE_REVIEW_REQUIRED" : flags.has("BRIDGE_REVIEW") || flags.has("KPRA_NOT_VERIFIED") ? "BRIDGE_REVIEW" : "PASS_PRELIMINARY";
    if (status === "PASS_PRELIMINARY") flags.add("PASS_PRELIMINARY");
    return {
      status,
      flags: [...flags],
      issues,
      overages,
      headroom,
      adjustments: [],
      feasible: true,
      assumptions: assumptionsFor(rules, bridge.checked, kpra, equipment, !!lbPerHole),
      sum_of_groups: sum,
      required_actions:
        status === "PASS_PRELIMINARY"
          ? ["Dispatch approval required before departure"]
          : ["Dispatch reviews the route, trailer and rules", "Dispatch approval required before departure"],
      bridge,
      kpra,
    };
  }

  // 4. Which move could shift the excess to a group with verified room (spec §6).
  // Direction always; a hole count only when this trailer's lb-per-hole was measured.
  if (Object.keys(overages).length) flags.add("OVER_AXLE");
  const room = (group: Group) => headroom[group] ?? 0;
  const trailer = equipment?.trailer;
  const holeFt = trailer?.hole_spacing_in ? trailer.hole_spacing_in / 12 : null;
  const adjustments: Adjustment[] = [];
  let feasible = true;

  const tandemMove = (action: "tandems_forward" | "tandems_backward", needed: number): Adjustment | null => {
    const holes = lbPerHole ? Math.ceil(needed / lbPerHole) : null;
    const available = action === "tandems_forward" ? trailer?.holes_forward_available : trailer?.holes_back_available;
    if (holes !== null && typeof available === "number" && holes > available) return null; // not enough travel
    const sign = action === "tandems_backward" ? 1 : -1; // backward lengthens KPRA
    const kpraAfter = holes !== null && holeFt && kpraFt !== null ? Math.round((kpraFt + sign * holes * holeFt) * 100) / 100 : null;
    if (kpraAfter !== null && kpraMax !== null && kpraAfter > kpraMax) return null; // would break KPRA
    return { action, holes, kpra_after_ft: kpraAfter };
  };

  // advisory: the steer target is company policy, so having no move for it never blocks a fix
  const consider = (from: Group, needed: number, options: { action: AdjustmentAction; to: Group }[], advisory = false) => {
    let found = false;
    options.forEach((o) => {
      if (room(o.to) < needed) return;
      const extra = o.action === "tandems_forward" || o.action === "tandems_backward" ? tandemMove(o.action, needed) : {};
      if (extra === null) return;
      found = true;
      adjustments.push({ action: o.action, from, to: o.to, needed_lb: needed, available_lb: room(o.to), reason: "weight", ...extra });
    });
    if (!found && !advisory) feasible = false;
  };
  if (overages.drive) {
    consider("drive", overages.drive, [
      { action: "tandems_forward", to: "trailer" },
      { action: "fifth_wheel_forward", to: "steer" },
    ]);
  }
  if (overages.trailer) consider("trailer", overages.trailer, [{ action: "tandems_backward", to: "drive" }]);
  if (steerExcess) consider("steer", steerExcess, [{ action: "fifth_wheel_back", to: "drive" }], !overages.steer);
  if (kpra.over_ft !== null) {
    // Sliding forward shortens KPRA but moves weight from the drives onto the trailer axle
    const holes = holeFt ? Math.ceil(kpra.over_ft / holeFt) : null;
    adjustments.push({ action: "tandems_forward", reason: "kpra", holes, kpra_after_ft: holes !== null && holeFt && kpraFt !== null ? Math.round((kpraFt - holes * holeFt) * 100) / 100 : null });
  }
  // A bridge violation needs the axle layout changed or weight removed: dispatch decides
  if (flags.has("BRIDGE_VIOLATION")) feasible = false;

  if (!feasible) {
    flags.add("NO_FEASIBLE_SLIDE");
    adjustments.push({ action: "rework_cargo" });
  }
  flags.add("ADJUST_AND_REWEIGH");
  return {
    status: "ADJUST_AND_REWEIGH",
    flags: [...flags],
    issues,
    overages,
    headroom,
    adjustments,
    feasible,
    assumptions: assumptionsFor(rules, bridge.checked, kpra, equipment, !!lbPerHole),
    sum_of_groups: sum,
    required_actions: feasible
      ? ["Park safely and secure the vehicle", "Make the suggested adjustment", "Dispatch records the adjustment", "Send a new CAT ticket", "Dispatch approval required"]
      : ["Do not depart", "Contact dispatch to rework the load", "Send a new CAT ticket", "Dispatch approval required"],
    bridge,
    kpra,
  };
};
