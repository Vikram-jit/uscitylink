import { Request, Response } from "express";
import { Message } from "../models/Message";
import { UserProfile } from "../models/UserProfile";

import multer from "multer";
import multerS3 from "multer-s3";
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3"; // AWS SDK v3 imports
import dotenv from "dotenv";
import { Media } from "../models/Media";
import Channel from "../models/Channel";
import { Op } from "sequelize";
import Group from "../models/Group";
dotenv.config();

const s3Client = new S3Client({
  region: "us-west-1", // Your AWS region
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || "",
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || "",
  },
});

// Multer setup for file upload to S3 using AWS SDK v3
const upload = multer({
  storage: multerS3({
    s3: s3Client,
    bucket: "ciity-sms", // Your S3 bucket name

    key: function (req: Request, file, cb) {
      const fileName = Date.now().toString() + "-" + file.originalname;
      cb(null, `uscitylink/${fileName}`); // Store file in "messages/" folder in S3
    },
  }),
  limits: {
    fileSize: 50 * 1024 * 1024, // 50MB file size limit (adjust as needed)
  },
});

export const createMessage = async (
  req: Request,
  res: Response
): Promise<any> => {
  try {
    const {
      channelId,
      userProfileId,
      groupId,
      body,
      messageDirection,
      deliveryStatus,
      senderId,
    } = req.body;

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
      status: "sent",
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

export const getMessages = async (
  req: Request,
  res: Response
): Promise<any> => {
  try {
    const { channelId } = req.params;

    const messages = await Message.findAll({
      where: {
        channelId: channelId,
        userProfileId: req.user?.id,
        type: {
          [Op.ne]: "group",
        },
     
      },
      include: {
        model: UserProfile,
        as: "sender",
        attributes: ["id", "username", "isOnline"],
      },
      order: [["messageTimestampUtc", "DESC"]],
    });

    return res.status(200).json({
      status: true,
      message: `Fetch message successfully`,
      data: messages,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
};

export const getGroupMessages = async (
  req: Request,
  res: Response
): Promise<any> => {
  try {
    const senderId = req.user?.id;

    const { channelId, groupId } = req.params;

    const page = parseInt(req.query.page as string) || 1; 
    const pageSize = parseInt(req.query.pageSize as string) || 10; 

    const offset = (page - 1) * pageSize;


    const messages = await Message.findAndCountAll({
      where: {
        channelId: channelId,
        groupId: groupId,
        type: "group",
      },
      include: {
        model: UserProfile,
        as: "sender",
        attributes: ["id", "username", "isOnline"],
      },
      order: [["messageTimestampUtc", "DESC"]],
      limit: pageSize,  
      offset: offset,   
    });

    const totalMessages = messages.count;
    const totalPages = Math.ceil(totalMessages / pageSize);

    return res.status(200).json({
      status: true,
      message: `Fetch message successfully`,
      data: { senderId, messages:messages.rows,pagination: {
        currentPage: page,
        pageSize: pageSize,
        total:totalMessages,
        totalPages,
      } },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
};

export const getMessagesByUserId = async (
  req: Request,
  res: Response
): Promise<any> => {
  try {
    const { id } = req.params;
    const page = parseInt(req.query.page as string) || 1; 
    const pageSize = parseInt(req.query.pageSize as string) || 10; 

    const offset = (page - 1) * pageSize;

    const userProfile = await UserProfile.findByPk(id);

    const messages = await Message.findAndCountAll({
      where: {
        channelId: req.activeChannel,
        userProfileId: id,
        groupId:null
      },
      include: {
        model: UserProfile,
        as: "sender",
        attributes: ["id", "username", "isOnline"],
      },
      order: [["messageTimestampUtc", "DESC"]],
      limit: pageSize,  
      offset: offset,   
    });

    const totalMessages = messages.count;
    const totalPages = Math.ceil(totalMessages / pageSize);

    return res.status(200).json({
      status: true,
      message: `Fetch message successfully`,
      data: { userProfile,
        messages: messages.rows,
        pagination: {
          currentPage: page,
          pageSize: pageSize,
          totalMessages,
          totalPages,
        },},
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
};

export const fileUpload = async (req: Request, res: Response): Promise<any> => {
  try {
    const channelId = req.body.channelId;
    const groupId = req.query.groupId || null;
    const userId = req.user?.id;
    if (req.file) {
      const file = req.file as any;

      await Media.create({
        user_profile_id: userId,
        channelId: channelId,
        file_name: req.file?.originalname,
        file_size: req.file.size,
        mime_type: req.file.mimetype,
        key: file?.key,
        file_type: req.body.type,
        groupId:groupId
      });
    }

    return res.status(201).json({
      status: true,
      message: `Message sent successfully`,
      data: req.file,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
};
export const fileUploadWeb = async (
  req: Request,
  res: Response
): Promise<any> => {
  try {
    const channelId = req.activeChannel;
    const userId = req.body.userId?.length > 0 ? req.body.userId : req.user?.id;
    const groupId = req.body.groupId as string;

    if (req.file) {
      const file = req.file as any;

      await Media.create({
        user_profile_id: userId,
        channelId: channelId,
        groupId: groupId ?? null,
        file_name: req.file?.originalname,
        file_size: req.file.size,
        mime_type: req.file.mimetype,
        key: file?.key,
        file_type: req.body.type,
      });
    }

    return res.status(201).json({
      status: true,
      message: `Message sent successfully`,
      data: req.file,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
};

export const getMedia = async (req: Request, res: Response): Promise<any> => {
  try {
    const page = parseInt(req.query.page + "") || 1; 
    const limit = parseInt(req.query.limit + "") || 10; 
    const offset = (page - 1) * limit; 


    const channelId =
      req.params.channelId == "null" ? req.activeChannel : req.params.channelId;
    const userId = req.query.userId ?? req.user?.id;

    const source = req.query.source as string;
    const channel =
      source == "channel"
        ? await Channel.findByPk(req.params.channelId)
        : await Group.findByPk(req.params.channelId);
       
    const media = await Media.findAndCountAll({
      where: {
        ...(source == "channel"
          ? { channelId: channelId,groupId:null,
            user_profile_id:userId
           }
          : { groupId: channel?.id }),

        file_type: req.query.type || "media",
      },
      limit: limit,
      offset: offset,
      order: [["createdAt", "DESC"]],
    });

    return res.status(200).json({
      status: true,
      message: `Get media successfully`,
      data: {
        channel,
        media: media.rows,
        page,
        limit,
        totalItems: media.count,
        totalPages: Math.ceil(media.count / limit),
      },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
};

export const uploadMiddleware = upload.single("file"); // 'file' is the key used in form-data
