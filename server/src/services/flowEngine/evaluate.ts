// Condition trees are plain JSON so the web flow builder can render and edit them:
//   { "all": [ cond, { "any": [cond, cond] } ] }
//   cond = { "field": "doc.fields.gross_lb", "op": "gte", "value": 80000 }

export type Operator =
  | "eq"
  | "neq"
  | "gt"
  | "gte"
  | "lt"
  | "lte"
  | "between"
  | "contains"
  | "in"
  | "exists"
  | "missing"
  | "is_true"
  | "is_false";

export interface Condition {
  field: string;
  op: Operator;
  value?: any;
}

export type ConditionNode = { all: ConditionNode[] } | { any: ConditionNode[] } | Condition;

export interface TraceNode {
  result: boolean;
  type: "all" | "any" | "condition";
  field?: string;
  op?: Operator;
  expected?: any;
  actual?: any;
  children?: TraceNode[];
}

export const OPERATORS: Operator[] = [
  "eq",
  "neq",
  "gt",
  "gte",
  "lt",
  "lte",
  "between",
  "contains",
  "in",
  "exists",
  "missing",
  "is_true",
  "is_false",
];

export const getPath = (obj: any, path: string): any =>
  path.split(".").reduce((acc, key) => (acc == null ? undefined : acc[key]), obj);

const isEmpty = (v: any) => v === undefined || v === null || v === "";

const toNumber = (v: any): number | null => {
  if (typeof v === "number") return Number.isFinite(v) ? v : null;
  if (typeof v === "string" && v.trim() !== "") {
    const n = Number(v.replace(/,/g, ""));
    return Number.isFinite(n) ? n : null;
  }
  return null;
};

const normalize = (v: any) => (typeof v === "string" ? v.trim().toLowerCase() : v);

const compare = (actual: any, op: Operator, expected: any): boolean => {
  switch (op) {
    case "exists":
      return !isEmpty(actual);
    case "missing":
      return isEmpty(actual);
    case "is_true":
      return actual === true || normalize(actual) === "true" || normalize(actual) === "yes";
    case "is_false":
      return actual === false || normalize(actual) === "false" || normalize(actual) === "no";
    case "eq":
      return normalize(actual) === normalize(expected) ||
        (toNumber(actual) !== null && toNumber(actual) === toNumber(expected));
    case "neq":
      return !compare(actual, "eq", expected);
    case "contains":
      if (isEmpty(actual)) return false;
      if (Array.isArray(actual)) return actual.map(normalize).includes(normalize(expected));
      return String(actual).toLowerCase().includes(String(expected ?? "").toLowerCase());
    case "in": {
      const list = Array.isArray(expected)
        ? expected
        : String(expected ?? "").split(",").map((s) => s.trim());
      return list.some((item) => compare(actual, "eq", item));
    }
    case "between": {
      const n = toNumber(actual);
      const [lo, hi] = Array.isArray(expected) ? expected.map(toNumber) : [null, null];
      return n !== null && lo !== null && hi !== null && n >= lo && n <= hi;
    }
    case "gt":
    case "gte":
    case "lt":
    case "lte": {
      const a = toNumber(actual);
      const b = toNumber(expected);
      // A missing number never satisfies a numeric comparison
      if (a === null || b === null) return false;
      if (op === "gt") return a > b;
      if (op === "gte") return a >= b;
      if (op === "lt") return a < b;
      return a <= b;
    }
    default:
      return false;
  }
};

export const evaluate = (node: ConditionNode | null | undefined, context: any): TraceNode => {
  // An empty condition set matches everything
  if (!node) return { result: true, type: "all", children: [] };

  if ("all" in node) {
    const children = (node.all || []).map((child) => evaluate(child, context));
    return { result: children.every((c) => c.result), type: "all", children };
  }
  if ("any" in node) {
    const children = (node.any || []).map((child) => evaluate(child, context));
    return { result: children.some((c) => c.result), type: "any", children };
  }

  const actual = getPath(context, node.field);
  return {
    result: compare(actual, node.op, node.value),
    type: "condition",
    field: node.field,
    op: node.op,
    expected: node.value,
    actual: actual === undefined ? null : actual,
  };
};

export const validateConditionTree = (node: any, depth = 0): string | null => {
  if (depth > 6) return "Conditions are nested too deeply";
  if (!node || typeof node !== "object") return "Condition must be an object";
  if ("all" in node || "any" in node) {
    const list = node.all ?? node.any;
    if (!Array.isArray(list)) return "all/any must be a list";
    for (const child of list) {
      const err = validateConditionTree(child, depth + 1);
      if (err) return err;
    }
    return null;
  }
  if (typeof node.field !== "string" || !node.field) return "Condition field is required";
  if (!OPERATORS.includes(node.op)) return `Unknown operator "${node.op}"`;
  if (node.op === "between" && (!Array.isArray(node.value) || node.value.length !== 2)) {
    return "between needs [min, max]";
  }
  return null;
};
