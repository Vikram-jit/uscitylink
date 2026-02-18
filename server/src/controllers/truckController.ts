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
export async function getRoutes(req: Request, res: Response): Promise<any> {
  try {
    // 1️⃣ Get trucks assigned to logged-in user
    const groupUsers = await GroupUser.findAll({
      where: { userProfileId: req.user?.id },
      include: [
        {
          model: Group,
          where: { type: "truck" },
          attributes: ["name"], // truck number
        },
      ],
    });
   
    const truckNumbers = groupUsers
      .map((g: any) => g?.Group?.name)
      .filter(Boolean);
  
    if (truckNumbers.length === 0) {
      return res.status(200).json({
        status: true,
        message: "No routes found.",
        data: [],
      });
    }
 const trucks = await secondarySequelize.query<any>(
      `SELECT * FROM trucks WHERE number = :truckNumber`,
      {

        type: QueryTypes.SELECT,
        replacements:{truckNumber: truckNumbers?.[0]}
      }
    
    );
    // 2️⃣ FLAT QUERY (NO JSON IN SQL)
    const rows = await secondarySequelize.query<any>(
      `
      SELECT
        r.id,
        r.from_location,
        r.to_location,
        r.distance,
        r.created_at,
        r.updated_at,
        r.from_address,
        r.from_city,
        r.from_state,
        r.from_zip,
        r.from_country,
        r.from_lat,
        r.from_lng,
        r.to_address,
        r.to_city,
        r.to_state,
        r.to_zip,
        r.to_country,
        r.to_lat,
        r.to_lng,

        t.id AS truck_id,
        t.number AS truck_number,
        t.samsara_vehicle_id AS samsara_vehicle_id,

        s.id AS station_id,
        s.store_number,
        s.name AS station_name,
        s.address,
        s.city AS station_city,
        s.state AS station_state,
        s.zip_code,
        s.interstate,
        s.latitude,
        s.longitude,
        s.phone_number,
        s.parking_spaces_count,
        s.fuel_lane_count,
        s.shower_count,
        s.amenities,
        s.restaurants,

        p.product,
        p.your_price,
        p.retail_price,
        p.savings_total,
        p.effective_date

      FROM routes r

      /* 🔥 Filter routes by assigned trucks */
      INNER JOIN route_truck rt_filter ON rt_filter.route_id = r.id
      INNER JOIN trucks t_filter
        ON t_filter.id = rt_filter.truck_id
       AND t_filter.number IN (:truckNumbers)

      /* 🔁 All trucks */
      LEFT JOIN route_truck rt ON rt.route_id = r.id
      LEFT JOIN trucks t ON t.id = rt.truck_id

      /* 🔁 Stations */
      LEFT JOIN route_fuel_stations rfs ON rfs.route_id = r.id
      LEFT JOIN stations s ON s.id = rfs.station_id

      /* 🔥 Latest fuel price */
      LEFT JOIN (
        SELECT dfpq.*
        FROM daily_fuel_price_quotes dfpq
        INNER JOIN (
          SELECT site, MAX(effective_date) AS max_date
          FROM daily_fuel_price_quotes
          GROUP BY site
        ) latest
          ON latest.site = dfpq.site
         AND latest.max_date = dfpq.effective_date
      ) p ON p.site = s.store_number

      ORDER BY r.created_at DESC
      `,
      {
        replacements: { truckNumbers },
        type: QueryTypes.SELECT,
      }
    );

    // 3️⃣ GROUP DATA SAFELY IN NODE
    const routeMap = new Map<number, any>();

    for (const row of rows) {
      // Create route
      if (!routeMap.has(row.id)) {
        routeMap.set(row.id, {
          id: row.id,
          from_location: row.from_location,
          to_location: row.to_location,
          distance: row.distance,
          created_at: row.created_at,
          updated_at: row.updated_at,
          from_address: row.from_address,
          from_city: row.from_city,
          from_state: row.from_state,
          from_zip: row.from_zip,
          from_country: row.from_country,
          from_lat: row.from_lat,
          from_lng: row.from_lng,
          to_address: row.to_address,
          to_city: row.to_city,
          to_state: row.to_state,
          to_zip: row.to_zip,
          to_country: row.to_country,
          to_lat: row.to_lat,
          to_lng: row.to_lng,
          truck: trucks.length > 0 ? trucks?.[0] : null,
          trucks: [],
          stations: [],
        });
      }

      const route = routeMap.get(row.id);

      // Add truck (dedupe)
      if (
        row.truck_id &&
        !route.trucks.some((t: any) => t.id === row.truck_id)
      ) {
        route.trucks.push({
          id: row.truck_id,
          number: row.truck_number,
        });
      }

      // Add station (dedupe)
      if (
        row.station_id &&
        !route.stations.some((s: any) => s.id === row.station_id)
      ) {
        route.stations.push({
          id: row.station_id,
          store_number: row.store_number,
          name: row.station_name,
          address: row.address,
          city: row.station_city,
          state: row.station_state,
          zip_code: row.zip_code,
          interstate: row.interstate,
          latitude: row.latitude,
          longitude: row.longitude,
          phone_number: row.phone_number,
          parking_spaces_count: row.parking_spaces_count,
          fuel_lane_count: row.fuel_lane_count,
          shower_count: row.shower_count,
          amenities: row.amenities,
          restaurants: row.restaurants,
          latest_price: row.product
            ? {
                product: row.product,
                your_price: row.your_price,
                retail_price: row.retail_price,
                savings_total: row.savings_total,
                effective_date: row.effective_date,
              }
            : null,
        });
      }
    }

    const routes = Array.from(routeMap.values());

    return res.status(200).json({
      status: true,
      message: "Routes fetched successfully",
      data:routes,
    });
  } catch (err: any) {
    console.error("getRoutes error:", err);
    return res.status(500).json({
      status: false,
      message: err.message || "Internal Server Error",
    });
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

const formatUSDate = (date: string | Date | null) => {
  if (!date) return null;
  return new Date(date).toLocaleDateString('en-US');
};

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

