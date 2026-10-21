import { Adjustment, GROUP_LABELS, Issue, RuleLimits, ScaleResult, Weights } from "./evaluate";

// Fixed driver/staff wording for each result (spec §8 sample). Never says "legal" or "good to go":
// a ticket alone cannot prove that, and the driver must wait for dispatch to confirm.

const lb = (n: number | null | undefined) => (n === null || n === undefined ? "—" : `${Math.round(n).toLocaleString("en-US")} lbs`);

const SAFETY = "Park safely and keep the vehicle secured. Do not drive overweight on public roads, and do not depart until dispatch confirms.";

const issueLine = (issue: Issue, weights: Weights): string => {
  if (issue.kind === "missing") return `- ${GROUP_LABELS[issue.group as keyof typeof GROUP_LABELS]}: could not be read`;
  if (issue.kind === "low_confidence") return "- The ticket could not be read with enough confidence";
  if (issue.kind === "poor_image") return "- The photo is blurry, dark or cut off";
  if (issue.kind === "sum_mismatch") {
    return `- The weights do not add up: steer + drive + trailer = ${lb(issue.value)}, but gross shows ${lb(weights.gross)}`;
  }
  if (issue.kind === "bridge") {
    return `- Bridge formula (${issue.detail}): ${lb(issue.value)} — ${lb(issue.over)} over the ${lb(issue.limit)} limit`;
  }
  if (issue.kind === "kpra") {
    return `- Trailer position: kingpin to rear axle ${issue.value} ft — ${issue.over} ft over the ${issue.limit} ft limit`;
  }
  const label = GROUP_LABELS[issue.group as keyof typeof GROUP_LABELS];
  if (issue.kind === "over_rating") {
    return `- ${label}: ${lb(issue.value)} — ${lb(issue.over)} over the ${lb(issue.limit)} axle/tire rating`;
  }
  if (issue.kind === "over_target") {
    return `- ${label}: ${lb(issue.value)} — ${lb(issue.over)} above the ${lb(issue.limit)} company steer target`;
  }
  return `- ${label}: ${lb(issue.value)} — ${lb(issue.over)} over the ${lb(issue.limit)} limit`;
};

const holesText = (a: Adjustment) =>
  a.holes ? ` About ${a.holes} hole${a.holes === 1 ? "" : "s"} (estimate from this trailer's past reweighs).` : "";

const adjustmentLine = (a: Adjustment): string | null => {
  const room = `${GROUP_LABELS[a.to as keyof typeof GROUP_LABELS] || ""} has ${lb(a.available_lb)} available`;
  if (a.reason === "kpra") {
    return `- Move the trailer tandems FORWARD to bring the rear axle within the trailer-length rule.${a.holes ? ` About ${a.holes} hole${a.holes === 1 ? "" : "s"}.` : ""} This moves weight onto the trailer axle.`;
  }
  switch (a.action) {
    case "tandems_forward":
      return `- Move the trailer tandems FORWARD to shift weight from the drives to the trailer axle (${room}).${holesText(a)}`;
    case "tandems_backward":
      return `- Move the trailer tandems BACKWARD to shift weight from the trailer axle to the drives (${room}).${holesText(a)}`;
    case "fifth_wheel_forward":
      return `- Move the fifth wheel FORWARD to shift weight from the drives to the steer axle (${room}).`;
    case "fifth_wheel_back":
      return `- Move the fifth wheel BACK to shift weight from the steer axle to the drives (${room}).`;
    default:
      return null;
  }
};

export const weightsLine = (w: Weights) =>
  `Steer ${lb(w.steer)} · Drive ${lb(w.drive)} · Trailer ${lb(w.trailer)} · Gross ${lb(w.gross)}`;

export const buildDriverMessage = (
  result: ScaleResult,
  weights: Weights,
  rules: RuleLimits,
  options: { reweigh?: boolean; predictionNote?: string | null } = {},
): string => {
  const prefix = options.reweigh ? "(Reweigh) " : "";
  const problems = result.issues.map((i) => issueLine(i, weights)).join("\n");
  const body = buildBody(result, weights, rules, prefix, problems);
  return options.predictionNote ? `${body}\n\nCompared with your last ticket: ${options.predictionNote}` : body;
};

