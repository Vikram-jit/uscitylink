import { Request, Response } from "express";
import { QueryTypes } from "sequelize";
import { secondarySequelize } from "../sequelize";

export async function getTrucks(req: Request, res: Response): Promise<any> {
  try {
    // Get pagination parameters from the request query, with defaults if not provided
    const page = parseInt(req.query.page as string) || 1;
    const pageSize = parseInt(req.query.pageSize as string) || 10;
    
    // Calculate OFFSET
    const offset = (page - 1) * pageSize;

    // Fetch the total number of trucks (for pagination info like total pages)
    const totalTrucks = await secondarySequelize.query<any>(
      `SELECT COUNT(*) AS total FROM trucks`,
      {
        type: QueryTypes.SELECT,
      }
    );

    // Fetch paginated data
    const trucks = await secondarySequelize.query<any>(
      `SELECT * FROM trucks LIMIT :limit OFFSET :offset`,
      {
        replacements: { limit: pageSize, offset },
        type: QueryTypes.SELECT,
      }
    );

    // Calculate total pages (for pagination metadata)
    const totalCount = totalTrucks[0].total;
    const totalPages = Math.ceil(totalCount / pageSize);

    return res.status(200).json({
      status: true,
      message: `Get Trucks Successfully.`,
      data: {data:trucks,  pagination: {
        currentPage: page,
        pageSize: pageSize,
        totalPages: totalPages,
        totalItems: totalCount,
      }},
    
    });
  } catch (err: any) {
    return res.status(400).json({ status: false, message: err.message || "Internal Server Error" });
  }
}
