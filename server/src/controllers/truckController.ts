import { Request, Response } from "express";
import { secondarySequelize } from "../sequelize";
import { QueryTypes } from "sequelize";
export async function getTrucks(req: Request, res: Response): Promise<any> {
  try {
    const trucks = await secondarySequelize.query<any>(
      `SELECT * FROM trucks `,
      {
        type: QueryTypes.SELECT,
      }
    );

    return res.status(200).json({
      status: true,
      message: `Get Users Successfully.`,
      data:trucks
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}
