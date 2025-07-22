import { Request, Response } from "express";
import { Message } from "../models/Message";
import { UserProfile } from "../models/UserProfile";

import multer from "multer";
import multerS3 from "multer-s3";
import { S3Client } from "@aws-sdk/client-s3"; // AWS SDK v3 imports
import dotenv from "dotenv";
import { Media } from "../models/Media";
import Channel from "../models/Channel";
import { Op, Sequelize } from "sequelize";
import Group from "../models/Group";
import GroupChannel from "../models/GroupChannel";
import moment from "moment";
import { getSocketInstance } from "../sockets/socket";
import SocketEvents from "../sockets/socketEvents";
import UserChannel from "../models/UserChannel";
import { sendNotificationToDevice } from "../utils/fcmService";
import GroupUser from "../models/GroupUser";
import User from "../models/User";
import Queue, { Job } from "bull";
import fs from "fs";
import AWS from "aws-sdk";
import path from "path";
import {
  driverMessageQueueProcess,
  driverMessageQueueProcessResend,
  driverMessageQueueProcessWithoutSocket,
  messageToChannelToUser,
  messageToDriver,
  messageToDriverByTruckGroup,
  messageToGroup,
  notifiyFileUploadDriverToStaff,
  notifiyFileUploadDriverToStaffGroup,
  notifiyFileUploadStaffToDriver,
  notifiyFileUploadStaffToStaff,
  notifiyFileUploadTruckGroupMembers,
  sendMessageToStaffMember,
} from "../sockets/messageHandler";
import GroupMessage from "../models/GroupMessage";

dotenv.config();

const storage = multer.diskStorage({
  destination: (
    req: Request,
    file: Express.Multer.File,
    cb: (error: Error | null, destination: string) => void
  ) => {
    cb(null, path.join(__dirname, "../", "../public/uscitylink"));
  },
  filename: (
    req: Request,
    file: Express.Multer.File,
    cb: (error: Error | null, filename: string) => void
  ) => {
    cb(null, `${Date.now()}-${file.originalname?.replace(" ", "_")}`);
  },
});

export const uploadLocal = multer({ storage });

export const fileUploadQueue = new Queue("fileUploadQueue", {
  redis: {
    host:
      process.env.DB_SERVER == "local" ? "127.0.0.1" : process.env.REDIS_HOST,
    port: 6379,
    maxRetriesPerRequest: null, // prevents crash on Redis failure
    enableReadyCheck: false, // speeds up startup when Redis is slow
    retryStrategy: (times) => {
      // Exponential backoff, cap retry delay to 2s
      return Math.min(times * 50, 2000);
    },
  },
});

const s3Client = new S3Client({
  region: "us-west-1", // Your AWS region
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || "",
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || "",
  },
});

const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID!,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY!,
});

