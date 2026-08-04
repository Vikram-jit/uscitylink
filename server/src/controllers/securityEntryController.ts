import { Request, Response } from "express";
import { QueryTypes, Op } from "sequelize";
import moment from "moment-timezone";
import { secondarySequelize } from "../sequelize";
import { Message } from "../models/Message";

export async function getEntryFormData(
  req: Request,
  res: Response
): Promise<any> {
  try {
    // Matches VehicleEntryTimeController::dashboard() exactly:
    // Truck::where('status','1') — Truck uses SoftDeletes, so Eloquent implicitly
    // adds deleted_at IS NULL too; we filter it explicitly since this is raw SQL.
    const trucks = await secondarySequelize.query<any>(
      `SELECT t.id, t.number, t.license_plate_number AS licensePlateNumber,
              e.status AS latestEntryStatus
       FROM trucks t
       LEFT JOIN daily_vehicle_entries e
         ON e.id = (SELECT MAX(id) FROM daily_vehicle_entries WHERE truck_id = t.id)
       WHERE t.status = '1' AND t.deleted_at IS NULL
       ORDER BY CAST(t.number AS UNSIGNED) ASC`,
      { type: QueryTypes.SELECT }
    );

    // Matches Trailer::where('company_id',null)->where('deleted_at',null)->where('is_active','1')
    const trailers = await secondarySequelize.query<any>(
      `SELECT tr.id, tr.number, tr.license_plate_number AS licensePlateNumber,
              e.status AS latestEntryStatus, s.ready_status AS latestReadyStatus
       FROM trailers tr
       LEFT JOIN daily_vehicle_entries e
         ON e.id = (SELECT MAX(id) FROM daily_vehicle_entries WHERE trailer_id = tr.id)
       LEFT JOIN daily_vehicle_sheet_news s
         ON s.id = (SELECT MAX(id) FROM daily_vehicle_sheet_news WHERE vehicle_type = 'trailer' AND vehicle_id = tr.id)
       WHERE tr.is_active = '1' AND tr.company_id IS NULL AND tr.deleted_at IS NULL
       ORDER BY CAST(tr.number AS UNSIGNED) ASC`,
      { type: QueryTypes.SELECT }
    );

    const drivers = await secondarySequelize.query<any>(
      `SELECT id, name FROM drivers WHERE status = '1' ORDER BY name ASC`,
      { type: QueryTypes.SELECT }
    );

    return res.status(200).json({
      status: true,
      message: "Get Entry Form Data Successfully.",
      data: { trucks, trailers, drivers },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

// Truck-level checklist — shown/required once a truck is selected, regardless
// of whether a trailer is attached (moved out of the trailer-gated group).
const TRUCK_CHECKLIST_FIELDS = [
  "truckKeyAttached",
  "truckMatt",
  "logBookStand",
  "securityGuardInspect",
];

const YES_NO_FIELDS_WITH_TRAILER = [
  "spareTyre",
  "fireExt",
  "warningTriangles",
  "paperWork",
  "damage",
];

function isBlank(v: any): boolean {
  return v === undefined || v === null || v === "";
}

export async function createEntry(req: Request, res: Response): Promise<any> {
  try {
    const b = req.body || {};
    const errors: string[] = [];

    if (isBlank(b.truckId)) errors.push("The truck field is required.");
    if (isBlank(b.status)) errors.push("The status field is required.");
    if (isBlank(b.truckFuel)) errors.push("The truck fuel field is required.");
    if (isBlank(b.truckLicensePlate))
      errors.push("The truck license plate field is required.");
    if (isBlank(b.security)) errors.push("The security field is required.");

    for (const field of TRUCK_CHECKLIST_FIELDS) {
      if (isBlank(b[field])) errors.push(`The ${field} field is required.`);
    }

    const hasTrailer = !isBlank(b.trailerId);
    if (hasTrailer) {
      if (isBlank(b.trailerFuel)) errors.push("The trailer fuel field is required.");
      if (isBlank(b.trailerLicensePlate))
        errors.push("The trailer license plate field is required.");
      if (isBlank(b.emptyLoaded)) errors.push("The empty/loaded field is required.");
      for (const field of YES_NO_FIELDS_WITH_TRAILER) {
        if (isBlank(b[field])) errors.push(`The ${field} field is required.`);
      }
    }

    const isLoaded = b.emptyLoaded === "loaded";
    const isEmpty = b.emptyLoaded === "empty";

    if (hasTrailer && isLoaded) {
      if (isBlank(b.loadType)) errors.push("The load type field is required.");
      if (isBlank(b.seal)) errors.push("The seal field is required.");
      if (isBlank(b.alartm)) errors.push("The alarm field is required.");
      if (isBlank(b.deliveryAddress))
        errors.push("The delivery address field is required.");
      if (isBlank(b.deliverAt)) errors.push("The deliver at field is required.");
      else {
        const deliverAt = moment.tz(b.deliverAt, "America/Los_Angeles");
        if (deliverAt.isValid() && deliverAt.isBefore(moment.tz("America/Los_Angeles"))) {
          errors.push("The deliver at time cannot be in the past.");
        }
      }
      if (b.loadType === "refer") {
        if (isBlank(b.setTemp)) errors.push("The set temp field is required.");
        if (isBlank(b.runningTemp)) errors.push("The running temp field is required.");
      }
    }

    if (hasTrailer && isEmpty) {
      if (isBlank(b.loadLocks)) errors.push("The load locks field is required.");
    }

    if (errors.length > 0) {
      return res.status(400).json({ status: false, message: errors[0], errors });
    }

    const now = moment.tz("America/Los_Angeles").format("YYYY-MM-DD HH:mm:ss");
    const today = moment.tz("America/Los_Angeles").format("YYYY-MM-DD");

    const driverId: string | null =
      Array.isArray(b.driverIds) && b.driverIds.length > 0
        ? b.driverIds.join(",")
        : null;

    const keepTemp = hasTrailer && isLoaded && b.loadType === "refer";
    const keepSeal = hasTrailer && isLoaded;
    const keepLoadLocks = hasTrailer && isEmpty;

    const insertResult: any = await secondarySequelize.query(
      `INSERT INTO daily_vehicle_entries
        (date, truck_id, truck_license_plate, driver_id, trailer_id, empty_loaded, load_type,
         truck_fuel, trailer_fuel, alartm, spare_tyre, paper_work,
         truck_key_attached, truck_matt, log_book_stand, security_guard_inspect, log_book_remark,
         load_locak, seal, fire_ext, warning_triangles, fuel_card, fuel_card_remark,
         damage, damage_description, trailer_license_plate, set_temp, running_temp,
         status, description, security, created_at, updated_at)
       VALUES
        (:date, :truckId, :truckLicensePlate, :driverId, :trailerId, :emptyLoaded, :loadType,
         :truckFuel, :trailerFuel, :alartm, :spareTyre, :paperWork,
         :truckKeyAttached, :truckMatt, :logBookStand, :securityGuardInspect, :logBookRemark,
         :loadLocks, :seal, :fireExt, :warningTriangles, :fuelCard, :fuelCardRemark,
         :damage, :damageDescription, :trailerLicensePlate, :setTemp, :runningTemp,
         :status, :description, :security, :createdAt, :updatedAt)`,
      {
        replacements: {
          date: today,
          truckId: b.truckId ?? null,
          truckLicensePlate: b.truckLicensePlate ?? null,
          driverId,
          trailerId: hasTrailer ? b.trailerId : null,
          emptyLoaded: hasTrailer ? b.emptyLoaded ?? null : null,
          loadType: hasTrailer && isLoaded ? b.loadType ?? null : null,
          truckFuel: b.truckFuel ?? null,
          trailerFuel: hasTrailer ? b.trailerFuel ?? null : null,
          alartm: keepSeal ? b.alartm ?? null : null,
          spareTyre: hasTrailer ? b.spareTyre ?? null : null,
          paperWork: hasTrailer ? b.paperWork ?? null : null,
          truckKeyAttached: b.truckKeyAttached ?? null,
          truckMatt: b.truckMatt ?? null,
          logBookStand: b.logBookStand ?? null,
          securityGuardInspect: b.securityGuardInspect ?? null,
          logBookRemark: b.logBookRemark ?? null,
          loadLocks: keepLoadLocks ? b.loadLocks ?? null : null,
          seal: keepSeal ? b.seal ?? null : null,
          fireExt: hasTrailer ? b.fireExt ?? null : null,
          warningTriangles: hasTrailer ? b.warningTriangles ?? null : null,
          fuelCard: b.fuelCard ?? null,
          fuelCardRemark: b.fuelCardRemark ?? null,
          damage: hasTrailer ? b.damage ?? null : null,
          damageDescription: b.damage === "yes" ? b.damageDescription ?? null : null,
          trailerLicensePlate: hasTrailer ? b.trailerLicensePlate ?? null : null,
          setTemp: keepTemp ? b.setTemp ?? null : null,
          runningTemp: keepTemp ? b.runningTemp ?? null : null,
          status: b.status,
          description: b.description ?? null,
          security: b.security ?? null,
          createdAt: now,
          updatedAt: now,
        },
        type: QueryTypes.INSERT,
      }
    );

    const entryId = insertResult?.[0];

    let delivery: any = null;
    const hasDeliveryData =
      !isBlank(b.deliveryAddress) || !isBlank(b.deliverAt) || !isBlank(b.departureAt);

    if (hasTrailer && isLoaded && hasDeliveryData) {
      await secondarySequelize.query(
        `INSERT INTO daily_vehicle_entry_deliveries
          (daily_vehicle_entry_id, deliver_at, departure_at, address, city, state, zipcode,
           country, lat, lng, distance_miles, duration_minutes, created_at, updated_at)
         VALUES
          (:entryId, :deliverAt, :departureAt, :address, :city, :state, :zipcode,
           :country, :lat, :lng, :distanceMiles, :durationMinutes, :createdAt, :updatedAt)`,
        {
          replacements: {
            entryId,
            deliverAt: b.deliverAt ?? null,
            departureAt: b.departureAt ?? null,
            address: b.deliveryAddress ?? null,
            city: b.deliveryCity ?? null,
            state: b.deliveryState ?? null,
            zipcode: b.deliveryZipcode ?? null,
            country: b.deliveryCountry ?? null,
            lat: b.deliveryLat ?? null,
            lng: b.deliveryLng ?? null,
            distanceMiles: b.deliveryDistanceMiles ?? null,
            durationMinutes: b.deliveryDurationMinutes ?? null,
            createdAt: now,
            updatedAt: now,
          },
          type: QueryTypes.INSERT,
        }
      );
      delivery = {
        deliverAt: b.deliverAt ?? null,
        departureAt: b.departureAt ?? null,
        address: b.deliveryAddress ?? null,
      };
    }

    // Side effects (trailer sheet tracking + gate-message completion) mirror the web's
    // DailyVehicleEntryController::store() exactly, but are isolated here so a failure in
    // either (e.g. no matching message) can't block the core entry from having been saved.
    try {
      await applyGateSideEffects(b, entryId, today, now, req.user?.id);
    } catch (sideEffectErr: any) {
      console.error("Entry side-effect error:", sideEffectErr?.message || sideEffectErr);
    }

    return res.status(200).json({
      status: true,
      message: "Vehicle entry saved successfully.",
      data: { id: entryId, date: today, status: b.status, delivery },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

/// Mirrors DailyVehicleEntryController::store()'s two post-save side effects on the web:
/// trailer "sheet" tracking (daily_vehicle_sheet_news + 2 log tables), and completing the
/// matching driver-app gate message. See app/Http/Controllers/web/Security/
/// DailyVehicleEntryController.php:420-527 (entry), 530-587 (depart), 604-623 (message).
async function applyGateSideEffects(
  b: any,
  entryId: number,
  today: string,
  now: string,
  staffId?: string
): Promise<void> {
  const hasTrailer = !isBlank(b.trailerId);

  if (b.status === "entry" && hasTrailer) {
    const oldSheetRows = await secondarySequelize.query<any>(
      `SELECT * FROM daily_vehicle_sheet_news
       WHERE vehicle_id = :trailerId AND vehicle_type = 'trailer' AND date = :today
       ORDER BY created_at DESC LIMIT 1`,
      { replacements: { trailerId: b.trailerId, today }, type: QueryTypes.SELECT }
    );

    let previousData: any = null;
    if (oldSheetRows.length > 0) {
      const oldSheet = oldSheetRows[0];
      previousData = {
        ready_status: oldSheet.ready_status,
        empty_loaded: oldSheet.empty_loaded,
        location: oldSheet.location,
        added_by: oldSheet.added_by,
        flag: oldSheet.flag,
        moved: oldSheet.moved,
      };
      await secondarySequelize.query(`DELETE FROM daily_vehicle_sheet_news WHERE id = :id`, {
        replacements: { id: oldSheet.id },
        type: QueryTypes.DELETE,
      });
    }

    // Safety net for any other duplicate rows the same day (matches Laravel's duplicateSheetExists check).
    await secondarySequelize.query(
      `DELETE FROM daily_vehicle_sheet_news
       WHERE vehicle_id = :trailerId AND vehicle_type = 'trailer' AND date = :today`,
      { replacements: { trailerId: b.trailerId, today }, type: QueryTypes.DELETE }
    );

    const sheetInsert: any = await secondarySequelize.query(
      `INSERT INTO daily_vehicle_sheet_news
        (date, vehicle_id, vehicle_type, empty_loaded, departure_date, ready_status, location,
         normal_inspection, note, added_by, problem, flag, previous_sheet_data,
         daily_vehicle_entry_id, created_at, updated_at)
       VALUES
        (:today, :trailerId, 'trailer', :emptyLoaded, :departureAt, 'not-ready', 'in_yard',
         '1', :note, 'Security', 'no', 'automatic', :previousSheetData,
         :entryId, :createdAt, :updatedAt)`,
      {
        replacements: {
          today,
          trailerId: b.trailerId,
          emptyLoaded: b.emptyLoaded ?? null,
          departureAt: b.departureAt ?? null,
          note: b.description ?? null,
          previousSheetData: previousData ? JSON.stringify(previousData) : null,
          entryId,
          createdAt: now,
          updatedAt: now,
        },
        type: QueryTypes.INSERT,
      }
    );
    const sheetId = sheetInsert?.[0];

    // Note: Laravel's own log_news insert omits empty_loaded even though the column exists —
    // ported faithfully (left null) rather than "fixing" it, per "same functionality" request.
    await secondarySequelize.query(
      `INSERT INTO daily_vehicle_sheet_log_news
        (daily_vehicle_sheets_id, vehicle_id, vehicle_type, departure_date, ready_status, created_at, updated_at)
       VALUES
        (:sheetId, :trailerId, 'trailer', :departureAt, 'not-ready', :createdAt, :updatedAt)`,
      {
        replacements: {
          sheetId,
          trailerId: b.trailerId,
          departureAt: b.departureAt ?? null,
          createdAt: now,
          updatedAt: now,
        },
        type: QueryTypes.INSERT,
      }
    );

    await secondarySequelize.query(
      `INSERT INTO daily_vehicle_status_log_news
        (daily_vehicle_sheets_id, vehicle_id, vehicle_type, ready_status, departure_date, empty_loaded, created_at, updated_at)
       VALUES
        (:sheetId, :trailerId, 'trailer', 'not-ready', :departureAt, :emptyLoaded, :createdAt, :updatedAt)`,
      {
        replacements: {
          sheetId,
          trailerId: b.trailerId,
          departureAt: b.departureAt ?? null,
          emptyLoaded: b.emptyLoaded ?? null,
          createdAt: now,
          updatedAt: now,
        },
        type: QueryTypes.INSERT,
      }
    );
  }

  if (b.status === "depart") {
    if (hasTrailer) {
      const trailerSheetRows = await secondarySequelize.query<any>(
        `SELECT id FROM daily_vehicle_sheet_news
         WHERE vehicle_id = :trailerId AND vehicle_type = 'trailer'
           AND location = 'in_yard' AND isDeparted IS NULL
         ORDER BY date DESC, created_at DESC LIMIT 1`,
        { replacements: { trailerId: b.trailerId }, type: QueryTypes.SELECT }
      );
      if (trailerSheetRows.length > 0) {
        await secondarySequelize.query(
          `UPDATE daily_vehicle_sheet_news
           SET location = 'Departed', isDeparted = :now, departed_truck_id = :truckId, updated_at = :now
           WHERE id = :id`,
          {
            replacements: { now, truckId: b.truckId ?? null, id: trailerSheetRows[0].id },
            type: QueryTypes.UPDATE,
          }
        );
      }
    }

    // Nothing in this port's scope currently creates truck sheet rows, so this is typically
    // a no-op — ported for parity regardless, matching the Laravel behavior exactly.
    const truckSheetRows = await secondarySequelize.query<any>(
      `SELECT id FROM daily_vehicle_sheet_news
       WHERE vehicle_type = 'truck' AND vehicle_id = :truckId AND DATE(departure_date) = :today
       LIMIT 1`,
      { replacements: { truckId: b.truckId, today }, type: QueryTypes.SELECT }
    );
    if (truckSheetRows.length > 0) {
      await secondarySequelize.query(
        `UPDATE daily_vehicle_sheet_news
         SET location = 'Departed', isDeparted = :now, updated_at = :now
         WHERE id = :id`,
        { replacements: { now, id: truckSheetRows[0].id }, type: QueryTypes.UPDATE }
      );
    }
  }

  const truckRows = await secondarySequelize.query<{ number: string }>(
    `SELECT number FROM trucks WHERE id = :truckId LIMIT 1`,
    { replacements: { truckId: b.truckId }, type: QueryTypes.SELECT }
  );
  const truckNumber = truckRows[0]?.number;
  if (truckNumber) {
    const phrase =
      b.status === "entry"
        ? `Truck #${truckNumber} has arrived at U S CITYLINK`
        : `Truck #${truckNumber} has departed U S CITYLINK`;
    const cutoff = moment.tz("America/Los_Angeles").subtract(24, "hours").toDate();

    await Message.update(
      { isCompleted: true, completedBy: null, note: `Completed by Security Guard By Mobile App` },
      {
        where: {
          body: { [Op.like]: `${phrase}%` },
          isCompleted: false,
          createdAt: { [Op.gte]: cutoff },
        },
      }
    );
  }
}

/// Batch-resolves the comma-joined driver_id column into "Name, Name" strings
/// for a page of rows in ONE extra query (not N+1), mirroring the same
/// grouped-query approach used for latestEntryStatus/latestReadyStatus above.
export async function resolveDriverNames(
  rows: any[],
  driverIdKey: string
): Promise<Map<number, string>> {
  const idSet = new Set<string>();
  for (const row of rows) {
    const raw = row[driverIdKey];
    if (!raw) continue;
    for (const part of String(raw).split(",")) {
      const trimmed = part.trim();
      if (trimmed) idSet.add(trimmed);
    }
  }
  if (idSet.size === 0) return new Map();

  const drivers = await secondarySequelize.query<{ id: number; name: string }>(
    `SELECT id, name FROM drivers WHERE id IN (:ids)`,
    { replacements: { ids: Array.from(idSet) }, type: QueryTypes.SELECT }
  );
  const nameById = new Map<number, string>();
  for (const d of drivers) nameById.set(d.id, d.name);
  return nameById;
}

export function driverNamesFor(rawDriverId: string | null, nameById: Map<number, string>): string | null {
  if (!rawDriverId) return null;
  const names = String(rawDriverId)
    .split(",")
    .map((idStr) => nameById.get(Number(idStr.trim())))
    .filter((n): n is string => !!n);
  return names.length > 0 ? names.join(", ") : null;
}

export async function getEntries(req: Request, res: Response): Promise<any> {
  try {
    const tab = (req.query.tab as string) === "depart" ? "depart" : "entry";
    const page = parseInt(req.query.page as string) || 1;
    const pageSize = parseInt(req.query.pageSize as string) || 20;
    const search = ((req.query.search as string) || "").trim();
    const offset = (page - 1) * pageSize;

    const searchCondition = search
      ? `AND (t.number LIKE :search OR tr.number LIKE :search)`
      : "";
    const replacements: any = { tab, limit: pageSize, offset };
    if (search) replacements.search = `%${search}%`;

    const totalResult = await secondarySequelize.query<{ total: number }>(
      `SELECT COUNT(*) AS total
       FROM daily_vehicle_entries e
       LEFT JOIN trucks t ON t.id = e.truck_id
       LEFT JOIN trailers tr ON tr.id = e.trailer_id
       WHERE e.status = :tab ${searchCondition}`,
      { replacements, type: QueryTypes.SELECT }
    );
    const totalItems = Number(totalResult?.[0]?.total || 0);

    const rows = await secondarySequelize.query<any>(
      `SELECT e.id, e.date, e.created_at AS createdAt, e.status,
              e.truck_license_plate AS truckLicensePlate,
              e.trailer_license_plate AS trailerLicensePlate,
              e.empty_loaded AS emptyLoaded, e.load_type AS loadType,
              e.driver_id AS driverId, e.security,
              t.number AS truckNumber, tr.number AS trailerNumber
       FROM daily_vehicle_entries e
       LEFT JOIN trucks t ON t.id = e.truck_id
       LEFT JOIN trailers tr ON tr.id = e.trailer_id
       WHERE e.status = :tab ${searchCondition}
       ORDER BY e.id DESC
       LIMIT :limit OFFSET :offset`,
      { replacements, type: QueryTypes.SELECT }
    );

    const nameById = await resolveDriverNames(rows, "driverId");
    const entries = rows.map((row) => ({
      ...row,
      driverNames: driverNamesFor(row.driverId, nameById),
    }));

    return res.status(200).json({
      status: true,
      message: "Get Entries Successfully.",
      data: {
        entries,
        pagination: {
          currentPage: page,
          pageSize,
          totalPages: Math.ceil(totalItems / pageSize),
          totalItems,
        },
      },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function getEntryById(req: Request, res: Response): Promise<any> {
  try {
    const id = req.params.id;

    const rows = await secondarySequelize.query<any>(
      `SELECT e.id, e.date, e.created_at AS createdAt, e.updated_at AS updatedAt, e.status,
              e.truck_id AS truckId, e.truck_fuel AS truckFuel,
              e.truck_license_plate AS truckLicensePlate,
              e.trailer_id AS trailerId, e.trailer_fuel AS trailerFuel,
              e.trailer_license_plate AS trailerLicensePlate,
              e.driver_id AS driverId, e.empty_loaded AS emptyLoaded, e.load_type AS loadType,
              e.truck_key_attached AS truckKeyAttached, e.truck_matt AS truckMatt,
              e.log_book_stand AS logBookStand, e.security_guard_inspect AS securityGuardInspect,
              e.spare_tyre AS spareTyre, e.anual_inspection AS anualInspection,
              e.registration, e.paper_work AS paperWork, e.damage, e.damage_description AS damageDescription,
              e.fire_ext AS fireExt, e.warning_triangles AS warningTriangles,
              e.seal, e.alartm, e.load_locak AS loadLocks,
              e.set_temp AS setTemp, e.running_temp AS runningTemp,
              e.log_book_remark AS logBookRemark, e.fuel_card AS fuelCard,
              e.fuel_card_remark AS fuelCardRemark, e.description, e.security,
              t.number AS truckNumber, tr.number AS trailerNumber,
              d.deliver_at AS deliverAt, d.departure_at AS departureAt,
              d.address AS deliveryAddress, d.city AS deliveryCity, d.state AS deliveryState,
              d.zipcode AS deliveryZipcode, d.country AS deliveryCountry,
              d.lat AS deliveryLat, d.lng AS deliveryLng,
              d.distance_miles AS deliveryDistanceMiles, d.duration_minutes AS deliveryDurationMinutes
       FROM daily_vehicle_entries e
       LEFT JOIN trucks t ON t.id = e.truck_id
       LEFT JOIN trailers tr ON tr.id = e.trailer_id
       LEFT JOIN daily_vehicle_entry_deliveries d ON d.daily_vehicle_entry_id = e.id
       WHERE e.id = :id
       LIMIT 1`,
      { replacements: { id }, type: QueryTypes.SELECT }
    );

    const entry = rows?.[0];
    if (!entry) {
      return res.status(400).json({ status: false, message: "Entry not found." });
    }

    const nameById = await resolveDriverNames([entry], "driverId");
    entry.driverNames = driverNamesFor(entry.driverId, nameById);

    if (entry.deliverAt || entry.deliveryAddress) {
      entry.delivery = {
        deliverAt: entry.deliverAt,
        departureAt: entry.departureAt,
        address: entry.deliveryAddress,
        city: entry.deliveryCity,
        state: entry.deliveryState,
        zipcode: entry.deliveryZipcode,
        country: entry.deliveryCountry,
        lat: entry.deliveryLat,
        lng: entry.deliveryLng,
        distanceMiles: entry.deliveryDistanceMiles,
        durationMinutes: entry.deliveryDurationMinutes,
      };
    } else {
      entry.delivery = null;
    }

    return res.status(200).json({
      status: true,
      message: "Get Entry Successfully.",
      data: entry,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

/// Mirrors DailyVehicleEntryController::checkTrailerStatus() — blocks taking an empty
/// trailer out on Exit unless its latest daily_vehicle_sheet_news row says ready_status
/// = 'ready'. See DailyVehicleEntryController.php:962-1037.
export async function checkTrailerStatus(req: Request, res: Response): Promise<any> {
  try {
    const trailerId = req.body?.trailerId;
    if (isBlank(trailerId)) {
      return res.status(400).json({ status: false, message: "trailerId is required" });
    }

    const sheetRows = await secondarySequelize.query<any>(
      `SELECT empty_loaded, ready_status FROM daily_vehicle_sheet_news
       WHERE vehicle_id = :trailerId AND vehicle_type = 'trailer'
       ORDER BY date DESC, id DESC LIMIT 1`,
      { replacements: { trailerId }, type: QueryTypes.SELECT }
    );
    const sheet = sheetRows[0] ?? null;

    if (!sheet || sheet.ready_status === "not-ready") {
      const trailerRows = await secondarySequelize.query<{ number: string }>(
        `SELECT number FROM trailers WHERE id = :trailerId LIMIT 1`,
        { replacements: { trailerId }, type: QueryTypes.SELECT }
      );

      return res.status(200).json({
        status: true,
        message: "Trailer is not ready to depart.",
        data: {
          blocked: true,
          trailerNumber: trailerRows[0]?.number ?? null,
          emptyLoaded: sheet?.empty_loaded ?? null,
          readyStatus: sheet?.ready_status ?? null,
          readyTrailers: await getReadyTrailers(),
        },
      });
    }

    return res.status(200).json({
      status: true,
      message: "Trailer is ready.",
      data: { blocked: false },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

/// Trailers whose latest daily_vehicle_sheet_news row is empty & ready, offered as
/// alternatives when the selected trailer is blocked from departing.
async function getReadyTrailers(): Promise<{ id: number; number: string }[]> {
  return secondarySequelize.query<{ id: number; number: string }>(
    `SELECT s.vehicle_id AS id, tr.number AS number
     FROM daily_vehicle_sheet_news s
     INNER JOIN (
       SELECT vehicle_id, MAX(id) AS max_id
       FROM daily_vehicle_sheet_news
       WHERE vehicle_type = 'trailer'
       GROUP BY vehicle_id
     ) latest ON latest.max_id = s.id
     INNER JOIN trailers tr ON tr.id = s.vehicle_id
     WHERE s.empty_loaded = 'empty' AND s.ready_status = 'ready'
       AND (s.location IS NULL OR s.location != 'Departed')
     ORDER BY CAST(tr.number AS UNSIGNED) ASC`,
    { type: QueryTypes.SELECT }
  );
}
