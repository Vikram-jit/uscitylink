import { QueryTypes, Transaction } from "sequelize";
import { secondarySequelize } from "../../sequelize";
import type { ChatTrip, ChatTripStop } from "../../models/ChatTrip";

// A trip gets its Accountant → Route List row in the yard (driver_pay_details) when dispatch marks it
// completed — after the driver delivered and dispatch checked it — already filled in with the final
// dates, drivers, truck, trailers, stops, Samsara miles and lumper. The accountant never types a trip
// again; they only add load rate, fuel and pay.
//
// Written with plain SQL, the way the yard's own form saves (AccountantLoginController@store,
// 'pay-list'), minus its form-only side effects (low-average email/SMS). driver_pays is NOT
// written: the accountant's save creates it, so payroll and paystubs only ever see priced trips.
// Once a row is priced, this never overwrites it.

const q = (sql: string, replacements: Record<string, any>, transaction?: Transaction) =>
  secondarySequelize.query(sql, { replacements, transaction });

const dateOnly = (d: Date | null | undefined, zone = "America/Los_Angeles") =>
  d ? new Intl.DateTimeFormat("en-CA", { timeZone: zone, year: "numeric", month: "2-digit", day: "2-digit" }).format(d) : null;

const stopLabel = (s: ChatTripStop) =>
  [s.name, [s.city, s.state].filter(Boolean).join(", ")].filter(Boolean).join(" - ").slice(0, 250);

/** Pickup → drop pairs, the way the accountant enters "Trip details" (stop to next stop). */
export const legs = (stops: ChatTripStop[]) => {
  const ordered = [...stops].sort((a, b) => a.seq - b.seq);
  return ordered.slice(1).map((s, i) => ({ from: ordered[i], to: s }));
};

/**
 * The next trip id the Route List form would give: the latest route's trip id + 1, with "00" in front
 * (AccountantLoginController@create 'pay-list': '00' . (latest trip_id + 1)). Trip ids are not the row
 * id. One already taken is skipped. Locks the latest row so two new trips don't take the same number.
 */
async function nextTripNo(t: Transaction): Promise<string> {
  const latest = await secondarySequelize.query<{ trip_id: string | null }>(
    `SELECT trip_id FROM driver_pay_details ORDER BY created_at DESC, id DESC LIMIT 1 FOR UPDATE`,
    { type: QueryTypes.SELECT, transaction: t }
  );
  let n = (parseInt(String(latest[0]?.trip_id || "").replace(/\D/g, ""), 10) || 0) + 1;
  for (let tries = 0; tries < 100; tries++, n++) {
    const taken = await secondarySequelize.query(`SELECT id FROM driver_pay_details WHERE trip_id = :tripNo LIMIT 1`, {
      replacements: { tripNo: `00${n}` },
      type: QueryTypes.SELECT,
      transaction: t,
    });
    if (!taken.length) break;
  }
  return `00${n}`;
}

/** Creates the Route List row for a new trip. Returns its id and trip id. */
export async function createRouteRow(trip: ChatTrip, stops: ChatTripStop[], t: Transaction): Promise<{ id: number; tripNo: string }> {
  const team = !!trip.driver_id_2;
  // Numbered before the row exists: the "latest route" must be the previous one, not this one
  const tripNo = await nextTripNo(t);
  const [insertId] = await secondarySequelize.query(
    `INSERT INTO driver_pay_details
       (trip_id, trip_start_date, trip_end_date, driver_type, truck_id, trailer_id, ready_status, created_at, updated_at)
     VALUES (:tripNo, :start, :end, :type, :truck, :trailer, 'not-ready', NOW(), NOW())`,
    {
      type: QueryTypes.INSERT,
      transaction: t,
      replacements: {
        tripNo,
        start: dateOnly(trip.started_at || trip.planned_start_at),
        end: dateOnly(trip.ended_at || lastAppointment(stops)),
        type: team ? "team" : "single",
        truck: trip.truck_id ? String(trip.truck_id) : null,
        trailer: trip.trailer_ids || null,
      },
    }
  );
  const id = Number(insertId);

  // One expense row per driver: the Route List only lists rows that have a driver
  for (const driverId of [trip.driver_id_1, trip.driver_id_2].filter(Boolean)) {
    await q(
      `INSERT INTO driver_expenses (driver_pay_details_id, driver_id, payment_status, created_at, updated_at)
       VALUES (:id, :driver, 'unpaid', NOW(), NOW())`,
      { id, driver: String(driverId) },
      t
    );
  }
  await writeLegs(id, stops, t);
  return { id, tripNo };
}

function lastAppointment(stops: ChatTripStop[]): Date | null {
  const times = stops.map((s) => s.appointment_at).filter(Boolean) as Date[];
  return times.length ? new Date(Math.max(...times.map((d) => new Date(d).getTime()))) : null;
}

/**
 * The form's "Trip details" rows. Its Total Mileage is always the sum of these rows (recalculated when
 * the route is opened), so the rows must add up to the trip: the drive from where the trip started to
 * the first stop gets its own row ("Trip start → pickup"), which the accountant can delete when it
 * isn't paid. Returns the rows' total when every row has miles, otherwise null.
 */
