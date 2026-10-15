import { Op, fn, col, literal } from "sequelize";
import { AiUsageLog } from "../../models/AiUsageLog";
import { DocType } from "../../models/DocType";
import { DocTypeExample } from "../../models/DocTypeExample";
import { MessageDocument } from "../../models/MessageDocument";
import { MAX_EXAMPLES_PER_TYPE, MAX_EXAMPLES_TOTAL } from "./analyzeDocument";
import { getAiModel } from "./settings";
import { buildExtractionSchema } from "./buildSchema";
import { buildSystemPrompt } from "./prompt";
import { computeCost, findRate, RATE_CARD } from "./pricing";

// Rough token sizes (the real numbers come from the usage log once documents are processed).
// An image costs about width*height/750 tokens; a phone photo resized to 1568px lands near 1.5-2.5k.
export const EST = {
  imageTokens: 2000,
  outputTokens: 700,
  charsPerToken: 3.5,
};

const num = (v: any) => Number(v) || 0;
const round = (v: number, places = 6) => Math.round(v * 10 ** places) / 10 ** places;

export const estimateCallTokens = async () => {
  const docTypes = await DocType.findAll({ where: { active: true } });
  const examples = await DocTypeExample.findAll({ where: { active: true }, attributes: ["doc_type_id"] });

  // Same rule as buildExampleBlocks: at most N per type, M overall
  const perType = new Map<string, number>();
  let exampleCount = 0;
  for (const ex of examples) {
    if (exampleCount >= MAX_EXAMPLES_TOTAL) break;
    const c = perType.get(ex.doc_type_id) || 0;
    if (c >= MAX_EXAMPLES_PER_TYPE) continue;
    perType.set(ex.doc_type_id, c + 1);
    exampleCount++;
  }

  const systemChars = buildSystemPrompt(docTypes).length;
  const schemaChars = JSON.stringify(buildExtractionSchema(docTypes)).length;
  const systemTokens = Math.round(systemChars / EST.charsPerToken);
  const schemaTokens = Math.round(schemaChars / EST.charsPerToken);
  const exampleTokens = exampleCount * (EST.imageTokens + 150); // image + its expected-fields text
  const cachedPrefix = systemTokens + exampleTokens; // what cache_control keeps
  const uncachedInput = schemaTokens + EST.imageTokens + 60; // schema + the driver's photo + instructions

  return {
    activeDocTypes: docTypes.length,
    activeExamples: exampleCount,
    parts: [
      { name: "Instructions + document catalog", tokens: systemTokens, cached: true },
      { name: `Training examples (${exampleCount} photos)`, tokens: exampleTokens, cached: true },
      { name: "Output format (JSON schema)", tokens: schemaTokens, cached: false },
      { name: "The driver's photo", tokens: EST.imageTokens + 60, cached: false },
      { name: "AI answer (output)", tokens: EST.outputTokens, cached: false, output: true },
    ],
    cachedPrefix,
    // Prompt caching only applies above a per-model minimum (up to ~4,096 tokens). Below it every
    // token is billed at the normal input price, so the 'uncached' column is the realistic one.
    cachingLikely: cachedPrefix >= 4096,
    uncachedInput,
    outputTokens: EST.outputTokens,
  };
};

export type Estimate = Awaited<ReturnType<typeof estimateCallTokens>>;

export const estimateByModel = (e: Estimate) =>
  RATE_CARD.map((r) => {
    const base = { input: e.uncachedInput, output: e.outputTokens };
    // warm: examples served from cache (another document within 5 minutes); cold: cache must be written
    const warm = computeCost(r.model, { ...base, cacheRead: e.cachedPrefix, cacheWrite: 0 });
    const cold = computeCost(r.model, { ...base, cacheRead: 0, cacheWrite: e.cachedPrefix });
    const uncached = computeCost(r.model, { input: e.uncachedInput + e.cachedPrefix, output: e.outputTokens, cacheRead: 0, cacheWrite: 0 });
    return { model: r.model, label: r.label, warm: round(warm), cold: round(cold), uncached: round(uncached) };
  });

