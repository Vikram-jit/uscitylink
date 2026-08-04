import { Request, Response } from "express";
import { QueryTypes } from "sequelize";
import axios from "axios";
import moment from "moment-timezone";
import { secondarySequelize } from "../sequelize";
import { resolveDriverNames, driverNamesFor } from "./securityEntryController";

// Canonical checklist — copied verbatim from yardController.ts's getInspectionView
// (already the version driver-submitted inspections use; keeps question text
// consistent for all rows in vehicle_inspection_questions regardless of who
// created them, rather than reintroducing the web Blade's "Clearance\Marker"
// typo/backslash for this new security-created flow).
export const TRUCK_INSPECTION_QUESTIONS = [
  "Air Lines",
  "Belts And Hoses",
  "Body",
  "Breaks",
  "Coolant Level",
  "Engine Oil Level",
  "Extra Oil & Coolant Gallon",
  "Fire Extinguisher",
  "Reflectors",
  "Reflective Triangles",
  "Spare Bulbs And Fuses",
  "Fuel Tanks",
  "Horn",
  "Jumper Cable",
  "Head/Stop",
  "Tail/Dash",
  "Turn Indicators",
  "ClearanceMarker",
  "Mirrors",
  "Oil Pressure",
  "Radiator",
  "Rear End",
  "Starter",
  "Steering",
  "Front Tires",
  "Drive Tires",
  "Wheels And Rims",
  "Windows",
  "Windshield Wipers",
  "Wheel Seal",
];

export const TRAILER_INSPECTION_QUESTIONS = [
  "Doors",
  "Landing Gear",
  "Lights - All",
  "Brakes",
  "Load Lock",
  "Refer Set Temp.",
  "Reflectors/Reflective Tape",
  "Spare Tire",
  "Suspension System",
  "Tires",
  "Wheels And Rims",
  "Wheel Seal",
  "Trailer Seal",
  "Fire Extinguisher",
  "Warning Triangles",
  "Fuel Card",
  "Log Book",
  "Paper Work",
  "License Plate",
];

function isBlank(v: any): boolean {
  return v === undefined || v === null || v === "";
}

/// GET /security/inspections/questions — the two canonical checklists, so the
/// Flutter form doesn't hardcode them separately from the backend's own copy.
export async function getInspectionQuestionList(req: Request, res: Response): Promise<any> {
  return res.status(200).json({
    status: true,
    message: "Get Inspection Questions Successfully.",
    data: {
      truckQuestions: TRUCK_INSPECTION_QUESTIONS,
      trailerQuestions: TRAILER_INSPECTION_QUESTIONS,
    },
  });
}

