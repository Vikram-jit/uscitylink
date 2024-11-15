import { Request, Response } from "express";
import { Message } from "../models/Message";
import { UserProfile } from "../models/UserProfile";


import multer from 'multer';
import multerS3 from 'multer-s3';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';  // AWS SDK v3 imports
import dotenv from 'dotenv'
dotenv.config();

const s3Client = new S3Client({
  region: 'us-west-1',  // Your AWS region
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || '',
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || '',
  },
});

// Multer setup for file upload to S3 using AWS SDK v3
const upload = multer({
  storage: multerS3({
    s3: s3Client,
    bucket: 'ciity-sms',  // Your S3 bucket name
   
    key: function (req: Request, file, cb) {
      const fileName = Date.now().toString() + '-' + file.originalname;
      cb(null, `uscitylink/${fileName}`);  // Store file in "messages/" folder in S3
    }
  }),
  limits: {
    fileSize: 50 * 1024 * 1024, // 50MB file size limit (adjust as needed)
  }
});


export const createMessage = async (req: Request, res: Response):Promise<any> => {
    try {
      const { channelId, userProfileId, groupId, body, messageDirection, deliveryStatus, senderId } = req.body;
  
      const newMessage = await Message.create({
        channelId,
        userProfileId,
        groupId,
        body,
        messageDirection,
        deliveryStatus,
        messageTimestampUtc: new Date(),
        senderId,
        isRead: false,
        status: 'sent', 
      });
  
      return res.status(201).json({
        status: true,
        message: `Message sent successfully`,
      });

    } catch (err: any) {
      return res
        .status(400)
        .json({ status: false, message: err.message || "Internal Server Error" });
    }
  };

  export const getMessages = async (req: Request, res: Response):Promise<any> => {
    try {
        
      const { channelId } = req.params;
    
      const messages = await Message.findAll({
        where:{
            channelId:channelId,
            userProfileId:req.user?.id
        },
        order: [['messageTimestampUtc', 'DESC']]
      })
  
      return res.status(200).json({
        status: true,
        message: `Fetch message successfully`,
        data:messages
      });

    } catch (err: any) {
      return res
        .status(400)
        .json({ status: false, message: err.message || "Internal Server Error" });
    }
  };

  export const getMessagesByUserId = async (req: Request, res: Response):Promise<any> => {
    try {
        
      const { id } = req.params;
    
      const userProfile = await UserProfile.findByPk(id)

      const messages = await Message.findAll({
        where:{
            channelId:req.activeChannel,
            userProfileId:id
        },
        include: {
          model: UserProfile,
          as: 'sender', 
          attributes: ['id', 'username','isOnline'], 
        },
        order: [['messageTimestampUtc', 'ASC']]
      })
  
      return res.status(200).json({
        status: true,
        message: `Fetch message successfully`,
        data:{userProfile,messages}
      });

    } catch (err: any) {
      return res
        .status(400)
        .json({ status: false, message: err.message || "Internal Server Error" });
    }
  };

  export const fileUpload = async (req: Request, res: Response):Promise<any> => {
    try {
     
      return res.status(201).json({
        status: true,
        message: `Message sent successfully`,
        data:req.file
      });

    } catch (err: any) {
      return res
        .status(400)
        .json({ status: false, message: err.message || "Internal Server Error" });
    }
  };


  export const uploadMiddleware = upload.single('file');  // 'file' is the key used in form-data

  