export const buildUsageReport = async (days: number) => {
  const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
  const where = { createdAt: { [Op.gte]: since } };

  const sumCols: any[] = [
    [fn("COUNT", col("id")), "calls"],
    [fn("SUM", col("input_tokens")), "input"],
    [fn("SUM", col("cache_read_tokens")), "cacheRead"],
    [fn("SUM", col("cache_write_tokens")), "cacheWrite"],
    [fn("SUM", col("output_tokens")), "output"],
    [fn("SUM", col("cost_usd")), "cost"],
    [fn("AVG", col("latency_ms")), "avgLatency"],
  ];
  const shape = (r: any) => ({
    calls: num(r.calls),
    input: num(r.input),
    cacheRead: num(r.cacheRead),
    cacheWrite: num(r.cacheWrite),
    output: num(r.output),
    cost: round(num(r.cost)),
    avgLatencyMs: Math.round(num(r.avgLatency)),
  });

  const grouped = async (group: string) =>
    (await AiUsageLog.findAll({ attributes: [group, ...sumCols], where, group: [group], raw: true })) as any[];

  const [totalsRow] = (await AiUsageLog.findAll({ attributes: sumCols, where, raw: true })) as any[];
  const totals = shape(totalsRow || {});

  const dailyRows = (await AiUsageLog.findAll({
    attributes: [[fn("DATE", col("createdAt")), "day"], ...sumCols],
    where,
    group: [literal("DATE(createdAt)") as any],
    order: [[literal("DATE(createdAt)"), "ASC"]],
    raw: true,
  })) as any[];
  const dailyMap = new Map(dailyRows.map((r) => [String(r.day).slice(0, 10), shape(r)]));
  const daily: ({ date: string } & ReturnType<typeof shape>)[] = [];
  for (let i = days - 1; i >= 0; i--) {
    const date = new Date(Date.now() - i * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
    daily.push({ date, ...(dailyMap.get(date) || shape({})) });
  }

  const bySource = (await grouped("source")).map((r) => ({ source: r.source, ...shape(r) }));
  const byModel = (await grouped("model")).map((r) => ({ model: r.model, ...shape(r) }));
  const byDocType = (await grouped("doc_type_key")).map((r) => ({ docType: r.doc_type_key || "unknown", ...shape(r) }));

  const latencies = (
    await AiUsageLog.findAll({ attributes: ["latency_ms"], where: { ...where, latency_ms: { [Op.ne]: null } } as any, order: [["createdAt", "DESC"]], limit: 5000, raw: true })
  ).map((r: any) => num(r.latency_ms)).sort((a, b) => a - b);
  const p95 = latencies.length ? latencies[Math.min(latencies.length - 1, Math.floor(latencies.length * 0.95))] : 0;

  const docStatus = (await MessageDocument.findAll({
    attributes: ["status", [fn("COUNT", col("id")), "count"]],
    where,
    group: ["status"],
    raw: true,
  })) as any[];
  const statusCount = (s: string) => num(docStatus.find((d) => d.status === s)?.count);
  const corrections = await MessageDocument.count({ where: { ...where, corrected_by: { [Op.ne]: null } } as any });

  const real = bySource.filter((s) => s.source === "message" || s.source === "reread");
  const messageCalls = real.reduce((a, s) => a + s.calls, 0);
  const messageCost = real.reduce((a, s) => a + s.cost, 0);
  const documentsRead = statusCount("done");

  const allInput = totals.input + totals.cacheRead + totals.cacheWrite;
  const cacheHitRate = allInput ? totals.cacheRead / allInput : 0;

  // Projection: scale what was actually spent over the days that had any activity
  const activeDays = Math.max(1, daily.filter((d) => d.calls > 0).length);
  const firstActive = daily.findIndex((d) => d.calls > 0);
  const elapsedDays = firstActive === -1 ? days : days - firstActive;
  const projectedMonthly = totals.cost && elapsedDays ? round((totals.cost / elapsedDays) * 30, 2) : 0;

  const monthStart = new Date();
  monthStart.setUTCDate(1);
  monthStart.setUTCHours(0, 0, 0, 0);
  const [mtd] = (await AiUsageLog.findAll({ attributes: [[fn("SUM", col("cost_usd")), "cost"]], where: { createdAt: { [Op.gte]: monthStart } }, raw: true })) as any[];
  const budget = process.env.AI_MONTHLY_BUDGET_USD ? Number(process.env.AI_MONTHLY_BUDGET_USD) : null;

  const estimate = await estimateCallTokens();
  const demoRows = await AiUsageLog.count({ where: { source: "demo" } });
  const aiModel = await getAiModel();
  const { rate, known } = findRate(aiModel);

  return {
    days,
    timezoneNote: "Days are UTC",
    totals: { ...totals, p95LatencyMs: p95, cacheHitRate: round(cacheHitRate, 4) },
    daily,
    bySource,
    byModel,
    byDocType,
    documents: {
      read: documentsRead,
      failed: statusCount("failed"),
      skipped: statusCount("skipped"),
      pending: statusCount("pending"),
      corrections,
      avgCostPerDocument: documentsRead ? round(messageCost / documentsRead) : 0,
      avgCallsPerDocument: documentsRead ? round(messageCalls / documentsRead, 2) : 0,
    },
    spend: {
      projectedMonthly,
      activeDays,
      monthToDate: round(num(mtd?.cost), 4),
      monthlyBudget: budget,
      budgetUsedPct: budget ? round((num(mtd?.cost) / budget) * 100, 1) : null,
    },
    config: {
      model: aiModel,
      modelKnown: known,
      rate,
      maxExamplesPerType: MAX_EXAMPLES_PER_TYPE,
      maxExamplesTotal: MAX_EXAMPLES_TOTAL,
      automationEnabled: process.env.AUTOMATION_ENABLED === "true",
      hasApiKey: !!process.env.ANTHROPIC_API_KEY,
      effort: "low",
      cacheMinutes: 5,
    },
    estimate: { ...estimate, byModel: estimateByModel(estimate) },
    rateCard: RATE_CARD,
    demoRows,
  };
};
