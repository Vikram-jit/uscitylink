// Run: npx ts-node scripts/seed-demo-usage.ts          -> adds ~30 days of fake usage so the charts have data
//      npx ts-node scripts/seed-demo-usage.ts --clear  -> removes it again
// Demo rows use source = "demo" and never touch real usage.
import { primarySequelize } from "../src/sequelize";
import { AiUsageLog } from "../src/models/AiUsageLog";
import { computeCost } from "../src/services/documentAi/pricing";

const MODEL = "claude-opus-5-5";
const TYPES = [
  ["scale_ticket", 0.34], ["bol_pickup", 0.26], ["pod_signed", 0.2], ["lumper_receipt", 0.08], ["fuel_receipt", 0.07], ["other", 0.05],
] as const;
const pick = () => { let r = Math.random(), acc = 0; for (const [t, w] of TYPES) { acc += w; if (r <= acc) return t; } return "other"; };
const jitter = (n: number, pct = 0.1) => Math.round(n * (1 + (Math.random() * 2 - 1) * pct));

(async () => {
  if (process.argv.includes("--clear")) {
    const n = await AiUsageLog.destroy({ where: { source: "demo" }, logging: false });
    console.log(`🧹 removed ${n} demo rows`);
    return primarySequelize.close();
  }
  const rows: any[] = [];
  for (let d = 29; d >= 0; d--) {
    const weekday = new Date(Date.now() - d * 864e5).getUTCDay();
    const docs = (weekday === 0 || weekday === 6 ? 8 : 24) + Math.floor(Math.random() * 10);
    for (let i = 0; i < docs; i++) {
      // ~70% of calls land within 5 minutes of another one, so the examples come from cache
      const warm = Math.random() < 0.7;
      const prefix = 15500, tokens = { input: jitter(2400), cacheRead: warm ? jitter(prefix, 0.02) : 0, cacheWrite: warm ? 0 : jitter(prefix, 0.02), output: jitter(720, 0.2) };
      const when = new Date(Date.now() - d * 864e5 - Math.floor(Math.random() * 12 * 36e5));
      rows.push({
        source: "demo", model: MODEL, doc_type_key: pick(), input_tokens: tokens.input, cache_read_tokens: tokens.cacheRead,
        cache_write_tokens: tokens.cacheWrite, output_tokens: tokens.output, cost_usd: computeCost(MODEL, tokens),
        latency_ms: jitter(5200, 0.35), createdAt: when, updatedAt: when,
      });
    }
  }
  await AiUsageLog.bulkCreate(rows, { logging: false });
  console.log(`✅ added ${rows.length} demo rows over 30 days (remove with --clear)`);
  await primarySequelize.close();
})().catch((e) => { console.error("❌", e.message); process.exit(1); });
