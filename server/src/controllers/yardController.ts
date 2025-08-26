import { promises as fs } from "fs";

import * as path from "path";
import ejs from "ejs"; // Import EJS
import Queue, { Job } from "bull";

import { Request, Response } from "express";
import { generatePdf } from "../utils/pdf";
import { secondarySequelize } from "../sequelize";
import { Op, QueryTypes } from "sequelize";
import { sendEmailWithAttachment } from "../utils/sendEmail";
import { UserProfile } from "../models/UserProfile";
import User from "../models/User";
import axios from "axios";
import GroupUser from "../models/GroupUser";
import Group from "../models/Group";
const renderTemplate = (templatePath: string, data: any) => {
  return new Promise((resolve, reject) => {
    ejs.renderFile(templatePath, data, (err: any, html: any) => {
      if (err) {
        reject(err);
      } else {
        resolve(html);
      }
    });
  });
};

const getInvoiceDetails = (id: number): Promise<any> => {
  return secondarySequelize.query<any>(
    `SELECT * FROM clean_truck_check_invoice_details WHERE id = :id`,
    {
      type: QueryTypes.SELECT,
      replacements: { id: id },
    }
  );
};

const getInvoice = (vinNumbersId: number): Promise<any> => {
  return secondarySequelize.query<any>(
    `SELECT * FROM clean_truck_check_vin_numbers WHERE id = :id`,
    {
      type: QueryTypes.SELECT,
      replacements: { id: vinNumbersId },
    }
  );
};

const getAddress = (vinNumberCompaniesId: number): Promise<any> => {
  return secondarySequelize.query<any>(
    `SELECT * FROM clean_truck_check_vin_number_companies WHERE id = :id`,
    {
      type: QueryTypes.SELECT,
      replacements: { id: vinNumberCompaniesId },
    }
  );
};

const getPayment = (invoiceDetailId: number): Promise<any> => {
  return secondarySequelize.query<any>(
    `SELECT * FROM clean_truck_check_invoice_payments WHERE invoice_detail = :id`,
    {
      type: QueryTypes.SELECT,
      replacements: { id: invoiceDetailId },
    }
  );
};

