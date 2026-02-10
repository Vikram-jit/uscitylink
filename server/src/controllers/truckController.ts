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
      where: {
        userProfileId: req.user?.id
      },
      include: [
        {
          model: Group,
          where: { type: "truck" },
          attributes: ["name"] // truck number
        }
      ]
    });

    const truckNumbers = groupUsers
      .map((g: any) => g?.Group?.name)
      .filter(Boolean);
  console.log(truckNumbers);
    if (truckNumbers.length === 0) {
      return res.status(200).json({
        status: true,
        message: "No routes found.",
        data: []
      });
    }

const routes = await secondarySequelize.query<any>(
`
SELECT
  r.*,

  /* 🚚 Trucks */
  CONCAT(
    '[',
    GROUP_CONCAT(
      DISTINCT JSON_OBJECT(
        'id', t.id,
        'number', t.number
      )
    ),
    ']'
  ) AS trucks,

  /* ⛽ Stations + latest fuel price */
  CONCAT(
    '[',
    GROUP_CONCAT(
      JSON_OBJECT(
        'id', s.id,
        'store_number', s.store_number,
        'name', s.name,
        'address', s.address,
        'city', s.city,
        'state', s.state,
        'zip_code', s.zip_code,
        'interstate', s.interstate,
        'latitude', s.latitude,
        'longitude', s.longitude,
        'phone_number', s.phone_number,
        'parking_spaces_count', s.parking_spaces_count,
        'fuel_lane_count', s.fuel_lane_count,
        'shower_count', s.shower_count,
        'amenities', s.amenities,
        'restaurants', s.restaurants,

        'latest_price', IFNULL(
          JSON_OBJECT(
            'product', p.product,
            'your_price', p.your_price,
            'retail_price', p.retail_price,
            'savings_total', p.savings_total,
            'effective_date', p.effective_date
          ),
          NULL
        )
      )
    ),
    ']'
  ) AS stations

FROM routes r

/* 🔥 Filter routes by truck numbers */
INNER JOIN route_truck rt_filter ON rt_filter.route_id = r.id
INNER JOIN trucks t_filter ON t_filter.id = rt_filter.truck_id
  AND t_filter.number IN (:truckNumbers)

/* 🔁 All trucks */
LEFT JOIN route_truck rt ON rt.route_id = r.id
LEFT JOIN trucks t ON t.id = rt.truck_id

/* 🔁 Stations */
LEFT JOIN route_fuel_stations rfs ON rfs.route_id = r.id
LEFT JOIN stations s ON s.id = rfs.station_id

/* 🔥 Latest fuel price per store */
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

GROUP BY r.id
ORDER BY r.created_at DESC
`,
{
  replacements: { truckNumbers },
  type: QueryTypes.SELECT
});
const parsedRoutes = routes.map(route => {
  const trucks = JSON.parse(route.trucks || '[]');

  const stations = JSON.parse(route.stations || '[]').map((station: any) => {
    return {
      ...station,
      latest_price: station.latest_price
        ? JSON.parse(station.latest_price)
        : null
    };
  });

  return {
    ...route,
    trucks,
    stations
  };
});

    return res.status(200).json({
      status: true,
      message: "Routes fetched successfully",
      data: parsedRoutes
    });

  } catch (err: any) {
    return res.status(400).json({
      status: false,
      message: err.message || "Internal Server Error"
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

