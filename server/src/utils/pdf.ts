import './../polyfills';

import { PDFDocument, rgb } from "pdf-lib";
import puppeteer, { PDFOptions } from "puppeteer";
import { promises as fs } from "fs";
import * as fss from "fs";
import moment from "moment";
import axios from "axios";
import dotenv from 'dotenv'
dotenv.config()



const generatePdf = async (
  htmlContent: string,
  options: PDFOptions,
  outputPath: string
): Promise<void> => {
  try {
    const browser = await puppeteer.launch({
      headless: true, // Run headless
  args: [
    '--no-sandbox',        // Disable sandbox (necessary in some environments like Docker)
    '--disable-setuid-sandbox', // Disable setuid sandbox (for non-root users)
    '--disable-gpu',       // Disable GPU acceleration (optional but helpful in some environments)
 
  ],
      // ...(process.env.DB_SERVER == "local"
      
      //   ? { headless: true }
      //   : { executablePath: "/usr/bin/chromium-browser" }),
      // headless: true,

      ignoreDefaultArgs: ["--disable-extensions"],
    });

    const page = await browser.newPage();
    await page.setContent(htmlContent, { waitUntil: "networkidle0" });
    await page.pdf({ ...options, path: outputPath,pageRanges: '1' });
    await browser.close();
  } catch (error) {
    console.error("Error generating PDF:", error);
  }
  // Launch Puppeteer
};

const addPagesToPdfWithCheckBlankPage = async (
  existingPdfPath: string,
  newPdfPath: string,
  outputPdfPath: string
): Promise<void> => {
  try {
    // Load the existing PDF
    const existingPdfBytes = await fs.readFile(existingPdfPath);
    const existingPdfDoc = await PDFDocument.load(existingPdfBytes);

    // Load the new PDF
    const newPdfBytes = await fs.readFile(newPdfPath);
    const newPdfDoc = await PDFDocument.load(newPdfBytes);

    // Iterate through all pages in the new PDF
    const newPdfPagesCount = newPdfDoc.getPageCount();
    for (let pageIndex = 0; pageIndex < newPdfPagesCount; pageIndex++) {
      if (pageIndex !== 0) {
        // Skip the first page

        const [copiedPage] = await existingPdfDoc.copyPages(newPdfDoc, [
          pageIndex,
        ]);
        existingPdfDoc.addPage(copiedPage);
      } else {
        console.log(`Page ${pageIndex + 1} is blank and will be skipped.`);
      }
    }

    // Save the updated PDF
    const updatedPdfBytes = await existingPdfDoc.save();
    await fs.writeFile(outputPdfPath, updatedPdfBytes);

    console.log("New pages added and PDF saved successfully!");
  } catch (error) {
    console.error("Error adding pages to PDF:", error);
  }
};

async function fetchImage(url: string): Promise<Uint8Array> {
  const response = await axios.get(url, { responseType: "arraybuffer" });
  return new Uint8Array(response.data);
}

export function isValidImageExtension(filePath: string): boolean {
  const validExtensions = [".png", ".jpeg", ".jpg"];
  const ext = filePath
    .slice(((filePath.lastIndexOf(".") - 1) >>> 0) + 2)
    .toLowerCase();
  return validExtensions.includes(`.${ext}`);
}

export async function addImageToPDF(
  imageUrls: string[],
  outputPath: string
): Promise<void> {
  const pdfDoc = await PDFDocument.create();
  const a4Width = 595.28; // 210 mm
  const a4Height = 841.89; // 297 mm
  for (const imageUrl of imageUrls) {
    const imageBytes = await fetchImage(imageUrl);
    const ext = imageUrl
      .slice(((imageUrl.lastIndexOf(".") - 1) >>> 0) + 2)
      .toLowerCase();
    let pngImage: any;

    if (ext === "png") {
      pngImage = await pdfDoc.embedPng(imageBytes);
    } else if (ext === "jpeg" || ext === "jpg") {
      pngImage = await pdfDoc.embedJpg(imageBytes);
    }
    
    const pngDims = pngImage?.scale(1);
    if (pngDims) {
    
      const page = pdfDoc.addPage([a4Width, a4Height]);

     
      page.drawRectangle({
        x: 0,
        y: 0,
        width: a4Width,
        height: a4Height,
        color: rgb(1, 1, 1), 
      });

      // Center the image on the page
      const xOffset = (a4Width - pngDims?.width) / 2;
      const yOffset = (a4Height - pngDims?.height) / 2;

      // Draw the image on the page
      page.drawImage(pngImage, {
        x: xOffset,
        y: yOffset,
        width: pngDims.width,
        height: pngDims.height,
      });
    }

    // Serialize the PDFDocument to bytes (a Uint8Array)
    const pdfBytes = await pdfDoc.save();

    // Write the new PDF to a file
    fss.writeFileSync(outputPath, pdfBytes);
  }
}

