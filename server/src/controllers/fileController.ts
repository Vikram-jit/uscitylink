import express, { Request, Response } from "express";
import multer, { FileFilterCallback } from "multer";
import AWS from "aws-sdk";
import fs from "fs";
import dotenv from "dotenv";
import { Media } from "../models/Media";
import ffmpeg from "fluent-ffmpeg";
import path from "path";
import { GetObjectCommand, S3Client } from "@aws-sdk/client-s3";
import sharp from 'sharp';
import { Readable } from "stream";
import imageToPDF from 'image-to-pdf';

dotenv.config();


AWS.config.update({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID || "",
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || "",
  region: "us-west-1",
});

const s3Client = new S3Client({
  region: process.env.AWS_REGION || 'us-west-1',
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || '',
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || '',
  },
});

const s3 = new AWS.S3();
const storage = multer.memoryStorage();

const upload = multer({ storage });
const initiateMultipartUpload = async (fileName: string): Promise<string> => {
  const params = {
    Bucket: "ciity-sms",
    Key: fileName,
  };

  const response = await s3.createMultipartUpload(params).promise();
  return response.UploadId!;
};

const uploadPart = (
  params: AWS.S3.UploadPartRequest,
  partNumber: number,
  chunkSize: number,
  progressCallback: (uploadedBytesInPart: number) => void
): Promise<AWS.S3.CompletedPart> => {
  return new Promise((resolve, reject) => {
    s3.uploadPart(params, (err, data) => {
      if (err) {
        return reject(err);
      }
      progressCallback(chunkSize);
      resolve({ ETag: data.ETag!, PartNumber: partNumber });
    });
  });
};

const completeMultipartUpload = async (
  uploadId: string,
  uploadedParts: AWS.S3.CompletedPart[],
  fileName: string
): Promise<AWS.S3.CompleteMultipartUploadOutput> => {
  const params = {
    Bucket: "ciity-sms",
    Key: fileName,
    UploadId: uploadId,
    MultipartUpload: {
      Parts: uploadedParts,
    },
  };

  const response = await s3.completeMultipartUpload(params).promise();
  return response;
};

