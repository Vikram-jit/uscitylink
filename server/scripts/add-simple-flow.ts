// Run: npx ts-node scripts/add-simple-flow.ts
import { primarySequelize } from "../src/sequelize";
import { Flow } from "../src/models/Flow";

const NAME = "EXAMPLE: Confirm scale ticket";

(async () => {
  const data = {
    name: NAME,
    description: "Simple example. IF the driver sends a scale ticket, THEN reply with the gross weight.",
    trigger: "document_analyzed" as const,
    priority: 5,
    active: true,
    shadow_mode: false, // live: really sends the reply
    conditions: { all: [{ field: "doc.type", op: "eq", value: "scale_ticket" }] },
    actions: [
      {
        type: "reply_driver",
        template: "✅ Got your scale ticket, {{driver.name}}. Gross weight: {{doc.fields.gross_lb}} lb.",
      },
    ],
    else_actions: [],
    cooldown_minutes: 0,
    stop_on_match: false,
  };
  const existing = await Flow.findOne({ where: { name: NAME } });
  if (existing) await existing.update(data);
  else await Flow.create(data);
  console.log("✅ Flow ready:", NAME);
  await primarySequelize.close();
})().catch((e) => { console.error("❌", e.message); process.exit(1); });