const addPagesToPdfWithoutCheckBlankPage = async (
  existingPdfPath: string,
  newPdfPath: string,
  outputPdfPath: string
): Promise<void> => {
  try {
    // Load the existing PDF
    const existingPdfBytes = await fs.readFile(existingPdfPath);
    const existingPdfDoc = await PDFDocument.load(existingPdfBytes);

    // Load the new PDF
    const newPdfBytes = await fs.readFile(newPdfPath);
    const newPdfDoc = await PDFDocument.load(newPdfBytes);

    const newPdfPagesCount = newPdfDoc.getPageCount();
    for (let pageIndex = 0; pageIndex < newPdfPagesCount; pageIndex++) {
      // Copy the page from the new PDF to the existing PDF
      const [copiedPage] = await existingPdfDoc.copyPages(newPdfDoc, [
        pageIndex,
      ]);
      existingPdfDoc.addPage(copiedPage);
    }

    // Save the updated PDF
    const updatedPdfBytes = await existingPdfDoc.save();
    await fs.writeFile(outputPdfPath, updatedPdfBytes);

    console.log("New pages added and PDF saved successfully!");
  } catch (error) {
    console.error("Error adding pages to PDF:", error);
  }
};

const groupIntoSets = (arr: any, groupSize: number) => {
  const result = [];
  for (let i = 0; i < arr.length; i += groupSize) {
    result.push(arr.slice(i, i + groupSize));
  }
  return result;
};

const combineMultiplePdfs = async (
  existingPdfPath: string,
  newPdfPaths: string[],
  outputPdfPath: string
): Promise<void> => {
  try {
    // Load the existing PDF
    const existingPdfBytes = await fs.readFile(existingPdfPath);
    const existingPdfDoc = await PDFDocument.load(existingPdfBytes);

    // Loop through each new PDF path
    for (const newPdfPath of newPdfPaths) {
      // Load the new PDF
      const newPdfBytes = await fs.readFile(newPdfPath);
      const newPdfDoc = await PDFDocument.load(newPdfBytes);

      // Get the count of pages in the new PDF
      const newPdfPagesCount = newPdfDoc.getPageCount();

      // Copy all pages from the new PDF to the existing PDF
      for (let pageIndex = 0; pageIndex < newPdfPagesCount; pageIndex++) {
        const [copiedPage] = await existingPdfDoc.copyPages(newPdfDoc, [
          pageIndex,
        ]);
        existingPdfDoc.addPage(copiedPage);
      }
    }

    // Save the updated PDF
    const updatedPdfBytes = await existingPdfDoc.save();
    await fs.writeFile(outputPdfPath, updatedPdfBytes);

    console.log("All new pages added and PDF saved successfully!");
  } catch (error) {
    console.error("Error combining PDFs:", error);
  }
};

export async function mergePdfs(pdfPaths: string[], outputPdfPath: string) {
  const mergedPdf = await PDFDocument.create();

  for (const pdfPath of pdfPaths) {
    try {
      const pdfBytes = fss.readFileSync(pdfPath);
      const pdf = await PDFDocument.load(pdfBytes);
      const copiedPages = await mergedPdf.copyPages(pdf, pdf.getPageIndices());
      copiedPages.forEach((page) => mergedPdf.addPage(page));
    } catch (error) {
      console.error(`Error processing ${pdfPath}:`, error);
      // Optionally, handle or skip the problematic PDF here
    }
  }

  const mergedPdfBytes = await mergedPdf.save();
  fss.writeFileSync(outputPdfPath, mergedPdfBytes);
}

