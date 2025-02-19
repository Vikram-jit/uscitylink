import { promises as fs } from "fs";

import * as path from "path";
import ejs from "ejs"; // Import EJS

import { Request, Response } from "express";
import { generatePdf } from "../utils/pdf";
import { secondarySequelize } from "../sequelize";
import { QueryTypes } from "sequelize";
import { sendEmailWithAttachment } from "../utils/sendEmail";
import { UserProfile } from "../models/UserProfile";
import User from "../models/User";

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
        return getInvoice(details.vin_numbers_id)
          .then((invoices: any[]) => {
            if (Array.isArray(invoices) && invoices.length > 0) {
              const invoice = invoices[0];

              return getAddress(details.vin_number_companies_id)
                .then((addresss: any[]) => {
                  if (Array.isArray(addresss) && addresss.length > 0) {
                    const address = addresss[0];

                    return getPayment(details.id)
                      .then(async (payments: any[]) => {
                        let payment = null;
                        if (Array.isArray(payments) && payments.length > 0) {
                          payment = payments[0];
                        }

                        // Now that all data is fetched, generate the PDF
                        const date = new Date();
                        const month = date.getMonth() + 1;
                        const day = date.getDate();
                        const year = date.getFullYear();
                        const formattedDate = `${month.toString().padStart(2, "0")}/${day.toString().padStart(2, "0")}/${year}`;
                       
                        const html: any = await renderTemplate(
                          path.join(__dirname, "../../views", "yard", "clean.ejs"),
                          { date: formattedDate, details, invoice, payment, address }
                        );
                      
                     
                        const outputPdfPath = path.join(__dirname, "../../", "dlfile.pdf");
                        await generatePdf(
                          html,
                          { landscape: false, printBackground: true, format: "A4" },
                          outputPdfPath
                        );
                    
                        // Step 10: Set response headers and send the PDF as a download
                        res.setHeader("Content-Disposition", "attachment; filename=dlfile.pdf");
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

                        // return generatePdf(
                        //   html,
                        //   { landscape: false, printBackground: true, format: "A4" },
                        //   outputPdfPath
                        // ).then(() => {
                        //   res.setHeader("Content-Disposition", "attachment; filename=dlfile.pdf");
                        //   res.setHeader("Content-Type", "application/pdf");
                        //   return fs.readFile(outputPdfPath);
                        // })
                        // .then((pdfBuffer) => {
                        //   res.send(pdfBuffer).end(() => {
                        //     fs.unlink(outputPdfPath);
                        //   });
                        // });
                      });
                  } else {
                    throw new Error("Address not found.");
                  }
                });
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
      return res.status(400).json({ status: false, message: err.message || "Internal Server Error" });
    });
   
}

export  async function sendInvoiceEmail(
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
console.log(req.user?.id)
     const userProfile = await UserProfile.findByPk(req.user?.id)
     const user = await User.findByPk(userProfile?.userId);
    // Get pagination parameters from the request query, with defaults if not provided
    const page = parseInt(req.query.page as string) || 1;
    const pageSize = parseInt(req.query.pageSize as string) || 10;
    const type = "driver_pays";
    const searchQuery = req.query.search || ""; // New parameter for search

    // Calculate OFFSET
    const offset = (page - 1) * pageSize;

    // Construct the search condition
    let searchCondition = '';
    let replacements: any = { limit: pageSize, offset };

   
     if (searchQuery) {
      // Use LIKE if searchQuery is provided
      searchCondition = `WHERE number = :searchQuery`;  // Modify `number` based on your table schema
      replacements.searchQuery = `${searchQuery}`; // Add the searchQuery parameter
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

    // Fetch the paginated data with the appropriate search condition
    const pays = await secondarySequelize.query<any>(
      `SELECT * FROM ${type} WHERE driver_id = :driverId ${searchCondition} ORDER BY id DESC LIMIT :limit OFFSET :offset`,
      {
        replacements: {
          driverId:  user?.yard_id,
          ...replacements, // Spread other replacements if necessary
        },
        type: QueryTypes.SELECT,
      }
    );
    // Calculate total pages (for pagination metadata)
    const totalCount = totalTrucks[0].total;
    const totalPages = Math.ceil(totalCount / pageSize);

    return res.status(200).json({
      status: true,
      message: `Get pays Successfully.`,
      data: {
        data: pays,
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