export const fileUploadAWS = async (
  req: Request,
  res: Response
): Promise<any> => {
  try {
    if (!req.file) {
      throw new Error("No file uploaded");
    }

    let thumbnail_data:any ;
    const file = req.file;
    const fileName = `uscitylink/video/${Date.now().toString()}-${
      file.originalname
    }`;
    const fileSize = file.size;
    const chunkSize = 5 * 1024 * 1024; // 5MB chunks
    const totalChunks = Math.ceil(fileSize / chunkSize);

    const channelId = req.body.channelId || req.activeChannel;
    const groupId = req.query.groupId || null;
    const userId = req.query.userId || req.user?.id;
    const private_chat_id = req.query.private_chat_id as string;

  

    if (fileSize < 5 * 1024 * 1024) {
      const params = {
        Bucket: "ciity-sms",
        Key: fileName,
        Body: file.buffer,
      };

      const managedUpload = s3.upload(params);

      const result: any = await managedUpload.promise();

      if (result) {
        const nameT = `${Date.now()}_thumbnail.png`;
      const thumbnailPath = path.join(__dirname,'../../', "uploads", nameT);

      const generatedThumbnailPath:any = await generateThumbnail(result?.Location, thumbnailPath, nameT);

    const uploadResult = await uploadToS3(generatedThumbnailPath, 'ciity-sms', `uscitylink/thumbnails/${Date.now()}_thumbnail.png`);
    
    
     thumbnail_data = uploadResult;

    
    fs.unlinkSync(generatedThumbnailPath);

      await Media.create({
        user_profile_id: userId,
        channelId: channelId,
        file_name: req.file?.originalname,
        file_size: req.file.size,
        mime_type: req.file.mimetype,
        key: result?.key,
        file_type: req.body.type,
        groupId: groupId == "null" ? null : groupId,
        upload_source: req.query.source || "message",
        thumbnail: thumbnail_data?.Key,
           upload_type:"server",
           private_chat_id:private_chat_id
      });
    
      }
      return res.status(201).json({
        status: true,
        message: "File uploaded successfully",
        data: {...result, thumbnail: thumbnail_data?.Key},
      });
    }

    // Step 1: Initiate the multipart upload
    const uploadId = await initiateMultipartUpload(fileName);

    const uploadPromises: Promise<AWS.S3.CompletedPart>[] = [];
    let uploadedBytes = 0;

    const updateProgress = (uploadedBytes: number) => {
      const progress = (uploadedBytes / fileSize) * 100;
      let progressPercentage = Math.floor(progress);

      if (progressPercentage > 100) progressPercentage = 100;

      console.log(`Upload progress: ${progressPercentage}%`);
    };

    // Step 2: Split the file into 5MB chunks and upload each part
    for (let chunkIndex = 0; chunkIndex < totalChunks; chunkIndex++) {
      const start = chunkIndex * chunkSize;
      const end = Math.min(start + chunkSize, fileSize);
      const chunkBuffer = file.buffer.slice(start, end);

      const params: AWS.S3.UploadPartRequest = {
        Bucket: "ciity-sms",
        Key: fileName,
        PartNumber: chunkIndex + 1,
        UploadId: uploadId,
        Body: chunkBuffer,
      };

      uploadPromises.push(
        uploadPart(
          params,
          chunkIndex + 1,
          chunkBuffer.length,
          (uploadedBytesInPart) => {
            uploadedBytes += uploadedBytesInPart;
            updateProgress(uploadedBytes);
          }
        )
      );
    }

    const uploadedParts = await Promise.all(uploadPromises);

    const result: any = await completeMultipartUpload(
      uploadId,
      uploadedParts,
      fileName
    );
    if (result) {

      const nameT = `${Date.now()}_thumbnail.png`;
      const thumbnailPath = path.join(__dirname,'../../', "uploads", nameT);

      const generatedThumbnailPath:any = await generateThumbnail(result?.Location, thumbnailPath, nameT);

    const uploadResult = await uploadToS3(generatedThumbnailPath, 'ciity-sms', `uscitylink/thumbnails/${Date.now()}_thumbnail.png`);
    
    
     thumbnail_data = uploadResult;

    
    fs.unlinkSync(generatedThumbnailPath);

      await Media.create({
        user_profile_id: userId,
        channelId: channelId,
        file_name: req.file?.originalname,
        file_size: req.file.size,
        mime_type: req.file.mimetype,
        key: result?.key,
        file_type: req.body.type,
        groupId: groupId,
        upload_source: req.query.source || "message",
        thumbnail: thumbnail_data?.Key,
      });
    }
    return res.status(201).json({
      status: true,
      message: "File uploaded successfully",
      data: {...result, thumbnail: thumbnail_data?.Key,},
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
};

export async function convertImageAndDownload(req: Request, res: Response):Promise<any> {
  const bucketName = 'ciity-sms';
  const objectKey = decodeURIComponent(req.params.fileName);
  
  try {
    // 1. Check if media exists in database
    const isMedia = await Media.findOne({ where: { key: objectKey } });
    if (!isMedia) {
      return res.status(404).json({ error: 'File not found in the database' });
    }

    let imageBuffer: Buffer;

    // 2. Handle different upload types
    if (isMedia.upload_type !== 'server') {
      // Handle non-S3 media (local files)
      const localPath = path.join(process.cwd(), 'public', objectKey);
        console.log('Local path:', localPath);
      try {
        imageBuffer = await fs.promises.readFile(localPath);
      } catch (err) {
        console.error('Error reading local file:', err);
        return res.status(404).json({ error: 'Local file not found' });
      }
    } else {
      // Handle S3 media
      try {
        const { Body } = await s3Client.send(
          new GetObjectCommand({ 
            Bucket: bucketName, 
            Key: objectKey 
          })
        );

        if (!Body || !(Body instanceof Readable)) {
          return res.status(404).json({ error: 'S3 file not found or invalid' });
        }

        imageBuffer = await streamToBuffer(Body);
      } catch (s3Error) {
        console.error('S3 retrieval error:', s3Error);
        return res.status(500).json({ error: 'Failed to retrieve file from S3' });
      }
    }

    // 3. Process image with error handling
    try {
      const transformedImage = await sharp(imageBuffer)
        .jpeg({ 
          quality: 80, // Adjust quality
          mozjpeg: true // Better compression
        })
        .withMetadata() // Preserve EXIF data
        .toBuffer();

      // 4. Set response headers
      res.setHeader('Content-Type', 'image/jpeg');
      res.setHeader('Content-Disposition', `attachment; filename="${path.parse(objectKey).name}.jpg"`);
      res.setHeader('Cache-Control', 'public, max-age=31536000'); // 1 year cache

      // 5. Send response
      return res.send(transformedImage);
    } catch (processingError) {
      console.error('Image processing error:', processingError);
      return res.status(500).json({ error: 'Failed to process image' });
    }

  } catch (error) {
    console.error('Unexpected error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

export async function convertImageAndDownloadOld(req:Request,res:Response){
  const bucketName = 'ciity-sms';
  const objectKey = decodeURIComponent(req.params.fileName); 
     const isMedia = await Media.findOne({ where: { key: objectKey } });

     if (!isMedia) {
    return res.status(404).send('File not found in the database.');
  } 

  if(isMedia.upload_type !== 'server'){
    //get from public public/uscitylink
  }else{

  }

  try {
    // Retrieve the image from S3
    const getObjectParams = { Bucket: bucketName, Key: objectKey };
    const command = new GetObjectCommand(getObjectParams);
    const { Body } = await s3Client.send(command);

    if (!Body || !(Body instanceof Readable)) {
      res.status(404).send('File not found in S3 or Body is not a readable stream.');
      return;
    }

    // Convert stream to buffer
    const imageBuffer = await streamToBuffer(Body);

    // Convert the image to JPEG using Sharp
    const transformedImage = await sharp(imageBuffer).jpeg().toBuffer();

    // Set response headers
    res.setHeader('Content-Type', 'image/jpeg');
    res.setHeader('Content-Disposition', 'attachment; filename=converted-image.jpg');

    // Send the converted image as the response
    res.send(transformedImage);
  } catch (error) {
    console.error('Error processing the image:', error);
    res.status(500).send('Error processing the image.');
  }
}

export async function convertImageToPDFAndDownload(req: Request, res: Response) {
  const fileName = decodeURIComponent(req.params.fileName)
  const bucketName = 'ciity-sms';
  const objectKey = fileName; 
  try {
    // Retrieve the image from S3
    const getObjectParams = { Bucket: bucketName, Key: objectKey };
    const command = new GetObjectCommand(getObjectParams);
    const { Body } = await s3Client.send(command);

    if (!Body || !(Body instanceof Readable)) {
      res.status(404).send('File not found in S3 or Body is not a readable stream.');
      return;
    }

    // Convert stream to buffer
    const imageBuffer = await streamToBuffer(Body);

    // Convert the image buffer to PDF
    const pdfBuffer = await new Promise<Buffer>((resolve, reject) => {
      const buffers: Buffer[] = [];
      imageToPDF([imageBuffer], 'A4')
        .on('data', (chunk:any) => buffers.push(chunk))
        .on('end', () => resolve(Buffer.concat(buffers)))
        .on('error', reject);
    });

    // Set response headers
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'attachment; filename=converted-image.pdf');

    // Send the PDF as the response
    res.send(pdfBuffer);
  } catch (error) {
    console.error('Error processing the image:', error);
    res.status(500).send('Error processing the image.');
  }
}

export const uploadAwsMiddleware = upload.single("file");


function generateThumbnail(videoUrl:string, thumbnailPath:string, nameT:string) {
  return new Promise((resolve, reject) => {
    ffmpeg(videoUrl)
      .screenshots({
        timestamps: [1], 
        filename: nameT,
        folder: path.dirname(thumbnailPath), 
        size: '320x240', 
      })
      .on('end', () => {
        console.log('Thumbnail generated successfully.');
        resolve(thumbnailPath); 
      })
      .on('error', (err) => {
        console.error('Error generating thumbnail:', err);
        reject(new Error('Error generating thumbnail.'));
      });
  });
}

function uploadToS3(filePath:string, bucketName:string, s3Key:string) {
  return new Promise((resolve, reject) => {
    const fileContent = fs.readFileSync(filePath);
    const params = {
      Bucket: bucketName,
      Key: s3Key,
      Body: fileContent,
      ContentType: 'image/png', // Assuming PNG thumbnail
    };

    s3.upload(params, (uploadError:any, uploadResult:any) => {
      if (uploadError) {
        console.error('Error uploading thumbnail to S3:', uploadError);
        reject(new Error('Error uploading thumbnail to S3.'));
      } else {
        console.log('Thumbnail uploaded to S3:', uploadResult.Location);
        resolve(uploadResult); // Resolve with the S3 upload result
      }
    });
  });

  
}

const streamToBuffer = async (stream: Readable): Promise<Buffer> => {
  return new Promise<Buffer>((resolve, reject) => {
    const chunks: Buffer[] = [];
    stream.on('data', (chunk) => chunks.push(chunk));
    stream.on('end', () => resolve(Buffer.concat(chunks)));
    stream.on('error', reject);
  });
};
