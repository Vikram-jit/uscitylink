import { Request, Response } from "express";
import { Message } from "../models/Message";
import { Op, Sequelize } from "sequelize";
import { UserProfile } from "../models/UserProfile";
import Group from "../models/Group";
import GroupChannel from "../models/GroupChannel";
import moment from "moment";
import { getSocketInstance } from "../sockets/socket";
import SocketEvents from "../sockets/socketEvents";
import UserChannel from "../models/UserChannel";
import GroupUser from "../models/GroupUser";
import { sendNotificationToDevice } from "../utils/fcmService";
import Channel from "../models/Channel";
import User from "../models/User";
import { MessageStaff } from "../models/MessageStaff";
import Role from "../models/Role";
import retry from "async-retry";

export const getMessagesV2 = async (
  req: Request,
  res: Response
): Promise<any> => {
  try {

    const { channelId } = req.params;
    const driverPin = req.query.driverPin;


    const page = parseInt(req.query.page as string) || 1;
    const pageSize = parseInt(req.query.pageSize as string) || 50;

    const offset = (page - 1) * pageSize;


    const messages = await Message.findAndCountAll({
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
      limit: pageSize,
      offset: offset,
    });

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
        messages:modifiedMessage,
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

export const quickMessage = async (
  req: Request,
  res: Response,
): Promise<any> => {
  try {
    const { driver_number, body } = req.body;

      const isUserId = await User.findOne({
        where:{
          driver_number:driver_number
        },
        
      })
      if(!isUserId) throw new Error("User Not found");

    const channelId = "1cb8a91e-921f-40fc-873f-af30d2ee3da0";
      const userProfile = await UserProfile.findOne({
        where:{
          userId:isUserId.id
        }
      })
      const userProfileId = userProfile?.id
   
  
    const messageSave = await Message.create({
      channelId:  channelId,
      userProfileId:userProfileId,
      groupId:  null,
      body,
      messageDirection: "R",
      deliveryStatus: "sent",
      messageTimestampUtc: new Date(),
      senderId: userProfileId,
      isRead: false,
      status: "sent",
      url: null,
      thumbnail:  null,
      reply_message_id:  null,
      url_upload_type:  "with-out-media",
    });
    const message = await Message.findOne({
      where: {
        id: messageSave.id,
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
              include: [
                {
                  model: User,
                  as: "user",
                },
              ],
            },
          ],
        },
        {
          model: UserProfile,
          as: "sender",
          attributes: ["id", "username", "isOnline"],
          include: [
            {
              model: User,
              as: "user",
            },
          ],
        },
      ],
    });
    if (message) {
      const utcTime = moment.utc().toDate();
      const openStaffChatIds: string[] = [];
      //Find Active Driver With Channel
      let isCheckAnyStaffOpenChat = 0;

      const promises = Object.entries(global.staffOpenChat).map(
        async ([staffId, e]) => {
          const isSocket = global.userSockets[staffId];

          if (
            e.channelId === (channelId) &&
            userProfileId === e.userId
          ) {
            if (isSocket) {
              await retry(
                async () => {
                  await MessageStaff.create({
                    messageId: messageSave.id,
                    staffId: staffId,
                    driverId: userProfileId,
                    status: "read",
                    type: "chat",
                  });
                },
                {
                  retries: 3,
                  onRetry: (err) => {
                    if (
                      err instanceof Error &&
                      (err as any).original?.code === "ER_LOCK_DEADLOCK"
                    ) {
                      console.warn("Deadlock detected, retrying...");
                    } else {
                      throw err;
                    }
                  },
                },
              );

              await message?.update(
                {
                  deliveryStatus: "seen",
                },
                {
                  where: {
                    id: messageSave.id,
                  },
                },
              );

              isCheckAnyStaffOpenChat += 1;
              getSocketInstance().to(isSocket.id).emit(
                SocketEvents.RECEIVE_MESSAGE_BY_CHANNEL,
                message,
              );
            }
          } else {
            if (e.channelId !== channelId) {
              if (isSocket) {
                // const channel = await Channel.findByPk(message?.channelId);
                getSocketInstance().to(isSocket.id).emit(
                  "notification_new_message",
                  `New Message received on  ${message?.dataValues.sender.username}  channel 1`,
                );
                getSocketInstance().to(isSocket.id).emit(
                  "notification_user_id",
                  `${message.userProfileId}`,
                );
                await UserChannel.update(
                  {
                    sent_message_count: Sequelize.literal(
                      "sent_message_count + 1",
                    ),
                  },
                  {
                    where: {
                      userProfileId: userProfileId, // The user you want to update
                      channelId: channelId, // The channel to target
                    },
                  },
                );
                isCheckAnyStaffOpenChat += 1;
              }
            } else {
              if (isSocket) {
                // io.to(isSocket.id).emit("new_message_count_update_staff", {
                //   channelId: message?.channelId,
                //   userId: message?.userProfileId,
                //   message,
                //   sent_message_count: 1,
                // });
                await UserChannel.update(
                  {
                    sent_message_count: Sequelize.literal(
                      "sent_message_count + 1",
                    ),
                  },
                  {
                    where: {
                      userProfileId: userProfileId,
                      channelId:channelId,
                    },
                  },
                );
                getSocketInstance().to(isSocket.id).emit(
                  "notification_new_message",
                  `New Message received`,
                );
                getSocketInstance().to(isSocket.id).emit(
                  "notification_user_id",
                  `${message.userProfileId}`,
                );
                isCheckAnyStaffOpenChat += 1;
              }
            }
          }
        },
      );

      await Promise.all(promises);
    //  getSocketInstance().to(socket?.id).emit(SocketEvents.RECEIVE_MESSAGE_BY_CHANNEL, message);
      if (isCheckAnyStaffOpenChat === 0) {
        await UserChannel.update(
          {
            sent_message_count: Sequelize.literal("sent_message_count + 1"),
          },
          {
            where: {
              userProfileId: userProfileId,
              channelId: channelId,
            },
          },
        );
      }

      if (isCheckAnyStaffOpenChat == 0) {
        const newPromise = Object.entries(global.staffActiveChannel).map(
          async ([staffId, el]) => {
            const isSocket = global.userSockets[staffId];

            await retry(
              async () => {
                await MessageStaff.findOrCreate({
                  where: {
                    messageId: messageSave.id,
                    staffId: staffId,
                    driverId: userProfileId,
                  },
                  defaults: {
                    messageId: messageSave.id,
                    staffId: staffId,
                    driverId:userProfileId,
                    status: "un-read",
                  },
                });
              },
              {
                retries: 3,
                onRetry: (err) => {
                  if (
                    err instanceof Error &&
                    (err as any).original?.code === "ER_LOCK_DEADLOCK"
                  ) {
                    console.warn("Deadlock detected, retrying...");
                  } else {
                    throw err;
                  }
                },
              },
            );

            if (
              el.role == "staff" &&
              el.channelId == channelId
            ) {
              if (isSocket) {
                
              }
            } else {
              if (
                el.role == "staff" &&
                el.channelId != channelId
              ) {
                // const channel = await Channel.findByPk(message?.channelId);
                if (isSocket) {
                  getSocketInstance().to(isSocket?.id).emit(
                    "notification_new_message",
                    `New Message received by ${message?.dataValues.sender.username} `,
                  );
                  getSocketInstance().to(isSocket.id).emit(
                    "notification_user_id",
                    `${message.userProfileId}`,
                  );
                }
              }
            }
          },
        );
        await Promise.all(newPromise);
      }

      await UserChannel.update(
        {
          last_message_id: message?.id,
          last_message_utc: utcTime,
        },
        {
          where: {
            userProfileId: userProfileId,
            channelId: channelId,
          },
        },
      );
      
    }
 
    const roleId = await Role.findOne({
      where: {
        name: "staff",
      },
    });

    // const channel = await Channel.findByPk(channelId);

    const users = await UserProfile.findAll({
      where: {
        role_id: roleId?.id,
        // device_token: {
        //   [Op.ne]: null,
        // },
      },
    });

    const userDriver = await UserChannel.findOne({
      where: {
        userProfileId: message?.userProfileId,
        channelId: message?.channelId,
      },
      include: [
        {
          model: UserProfile,
          attributes: {
            exclude: ["password"],
          },
          include: [
            {
              model: User,
              as: "user",
              where: {
                status: "active",
              },
            },
          ],
        },
        {
          model: Message,
          as: "last_message",
        },
      ],
    });

    await Promise.all(
      users.map(async (user) => {
        if (user) {
          const isSocket = global.userSockets[user.id];
          if (isSocket) {
            getSocketInstance().to(isSocket.id).emit(
              "notification_new_message",
              `New Message received by ${message?.dataValues.sender.username}`,
            );
            if (userDriver) {
              const unreadCount = await MessageStaff.count({
                where: {
                  driverId: userDriver.userProfileId,
                  status: "un-read",
                  type: "chat",
                  staffId: user.id,
                },
              });
              getSocketInstance().to(isSocket.id).emit(
                "notification_user_id",
                `${userDriver.userProfileId}`,
              );
              const groupUsers: any = await GroupUser.findAll({
                where: {
                  userProfileId: userDriver.userProfileId,
                  status: "active",
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
              const getTruckNumbers = await Promise.all(
                groupUsers.map((e: any) => e.Group.name),
              );

              const newObj = {
                ...userDriver.dataValues,
                unreadCount: unreadCount,
                assginTrucks: getTruckNumbers?.join(","),
              };
              getSocketInstance().to(isSocket.id).emit(
                "notification_new_message_with_user",
                newObj,
              );
            }

            getSocketInstance().to(isSocket.id).emit("new_message_count_update_staff", {
              channelId: message?.channelId,
              userId: message?.userProfileId,
              message,
              sent_message_count: 1,
            });
          }
        }
      }),
    );
  
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