export const insertInspection = async (
  req: Request,
  res: Response
): Promise<any> => {
  try {
    const {
      company_name,
      truck_id,
      trailer_id,
      odometer,
      inspected_at,
      vehicle_type,
      truckData,
      trailerData
    } = req.body;
     
    // Get current time
    const now = new Date();

     const userProfile = await UserProfile.findByPk(req.user?.id);
    const user = await User.findByPk(userProfile?.userId);

    // Combine date from frontend with current time
    let finalInspectedAt;
    
    if (inspected_at) {
      // Parse the date from frontend and combine with current time
      const dateFromFrontend = new Date(inspected_at);
      
      if (!isNaN(dateFromFrontend.getTime())) {
        // Create new date with frontend's date but current time
        finalInspectedAt = new Date(
          dateFromFrontend.getFullYear(),
          dateFromFrontend.getMonth(),
          dateFromFrontend.getDate(),
          now.getHours(),
          now.getMinutes(),
          now.getSeconds()
        );
      } else {
        // If frontend date is invalid, use current datetime
        finalInspectedAt = now;
      }
    } else {
      // If no date from frontend, use current datetime
      finalInspectedAt = now;
    }

    // Raw SQL query with parameter binding (recommended for security)
    const query = `
      INSERT INTO daily_vehicle_inspections 
      (company_name, truck_id, trailer_id, driver_id, odometer, inspected_at, created_at, updated_at, vehicle_type) 
      VALUES 
      (:company_name, :truck_id, :trailer_id, :driver_id, :odometer, :inspected_at, NOW(), NOW(), :vehicle_type)
    `;

   const result = await secondarySequelize.query(query, {
      replacements: {
        company_name,
        truck_id,
        trailer_id:trailer_id || null,
        driver_id:user?.yard_id,
        odometer,
        inspected_at:finalInspectedAt,
        vehicle_type,
      },
      type: QueryTypes.INSERT,
    });
  
    await insertInspectionQuestions(result?.[0],truckData,trailerData)

    return res.status(200).json({
      status: true,
      message: `Inspection Submitted Successfully.`,
      data: null,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
};

export async function getInspectionView(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const driverId = req.user?.id;

    const groupUser = await GroupUser.findOne({
      where: {
        userProfileId: driverId,
      },
      include: [
        {
          model: Group,

          where: {
            type: "truck",
            name: {
              [Op.ne]: "Mechanic",
            },
          },
        },
      ],
    });

    const getYardDriver = await secondarySequelize.query<any>(
      `SELECT * FROM trucks WHERE number = :truckNumber`,
      {
        type: QueryTypes.SELECT,
        replacements: {
          truckNumber: groupUser?.dataValues.Group?.name,
        },
      }
    );

    const questionsTruck = [
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

    const questionsTrailer = [
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

    const trailers = await secondarySequelize.query<any>(
      `SELECT * FROM trailers`,
      {
        type: QueryTypes.SELECT,
      }
    );
    let odometerMiles = null;

    const apiKey = process.env.SAMSARA_API_KEY;

    try {
      const response = await axios.get(
        "https://api.samsara.com/fleet/vehicles/stats/feed",
        {
          headers: {
            Accept: "application/json",
            Authorization: `Bearer ${apiKey}`,
          },
          params: {
            vehicleIds: getYardDriver?.[0]?.samsara_vehicle_id,
            types: "obdOdometerMeters",
          },
        }
      );

      if (
        response.data &&
        response.data.data &&
        response.data.data[0] &&
        response.data.data[0].obdOdometerMeters &&
        response.data.data[0].obdOdometerMeters[0] &&
        response.data.data[0].obdOdometerMeters[0].value
      ) {
        const meters = response.data.data[0].obdOdometerMeters[0].value;
        odometerMiles = Math.round(meters * 0.000621371 * 100) / 100; // Convert to miles and round to 2 decimal places
      }
    } catch (apiError: any) {
      console.error("Samsara API error:", apiError.message);
      // Continue to return null odometer value if API fails
    }

    return res.status(200).json({
      status: true,
      message: `Get Inspection Data Successfully.`,
      data: {
        groupUser: groupUser,
        questionsTrailer,
        questionsTruck,
        trailers,
        getYardDriver: getYardDriver?.length > 0 ? getYardDriver?.[0] : null,
        odometerMiles,
      },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export default async function pdfGernate(
  req: Request,
  res: Response
): Promise<any> {
  const id = req.params.id;
  getInvoiceDetails(parseInt(id))
    .then((invoiceDetails: any[]) => {
      if (Array.isArray(invoiceDetails) && invoiceDetails.length > 0) {
        const details = invoiceDetails[0];

        // Chain the next queries based on the results
        return getInvoice(details.vin_numbers_id).then((invoices: any[]) => {
          if (Array.isArray(invoices) && invoices.length > 0) {
            const invoice = invoices[0];

            return getAddress(details.vin_number_companies_id).then(
              (addresss: any[]) => {
                if (Array.isArray(addresss) && addresss.length > 0) {
                  const address = addresss[0];

                  return getPayment(details.id).then(
                    async (payments: any[]) => {
                      let payment = null;
                      if (Array.isArray(payments) && payments.length > 0) {
                        payment = payments[0];
                      }

                      // Now that all data is fetched, generate the PDF
                      const date = new Date();
                      const month = date.getMonth() + 1;
                      const day = date.getDate();
                      const year = date.getFullYear();
                      const formattedDate = `${month
                        .toString()
                        .padStart(2, "0")}/${day
                        .toString()
                        .padStart(2, "0")}/${year}`;

                      const html: any = await renderTemplate(
                        path.join(
                          __dirname,
                          "../../views",
                          "yard",
                          "clean.ejs"
                        ),
                        {
                          date: formattedDate,
                          details,
                          invoice,
                          payment,
                          address,
                        }
                      );

                      const outputPdfPath = path.join(
                        __dirname,
                        "../../",
                        "dlfile.pdf"
                      );
                      await generatePdf(
                        html,
                        {
                          landscape: false,
                          printBackground: true,
                          format: "A4",
                        },
                        outputPdfPath
                      );

                      // Step 10: Set response headers and send the PDF as a download
                      res.setHeader(
                        "Content-Disposition",
                        "attachment; filename=dlfile.pdf"
                      );
                      res.setHeader("Content-Type", "application/pdf");

                      const pdfBuffer = await fs.readFile(outputPdfPath);
                      return res.send(pdfBuffer).end(async () => {
                        // Step 11: Cleanup the generated PDF file after sending the response
                        try {
                          await fs.unlink(outputPdfPath); // Remove the file from the server
                        } catch (err) {
                          console.error("Error deleting the file:", err);
                        }
                      });
                    }
                  );
                } else {
                  throw new Error("Address not found.");
                }
              }
            );
          } else {
            throw new Error("Invoice not found.");
          }
        });
      } else {
        throw new Error("Invoice details not found.");
      }
    })
    .catch((err) => {
      console.error("Error in generating invoice:", err);
      return res.status(400).json({
        status: false,
        message: err.message || "Internal Server Error",
      });
    });
}

export async function sendInvoiceEmail(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const id = req.params.id;

    let details: any = null;
    let invoice: any = null;
    let address: any = null;
    let payment: any = null;

    const invoice_details = await secondarySequelize.query<any>(
      `SELECT * FROM clean_truck_check_invoice_details WHERE id = :id`,
      {
        type: QueryTypes.SELECT,
        replacements: { id: id },
      }
    );
    if (Array.isArray(invoice_details) && invoice_details.length > 0) {
      details = invoice_details[0];
    }

    if (details != null) {
      const invoices = await secondarySequelize.query<any>(
        `SELECT * FROM clean_truck_check_vin_numbers WHERE id = :id`,
        {
          type: QueryTypes.SELECT,
          replacements: { id: details.vin_numbers_id },
        }
      );
      if (Array.isArray(invoices) && invoices.length > 0) {
        invoice = invoices[0];
      }
      const addresss = await secondarySequelize.query<any>(
        `SELECT * FROM clean_truck_check_vin_number_companies WHERE id = :id`,
        {
          type: QueryTypes.SELECT,
          replacements: { id: details.vin_number_companies_id },
        }
      );
      if (Array.isArray(addresss) && addresss.length > 0) {
        address = addresss[0];
      }
      const payments = await secondarySequelize.query<any>(
        `SELECT * FROM clean_truck_check_invoice_payments WHERE invoice_detail = :id`,
        {
          type: QueryTypes.SELECT,
          replacements: { id: details.id },
        }
      );

      if (Array.isArray(payments) && payments.length > 0) {
        payment = payments[0];
      }
    }

    const date = new Date();

    const month = date.getMonth() + 1;
    const day = date.getDate();
    const year = date.getFullYear();

    const formattedDate = `${month.toString().padStart(2, "0")}/${day
      .toString()
      .padStart(2, "0")}/${year}`;

    const html: any = await renderTemplate(
      path.join(__dirname, "../../views", "yard", "clean.ejs"),
      { date: formattedDate, details, invoice, payment, address }
    );
    const outputPdfPath = path.join(
      __dirname,
      "../../",
      `report-${details.text_number}.pdf`
    );
    await generatePdf(
      html,
      { landscape: false, printBackground: true, format: "A4" },
      outputPdfPath
    );

    await sendEmailWithAttachment(
      address.email,
      `Clean Truck Check Report Test No. ${details.text_number}`,
      "Please find clean truck check report your vehicle.",
      "<p>Please find clean truck check report your vehicle.</p>",
      outputPdfPath
    );

    await fs.unlink(outputPdfPath);

    return res
      .status(200)
      .json({ status: true, message: "Sent Invoice Successfully." });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function getPays(req: Request, res: Response): Promise<any> {
  try {
    const userProfile = await UserProfile.findByPk(req.user?.id);
    const user = await User.findByPk(userProfile?.userId);
    // Get pagination parameters from the request query, with defaults if not provided
    const page = parseInt(req.query.page as string) || 1;
    const pageSize = parseInt(req.query.pageSize as string) || 10;
    const type = "driver_pays";
    const searchQuery = req.query.search || ""; // New parameter for search

    // Calculate OFFSET
    const offset = (page - 1) * pageSize;

    // Construct the search condition
    let searchCondition = "";
    let replacements: any = { limit: pageSize, offset };

    if (searchQuery) {
      // Use LIKE if searchQuery is provided
      searchCondition = `AND tripId LIKE :searchQuery`;
      // Modify `number` based on your table schema
      replacements.searchQuery = `%${searchQuery}%`; // Add the searchQuery parameter
    }

    // Fetch the total number of records for pagination
    const totalTrucks = await secondarySequelize.query<any>(
      `SELECT COUNT(*) AS total FROM ${type} WHERE driver_id = :driverId ${searchCondition}`,
      {
        replacements: {
          driverId: user?.yard_id,
          ...replacements, // Spread other replacements if necessary
        },
        type: QueryTypes.SELECT,
      }
    );

    const totalAmount = await secondarySequelize.query<any>(
      `SELECT SUM(amount) AS totalAmount
       FROM driver_pays 
       WHERE driver_id = :driverId 
       ${searchCondition}`,
      {
        replacements: {
          driverId: user?.yard_id,
          ...replacements, // Spread other replacements if necessary (e.g., search term, dates)
        },
        type: QueryTypes.SELECT,
      }
    );
    // Fetch the paginated data with the appropriate search condition
    const paysOld = await secondarySequelize.query<any>(
      `SELECT * FROM ${type} WHERE driver_id = :driverId ${searchCondition} ORDER BY id DESC LIMIT :limit OFFSET :offset`,
      {
        replacements: {
          driverId: user?.yard_id,
          ...replacements, // Spread other replacements if necessary
        },
        type: QueryTypes.SELECT,
      }
    );
    const pays = await Promise.all(
      paysOld.map(async (e) => {
        const detailsM = await secondarySequelize.query<any>(
          `SELECT * FROM driver_pay_mileages WHERE driver_pay_details_id = :driver_pay_details_id`,
          {
            replacements: {
              driver_pay_details_id: e.driver_pay_details_id,
              ...replacements, // Spread other replacements if necessary
            },
            type: QueryTypes.SELECT,
          }
        );
        return { ...e, locations: detailsM };
      })
    );
    // Calculate total pages (for pagination metadata)
    const totalCount = totalTrucks[0].total;
    const totalPages = Math.ceil(totalCount / pageSize);

    return res.status(200).json({
      status: true,
      message: `Get pays Successfully.`,
      data: {
        data: pays,
        totalAmount: parseFloat(totalAmount?.[0]?.totalAmount.toFixed(2)) || 0,
        pagination: {
          currentPage: page,
          pageSize: pageSize,
          totalPages: totalPages,
          totalItems: totalCount,
        },
      },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

interface JobProgress {
  jobId: string;
  progress: number;
}

// Define the structure of the queue progress data
interface QueueProgress {
  waiting: JobProgress[];
  active: JobProgress[];
  delayed: JobProgress[];
  completed: JobProgress[];
  failed: JobProgress[];
}

// Function to get the progress of all queues
async function getProgressOfAllQueues(): Promise<{
  [queueName: string]: QueueProgress;
}> {
  const queues = ["fileUploadQueue", "jobQueue"]; // Add your queues here
  const result: { [queueName: string]: QueueProgress } = {};

  // Loop through all queues
  for (let queueName of queues) {
    const queue = new Queue(queueName);
    const states: (
      | "waiting"
      | "active"
      | "delayed"
      | "completed"
      | "failed"
    )[] = ["waiting", "active", "delayed", "completed", "failed"];

    result[queueName] = {
      waiting: [],
      active: [],
      delayed: [],
      completed: [],
      failed: [],
    };

    // Loop through each state
    for (let state of states) {
      const jobs: Job[] = await queue.getJobs([state]); // Pass the state as an array

      // Get the progress of each job
      for (let job of jobs) {
        const progress = await job.progress();
        result[queueName][state].push({
          jobId: job.id.toString(), // Convert jobId to string
          progress,
        });
      }
    }
  }

  return result;
}

export async function queueData(req: Request, res: Response): Promise<any> {
  try {
    const progressData = await getProgressOfAllQueues();
    return res.status(200).json({
      status: true,
      message: `Get queue Successfully.`,
      data: progressData,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}


const insertInspectionQuestions = async (dailyVehicleInspectionId:any, truckData:any, trailerData:any) => {
  try {
    // Prepare all questions data
    const allQuestions = [
      ...truckData.map((item:any) => ({
        daily_vehicle_inspections_id: dailyVehicleInspectionId,
        inspected_vehicle_type: 'truck',
        question: item.question,
        status: item.status,
        created_at: new Date(),
        updated_at: new Date()
      })),
      ...trailerData.map((item:any) => ({
        daily_vehicle_inspections_id: dailyVehicleInspectionId,
        inspected_vehicle_type: 'trailer',
        question: item.question,
        status: item.status,
        created_at: new Date(),
        updated_at: new Date()
      }))
    ];

    // If no questions to insert, return early
    if (allQuestions.length === 0) {
      return { message: 'No questions to insert' };
    }

    // Build the raw SQL query
    const valuesPlaceholders = allQuestions.map((_, index) => 
      `(:daily_vehicle_inspections_id_${index}, :inspected_vehicle_type_${index}, :question_${index}, :status_${index}, :created_at_${index}, :updated_at_${index})`
    ).join(', ');

    const query = `
      INSERT INTO vehicle_inspection_questions 
      (daily_vehicle_inspections_id, inspected_vehicle_type, question, status, created_at, updated_at) 
      VALUES 
      ${valuesPlaceholders}
    `;

    // Prepare replacements object
    const replacements:any = {};
    allQuestions.forEach((question:any, index:number) => {
      replacements[`daily_vehicle_inspections_id_${index}`] = question.daily_vehicle_inspections_id;
      replacements[`inspected_vehicle_type_${index}`] = question.inspected_vehicle_type;
      replacements[`question_${index}`] = question.question;
      replacements[`status_${index}`] = question.status;
      replacements[`created_at_${index}`] = question.created_at;
      replacements[`updated_at_${index}`] = question.updated_at;
    });

    // Execute the query
    const result = await secondarySequelize.query(query, {
      replacements,
      type: QueryTypes.INSERT
    });

    console.log(`Inserted ${allQuestions.length} inspection questions`);
    return result;

  } catch (error) {
    console.error('Error inserting inspection questions:', error);
    throw error;
  }
};
