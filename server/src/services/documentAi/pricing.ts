// Anthropic list prices in USD per million tokens. Cached from the model catalog on 2026-10-06;
// confirm against https://www.anthropic.com/pricing before relying on them for invoices.
// Cache write = the standard 5-minute cache (1.25x base input price). Cache read = a fraction of input.
export interface Rate {
  model: string;
  label: string;
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
}

const rate = (model: string, label: string, input: number, output: number, cacheRead: number): Rate => ({
  model,
  label,
  input,
  output,
  cacheRead,
  cacheWrite: Math.round(input * 1.25 * 10000) / 10000,
});

export const RATE_CARD: Rate[] = [
  rate("claude-opus-5-5", "Claude Opus 5.5", 4, 20, 0.2),
  rate("claude-sonnet-5-5", "Claude Sonnet 5.5", 2, 10, 0.2),
  rate("claude-haiku-5-5", "Claude Haiku 5.5", 0.1, 0.5, 0.01),
  rate("claude-opus-5", "Claude Opus 5", 5, 25, 0.5),
  rate("claude-fable-5-1", "Claude Fable 5.1", 10, 50, 0.25),
];

const DEFAULT_RATE = RATE_CARD[0];

export const findRate = (model?: string | null): { rate: Rate; known: boolean } => {
  const exact = RATE_CARD.find((r) => model === r.model || (model || "").startsWith(`${r.model}-`));
  return exact ? { rate: exact, known: true } : { rate: DEFAULT_RATE, known: false };
};

export interface TokenUsage {
  input: number; // uncached input tokens
  cacheRead: number;
  cacheWrite: number;
  output: number;
}

export const computeCost = (model: string | null | undefined, usage: TokenUsage): number => {
  const { rate: r } = findRate(model);
  const cost =
    (usage.input * r.input + usage.cacheRead * r.cacheRead + usage.cacheWrite * r.cacheWrite + usage.output * r.output) /
    1_000_000;
  return Math.round(cost * 1_000_000) / 1_000_000;
};
