import express, { Request, Response } from "express";
import multer, { FileFilterCallback } from "multer";
import AWS from "aws-sdk";
import fs from "fs";
import path from "path";
import dotenv from "dotenv";
import { Media } from "../models/Media";

dotenv.config();


// Set up AWS S3 configuration
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
      Bucket: 'ciity-sms', 
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
      Bucket: 'ciity-sms',
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
        throw new Error('No file uploaded');
      }
  
      const file = req.file;
      const fileName = `uscitylink/video/${Date.now().toString()}-${file.originalname}`;
      const fileSize = file.size;
      const chunkSize = 5 * 1024 * 1024; // 5MB chunks
      const totalChunks = Math.ceil(fileSize / chunkSize);
  
      const channelId = req.body.channelId || req.activeChannel;
      const groupId = req.query.groupId || null;
      const userId = req.query.userId || req.user?.id;

      if (fileSize < 5 * 1024 * 1024) {
    
        const params = {
          Bucket: 'ciity-sms',
          Key: fileName,
          Body: file.buffer,
        };
  
        const managedUpload = s3.upload(params);
      
        
        const result:any = await managedUpload.promise();

        if(result){
          await Media.create({
            user_profile_id: userId,
            channelId: channelId,
            file_name: req.file?.originalname,
            file_size: req.file.size,
            mime_type: req.file.mimetype,
            key: result?.key,
            file_type: req.body.type,
            groupId: groupId,
            upload_source: req.query.source || "message"
          });
        }
        return res.status(201).json({
          status: true,
          message: 'File uploaded successfully',
          data: result,
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
          Bucket: 'ciity-sms', 
          Key: fileName,
          PartNumber: chunkIndex + 1,
          UploadId: uploadId,
          Body: chunkBuffer,
        };
  
       
        uploadPromises.push(
          uploadPart(params, chunkIndex + 1, chunkBuffer.length, (uploadedBytesInPart) => {
            uploadedBytes += uploadedBytesInPart;
            updateProgress(uploadedBytes);
          })
        );
      }
   
      const uploadedParts = await Promise.all(uploadPromises);
  
    
      const result:any = await completeMultipartUpload(uploadId, uploadedParts, fileName);
      if(result){
      
        await Media.create({
            user_profile_id: userId,
            channelId: channelId,
            file_name: req.file?.originalname,
            file_size: req.file.size,
            mime_type: req.file.mimetype,
            key: result?.key,
            file_type: req.body.type,
            groupId: groupId,
            upload_source: req.query.source || "message"
          });
      }
      return res.status(201).json({
        status: true,
        message: 'File uploaded successfully',
        data: result,
      });
    } catch (err: any) {
      return res.status(400).json({ status: false, message: err.message || 'Internal Server Error' });
    }
  };

  export const uploadAwsMiddleware = upload.single("file"); 
  