/// GET /security/inspections/odometer/:truckId — mirrors
/// DailyVehicleInspectionController::getOdometer(), same Samsara call already
/// established in yardController.ts's getInspectionView.
export async function getInspectionOdometer(req: Request, res: Response): Promise<any> {
  try {
    const { truckId } = req.params;
    const truckRows = await secondarySequelize.query<{ samsara_vehicle_id: string | null }>(
      `SELECT samsara_vehicle_id FROM trucks WHERE id = :truckId LIMIT 1`,
      { replacements: { truckId }, type: QueryTypes.SELECT }
    );

    if (truckRows.length === 0) {
      return res.status(404).json({ status: false, message: "Truck not found", data: { odometerMiles: null } });
    }

    let odometerMiles: number | null = null;
    const samsaraVehicleId = truckRows[0].samsara_vehicle_id;

    if (samsaraVehicleId) {
      try {
        const apiKey = process.env.SAMSARA_API_KEY;
        const response = await axios.get(
          "https://api.samsara.com/fleet/vehicles/stats/feed",
          {
            headers: { Accept: "application/json", Authorization: `Bearer ${apiKey}` },
            params: { vehicleIds: samsaraVehicleId, types: "obdOdometerMeters" },
          }
        );
        const meters = response.data?.data?.[0]?.obdOdometerMeters?.[0]?.value;
        if (meters) odometerMiles = Math.round(meters * 0.000621371 * 100) / 100;
      } catch (apiError: any) {
        console.error("Samsara API error:", apiError.message);
      }
    }

    return res.status(200).json({
      status: true,
      message: "Get Odometer Successfully.",
      data: { odometerMiles },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

/// GET /security/inspections — vehicle list with last-inspection status.
/// Mirrors DailyVehicleInspectionController::index(): loads every truck/trailer,
/// merges in its most recent inspection timestamp, filters (never/within24/
/// older24), sorts (most-recently-inspected first, never-inspected last), then
/// paginates — done in application code exactly like the Laravel collection
/// pipeline does, rather than one large SQL query.
export async function getInspectionVehicles(req: Request, res: Response): Promise<any> {
  try {
    const tab = (req.query.tab as string) === "trailer" ? "trailer" : "truck";
    const filter = (req.query.filter as string) || "all";
    const page = Math.max(1, parseInt((req.query.page as string) || "1", 10));
    const pageSize = Math.max(1, parseInt((req.query.pageSize as string) || "20", 10));
    const search = (req.query.search as string) || "";

    const table = tab === "truck" ? "trucks" : "trailers";
    const vehicleIdColumn = tab === "truck" ? "truck_id" : "trailer_id";

    const searchCondition = search ? `WHERE number LIKE :search` : "";
    const vehicles = await secondarySequelize.query<{ id: number; number: string }>(
      `SELECT id, number FROM ${table} ${searchCondition} ORDER BY CAST(number AS UNSIGNED) ASC`,
      { replacements: { search: `%${search}%` }, type: QueryTypes.SELECT }
    );

    // MAX(id) (not MAX(inspected_at)) identifies "latest" — matches the
    // MAX(id)-per-vehicle pattern already used for latestEntryStatus/
    // latestReadyStatus elsewhere in this module, and gives us the actual
    // inspection row id so we can look up its OK/Problem answer counts.
    const lastInspectionRows = await secondarySequelize.query<{
      vehicleId: number;
      inspectionId: number;
      lastInspectedAt: string;
    }>(
      `SELECT i.${vehicleIdColumn} AS vehicleId, i.id AS inspectionId, i.inspected_at AS lastInspectedAt
       FROM daily_vehicle_inspections i
       INNER JOIN (
         SELECT ${vehicleIdColumn} AS vid, MAX(id) AS maxId
         FROM daily_vehicle_inspections
         WHERE ${vehicleIdColumn} IS NOT NULL
         GROUP BY ${vehicleIdColumn}
       ) latest ON latest.vid = i.${vehicleIdColumn} AND latest.maxId = i.id`,
      { type: QueryTypes.SELECT }
    );
    const lastInspectionById = new Map<
      number,
      { inspectionId: number; lastInspectedAt: string }
    >();
    for (const row of lastInspectionRows) {
      lastInspectionById.set(row.vehicleId, {
        inspectionId: row.inspectionId,
        lastInspectedAt: row.lastInspectedAt,
      });
    }

    const now = moment.tz("America/Los_Angeles");
    const cutoff24h = now.clone().subtract(24, "hours");

    let merged = vehicles.map((v) => {
      const last = lastInspectionById.get(v.id) ?? null;
      const lastInspectedAt = last?.lastInspectedAt ?? null;
      const isDone = lastInspectedAt
        ? moment.tz(lastInspectedAt, "America/Los_Angeles").isAfter(cutoff24h)
        : false;
      return {
        id: v.id,
        number: v.number,
        lastInspectedAt,
        isDone,
        inspectionId: last?.inspectionId ?? null,
      };
    });

    if (filter === "never") {
      merged = merged.filter((v) => v.lastInspectedAt === null);
    } else if (filter === "within24") {
      merged = merged.filter((v) => v.lastInspectedAt !== null && v.isDone);
    } else if (filter === "older24") {
      merged = merged.filter((v) => v.lastInspectedAt !== null && !v.isDone);
    }

    merged.sort((a, b) => {
      if (a.lastInspectedAt === null && b.lastInspectedAt === null) return 0;
      if (a.lastInspectedAt === null) return 1;
      if (b.lastInspectedAt === null) return -1;
      return new Date(b.lastInspectedAt).getTime() - new Date(a.lastInspectedAt).getTime();
    });

    const totalItems = merged.length;
    const totalPages = Math.max(1, Math.ceil(totalItems / pageSize));
    const start = (page - 1) * pageSize;
    const pageItems = merged.slice(start, start + pageSize);

    // OK/Problem counts only fetched for this page's vehicles (not the whole
    // filtered set) — cheap, and avoids computing counts that never get shown.
    const inspectionIds = pageItems
      .map((v) => v.inspectionId)
      .filter((id): id is number => id !== null);
    let countsByInspectionId = new Map<number, { okCount: number; problemCount: number }>();
    if (inspectionIds.length > 0) {
      const countRows = await secondarySequelize.query<{
        inspectionId: number;
        okCount: number;
        problemCount: number;
      }>(
        `SELECT daily_vehicle_inspections_id AS inspectionId,
                SUM(status = 'ok') AS okCount,
                SUM(status = 'problem') AS problemCount
         FROM vehicle_inspection_questions
         WHERE daily_vehicle_inspections_id IN (:inspectionIds)
         GROUP BY daily_vehicle_inspections_id`,
        { replacements: { inspectionIds }, type: QueryTypes.SELECT }
      );
      countsByInspectionId = new Map(countRows.map((c) => [c.inspectionId, c]));
    }

    const vehiclesWithCounts = pageItems.map((v) => {
      const counts = v.inspectionId ? countsByInspectionId.get(v.inspectionId) : null;
      return {
        id: v.id,
        number: v.number,
        lastInspectedAt: v.lastInspectedAt,
        isDone: v.isDone,
        okCount: Number(counts?.okCount ?? 0),
        problemCount: Number(counts?.problemCount ?? 0),
      };
    });

    return res.status(200).json({
      status: true,
      message: "Get Inspection Vehicles Successfully.",
      data: {
        vehicles: vehiclesWithCounts,
        pagination: { currentPage: page, pageSize, totalPages, totalItems },
      },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

/// GET /security/inspections/vehicle/:tab/:vehicleId — one vehicle's inspection
/// history, paginated. Mirrors DailyVehicleInspectionController::show().
export async function getVehicleInspectionHistory(req: Request, res: Response): Promise<any> {
  try {
    const tab = req.params.tab === "trailer" ? "trailer" : "truck";
    const vehicleId = req.params.vehicleId;
    const page = Math.max(1, parseInt((req.query.page as string) || "1", 10));
    const pageSize = Math.max(1, parseInt((req.query.pageSize as string) || "20", 10));
    const vehicleIdColumn = tab === "truck" ? "truck_id" : "trailer_id";

    const countRows = await secondarySequelize.query<{ count: number }>(
      `SELECT COUNT(*) AS count FROM daily_vehicle_inspections WHERE ${vehicleIdColumn} = :vehicleId`,
      { replacements: { vehicleId }, type: QueryTypes.SELECT }
    );
    const totalItems = Number(countRows[0]?.count ?? 0);
    const totalPages = Math.max(1, Math.ceil(totalItems / pageSize));
    const offset = (page - 1) * pageSize;

    const rows = await secondarySequelize.query<any>(
      `SELECT i.id, i.inspected_at AS inspectedAt, i.company_name AS companyName,
              i.driver_id AS driverId, i.note, i.added_by AS addedBy,
              t.number AS truckNumber, tr.number AS trailerNumber
       FROM daily_vehicle_inspections i
       LEFT JOIN trucks t ON t.id = i.truck_id
       LEFT JOIN trailers tr ON tr.id = i.trailer_id
       WHERE i.${vehicleIdColumn} = :vehicleId
       ORDER BY i.inspected_at DESC
       LIMIT :limit OFFSET :offset`,
      { replacements: { vehicleId, limit: pageSize, offset }, type: QueryTypes.SELECT }
    );

    const nameById = await resolveDriverNames(rows, "driverId");
    const inspectionIds = rows.map((r) => r.id);
    let counts: { inspectionId: number; okCount: number; problemCount: number }[] = [];
    if (inspectionIds.length > 0) {
      counts = await secondarySequelize.query<any>(
        `SELECT daily_vehicle_inspections_id AS inspectionId,
                SUM(status = 'ok') AS okCount,
                SUM(status = 'problem') AS problemCount
         FROM vehicle_inspection_questions
         WHERE daily_vehicle_inspections_id IN (:inspectionIds)
         GROUP BY daily_vehicle_inspections_id`,
        { replacements: { inspectionIds }, type: QueryTypes.SELECT }
      );
    }
    const countsById = new Map(counts.map((c) => [c.inspectionId, c]));

    const inspections = rows.map((row) => ({
      ...row,
      driverNames: driverNamesFor(row.driverId, nameById),
      okCount: Number(countsById.get(row.id)?.okCount ?? 0),
      problemCount: Number(countsById.get(row.id)?.problemCount ?? 0),
    }));

    return res.status(200).json({
      status: true,
      message: "Get Vehicle Inspection History Successfully.",
      data: {
        inspections,
        pagination: { currentPage: page, pageSize, totalPages, totalItems },
      },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

/// GET /security/inspections/:id — full inspection detail (all question
/// answers). Mirrors DailyVehicleInspectionController::getInspectionQuestions()
/// but returns JSON instead of a rendered HTML partial.
export async function getInspectionById(req: Request, res: Response): Promise<any> {
  try {
    const { id } = req.params;
    const rows = await secondarySequelize.query<any>(
      `SELECT i.id, i.inspected_at AS inspectedAt, i.company_name AS companyName,
              i.odometer, i.driver_id AS driverId, i.note, i.added_by AS addedBy,
              i.vehicle_type AS vehicleType,
              t.number AS truckNumber, tr.number AS trailerNumber
       FROM daily_vehicle_inspections i
       LEFT JOIN trucks t ON t.id = i.truck_id
       LEFT JOIN trailers tr ON tr.id = i.trailer_id
       WHERE i.id = :id
       LIMIT 1`,
      { replacements: { id }, type: QueryTypes.SELECT }
    );

    if (rows.length === 0) {
      return res.status(404).json({ status: false, message: "Inspection not found" });
    }

    const inspection = rows[0];
    const nameById = await resolveDriverNames(rows, "driverId");
    inspection.driverNames = driverNamesFor(inspection.driverId, nameById);

    const answerRows = await secondarySequelize.query<{
      question: string;
      status: string;
      inspected_vehicle_type: string;
    }>(
      `SELECT question, status, inspected_vehicle_type
       FROM vehicle_inspection_questions
       WHERE daily_vehicle_inspections_id = :id
       ORDER BY id ASC`,
      { replacements: { id }, type: QueryTypes.SELECT }
    );

    inspection.truckAnswers = answerRows
      .filter((r) => r.inspected_vehicle_type === "truck")
      .map((r) => ({ question: r.question, status: r.status }));
    inspection.trailerAnswers = answerRows
      .filter((r) => r.inspected_vehicle_type === "trailer")
      .map((r) => ({ question: r.question, status: r.status }));

    return res.status(200).json({
      status: true,
      message: "Get Inspection Successfully.",
      data: inspection,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

/// POST /security/inspections — mirrors
/// DailyVehicleInspectionController::store(). The web performs no server-side
/// validation at all (its validate() call is commented out) — this port still
/// enforces the client-side rule the Blade JS already requires (every visible
/// checklist item answered) rather than accepting silently-incomplete data.
export async function createInspection(req: Request, res: Response): Promise<any> {
  try {
    const b = req.body || {};
    const errors: string[] = [];

    if (isBlank(b.truckId)) errors.push("The truck field is required.");
    if (isBlank(b.inspectedAt)) errors.push("The inspection date field is required.");
    if (isBlank(b.security)) errors.push("The security field is required.");

    const truckAnswers: { question: string; status: string }[] = Array.isArray(b.truckAnswers)
      ? b.truckAnswers
      : [];
    const answeredTruckQuestions = new Set(truckAnswers.map((a) => a.question));
    for (const q of TRUCK_INSPECTION_QUESTIONS) {
      if (!answeredTruckQuestions.has(q)) errors.push(`Please answer "${q}".`);
    }

    const hasTrailer = !isBlank(b.trailerId);
    const trailerAnswers: { question: string; status: string }[] = Array.isArray(b.trailerAnswers)
      ? b.trailerAnswers
      : [];
    if (hasTrailer) {
      const answeredTrailerQuestions = new Set(trailerAnswers.map((a) => a.question));
      for (const q of TRAILER_INSPECTION_QUESTIONS) {
        if (!answeredTrailerQuestions.has(q)) errors.push(`Please answer "${q}" (trailer).`);
      }
    }

    if (errors.length > 0) {
      return res.status(400).json({ status: false, message: errors[0], errors });
    }

    const inspectedAt = moment
      .tz(b.inspectedAt, "America/Los_Angeles")
      .format("YYYY-MM-DD HH:mm:ss");
    const now = moment.tz("America/Los_Angeles").format("YYYY-MM-DD HH:mm:ss");

    const driverId: string | null =
      Array.isArray(b.driverIds) && b.driverIds.length > 0 ? b.driverIds.join(",") : null;

    const vehicleType = hasTrailer ? "truckandtrailer" : "truck";

    const insertResult: any = await secondarySequelize.query(
      `INSERT INTO daily_vehicle_inspections
        (vehicle_type, company_name, truck_id, trailer_id, driver_id, odometer,
         inspected_at, note, added_by, created_at, updated_at)
       VALUES
        (:vehicleType, :companyName, :truckId, :trailerId, :driverId, :odometer,
         :inspectedAt, :note, :addedBy, :createdAt, :updatedAt)`,
      {
        replacements: {
          vehicleType,
          companyName: b.companyName ?? "US City Link Corporation",
          truckId: b.truckId,
          trailerId: hasTrailer ? b.trailerId : null,
          driverId,
          odometer: b.odometer ?? null,
          inspectedAt,
          note: b.note ?? null,
          addedBy: b.security,
          createdAt: now,
          updatedAt: now,
        },
        type: QueryTypes.INSERT,
      }
    );
    const inspectionId = insertResult?.[0];

    const allAnswers = [
      ...truckAnswers.map((a) => ({ ...a, inspectedVehicleType: "truck" })),
      ...(hasTrailer ? trailerAnswers.map((a) => ({ ...a, inspectedVehicleType: "trailer" })) : []),
    ];

    if (allAnswers.length > 0) {
      const valuesPlaceholders = allAnswers
        .map(
          (_, i) =>
            `(:inspectionId, :inspectedVehicleType_${i}, :question_${i}, :status_${i}, :createdAt, :updatedAt)`
        )
        .join(", ");
      const replacements: any = { inspectionId, createdAt: now, updatedAt: now };
      allAnswers.forEach((a, i) => {
        replacements[`inspectedVehicleType_${i}`] = a.inspectedVehicleType;
        replacements[`question_${i}`] = a.question;
        replacements[`status_${i}`] = a.status;
      });

      await secondarySequelize.query(
        `INSERT INTO vehicle_inspection_questions
          (daily_vehicle_inspections_id, inspected_vehicle_type, question, status, created_at, updated_at)
         VALUES ${valuesPlaceholders}`,
        { replacements, type: QueryTypes.INSERT }
      );
    }

    return res.status(200).json({
      status: true,
      message: "Inspection submitted successfully.",
      data: { id: inspectionId },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}