const buildBody = (result: ScaleResult, weights: Weights, rules: RuleLimits, prefix: string, problems: string): string => {
  switch (result.status) {
    case "ROUTE_REVIEW_REQUIRED":
    case "BRIDGE_REVIEW":
      return [
        `🕓 ${prefix}Scale ticket — weights look within limits, review pending`,
        weightsLine(weights),
        result.status === "ROUTE_REVIEW_REQUIRED"
          ? "Dispatch still has to check your route and the state rules for it."
          : "Dispatch still has to check the axle spacing and trailer position.",
        "Please wait for dispatch to confirm before you depart.",
      ].join("\n\n");

    case "PASS_PRELIMINARY":
      return [
        `✅ ${prefix}Scale ticket — preliminary check passed`,
        weightsLine(weights),
        `Within the limits for your route (${rules.jurisdiction}: tandem ${lb(rules.tandem_lb)}, gross ${lb(rules.gross_lb)}), including axle spacing and trailer position.`,
        "Please wait for dispatch to confirm before you depart.",
      ].join("\n\n");

    case "OVER_GROSS":
      return [
        `⛔ ${prefix}Scale ticket — over gross weight`,
        problems,
        "Sliding the tandems or fifth wheel cannot reduce gross weight. Contact dispatch now to remove or rework cargo, then send a new CAT ticket.",
        SAFETY,
      ].join("\n\n");

    case "ADJUST_AND_REWEIGH": {
      const moves = result.adjustments.map(adjustmentLine).filter(Boolean).join("\n");
      const advice = result.feasible
        ? `If the trailer position and route rules allow, this may help (an estimate, not a guarantee):\n${moves}\n\nMake a small adjustment, then send a new CAT ticket.`
        : `${moves ? `${moves}\n\n` : ""}A slide alone cannot bring every axle within its limit. Contact dispatch to rework the load, then send a new CAT ticket.`;
      return [`⚠️ ${prefix}Scale ticket — adjust and reweigh`, problems, advice, SAFETY].join("\n\n");
    }

    case "OCR_UNCERTAIN":
    default:
      return [
        `📷 ${prefix}Scale ticket — we could not verify it`,
        problems,
        "Please send a clear, straight photo of the whole ticket. Dispatch will review it.",
        "Do not depart until dispatch confirms.",
      ].join("\n\n");
  }
};

export const buildStaffAlert = (result: ScaleResult, weights: Weights, driverName: string | null, truck: string | null) => {
  const who = `${driverName || "Driver"}${truck ? ` (truck ${truck})` : ""}`;
  const problems = result.issues.map((i) => issueLine(i, weights)).join("\n");
  switch (result.status) {
    case "PASS_PRELIMINARY":
      return { severity: "info" as const, title: `Scale check passed — approve release for ${who}`, body: weightsLine(weights) };
    case "ROUTE_REVIEW_REQUIRED":
    case "BRIDGE_REVIEW":
      return {
        severity: "warning" as const,
        title: `${result.status === "ROUTE_REVIEW_REQUIRED" ? "Route review" : "Axle spacing / KPRA review"} needed before release — ${who}`,
        body: `${weightsLine(weights)}\n${result.assumptions.join("\n")}`,
      };
    case "OVER_GROSS":
      return { severity: "critical" as const, title: `Over gross weight — ${who}`, body: problems };
    case "ADJUST_AND_REWEIGH":
      return {
        severity: (result.feasible ? "warning" : "critical") as "warning" | "critical",
        title: `${result.feasible ? "Axle over — adjust and reweigh" : "Axle over — no slide fix"} — ${who}`,
        body: problems,
      };
    default:
      return { severity: "warning" as const, title: `Scale ticket needs review — ${who}`, body: problems };
  }
};
