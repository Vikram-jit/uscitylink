// Reweigh feedback (spec §6, §9 test "new reweigh contradicts prediction"): compare what the recorded
// adjustment should have done with what the new ticket shows, and learn the trailer's real
// weight shift per tandem hole from it.

export interface AdjustmentMade {
  action: string; // tandems_forward | tandems_backward | fifth_wheel_forward | fifth_wheel_back | rework_cargo
  holes?: number | null;
  parked_confirmed?: boolean;
}

export interface Prediction {
  action: string;
  holes: number | null;
  measured_group: "trailer" | "steer" | null;
  expected_direction: 1 | -1 | 0;
  expected_shift_lb: number | null;
  actual_shift_lb: number | null;
  direction_ok: boolean | null;
  mismatch: boolean;
  learned_lb_per_hole: number | null;
  note: string;
}

type W = { steer?: number | null; drive?: number | null; trailer?: number | null; gross?: number | null };

// Which group gains weight when the move is made
const EFFECT: Record<string, { group: "trailer" | "steer"; direction: 1 | -1 }> = {
  tandems_forward: { group: "trailer", direction: 1 },
  tandems_backward: { group: "trailer", direction: -1 },
  fifth_wheel_forward: { group: "steer", direction: 1 },
  fifth_wheel_back: { group: "steer", direction: -1 },
};

export const comparePrediction = (
  before: W,
  after: W,
  adjustment: AdjustmentMade,
  lbPerHole: number | null,
): Prediction => {
  const effect = EFFECT[adjustment.action];
  const holes = adjustment.holes && adjustment.holes > 0 ? adjustment.holes : null;
  if (!effect) {
    return {
      action: adjustment.action,
      holes,
      measured_group: null,
      expected_direction: 0,
      expected_shift_lb: null,
      actual_shift_lb: null,
      direction_ok: null,
      mismatch: false,
      learned_lb_per_hole: null,
      note: "Cargo was reworked; no slide prediction to compare.",
    };
  }
  const b = before[effect.group];
  const a = after[effect.group];
  const actual = typeof a === "number" && typeof b === "number" ? a - b : null;
  const expected = holes && lbPerHole && effect.group === "trailer" ? effect.direction * holes * lbPerHole : null;
  const directionOk = actual === null ? null : actual === 0 ? false : Math.sign(actual) === effect.direction;
  const mismatch =
    directionOk === false ||
    (expected !== null && actual !== null && Math.abs(actual - expected) > Math.max(500, Math.abs(expected) * 0.5));
  const learned = effect.group === "trailer" && holes && directionOk && actual !== null ? Math.round(Math.abs(actual) / holes) : null;
  const note =
    actual === null
      ? "Reweigh is missing a weight; nothing to compare."
      : directionOk === false
        ? `Expected the ${effect.group} weight to ${effect.direction > 0 ? "rise" : "fall"}, but it ${actual === 0 ? "did not change" : actual > 0 ? "rose" : "fell"} (${Math.round(actual).toLocaleString("en-US")} lb). Check what was actually moved.`
        : expected !== null && mismatch
          ? `Moved ${Math.round(Math.abs(actual)).toLocaleString("en-US")} lb, expected about ${Math.round(Math.abs(expected)).toLocaleString("en-US")} lb.`
          : `Shifted ${Math.round(Math.abs(actual)).toLocaleString("en-US")} lb as expected.`;
  return {
    action: adjustment.action,
    holes,
    measured_group: effect.group,
    expected_direction: effect.direction,
    expected_shift_lb: expected,
    actual_shift_lb: actual,
    direction_ok: directionOk,
    mismatch,
    learned_lb_per_hole: learned,
    note,
  };
};

// Running average of the trailer's measured lb-per-hole
export const updateLbPerHole = (current: number | null | undefined, samples: number, learned: number) => {
  const n = Math.max(0, samples);
  return { lb_per_hole: Math.round(((current || 0) * n + learned) / (n + 1)), lb_per_hole_samples: n + 1 };
};
