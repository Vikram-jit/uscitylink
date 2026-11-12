import { Adjustment, GROUP_LABELS, Issue, RuleLimits, ScaleResult, Weights } from "./evaluate";

// Driver / staff wording for each result. Never says "legal" or "good to go":
// a ticket alone cannot prove that, and the driver must wait for dispatch to confirm.

const lb = (n: number | null | undefined) => (n === null || n === undefined ? "—" : `${Math.round(n).toLocaleString("en-US")} lbs`);


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

export const weightsLine = (w: Weights) =>
  `Steer ${lb(w.steer)} · Drive ${lb(w.drive)} · Trailer ${lb(w.trailer)} · Gross ${lb(w.gross)}`;

// ---------- the driver's message: one plain line ----------
// Drivers read this in the cab: what's wrong, what to do, and wait for dispatch. Numbers and limits
// stay in dispatch's alert (buildStaffAlert).

const PLAIN: Record<string, string> = { steer: "Front axle", drive: "Drive axles", trailer: "Trailer axles", gross: "Truck" };
const holes = (a: Adjustment) => (a.holes ? ` (about ${a.holes} hole${a.holes === 1 ? "" : "s"})` : "");
const WAIT = "Don't leave until dispatch OKs it.";

/** The one thing to do for the first suggested move */
const moveText = (a?: Adjustment | null): string | null => {
  if (!a) return null;
  if (a.reason === "kpra") return `slide the trailer tandems forward${holes(a)}`;
  switch (a.action) {
    case "tandems_forward":
      return `slide the trailer tandems forward${holes(a)}`;
    case "tandems_backward":
      return `slide the trailer tandems back${holes(a)}`;
    case "fifth_wheel_forward":
      return "slide the fifth wheel forward";
    case "fifth_wheel_back":
      return "slide the fifth wheel back";
    default:
      return null;
  }
};

/** The biggest problem, in plain words ("Trailer axles are 920 lbs too heavy") */
const mainProblem = (result: ScaleResult): string | null => {
  const over = result.issues.filter((i) => ["over_limit", "over_rating", "over_target", "bridge", "kpra"].includes(i.kind));
  const worst = [...over].sort((a, b) => (Number(b.over) || 0) - (Number(a.over) || 0))[0];
  if (!worst) return null;
  if (worst.kind === "kpra") return "The trailer tandems are too far back";
  if (worst.kind === "bridge") return `The axles are ${lb(worst.over)} too heavy for their spacing`;
  const who = PLAIN[worst.group as string] || "One axle";
  return `${who} ${who === "Truck" || who === "Front axle" ? "is" : "are"} ${lb(worst.over)} too heavy`;
};

export const buildDriverMessage = (
  result: ScaleResult,
  weights: Weights,
  _rules: RuleLimits,
  options: { reweigh?: boolean; predictionNote?: string | null } = {},
): string => {
  const again = options.reweigh ? "New ticket: " : "";
  switch (result.status) {
    case "PASS_PRELIMINARY":
      return `✅ ${again}Scale ticket looks good (gross ${lb(weights.gross)}). ${WAIT}`;
    case "ROUTE_REVIEW_REQUIRED":
    case "BRIDGE_REVIEW":
      return `🕓 ${again}Scale ticket looks OK — dispatch is checking it. ${WAIT}`;
    case "OVER_GROSS": {
      const over = result.issues.find((i) => i.group === "gross")?.over;
      return `⛔ ${again}The truck is ${over ? `${lb(over)} ` : ""}too heavy overall — sliding won't fix it. Don't drive; call dispatch.`;
    }
    case "ADJUST_AND_REWEIGH": {
      const problem = mainProblem(result) || "One axle is too heavy";
      const move = result.feasible ? moveText(result.adjustments[0]) : null;
      return move
        ? `⚠️ ${again}${problem} — ${move}, reweigh and send the new ticket. ${WAIT}`
        : `⚠️ ${again}${problem} and a slide won't fix it — don't drive; call dispatch.`;
    }
    case "OCR_UNCERTAIN":
    default:
      return `📷 ${again}We couldn't read the scale ticket — please send a clear photo of the whole ticket. ${WAIT}`;
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
