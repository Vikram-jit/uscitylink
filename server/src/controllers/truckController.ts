import { Request, Response } from "express";
import { QueryTypes } from "sequelize";
import { secondarySequelize } from "../sequelize";
import GroupUser from "../models/GroupUser";
import Group from "../models/Group";

export async function getTrucks(req: Request, res: Response): Promise<any> {
  try {

    const groupUsers = await GroupUser.findAll({
      where: {
        userProfileId: req.user?.id
      },
      include: [
        {
          model: Group,
          where: {
            type: "truck"
          },
          attributes: ['name']
        }
      ]
    })

    const truckIds = groupUsers.map((e: any) => {
      return e?.Group?.name
    })
    if (truckIds.length === 0) {
      return res.status(200).json({
        status: true,
        message: "No trucks found.",
        data: {
          data: [],
          pagination: {
            currentPage: 1,
            pageSize: 10,
            totalPages: 0,
            totalItems: 0,
          },
        },
      });
    }
    // Get pagination parameters from the request query, with defaults if not provided
    const page = parseInt(req.query.page as string) || 1;
    const pageSize = parseInt(req.query.pageSize as string) || 10;
    const type = req.query.type || "trucks";
    const searchQuery = req.query.search || ""; // New parameter for search

    // Calculate OFFSET
    const offset = (page - 1) * pageSize;

    // Construct the search condition
    let searchCondition = '';
    let replacements: any = { limit: pageSize, offset };

    if (truckIds.length > 0 && searchQuery.length == 0) {
      // Use WHERE IN if numbers array is not empty
      searchCondition = `WHERE number IN (:numbers)`;
      replacements.numbers = truckIds; // Set the 'numbers' replacement
    } else if (searchQuery) {
      // Use LIKE if searchQuery is provided
      searchCondition = `WHERE number = :searchQuery`;  // Modify `number` based on your table schema
      replacements.searchQuery = `${searchQuery}`; // Add the searchQuery parameter
    }

    // Fetch the total number of records for pagination
    const totalTrucks = await secondarySequelize.query<any>(
      `SELECT COUNT(*) AS total FROM ${type} ${searchCondition}`,
      {
        replacements,
        type: QueryTypes.SELECT,
      }
    );

    // Fetch the paginated data with the appropriate search condition
    const trucks = await secondarySequelize.query<any>(
      `SELECT * FROM ${type} ${searchCondition} LIMIT :limit OFFSET :offset`,
      {
        replacements,
        type: QueryTypes.SELECT,
      }
    );
    // Calculate total pages (for pagination metadata)
    const totalCount = totalTrucks[0].total;
    const totalPages = Math.ceil(totalCount / pageSize);

    return res.status(200).json({
      status: true,
      message: `Get Trucks Successfully.`,
      data: {
        data: trucks,
        pagination: {
          currentPage: page,
          pageSize: pageSize,
          totalPages: totalPages,
          totalItems: totalCount,
        },
      },
    });
  } catch (err: any) {
    return res.status(400).json({ status: false, message: err.message || "Internal Server Error" });
  }
}


export async function getById(req: Request, res: Response): Promise<any> {
  try {

    const type = req.query.type || "truck";
    const id = req.params.id;


    const details = await secondarySequelize.query<any>(
      `SELECT * FROM ${type}s WHERE id = :id`,
      {
        replacements: { id: id },
        type: QueryTypes.SELECT,
      }
    );
    const documents = await secondarySequelize.query<any>(
      `SELECT * FROM documents WHERE item_id = :id AND type = :type`,
      {
        replacements: { id: id, type: type },
        type: QueryTypes.SELECT,
      }
    );
    return res.status(200).json({
      status: true,
      message: `Get Details Successfully.`,
      data: { ...details?.[0], documents },
    });
  } catch (err: any) {
    return res.status(400).json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function getTruckList(req: Request, res: Response): Promise<any> {
  try {



    // Fetch paginated data with search functionality
    const trucks = await secondarySequelize.query<any>(
      `SELECT * FROM trucks`,
      {

        type: QueryTypes.SELECT,
      }
    );




    return res.status(200).json({
      status: true,
      message: `Get Trucks Successfully.`,
      data: trucks
    });
  } catch (err: any) {
    return res.status(400).json({ status: false, message: err.message || "Internal Server Error" });
  }
}