export const processFileUpload = async (
  job: Job<{
    filePath: string;
    fileName: string;
    mediaId: string;
    source: string;
    channelId: string;
    groupId?: string;
    userId: string;
    location: string;
    private_chat_id?: string;
    tempId?: string;
  }>
): Promise<void> => {
  const {
    filePath,
    fileName,
    mediaId,
    source,
    channelId,
    groupId,
    userId,
    location,
    private_chat_id,
    tempId,
  } = job.data;

  const fileStream = fs.createReadStream(filePath);

  const uploadParams = {
    Bucket: process.env.BUCKET_NAME!,
    Key: `uscitylink/${fileName}`,
    Body: fileStream,
  };
  const maxRetries = 3;
  let attempt = 0;
  let uploadSuccess = false;

  const existingMessage = await Message.findOne({
    where: { url: `uscitylink/${fileName}` },
  });

  while (attempt < maxRetries) {
    try {
      await s3.upload(uploadParams).promise();

      await Media.update({ upload_type: "server" }, { where: { id: mediaId } });

      if (existingMessage) {
        await Message.update(
          { url_upload_type: "server" },
          { where: { id: existingMessage.id } }
        );
      }

      fs.unlinkSync(filePath);
      console.log(`File ${fileName} uploaded successfully.`);
      const socket = global.userSockets[userId];
      uploadSuccess = true;
      if (source == "staff") {
        if (location == "group") {
          await notifiyFileUploadDriverToStaffGroup(
            getSocketInstance(),
            socket,
            groupId!,
            channelId,
            existingMessage!.id,
            "server",
            userId
          );
        } else if (location == "truck") {
          const existingGroupMessage = await GroupMessage.findOne({
            where: { url: `uscitylink/${fileName}` },
          });
          if (existingGroupMessage) {
            await GroupMessage.update(
              { url_upload_type: "server" },
              { where: { id: existingGroupMessage.id } }
            );
          }

          await notifiyFileUploadTruckGroupMembers(
            getSocketInstance(),
            socket,
            channelId,
            groupId!,
            existingMessage!.id,
            "server",
            userId,
            existingGroupMessage!.id,
            `uscitylink/${fileName}`
          );
        } else {
          await notifiyFileUploadStaffToDriver(
            getSocketInstance(),
            socket,
            channelId,
            existingMessage!.id,
            "server",
            userId
          );
        }
      } else if (source == "staff_group") {
        await notifiyFileUploadStaffToStaff(
          getSocketInstance(),
          socket,
          channelId,
          existingMessage!.id,
          "server",
          userId,
          private_chat_id
        );
      } else {
        if (location == "group") {
          await notifiyFileUploadDriverToStaffGroup(
            getSocketInstance(),
            socket,
            groupId!,
            channelId,
            existingMessage!.id,
            "server",
            userId
          );
        } else {
          await notifiyFileUploadDriverToStaff(
            getSocketInstance(),
            socket,
            channelId,
            existingMessage!.id,
            "server",
            userId,
            tempId
          );
        }
      }
      break; // Exit loop if upload is successful
    } catch (error) {
      attempt++;
      console.error(
        `Attempt ${attempt} - Error uploading file ${fileName}:`,
        error
      );

      if (attempt >= maxRetries) {
        console.error(
          `Failed to upload file ${fileName} after ${maxRetries} attempts.`
        );

        if (existingMessage) {
          await Message.update(
            { url_upload_type: "failed" },
            { where: { id: existingMessage.id } }
          );
        }

        throw error;
      }

      const delay = Math.pow(2, attempt) * 100; // Exponential backoff
      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }
};

fileUploadQueue.process(processFileUpload);

// Multer setup for file upload to S3 using AWS SDK v3
const upload = multer({
  storage: multerS3({
    s3: s3Client,
    bucket: "ciity-sms",

    key: function (req: Request, file, cb) {
      const fileName = Date.now().toString() + "-" + file.originalname;
      cb(null, `uscitylink/${fileName}`);
    },
  }),
  limits: {
    fileSize: 50 * 1024 * 1024,
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
    const driverPin = req.query.driverPin;
    const messages = await Message.findAll({
      where: {
        ...(driverPin == "1" && { driverPin: "1" }),
        channelId: channelId,
        userProfileId: req.user?.id,
        type: {
          [Op.ne]: "group",
        },
      },
      include: [
        {
          model: Message,
          as: "r_message",
          include: [
            {
              model: UserProfile,
              as: "sender",
              attributes: ["id", "username", "isOnline"],
            },
          ],
        },
        {
          model: UserProfile,
          as: "sender",
          attributes: ["id", "username", "isOnline"],
        },
      ],
      order: [["messageTimestampUtc", "DESC"]],
    });

    const modifiedMessage = await Promise.all(
      messages.map(async (e) => {
        let group = null;
        if (e.type == "truck_group") {
          group = await Group.findOne({
            where: {
              id: e?.groupId!,
            },
            include: [
              {
                model: GroupChannel,
                as: "group_channel",
              },
            ],
          });
        }
        return { ...e.dataValues, group };
      })
    );

    return res.status(200).json({
      status: true,
      message: `Fetch message successfully`,
      data: modifiedMessage,
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
      data: {
        senderId,
        messages: messages.rows,
        pagination: {
          currentPage: page,
          pageSize: pageSize,
          total: totalMessages,
          totalPages,
        },
      },
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

    const userProfile = await UserProfile.findByPk(id, {
      include: [{ model: User, as: "user" }],
    });

    const messages = await Message.findAndCountAll({
      where: {
        channelId: req.activeChannel,
        userProfileId: id,
        type: {
          [Op.ne]: "group",
        },
        ...(req.query.pinMessage == "1" && { staffPin: "1" }),
      },
      include: [
        {
          model: Message,
          as: "r_message",
          include: [
            {
              model: UserProfile,
              as: "sender",
              attributes: ["id", "username", "isOnline"],
              include: [{ model: User, as: "user" }],
            },
          ],
        },
        {
          model: UserProfile,
          as: "sender",
          attributes: ["id", "username", "isOnline"],
          include: [{ model: User, as: "user" }],
        },
      ],
      order: [["messageTimestampUtc", "DESC"]],
      limit: pageSize,
      offset: offset,
    });

    const groupUser = await GroupUser.findAll({
      where: {
        userProfileId: id,
      },
      include: [
        {
          model: Group,
          where: {
            type: "truck",
          },
        },
      ],
    });

    const truckNumbers = await Promise.all(
      groupUser.map((e) => e.dataValues.Group.name)
    );

    const totalMessages = messages.count;
    const totalPages = Math.ceil(totalMessages / pageSize);

    const modifiedMessage = await Promise.all(
      messages.rows.map(async (e) => {
        let group = null;
        if (e.type == "truck_group") {
          group = await Group.findOne({
            where: {
              id: e?.groupId!,
            },
            include: [
              {
                model: GroupChannel,
                as: "group_channel",
              },
            ],
          });
        }
        return { ...e.dataValues, group };
      })
    );

    return res.status(200).json({
      status: true,
      message: `Fetch message successfully`,
      data: {
        userProfile,
        messages: modifiedMessage,
        truckNumbers: truckNumbers ? truckNumbers?.join(",") : "",
        pagination: {
          currentPage: page,
          pageSize: pageSize,
          totalMessages,
          totalPages,
        },
      },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
};

export const fileUpload = async (req: Request, res: Response): Promise<any> => {
  try {
    const channelId = req.body.channelId || req.activeChannel;
    const groupId = req.query.groupId || null;

    const userId = req.query.userId || req.user?.id;
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
        groupId: groupId,
        upload_source: req.query.source || "message",
        upload_type: "server",
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

export const fileUploadMultiple = async (
  req: Request,
  res: Response
): Promise<any> => {
  try {
    const channelId = req.body.channelId || req.activeChannel;
    const groupId = req.query.groupId || null;

    const userId = req.query.userId || req.user?.id;

    const uploadedFiles: any = req.files;

    await Promise.all(
      uploadedFiles?.map(async (item: any, index: any) => {
        const file = item as any;
        await Media.create({
          user_profile_id: userId,
          channelId: channelId,
          file_name: file?.originalname,
          file_size: file.size,
          mime_type: file.mimetype,
          key: file?.key,
          file_type: req.body.type,
          groupId: groupId,
          upload_source: req.query.source || "message",
        });
      })
    );

    return res.status(201).json({
      status: true,
      message: `Upload sent successfully`,
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
    const private_chat_id = req.query.private_chat_id as string;
    const source = req.body.source || "message";
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
        upload_source: source,
        upload_type: "server",
        private_chat_id: private_chat_id || null,
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
    const limit = parseInt(req.query.limit + "") || 20;
    const offset = (page - 1) * limit;
    const source = req.query.source as string;
    const private_chat_id = req.query.private_chat_id as string;
    if (source == "staff") {
      const userProfile = await UserProfile.findByPk(req.params.channelId);
      const media = await Media.findAndCountAll({
        where: {
          [Op.or]: [
            ...(source === "staff"
              ? [
                  {
                    channelId: req.activeChannel,
                    upload_source: "message",
                    user_profile_id: req.params.channelId,
                  },
                ]
              : []),

            ...(source === "staff"
              ? [
                  {
                    channelId: req.activeChannel,
                    upload_source: "truck",
                  },
                ]
              : []),
            ...(source === "staff"
              ? [
                  {
                    channelId: req.activeChannel,
                    upload_source: "chat",
                    user_profile_id: req.params.channelId,
                  },
                ]
              : []),
          ],

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
          channel: {
            id: userProfile?.id,
            name: userProfile?.username,
            description: "",
            createdAt: userProfile?.createdAt,
            updatedAt: userProfile?.updatedAt,
          },
          media: media.rows,
          page,
          limit,
          totalItems: media.count,
          totalPages: Math.ceil(media.count / limit),
        },
      });
    }

    // if(private_chat_id != "undefined"){

    // const channel =
    //    await Channel.findByPk(req.activeChannel)
    // const media = await Media.findAndCountAll({
    //   where: {
    //     private_chat_id:private_chat_id,
    //     file_type: req.query.type || "media",
    //   },
    //   limit: limit,
    //   offset: offset,
    //   order: [["createdAt", "DESC"]],
    // });

    // return res.status(200).json({
    //   status: true,
    //   message: `Get media successfully`,
    //   data: {
    //     channel,
    //     media: media.rows,
    //     page,
    //     limit,
    //     totalItems: media.count,
    //     totalPages: Math.ceil(media.count / limit),
    //   },
    // });
    // }

    const channelId =
      req.params.channelId == "null" ? req.activeChannel : req.params.channelId;
    const userId = req.query.userId ?? req.user?.id;

    const channel =
      source == "channel"
        ? await Channel.findByPk(channelId)
        : await Group.findByPk(req.params.channelId);
    let channelGroupId;
    let groupUserIds;
    if (source == "group") {
      channelGroupId = await GroupChannel.findOne({
        where: {
          groupId: channelId,
        },
      });
      const groupUser = await GroupUser.findAll({
        where: {
          groupId: channelId,
        },
      });
      groupUserIds = groupUser.map((groupUser) => groupUser.userProfileId);
    }
    const media = await Media.findAndCountAll({
      where: {
        [Op.or]: [
          ...(source === "channel"
            ? [
                {
                  channelId: channelId,
                  upload_source: "message",
                  user_profile_id: userId,
                },
              ]
            : []),
          ...(source === "channel"
            ? [
                {
                  channelId: channelId,
                  upload_source: "chat",
                  user_profile_id: userId,
                },
              ]
            : []),
          ...(source === "channel"
            ? [
                {
                  channelId: channelId,
                  upload_source: "truck",
                },
              ]
            : []),

          ...(source !== "channel"
            ? [
                {
                  groupId: channelId,
                  upload_source: "group",
                },
              ]
            : []),
          ...(source !== "channel"
            ? [
                {
                  groupId: channelId,
                  // upload_source: "truck",
                },
              ]
            : []),
          ...(source !== "channel"
            ? [
                {
                  channelId: channelGroupId?.channelId,
                  user_profile_id: {
                    [Op.in]: groupUserIds,
                  },
                  // upload_source: "truck",
                },
              ]
            : []),
        ],

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

export const uploadMiddleware = upload.single("file");

export const quickMessageAndReply = async (
  req: Request,
  res: Response
): Promise<any> => {
  try {
    const { userProfileId, body } = req.body;
    const channelId = req.activeChannel;

    const findDriverSocket = global.driverOpenChat.find(
      (driver) => driver?.driverId === userProfileId
    );

    const messageSave = await Message.create({
      channelId: req.activeChannel,
      userProfileId,
      groupId: null,
      body,
      messageDirection: "S",
      deliveryStatus: "sent",
      messageTimestampUtc: moment.utc().format(),
      senderId: req.user?.id,
      isRead: false,
      status: "sent",
    });

    const message = await Message.findOne({
      where: {
        id: messageSave.id,
      },
      include: {
        model: UserProfile,
        as: "sender",
        attributes: ["id", "username", "isOnline"],
      },
    });

    const findStaffActiveChannel = global.staffActiveChannel[req.user?.id];

    //Check Before send driver active room channel
    const isDriverSocket = global.userSockets[userProfileId];

    if (
      findDriverSocket &&
      findDriverSocket?.channelId == findStaffActiveChannel?.channelId
    ) {
      if (isDriverSocket) {
        await messageSave.update(
          {
            deliveryStatus: "seen",
          },
          {
            where: {
              id: messageSave.id,
            },
          }
        );
        getSocketInstance()
          .to(isDriverSocket?.id)
          .emit(SocketEvents.RECEIVE_MESSAGE_BY_CHANNEL, message);
      }
    } else {
      if (isDriverSocket) {
        getSocketInstance()
          .to(isDriverSocket?.id)
          .emit("update_user_channel_list", message);
        getSocketInstance()
          .to(isDriverSocket?.id)
          .emit("new_message_count_update", message?.channelId);
        const isUser = await UserProfile.findOne({
          where: {
            id: userProfileId,
          },
        });
        if (isUser) {
          if (isUser.device_token) {
            const isChannel = await Channel.findByPk(
              findStaffActiveChannel?.channelId
            );
            const messageCount = await UserChannel.sum(
              "recieve_message_count",
              {
                where: {
                  userProfileId: userProfileId,
                },
              }
            );

            const userGroupsCount = await GroupUser.sum("message_count", {
              where: { userProfileId: userProfileId },
            });
            await sendNotificationToDevice(isUser.device_token, {
              title: isChannel?.name || "",
              badge: messageCount + userGroupsCount,
              body: body,
              data: {
                channelId: isChannel?.id,

                type: "NEW MESSAGE",
                title: isChannel?.name,
              },
            });
          }
        }
      } else {
        const isUser = await UserProfile.findOne({
          where: {
            id: userProfileId,
          },
        });
        if (isUser) {
          if (isUser.device_token) {
            const isChannel = await Channel.findByPk(
              findStaffActiveChannel?.channelId
            );
            const messageCount = await UserChannel.sum(
              "recieve_message_count",
              {
                where: {
                  userProfileId: userProfileId,
                },
              }
            );

            const userGroupsCount = await GroupUser.sum("message_count", {
              where: { userProfileId: userProfileId },
            });
            await sendNotificationToDevice(isUser.device_token, {
              badge: messageCount + userGroupsCount,
              title: isChannel?.name || "",
              body: body,
              data: {
                channelId: isChannel?.id,

                type: "NEW MESSAGE",
                title: isChannel?.name,
              },
            });
          }
        }
      }

      await UserChannel.update(
        {
          recieve_message_count: Sequelize.literal("recieve_message_count + 1"),
        },
        {
          where: {
            userProfileId: userProfileId, // The user you want to update
            channelId: findStaffActiveChannel?.channelId, // The channel to target
          },
        }
      );
    }
    const utcTime = moment.utc().toDate();

    await UserChannel.update(
      {
        last_message_id: message?.id,
        last_message_utc: utcTime,
      },
      {
        where: {
          userProfileId: userProfileId,
          channelId: findStaffActiveChannel?.channelId,
        },
      }
    );
    //Return Message To Staff After Store
    Object.entries(global.staffOpenChat).forEach(([staffId, e]) => {
      if (e.channelId === findStaffActiveChannel?.channelId) {
        const isSocket = global.userSockets[staffId]; // Use staffId as the identifier

        if (isSocket) {
          getSocketInstance()
            .to(isSocket.id)
            .emit(SocketEvents.RECEIVE_MESSAGE_BY_CHANNEL, message);
        }
      }
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

export const fileUploadByQueue = async (
  req: Request,
  res: Response
): Promise<any> => {
  try {
    if (!req.files || !Array.isArray(req.files)) {
      return res.status(400).send("No files uploaded.");
    }

    const channelId = req.body.channelId || req.activeChannel;
    const groupId = req.query.groupId || null;
    const body = req.body.body;
    const userId = req.query.userId || req.user?.id;
    const tempId = req.query.tempId as string;
    const private_chat_id = req.query.private_chat_id as string;
    const files = req.files as Express.Multer.File[];
    const fileUpload: any = [];

    const isMediaExistSameTempId = await Media.findOne({
      where: {
        temp_id: tempId,
      },
    });
    if (isMediaExistSameTempId) {
      return res.status(201).json({
        status: true,
        message: `File upload successfully`,
        data: fileUpload,
      });
    }

    if (tempId) {
      const findTempId = await Message.findOne({
        where: {
          temp_id: tempId,
        },
      });
      if (findTempId) {
        const socket = global.userSockets[req.user?.id];
        await driverMessageQueueProcessResend(
          getSocketInstance(),
          socket,
          tempId,
          body,
          findTempId.url || "",
          channelId,
          null,
          null,
          "not-upload"
        );
      }
    }
    for (const file of files) {
      const filePath = file.path;
      const fileName = file.originalname?.replace(" ", "_");
      const fileNameS3 = file?.filename;
      const source = req.query.location;
      const location = req.query.source;
      const uploadBy = req.query.uploadBy as string;

      // for staff
      if (uploadBy == "staff") {
        const socket = global.userSockets[req.user?.id];
        if (location == "group") {
          await messageToGroup(
            getSocketInstance(),
            socket,
            groupId!.toString(),
            channelId,
            body,
            "S",
            `uscitylink/${fileNameS3}`,
            null,
            "not-upload"
          );
        } else if (location == "truck") {
          await messageToDriverByTruckGroup(
            getSocketInstance(),
            socket,
            "",
            groupId!.toString(),
            body,
            "S",
            `uscitylink/${fileNameS3}`,
            null,
            "not-upload"
          );
        } else {
          await messageToDriver(
            getSocketInstance(),
            socket,
            userId,
            body,
            "S",
            `uscitylink/${fileNameS3}`,
            null,
            null,
            "not-upload"
          );
        }
      } else if (uploadBy == "staff_group") {
        const socket = global.userSockets[req.user?.id];
        await sendMessageToStaffMember(
          getSocketInstance(),
          socket,
          body,
          "S",
          "",
          private_chat_id,
          `uscitylink/${fileNameS3}`,
          "",
          "",
          "not-upload"
        );
      } else {
        const socket = global.userSockets[req.user?.id];
        if (location == "group") {
          await messageToGroup(
            getSocketInstance(),
            socket,
            groupId!.toString(),
            channelId,
            body,
            "S",
            `uscitylink/${fileNameS3}`,
            null,
            "not-upload"
          );
        } else {
          if (tempId) {
            if (socket) {
              await driverMessageQueueProcess(
                getSocketInstance(),
                socket,
                tempId,
                body,
                `uscitylink/${fileNameS3}`,
                channelId,
                null,
                null,
                "not-upload"
              );
            } else {
              await driverMessageQueueProcessWithoutSocket(
                getSocketInstance(),
                tempId,
                body,
                `uscitylink/${fileNameS3}`,
                channelId,
                null,
                null,
                "not-upload",
                userId,
                null
              );
            }
          } else {
            await messageToChannelToUser(
              getSocketInstance(),
              socket,
              body,
              `uscitylink/${fileNameS3}`,
              channelId,
              null,
              null,
              "not-upload"
            );
          }
        }
      }
      // Create media record in the database
      const media = await Media.create({
        temp_id: tempId,
        user_profile_id: userId,
        channelId: channelId,
        file_name: fileName,
        file_size: file.size,
        mime_type: file.mimetype,
        key: `uscitylink/${fileNameS3}`,
        file_type:
          req.body.type || file.mimetype.startsWith("image/") ? "media" : "doc",
        groupId: groupId,
        upload_source: source || "message",
        upload_type: "local",
        private_chat_id: private_chat_id,
      });

      // Add job to the queue for the current file
      const job = await fileUploadQueue.add({
        filePath,
        fileName: fileNameS3,
        mediaId: media.id,
        channelId,
        groupId,
        userId: uploadBy == "staff_group" ? req.user?.id : userId,
        source: uploadBy,
        location: req.query.source,
        private_chat_id: private_chat_id,
        tempId: tempId,
      });

      if (!job || !job.id) {
        media.update({
          upload_type: "fail_to_add_queue",
        });
      }

      fileUpload.push({ ...file, key: `uscitylink/${fileNameS3}` });
    }

    return res.status(201).json({
      status: true,
      message: `File upload successfully`,
      data: fileUpload,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
};

export const uploadMultipleMiddleware = upload.array("file");

export const uploadFromLocal = async (
  job: Job<{
    filePath: string;
    fileName: string;
    mediaId: string;
    source: string;
    channelId: string;
    groupId?: string;
    userId: string;
    location: string;
    private_chat_id?: string;
  }>
): Promise<void> => {
  const {
    filePath,
    fileName,
    mediaId,
    source,
    channelId,
    groupId,
    userId,
    location,
    private_chat_id,
  } = job.data;

  const fileStream = fs.createReadStream(filePath);

  const uploadParams = {
    Bucket: process.env.BUCKET_NAME!,
    Key: `uscitylink/${fileName}`,
    Body: fileStream,
  };
  const maxRetries = 3;
  let attempt = 0;
  let uploadSuccess = false;

  const existingMessage = await Message.findOne({
    where: { url: `uscitylink/${fileName}` },
  });

  while (attempt < maxRetries) {
    try {
      await s3.upload(uploadParams).promise();

      await Media.update({ upload_type: "server" }, { where: { id: mediaId } });

      if (existingMessage) {
        await Message.update(
          { url_upload_type: "server" },
          { where: { id: existingMessage.id } }
        );
      }

      fs.unlinkSync(filePath);
      console.log(`File ${fileName} uploaded successfully.`);
      const socket = global.userSockets[userId];
      uploadSuccess = true;
      if (source == "staff") {
        if (location == "group") {
          await notifiyFileUploadDriverToStaffGroup(
            getSocketInstance(),
            socket,
            groupId!,
            channelId,
            existingMessage!.id,
            "server",
            userId
          );
        } else if (location == "truck") {
          const existingGroupMessage = await GroupMessage.findOne({
            where: { url: `uscitylink/${fileName}` },
          });
          if (existingGroupMessage) {
            await GroupMessage.update(
              { url_upload_type: "server" },
              { where: { id: existingGroupMessage.id } }
            );
          }

          await notifiyFileUploadTruckGroupMembers(
            getSocketInstance(),
            socket,
            channelId,
            groupId!,
            existingMessage!.id,
            "server",
            userId,
            existingGroupMessage!.id,
            `uscitylink/${fileName}`
          );
        } else {
          await notifiyFileUploadStaffToDriver(
            getSocketInstance(),
            socket,
            channelId,
            existingMessage!.id,
            "server",
            userId
          );
        }
      } else if (source == "staff_group") {
        await notifiyFileUploadStaffToStaff(
          getSocketInstance(),
          socket,
          channelId,
          existingMessage!.id,
          "server",
          userId,
          private_chat_id
        );
      } else {
        if (location == "group") {
          await notifiyFileUploadDriverToStaffGroup(
            getSocketInstance(),
            socket,
            groupId!,
            channelId,
            existingMessage!.id,
            "server",
            userId
          );
        } else {
          await notifiyFileUploadDriverToStaff(
            getSocketInstance(),
            socket,
            channelId,
            existingMessage!.id,
            "server",
            userId
          );
        }
      }
      break; // Exit loop if upload is successful
    } catch (error) {
      attempt++;
      console.error(
        `Attempt ${attempt} - Error uploading file ${fileName}:`,
        error
      );

      if (attempt >= maxRetries) {
        console.error(
          `Failed to upload file ${fileName} after ${maxRetries} attempts.`
        );

        if (existingMessage) {
          await Message.update(
            { url_upload_type: "failed" },
            { where: { id: existingMessage.id } }
          );
        }

        throw error;
      }

      const delay = Math.pow(2, attempt) * 100; // Exponential backoff
      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }
};
