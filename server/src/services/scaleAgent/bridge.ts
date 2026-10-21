// Federal Bridge Formula check (spec §3) for a 5-axle tractor-semitrailer: steer, tandem drives,
// tandem trailer axles. Axle positions come from the equipment profiles; per-axle weights assume each
// tandem splits evenly (the CAT ticket only gives group totals), which the result states.
//
//   W = 500 × [ L×N/(N−1) + 12×N + 36 ], rounded to the nearest 500 lb (FHWA Table B)
//   - a tandem (axles more than 40 in and no more than 96 in apart) is governed by the tandem limit
//   - two consecutive tandems may carry the tandem limit each when first-to-last is 36 ft or more
//   - the whole-vehicle group can never exceed the gross limit

export interface TractorLayout {
  steer_to_drive_center_ft?: number | null;
  drive_spread_ft?: number | null;
  kingpin_to_drive_center_ft?: number | null;
}

export interface TrailerLayout {
  kpra_ft?: number | null;
  trailer_spread_ft?: number | null;
  axle_count?: number | null;
}

export interface BridgeGroup {
  axles: string; // "1–3"
  count: number;
  length_ft: number;
  weight_lb: number;
  limit_lb: number;
  over_lb: number;
  rule: "formula" | "two_tandems_36ft" | "gross";
}

export const bridgeFormula = (n: number, lengthFt: number) =>
  Math.round((500 * ((lengthFt * n) / (n - 1) + 12 * n + 36)) / 500) * 500;

// Axle positions in feet behind the steer axle, or the list of missing measurements
export const buildLayout = (
  tractor: TractorLayout | null | undefined,
  trailer: TrailerLayout | null | undefined,
): { positions: number[] } | { missing: string[] } => {
  const missing: string[] = [];
  const need = (v: any, name: string) => {
    if (typeof v !== "number" || !Number.isFinite(v) || v < 0) missing.push(name);
    return v as number;
  };
  const wb = need(tractor?.steer_to_drive_center_ft, "tractor steer-to-drive-center");
  const ds = need(tractor?.drive_spread_ft, "tractor drive axle spread");
  const kp = need(tractor?.kingpin_to_drive_center_ft, "fifth wheel position");
  const kpra = need(trailer?.kpra_ft, "trailer KPRA");
  const ts = need(trailer?.trailer_spread_ft, "trailer axle spread");
  if (trailer?.axle_count && trailer.axle_count !== 2) missing.push("only 2-axle trailers can be checked automatically");
  if (missing.length) return { missing };
  const kingpin = wb - kp;
  const rearmost = kingpin + kpra;
  return { positions: [0, wb - ds / 2, wb + ds / 2, rearmost - ts, rearmost] };
};

export const checkBridge = (
  positions: number[],
  weights: { steer: number; drive: number; trailer: number },
  limits: { tandem_lb: number; gross_lb: number },
): BridgeGroup[] => {
  const axleWeights = [weights.steer, weights.drive / 2, weights.drive / 2, weights.trailer / 2, weights.trailer / 2];
  const isTandem = (i: number, j: number) =>
    j - i === 1 && ((i === 1 && j === 2) || (i === 3 && j === 4)) && positions[j] - positions[i] > 40 / 12 && positions[j] - positions[i] <= 96 / 12;
  const groups: BridgeGroup[] = [];
  for (let i = 0; i < positions.length; i++) {
    for (let j = i + 1; j < positions.length; j++) {
      if (isTandem(i, j)) continue; // the tandem limit, checked per axle group
      const n = j - i + 1;
      const length = positions[j] - positions[i];
      const weight = axleWeights.slice(i, j + 1).reduce((a, b) => a + b, 0);
      let limit = bridgeFormula(n, length);
      let rule: BridgeGroup["rule"] = "formula";
      if (i === 1 && j === 4 && length >= 36 && 2 * limits.tandem_lb > limit) {
        limit = 2 * limits.tandem_lb;
        rule = "two_tandems_36ft";
      }
      if (i === 0 && j === positions.length - 1 && limits.gross_lb < limit) {
        limit = limits.gross_lb;
        rule = "gross";
      }
      groups.push({
        axles: `${i + 1}–${j + 1}`,
        count: n,
        length_ft: Math.round(length * 100) / 100,
        weight_lb: Math.round(weight),
        limit_lb: limit,
        over_lb: Math.max(0, Math.round(weight - limit)),
        rule,
      });
    }
  }
  return groups;
};
