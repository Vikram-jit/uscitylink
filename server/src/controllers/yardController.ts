import { promises as fs } from "fs";

import * as path from "path";
import ejs from "ejs"; // Import EJS

import { Request, Response } from "express";
import { generatePdf } from "../utils/pdf";
import { secondarySequelize } from "../sequelize";
import { QueryTypes } from "sequelize";

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

export default async function pdfGernate(
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
      { date: formattedDate ,details,invoice,payment,address}
    );
    const outputPdfPath = path.join(__dirname,'../../', "dlfile.pdf");
    await generatePdf(
      html,
      { landscape: false, printBackground: true, format: "A4" },
      outputPdfPath
    );

    res.setHeader("Content-Disposition", "attachment; filename=dlfile.pdf");
    res.setHeader("Content-Type", "application/pdf");
    const pdfBuffer = await fs.readFile(outputPdfPath);

    return res.send(pdfBuffer).end(async () => {
      await fs.unlink(outputPdfPath);
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}