async function writeLegs(id: number, stops: ChatTripStop[], t?: Transaction): Promise<number | null> {
  await q(`DELETE FROM driver_pay_mileages WHERE driver_pay_details_id = :id`, { id }, t);
  const ordered = [...stops].sort((a, b) => a.seq - b.seq);
  const rows: { from: string; to: string; miles: number | null }[] = [];
  const first = ordered[0];
  if (first && Number(first.mileage) > 0) rows.push({ from: "Trip start", to: stopLabel(first), miles: Number(first.mileage) });
  for (const leg of legs(ordered)) {
    rows.push({ from: stopLabel(leg.from), to: stopLabel(leg.to), miles: leg.to.mileage !== null && leg.to.mileage !== undefined ? Number(leg.to.mileage) : null });
  }
  for (const r of rows) {
    await q(
      `INSERT INTO driver_pay_mileages (driver_pay_details_id, pickup_location, delivery_location, mileage, created_at, updated_at)
       VALUES (:id, :from, :to, :miles, NOW(), NOW())`,
      { id, ...r },
      t
    );
  }
  if (!rows.length || rows.some((r) => r.miles === null)) return null;
  return Math.round(rows.reduce((sum, r) => sum + (r.miles || 0), 0) * 100) / 100;
}

/** The accountant has started pricing it (load rate, fuel, pay or a pay record): hands off. */
export async function isPriced(id: number): Promise<boolean> {
  const rows = await secondarySequelize.query<{ priced: number }>(
    `SELECT (
        (SELECT COUNT(*) FROM driver_pays WHERE driver_pay_details_id = :id) +
        (SELECT COUNT(*) FROM driver_expenses WHERE driver_pay_details_id = :id AND (pay_rate IS NOT NULL AND pay_rate <> '' OR grand_total IS NOT NULL AND grand_total <> 0)) +
        (SELECT COUNT(*) FROM driver_pay_details WHERE id = :id AND (
            COALESCE(load_rate_up, 0) <> 0 OR COALESCE(load_rate_down, 0) <> 0 OR
            COALESCE(load_rate_local, 0) <> 0 OR COALESCE(load_rate_extra, 0) <> 0 OR
            COALESCE(fuel_expense, 0) <> 0))
      ) AS priced`,
    { replacements: { id }, type: QueryTypes.SELECT }
  );
  return Number(rows[0]?.priced || 0) > 0;
}

/**
 * Keeps the row in step with the trip as it runs (real start/end dates, stops, Samsara mileage, the
 * lumper reported on the trip). Returns false when the row is already priced and was left alone.
 */
export async function syncRouteRow(trip: ChatTrip, stops: ChatTripStop[], extras: { lumper?: number | null } = {}): Promise<boolean> {
  const id = trip.driver_pay_details_id;
  if (!id) return false;
  if (await isPriced(id)) return false;
  // The form shows the rows' sum as Total Mileage: write the same number
  const rowsTotal = await writeLegs(id, stops);
  await q(
    `UPDATE driver_pay_details SET
       trip_start_date = :start, trip_end_date = :end, driver_type = :type,
       truck_id = :truck, trailer_id = :trailer, total_mileage = :miles,
       lumper = COALESCE(:lumper, lumper), updated_at = NOW()
     WHERE id = :id`,
    {
      id,
      start: dateOnly(trip.started_at || trip.planned_start_at),
      end: dateOnly(trip.ended_at || lastAppointment(stops)),
      type: trip.driver_id_2 ? "team" : "single",
      truck: trip.truck_id ? String(trip.truck_id) : null,
      trailer: trip.trailer_ids || null,
      miles: rowsTotal ?? trip.total_mileage ?? null,
      lumper: extras.lumper ?? null,
    }
  );
  // Drivers may have changed (team added, driver swapped)
  const drivers = [trip.driver_id_1, trip.driver_id_2].filter(Boolean).map(String);
  const existing = await secondarySequelize.query<{ id: number; driver_id: string }>(
    `SELECT id, driver_id FROM driver_expenses WHERE driver_pay_details_id = :id ORDER BY id`,
    { replacements: { id }, type: QueryTypes.SELECT }
  );
  for (let i = 0; i < Math.max(drivers.length, existing.length); i++) {
    if (drivers[i] && existing[i]) {
      if (existing[i].driver_id !== drivers[i]) {
        await q(`UPDATE driver_expenses SET driver_id = :d, updated_at = NOW() WHERE id = :e`, { d: drivers[i], e: existing[i].id });
      }
    } else if (drivers[i]) {
      await q(
        `INSERT INTO driver_expenses (driver_pay_details_id, driver_id, payment_status, created_at, updated_at)
         VALUES (:id, :d, 'unpaid', NOW(), NOW())`,
        { id, d: drivers[i] }
      );
    } else {
      await q(`DELETE FROM driver_expenses WHERE id = :e`, { e: existing[i].id });
    }
  }
  return true;
}

/** A cancelled trip takes its unpriced row with it; a priced one stays for the accountant. */
export async function removeRouteRow(trip: Pick<ChatTrip, "driver_pay_details_id">): Promise<boolean> {
  const id = trip.driver_pay_details_id;
  if (!id || (await isPriced(id))) return false;
  await secondarySequelize.transaction(async (t) => {
    await q(`DELETE FROM driver_pay_mileages WHERE driver_pay_details_id = :id`, { id }, t);
    await q(`DELETE FROM driver_expenses WHERE driver_pay_details_id = :id`, { id }, t);
    await q(`DELETE FROM driver_pay_details WHERE id = :id`, { id }, t);
  });
  return true;
}
