import { GetObjectCommand, PutObjectCommand, S3Client } from "@aws-sdk/client-s3";
import fs from "fs";
import path from "path";
import sharp from "sharp";
import dotenv from "dotenv";

dotenv.config();

const s3Client = new S3Client({
  region: "us-west-1",
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || "",
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || "",
  },
});

const IMAGE_EXTENSIONS = ["jpg", "jpeg", "png", "webp", "heic", "heif", "gif", "bmp", "tif", "tiff"];

export type AnalyzableKind = "image" | "pdf" | null;

export const getAnalyzableKind = (key?: string | null): AnalyzableKind => {
  if (!key) return null;
  const ext = key.split("?")[0].split(".").pop()?.toLowerCase() || "";
  if (IMAGE_EXTENSIONS.includes(ext)) return "image";
  if (ext === "pdf") return "pdf";
  return null;
};

export interface PreparedFile {
  kind: "image" | "pdf";
  mediaType: "image/jpeg" | "application/pdf";
  base64: string;
}

export const readS3Object = async (key: string): Promise<Buffer> => {
  const result = await s3Client.send(
    new GetObjectCommand({ Bucket: process.env.BUCKET_NAME || "ciity-sms", Key: key }),
  );
  const bytes = await result.Body!.transformToByteArray();
  return Buffer.from(bytes);
};

// Files uploaded through the queue sit in public/uscitylink until the S3 upload finishes
const readLocalObject = (key: string): Buffer | null => {
  const localPath = path.join(__dirname, "../../../public", key);
  return fs.existsSync(localPath) ? fs.readFileSync(localPath) : null;
};

export const prepareBuffer = async (buffer: Buffer, kind: "image" | "pdf"): Promise<PreparedFile> => {
  if (kind === "pdf") {
    return { kind, mediaType: "application/pdf", base64: buffer.toString("base64") };
  }
  // Respect EXIF rotation, cap the long edge at 1568px (larger images are
  // downscaled by the API anyway) and re-encode as JPEG to keep payloads small.
  const jpeg = await sharp(buffer)
    .rotate()
    .resize({ width: 1568, height: 1568, fit: "inside", withoutEnlargement: true })
    .jpeg({ quality: 85 })
    .toBuffer();
  return { kind, mediaType: "image/jpeg", base64: jpeg.toString("base64") };
};

export const loadFileForAnalysis = async (key: string): Promise<PreparedFile | null> => {
  const kind = getAnalyzableKind(key);
  if (!kind) return null;
  let buffer: Buffer | null = null;
  try {
    buffer = await readS3Object(key);
  } catch (err) {
    buffer = readLocalObject(key);
    if (!buffer) throw err;
  }
  return prepareBuffer(buffer, kind);
};

export const putS3Object = async (key: string, body: Buffer, contentType?: string) => {
  await s3Client.send(
    new PutObjectCommand({
      Bucket: process.env.BUCKET_NAME || "ciity-sms",
      Key: key,
      Body: body,
      ContentType: contentType,
    }),
  );
  return key;
};
