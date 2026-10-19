import { TraceNode } from "./evaluate";

// Text for {{flow.reasons}} and {{flow.checks}} in reply/alert templates, generated from the flow's own
// conditions so the limits in a message always match the limits the flow actually checks.
//   reasons: why this branch ran, e.g. "- Trailer axle: 33,980 lbs (280 lbs over the 33,700 limit)".
//            Flow matched -> the conditions that were true. "Otherwise" branch -> the checks that failed,
//            so one flow "all weights within limits" can explain an overweight or unreadable ticket.
//            ELSE IF branch -> that branch's own conditions that were true.
//   failed:  every IF check that did not pass (all problems on the document), in any branch
//   checks:  every number condition with its value and limit, e.g. "- Steer axle: 11,740 lbs (limit 12,000)"

const NUMBER_OPS = ["gt", "gte", "lt", "lte"];

const num = (v: any): number | null => {
  const n = typeof v === "number" ? v : Number(String(v ?? "").replace(/,/g, ""));
  return v === null || v === undefined || v === "" || !Number.isFinite(n) ? null : n;
};
const fmt = (n: number) => n.toLocaleString("en-US");

const unitFor = (field: string) => (/_lbs?$/.test(field) ? " lbs" : "");

const labelFor = (field: string, labels: Record<string, string>) => {
  const key = field.replace(/^doc\.fields\./, "");
  const label = labels[key] || key.replace(/_lbs?$/, "").replace(/_/g, " ");
  // "Trailer axle (lb)" -> "Trailer axle"; the unit is printed after the value
  const clean = label.replace(/\s*\((lbs?|kg)\)\s*$/i, "");
  return clean.charAt(0).toUpperCase() + clean.slice(1);
};

const leaves = (node: TraceNode | undefined, out: TraceNode[] = []): TraceNode[] => {
  if (!node) return out;
  if (node.type === "condition") out.push(node);
  (node.children || []).forEach((c) => leaves(c, out));
  return out;
};

const describeReason = (leaf: TraceNode, labels: Record<string, string>): string | null => {
  const field = leaf.field || "";
  if (!field.startsWith("doc.fields.")) return null;
  const label = labelFor(field, labels);
  const unit = unitFor(field);
  if (leaf.op === "missing") return `- ${label}: could not be read`;
  const actual = num(leaf.actual);
  const limit = num(leaf.expected);
  if (actual === null || limit === null || !NUMBER_OPS.includes(leaf.op || "")) return null;
  if (leaf.op === "gt" || leaf.op === "gte") {
    return `- ${label}: ${fmt(actual)}${unit} (${fmt(actual - limit)}${unit} over the ${fmt(limit)} limit)`;
  }
  return `- ${label}: ${fmt(actual)}${unit} (${fmt(limit - actual)}${unit} under the ${fmt(limit)} minimum)`;
};

// A check that did not pass, e.g. "steer <= 12,000" with 12,300 -> over; with no value -> unreadable
const describeFailure = (leaf: TraceNode, labels: Record<string, string>): string | null => {
  const field = leaf.field || "";
  if (!field.startsWith("doc.fields.")) return null;
  const label = labelFor(field, labels);
  const unit = unitFor(field);
  const actual = num(leaf.actual);
  if (leaf.op === "exists" || (actual === null && NUMBER_OPS.includes(leaf.op || ""))) return `- ${label}: could not be read`;
  const limit = num(leaf.expected);
  if (actual === null || limit === null) return null;
  if (leaf.op === "lt" || leaf.op === "lte") {
    return `- ${label}: ${fmt(actual)}${unit} (${fmt(actual - limit)}${unit} over the ${fmt(limit)} limit)`;
  }
  if (leaf.op === "gt" || leaf.op === "gte") {
    return `- ${label}: ${fmt(actual)}${unit} (${fmt(limit - actual)}${unit} under the ${fmt(limit)} minimum)`;
  }
  return null;
};

const describeCheck = (leaf: TraceNode, labels: Record<string, string>): string | null => {
  const field = leaf.field || "";
  if (!field.startsWith("doc.fields.") || !NUMBER_OPS.includes(leaf.op || "")) return null;
  const actual = num(leaf.actual);
  const limit = num(leaf.expected);
  if (limit === null) return null;
  const unit = unitFor(field);
  const kind = leaf.op === "gt" || leaf.op === "lte" ? "limit" : "minimum";
  return `- ${labelFor(field, labels)}: ${actual === null ? "not readable" : `${fmt(actual)}${unit}`} (${kind} ${fmt(limit)})`;
};

// main: the IF trace. branch: the ELSE IF that ran, if any.
export const describeTrace = (main: TraceNode, labels: Record<string, string>, branch?: TraceNode | null) => {
  const all = leaves(main);
  const failed = all.filter((l) => !l.result).map((l) => describeFailure(l, labels)).filter(Boolean);
  const matchedIn = (node: TraceNode) => leaves(node).filter((l) => l.result).map((l) => describeReason(l, labels)).filter(Boolean);
  const reasons = branch ? matchedIn(branch) : main.result ? matchedIn(main) : failed;
  const seen = new Set<string>();
  const checks = all
    .filter((l) => (seen.has(l.field || "") ? false : (seen.add(l.field || ""), true)))
    .map((l) => describeCheck(l, labels))
    .filter(Boolean);
  return { reasons: reasons.join("\n"), checks: checks.join("\n"), failed: failed.join("\n") };
};
