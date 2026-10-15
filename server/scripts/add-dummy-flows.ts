// Run: npx ts-node scripts/add-dummy-flows.ts
// Adds simple "EXAMPLE:" flows to the database in .env (your local one). Safe to re-run.
import { primarySequelize } from "../src/sequelize";
import { Flow } from "../src/models/Flow";

const base = {
  trigger: "document_analyzed" as const,
  active: true,
  shadow_mode: true, // logs what it WOULD do in Automation → Run log; sends nothing
  else_actions: [],
  cooldown_minutes: 0,
  stop_on_match: false,
};

const flows = [
  {
    name: "EXAMPLE: Scale weight out of range",
    description: "IF scale ticket AND (gross < 1,000 OR gross > 10,000 OR weight unreadable) THEN reply + alert dispatch.",
    priority: 6,
    conditions: {
      all: [
        { field: "doc.type", op: "eq", value: "scale_ticket" },
        {
          any: [
            { field: "doc.fields.gross_lb", op: "lt", value: 1000 },
            { field: "doc.fields.gross_lb", op: "gt", value: 10000 },
            { field: "doc.fields.gross_lb", op: "missing" },
          ],
        },
      ],
    },
    actions: [
      {
        type: "reply_driver",
        template: "The weight on your scale ticket ({{doc.fields.gross_lb}} lb) looks wrong. Please send a clear photo or call dispatch.",
      },
      {
        type: "alert_staff",
        severity: "warning",
        title: "Odd scale weight — truck {{driver.truck}}",
        template: "{{driver.name}} sent a scale ticket with gross {{doc.fields.gross_lb}} lb.",
      },
    ],
  },
  {
    name: "EXAMPLE: Big lumper receipt",
    description: "IF lumper receipt AND amount is over $200 THEN alert dispatch and tag it.",
    priority: 7,
    conditions: {
      all: [
        { field: "doc.type", op: "eq", value: "lumper_receipt" },
        { field: "doc.fields.amount", op: "gt", value: 200 },
      ],
    },
    actions: [
      {
        type: "alert_staff",
        severity: "info",
        title: "Lumper over $200",
        template: "{{driver.name}} paid ${{doc.fields.amount}} to {{doc.fields.vendor}}.",
      },
      { type: "tag", tags: ["big_lumper"] },
    ],
  },
  {
    name: "EXAMPLE: Paperwork sent at night",
    description: "IF any document arrives before 6 am or after 10 pm THEN tag it 'night'.",
    priority: 8,
    conditions: {
      any: [
        { field: "time.hour", op: "lt", value: 6 },
        { field: "time.hour", op: "gte", value: 22 },
      ],
    },
    actions: [{ type: "tag", tags: ["night"] }],
  },
];

(async () => {
  for (const f of flows) {
    const existing = await Flow.findOne({ where: { name: f.name }, logging: false });
    if (existing) await existing.update({ ...base, ...f }, { logging: false });
    else await Flow.create({ ...base, ...f } as any, { logging: false });
    console.log("✅", f.name);
  }
  await primarySequelize.close();
})().catch((e) => { console.error("❌", e.message); process.exit(1); });
