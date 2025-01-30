import  { Request, Response } from "express";
import multer from "multer";
import AWS from "aws-sdk";
import fs from "fs";
import dotenv from "dotenv";
import ffmpeg from "fluent-ffmpeg";
import path from "path";
import { Training } from "../models/Training";
dotenv.config();


AWS.config.update({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID || "",
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || "",
  region: "us-west-1",
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

export const createTraining = async (
  req: Request,
  res: Response
): Promise<any> => {
  try {
    if (!req.file) {
      throw new Error("No file uploaded");
    }
   let training:any
    let thumbnail_data:any ;
    const file = req.file;
    const fileName = `uscitylink/trainings/${Date.now().toString()}-${
      file.originalname
    }`;
    const fileSize = file.size;
    const chunkSize = 5 * 1024 * 1024; // 5MB chunks
    const totalChunks = Math.ceil(fileSize / chunkSize);



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

    const uploadResult = await uploadToS3(generatedThumbnailPath, 'ciity-sms', `uscitylink/trainings/${Date.now()}_thumbnail.png`);
    
    
     thumbnail_data = uploadResult;

    
    fs.unlinkSync(generatedThumbnailPath);

    training =  await Training.create({
        title:req.body.title,
        description:req.body.title,
        file_name: req.file?.originalname,
        file_size: req.file.size,
        mime_type: req.file.mimetype,
        key: result?.key,
        file_type: req.body.type,
        thumbnail: thumbnail_data?.Key,
      });
    
      }
      return res.status(201).json({
        status: true,
        message: "File uploaded successfully",
        data: {...result, thumbnail: thumbnail_data?.Key,...training.dataValues},
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

    const uploadResult = await uploadToS3(generatedThumbnailPath, 'ciity-sms', `uscitylink/trainings/${Date.now()}_thumbnail.png`);
    
    
     thumbnail_data = uploadResult;

    
    fs.unlinkSync(generatedThumbnailPath);

    
   training =  await Training.create({
        title:req.body.title,
        description:req.body.title,
        file_name: req.file?.originalname,
        file_size: req.file.size,
        mime_type: req.file.mimetype,
        key: result?.key,
        file_type: req.body.type,
        thumbnail: thumbnail_data?.Key,
      });
    
    }
    return res.status(201).json({
      status: true,
      message: "File uploaded successfully",
      data: {...result, thumbnail: thumbnail_data?.Key,...training.dataValues},
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
};

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

export async function getTrainingById(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const user = await Training.findByPk(req.params.id);
    return res.status(200).json({
      status: true,
      message: `Get Training Successfully.`,
      data: user,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}