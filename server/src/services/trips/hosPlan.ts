// The road ahead as a truck really drives it: US hours-of-service (FMCSA, property-carrying) plus the
// company's fuel stops, so trip ETAs include every stop the driver has to make.
//
//   30-minute break   after 8 hours of driving (any stop of 30+ minutes counts, e.g. a fuel stop)
//   10-hour rest      after 11 hours of driving, or 14 hours on duty since the last rest
//   1-hour fuel stop  every 1,000 miles (company rule)
//   Team              drivers swap at the wheel: the truck only stops for fuel
//
// Assumes the driver starts the road ahead rested (Samsara HOS clocks aren't read here). The 60/70-hour
// weekly limit isn't applied. No I/O: scripts/trips/hosPlan.check.ts tests it directly.

export const BREAK_AFTER_DRIVING = 8 * 60;
export const BREAK_MINUTES = 30;
export const MAX_DRIVING = 11 * 60;
export const DUTY_WINDOW = 14 * 60;
export const REST_MINUTES = 10 * 60;
export const FUEL_EVERY_MILES = 1000;
export const FUEL_MINUTES = 60;
/** Google plans car speeds; a loaded truck averages about this on the highway. */
export const TRUCK_MAX_MPH = 60;

export type StopKind = "break" | "rest" | "fuel";

export interface PlannedStop {
  kind: StopKind;
  minutes: number;
  /** Driving done before this stop (minutes) and where that is */
  afterDrivingMinutes: number;
  atMile: number;
  /** Minutes from now when the stop starts */
  startsAfter: number;
}

export interface HosPlan {
  miles: number;
  /** Truck driving time (Google's, or the 60 mph pace when that is slower) */
  drivingMinutes: number;
  stops: PlannedStop[];
  breakMinutes: number;
  restMinutes: number;
  fuelMinutes: number;
  /** Driving plus every stop */
  totalMinutes: number;
  team: boolean;
}

/** Truck driving time for a route Google timed for cars. */
export const truckDriving = (miles: number, googleMinutes: number) => Math.max(googleMinutes, (miles / TRUCK_MAX_MPH) * 60);

export function planTrip(miles: number, drivingMinutes: number, team: boolean): HosPlan {
  const stops: PlannedStop[] = [];
  const mph = drivingMinutes > 0 ? miles / (drivingMinutes / 60) : 0;
  const mileAt = (driven: number) => Math.round((driven / 60) * mph);
  let elapsed = 0;
  let driven = 0;
  let sinceBreak = 0; // driving since the last 30+ minute stop
  let sinceRest = 0; // driving since the last 10-hour rest
  let onDuty = 0; // time since the last rest (the 14-hour window)
  let nextFuelMile = FUEL_EVERY_MILES;

  const stop = (kind: StopKind, minutes: number) => {
    stops.push({ kind, minutes, afterDrivingMinutes: Math.round(driven), atMile: mileAt(driven), startsAfter: Math.round(elapsed) });
    elapsed += minutes;
    if (kind === "rest") {
      sinceBreak = 0;
      sinceRest = 0;
      onDuty = 0;
    } else {
      sinceBreak = 0; // 30+ minutes off the wheel
      onDuty += minutes;
    }
    if (kind === "fuel") nextFuelMile += FUEL_EVERY_MILES;
  };

  let guard = 0;
  while (driven < drivingMinutes - 0.01 && guard++ < 10_000) {
    if (!team && onDuty >= DUTY_WINDOW) {
      stop("rest", REST_MINUTES);
      continue;
    }
    const toEnd = drivingMinutes - driven;
    const toFuel = mph > 0 ? ((nextFuelMile - (driven / 60) * mph) / mph) * 60 : Infinity;
    const limits = team
      ? [toEnd, toFuel]
      : [toEnd, toFuel, BREAK_AFTER_DRIVING - sinceBreak, MAX_DRIVING - sinceRest, DUTY_WINDOW - onDuty];
    const step = Math.max(0, Math.min(...limits));
    driven += step;
    elapsed += step;
    sinceBreak += step;
    sinceRest += step;
    onDuty += step;
    if (driven >= drivingMinutes - 0.01) break;

    const fuelDue = (driven / 60) * mph >= nextFuelMile - 0.5;
    if (!team && (sinceRest >= MAX_DRIVING - 0.01 || onDuty >= DUTY_WINDOW - 0.01)) {
      if (fuelDue) stop("fuel", FUEL_MINUTES);
      stop("rest", REST_MINUTES);
    } else if (fuelDue) {
      stop("fuel", FUEL_MINUTES);
    } else if (!team && sinceBreak >= BREAK_AFTER_DRIVING - 0.01) {
      stop("break", BREAK_MINUTES);
    }
  }

  const sum = (kind: StopKind) => stops.filter((s) => s.kind === kind).reduce((a, s) => a + s.minutes, 0);
  return {
    miles: Math.round(miles),
    drivingMinutes: Math.round(drivingMinutes),
    stops,
    breakMinutes: sum("break"),
    restMinutes: sum("rest"),
    fuelMinutes: sum("fuel"),
    totalMinutes: Math.round(elapsed),
    team,
  };
}

/** Minutes from now to reach the point where [drivenMinutes] of driving is done (stops before it included). */
export function elapsedAt(plan: HosPlan, drivenMinutes: number): number {
  return drivenMinutes + plan.stops.filter((s) => s.afterDrivingMinutes < drivenMinutes - 0.5).reduce((a, s) => a + s.minutes, 0);
}
