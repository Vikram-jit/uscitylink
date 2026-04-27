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
    const findDriverSocket = global.driverOpenChat.find(
      (driver) => driver?.driverId === userProfileId,
    );

    const messageSave = await Message.create({
      channelId: channelId,
      userProfileId,
      groupId: null,
      body,
      messageDirection: "R",
      deliveryStatus: "sent",
      messageTimestampUtc: moment.utc().format(),
      senderId: userProfileId,
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

    const findStaffActiveChannel = global.staffActiveChannel[""];

    //Check Before send driver active room channel
    const isDriverSocket = global.userSockets[userProfileId ?? ""];

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
          },
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
              findStaffActiveChannel?.channelId,
            );
            const messageCount = await UserChannel.sum(
              "recieve_message_count",
              {
                where: {
                  userProfileId: userProfileId,
                },
              },
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
              findStaffActiveChannel?.channelId,
            );
            const messageCount = await UserChannel.sum(
              "recieve_message_count",
              {
                where: {
                  userProfileId: userProfileId,
                },
              },
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
        },
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
      },
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




