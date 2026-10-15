// Run: npx ts-node scripts/test-flow-evaluator.ts
import assert from "assert";
import { evaluate, validateConditionTree } from "../src/services/flowEngine/evaluate";
import { renderTemplate } from "../src/services/flowEngine/template";

const ctx = {
  doc: {
    type: "scale_ticket",
    confidence: 0.93,
    quality: "good",
    fields: {
      steer_axle_lb: 11740,
      drive_axle_lb: 31880,
      trailer_axle_lb: 33980,
      gross_lb: 77600,
      trailer_number: "87565",
      seal_number: null,
      receiver_signature_present: false,
      weight_text: "77,600",
    },
  },
  driver: { name: "Test Driver", truck: "31765" },
};

const cond = (field: string, op: any, value?: any) => evaluate({ field, op, value }, ctx).result;
let passed = 0;
const check = (name: string, actual: boolean, expected: boolean) => {
  assert.strictEqual(actual, expected, name);
  passed++;
};

check("eq string case-insensitive", cond("doc.type", "eq", "SCALE_TICKET"), true);
check("eq number vs string", cond("doc.fields.trailer_number", "eq", 87565), true);
check("neq", cond("doc.type", "neq", "bol_pickup"), true);
check("gt", cond("doc.fields.gross_lb", "gt", 80000), false);
check("gte", cond("doc.fields.gross_lb", "gte", 77600), true);
check("lt", cond("doc.confidence", "lt", 0.6), false);
check("lte", cond("doc.fields.trailer_axle_lb", "lte", 34000), true);
check("numeric string with comma", cond("doc.fields.weight_text", "eq", 77600), true);
check("between", cond("doc.fields.gross_lb", "between", [70000, 80000]), true);
check("between outside", cond("doc.fields.gross_lb", "between", [0, 1000]), false);
check("contains", cond("driver.name", "contains", "test"), true);
check("in list", cond("doc.quality", "in", ["poor", "good"]), true);
check("in comma string", cond("doc.quality", "in", "poor, unreadable"), false);
check("exists", cond("doc.fields.gross_lb", "exists"), true);
check("missing null", cond("doc.fields.seal_number", "missing"), true);
check("missing undefined path", cond("doc.fields.nope.deeper", "missing"), true);
check("is_false", cond("doc.fields.receiver_signature_present", "is_false"), true);
check("is_true", cond("doc.fields.receiver_signature_present", "is_true"), false);
check("numeric op on missing value is false", cond("doc.fields.seal_number", "gt", 1), false);
check("empty tree matches", evaluate(null, ctx).result, true);

const overweight = {
  all: [
    { field: "doc.type", op: "eq", value: "scale_ticket" },
    {
      any: [
        { field: "doc.fields.gross_lb", op: "gt", value: 80000 },
        { field: "doc.fields.drive_axle_lb", op: "gt", value: 34000 },
      ],
    },
  ],
} as any;
const trace = evaluate(overweight, ctx);
check("nested all/any not matched", trace.result, false);
check("trace keeps child results", trace.children?.[0].result === true, true);
check(
  "nested any matched when one child true",
  evaluate({ any: [{ field: "doc.type", op: "eq", value: "x" }, { field: "doc.fields.gross_lb", op: "lt", value: 80000 }] } as any, ctx).result,
  true,
);

assert.strictEqual(validateConditionTree({ all: [{ field: "doc.type", op: "bogus" }] }), 'Unknown operator "bogus"');
assert.strictEqual(validateConditionTree({ all: [{ field: "x", op: "between", value: 5 }] }), "between needs [min, max]");
assert.strictEqual(validateConditionTree(overweight), null);
passed += 3;

assert.strictEqual(
  renderTemplate("Gross {{doc.fields.gross_lb}} lb, seal {{ doc.fields.seal_number }}, truck {{driver.truck}}", ctx),
  "Gross 77,600 lb, seal —, truck 31765",
);
passed++;

console.log(`✅ ${passed} evaluator checks passed`);