// export const mergePdfs = async (pdfPaths: string[], outputPdfPath: string): Promise<void> => {
//   try {
//     // Create a new PDF document
//     const mergedPdf = await PDFDocument.create();

//     for (const pdfPath of pdfPaths) {
//       // Read the PDF file
//       const pdfBytes = await fs.readFile(pdfPath);
//       const pdfDoc = await PDFDocument.load(pdfBytes);

//       // Copy pages from the PDF
//       const copiedPages = await mergedPdf.copyPages(pdfDoc, pdfDoc.getPageIndices());
//       copiedPages.forEach((page) => {
//         mergedPdf.addPage(page);
//       });
//     }

//     // Save the merged PDF
//     const mergedPdfBytes = await mergedPdf.save();
//     await fs.writeFile(outputPdfPath, mergedPdfBytes);

//     console.log(`Merged PDF saved to ${outputPdfPath}`);
//   } catch (error) {
//     console.error("Error merging PDFs:", error);
//   }
// };

function dateFormat(
  date: string,
  daysToAdd: number = 0,
  format: string = "MM-DD-YYYY"
): string {
  if (typeof date == null) return "";

  if (!date) return "";

  // Check if the input date is valid
  if (!moment(date, moment.ISO_8601, true).isValid()) {
    throw new Error("Invalid date format");
  }

  // Format the date as MM-DD-YYYY
  return moment(date).add(daysToAdd, "days").format(format);
}
export function hasExtension(filename: string, extension: string) {
  const regex = new RegExp(`\\.${extension}$`, "i");
  return regex.test(filename);
}

export const addPagesToPdfWithoutCheckBlankPageWithUrl = async (
  existingPdfPath: string,
  newPdfUrl: string,
  outputPdfPath: string
): Promise<void> => {
  try {
    // Fetch the existing PDF from the URL
    const existingPdfBytes = await fs.readFile(existingPdfPath);
    const existingPdfDoc = await PDFDocument.load(existingPdfBytes);

    // Fetch the new PDF from the URL
    const newPdfResponse = await axios.get(newPdfUrl, {
      responseType: "arraybuffer",
    });
    const newPdfBytes = newPdfResponse.data;
    const newPdfDoc = await PDFDocument.load(newPdfBytes);

    const newPdfPagesCount = newPdfDoc.getPageCount();
    for (let pageIndex = 0; pageIndex < newPdfPagesCount; pageIndex++) {
      // Copy the page from the new PDF to the existing PDF
      const [copiedPage] = await existingPdfDoc.copyPages(newPdfDoc, [
        pageIndex,
      ]);
      existingPdfDoc.addPage(copiedPage);
    }

    // Save the updated PDF
    const updatedPdfBytes = await existingPdfDoc.save();
    await fs.writeFile(outputPdfPath, updatedPdfBytes);

    console.log("New pages added and PDF saved successfully!");
  } catch (error) {
    console.error("Error adding pages to PDF:", error);
  }
};

export const savePdfFromUrl = async (url: string, outputPath: string,refererUrl?:string) => {
  try {
   
    // Fetch the PDF from the server
    const response = await axios.get(url, {
      responseType: "stream", // Important: Set response type to stream
      headers: {
        'Referer': refererUrl,
      },
    });
    
    // Check if the response is okay
    if (response.status !== 200) {
      throw new Error(`Failed to fetch PDF: ${response.statusText}`);
    }

    // Create a write stream to save the PDF
    const dest = fss.createWriteStream(outputPath);

    // Pipe the response data to the file
    response.data.pipe(dest);

    // Wait for the write stream to finish
    dest.on("finish", () => {
      console.log(`PDF saved to ${outputPath}`);
    });

    dest.on("error", (err) => {
      console.error("Error writing PDF file:", err);
    });
  } catch (error) {
    console.error("Error fetching or saving PDF:", error);
  }
};

export {
  addPagesToPdfWithCheckBlankPage,
  addPagesToPdfWithoutCheckBlankPage,
  generatePdf,
  groupIntoSets,
  combineMultiplePdfs,
  dateFormat,
};
