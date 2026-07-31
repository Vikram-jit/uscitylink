import { Request, Response } from "express";
import { QueryTypes } from "sequelize";
import moment from "moment-timezone";
import { secondarySequelize } from "../sequelize";

export async function getSecurityDashboard(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const today = moment.tz("America/Los_Angeles").format("YYYY-MM-DD");

    // All-time totals — mirrors the web dashboard exactly (VehicleEntryTimeController::dashboard()):
    // entryVehicles/exitVehicles are plain status counts with no date filter.
    const rows = await secondarySequelize.query<{
      status: "entry" | "depart";
      count: number;
    }>(
      `SELECT status, COUNT(*) AS count FROM daily_vehicle_entries GROUP BY status`,
      {
        type: QueryTypes.SELECT,
      }
    );

    let totalEntries = 0;
    let totalDepartures = 0;
    for (const row of rows) {
      if (row.status === "entry") totalEntries = Number(row.count);
      if (row.status === "depart") totalDepartures = Number(row.count);
    }

    return res.status(200).json({
      status: true,
      message: "Get Security Dashboard Successfully.",
      data: {
        totalEntries,
        totalDepartures,
        date: today,
      },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}
