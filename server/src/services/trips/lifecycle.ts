// The trip lifecycle in one place: which action moves a trip from which status, and who may do it.
// tripService.ts applies these rules to the database; the driver app and the dashboard only offer the
// actions allowed here. No I/O in this file (scripts/trips/lifecycle.check.ts tests it directly).
//
//   scheduled → offered → planned → accepted → started → rolling → ended → paperwork → completed → routed
//   (on_hold from any active status and back; cancelled before completed)

export type TripStatus =
  | "scheduled"
  | "offered"
  | "planned"
  | "accepted"
  | "started"
  | "rolling"
  | "ended"
  | "paperwork"
  | "completed"
  | "routed"
  | "on_hold"
  | "cancelled";

export type TripAction =
  | "offer"
  | "send"
  | "decline_offer"
  | "accept"
  | "start"
  | "rolling"
  | "arrive"
  | "depart"
  | "end"
  | "paperwork"
  | "complete"
  | "route"
  | "hold"
  | "resume"
  | "cancel";

export type ActorRole = "driver" | "dispatcher" | "accountant" | "ai" | "system";

interface Rule {
  from: TripStatus[];
  /** Status afterwards; "same" keeps it (stop arrivals), "held" goes back to the status before hold. */
  to: TripStatus | "same" | "held";
  who: ActorRole[];
}

const ON_THE_ROAD: TripStatus[] = ["started", "rolling"];
const ACTIVE: TripStatus[] = ["planned", "accepted", "started", "rolling", "ended", "paperwork"];

export const RULES: Record<TripAction, Rule> = {
  // A lined-up load is offered to the driver (they asked, or finished/loaded the current one).
  // Only dispatch actually sends it.
  offer: { from: ["scheduled"], to: "offered", who: ["system", "dispatcher"] },
  send: { from: ["scheduled", "offered"], to: "planned", who: ["dispatcher"] },
  decline_offer: { from: ["offered"], to: "scheduled", who: ["dispatcher"] },
  accept: { from: ["planned"], to: "accepted", who: ["driver", "dispatcher"] },
  start: { from: ["planned", "accepted"], to: "started", who: ["driver", "dispatcher"] },
  // The driver's flow is three taps: Got it → Rolling → Delivered. Rolling also starts the trip.
  rolling: { from: ["planned", "accepted", "started"], to: "rolling", who: ["driver", "dispatcher"] },
  arrive: { from: ON_THE_ROAD, to: "same", who: ["driver", "dispatcher"] },
  // Leaving a stop means moving again
  depart: { from: ON_THE_ROAD, to: "rolling", who: ["driver", "dispatcher"] },
  end: { from: ON_THE_ROAD, to: "ended", who: ["driver", "dispatcher"] },
  paperwork: { from: ["ended"], to: "paperwork", who: ["system", "ai", "dispatcher"] },
  complete: { from: ["ended", "paperwork"], to: "completed", who: ["dispatcher"] },
  route: { from: ["completed"], to: "routed", who: ["accountant", "system"] },
  hold: { from: ACTIVE, to: "on_hold", who: ["dispatcher", "driver", "system"] },
  resume: { from: ["on_hold"], to: "held", who: ["dispatcher"] },
  cancel: {
    from: ["scheduled", "offered", ...ACTIVE, "on_hold"],
    to: "cancelled",
    who: ["dispatcher"],
  },
};

export const UNDO_WINDOW_MS = 5 * 60 * 1000;

export type Check = { ok: true; to: TripStatus } | { ok: false; error: string };

export function check(
  action: TripAction,
  status: TripStatus,
  role: ActorRole,
  opts: { statusBeforeHold?: TripStatus | null; note?: string | null } = {}
): Check {
  const rule = RULES[action];
  if (!rule) return { ok: false, error: "Unknown action" };
  if (!rule.who.includes(role)) return { ok: false, error: `${label(action)} is done by ${rule.who.join(" or ")}` };
  if (!rule.from.includes(status)) return { ok: false, error: `Can't ${label(action).toLowerCase()} a trip that is ${statusLabel(status)}` };
  if (action === "cancel" && !opts.note?.trim()) return { ok: false, error: "Say why the trip is cancelled" };
  if (rule.to === "same") return { ok: true, to: status };
  if (rule.to === "held") {
    const back = opts.statusBeforeHold;
    return back && back !== "on_hold" ? { ok: true, to: back } : { ok: false, error: "Nothing to resume" };
  }
  return { ok: true, to: rule.to };
}

/** Trips a driver is on (one at a time) — these get the driver app's trip card. */
export const DRIVER_CURRENT: TripStatus[] = ["planned", "accepted", "started", "rolling", "ended", "paperwork", "on_hold"];

export interface StopProgress {
  id: number;
  seq: number;
  type: "pickup" | "drop" | "switch" | "yard";
  name: string | null;
  arrived_at: Date | string | null;
  departed_at: Date | string | null;
}

export type NextStep =
  | { action: "accept" | "start" | "rolling" | "end"; label: string; stopId?: number }
  | { action: "arrive" | "depart"; label: string; stopId: number }
  | null;

/**
 * The one big button the driver sees — three steps only, so the app never gets in their way:
 * Got it (accept) → Rolling (loaded and on the way) → Delivered (end trip). Stop arrivals and other
 * details are optional for dispatch; the driver isn't asked for them.
 */
export function nextStep(status: TripStatus, stops: StopProgress[]): NextStep {
  const last = [...stops].sort((a, b) => a.seq - b.seq).pop();
  if (status === "planned") return { action: "accept", label: "Got it" };
  if (status === "accepted" || status === "started") return { action: "rolling", label: "Loaded — rolling" };
  if (status === "rolling") {
    // A leg that hands the load over (our yard / a meet point) ends there, not at the customer
    const label = last?.type === "yard" ? "Dropped at yard — end trip" : last?.type === "switch" ? "Handed over — end trip" : "Delivered — end trip";
    return { action: "end", label, stopId: last?.id };
  }
  return null;
}

const LABELS: Record<TripAction, string> = {
  offer: "Offer",
  send: "Send",
  decline_offer: "Decline",
  accept: "Accept",
  start: "Start",
  rolling: "Mark rolling",
  arrive: "Arrive",
  depart: "Depart",
  end: "End",
  paperwork: "Mark paperwork",
  complete: "Complete",
  route: "Route",
  hold: "Hold",
  resume: "Resume",
  cancel: "Cancel",
};
export const label = (a: TripAction) => LABELS[a] || a;

const STATUS_LABELS: Record<TripStatus, string> = {
  scheduled: "scheduled",
  offered: "waiting for dispatch to confirm",
  planned: "sent to the driver",
  accepted: "accepted",
  started: "started",
  rolling: "rolling",
  ended: "delivered",
  paperwork: "waiting for paperwork check",
  completed: "completed",
  routed: "in the pay route",
  on_hold: "on hold",
  cancelled: "cancelled",
};
export const statusLabel = (s: TripStatus) => STATUS_LABELS[s] || s;
