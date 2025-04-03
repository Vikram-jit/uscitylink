import { Request, Response } from "express";
import PrivateChatMember from "../../models/PrivateChatMember";
import { UserProfile } from "../../models/UserProfile";
import Role from "../../models/Role";
import { Op } from "sequelize";
import { Message } from "../../models/Message";
import User from "../../models/User";

export async function getStaffMembers(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const onlineUserId = req?.user?.id as string;

    const userCreated = await PrivateChatMember.findAll({
      where: {
        createdBy: onlineUserId,
      },
    });
    const userCreatedByOtherStaff = await PrivateChatMember.findAll({
      where: {
        userProfileId: onlineUserId,
      },
    });

    const userCreatedUserIds = await Promise.all(
      userCreated.map((e) => e.userProfileId)
    );
    const userCreatedByOtherStaffIds = await Promise.all(
      userCreatedByOtherStaff.map((e) => e.createdBy)
    );

    const combinedIds = [...userCreatedUserIds, ...userCreatedByOtherStaffIds];

    const uniqueIdsSet = new Set(combinedIds);

    const uniqueIds = Array.from(uniqueIdsSet);

    const role = await Role.findOne({
      where: {
        name: "staff",
      },
    });

    const userIds = await UserProfile.findAll({
      where: {
        role_id: role?.id,
        id: { [Op.notIn]: uniqueIds },
      },
      attributes: ["id", "username"],
    });

    return res.status(200).json({
      status: true,
      message: `Fetch staff members successfully.`,
      data: userIds,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function getChatUsers(req: Request, res: Response): Promise<any> {
  try {
    const onlineUserId = req?.user?.id;

    const chatMemberships:any = await PrivateChatMember.findAll({
      where: {
        [Op.or]: [{ createdBy: onlineUserId }, { userProfileId: onlineUserId }],
      },
      include: [
        {
          model: Message,
          as: "last_message",
        },
      ],
    });

   
    const userIdsSet = new Set();

    chatMemberships.forEach(({ createdBy, userProfileId }:any) => {
      if (createdBy !== onlineUserId) userIdsSet.add(createdBy);
      if (userProfileId !== onlineUserId) userIdsSet.add(userProfileId);
    });

    const uniqueUserIds = Array.from(userIdsSet);

    const staffRole = await Role.findOne({
      where: { name: "staff" },
    });

    const userProfiles = await UserProfile.findAll({
      where: {
        role_id: staffRole!.id,
        id: { [Op.in]: uniqueUserIds },
      },
      attributes: ["id", "username"],
    });

    const usersWithChatIds = userProfiles.map((user) => {
      const chat = chatMemberships.find(
        (chat:any) =>
          (chat.createdBy === onlineUserId && chat.userProfileId === user.id) ||
          (chat.userProfileId === onlineUserId && chat.createdBy === user.id)
      );
       const isCreatedBy =chat.createdBy === onlineUserId
      return {
        ...user.get({ plain: true }),
        chat_id: chat ? chat.id : null,
        senderCount: chat ? chat.senderCount : 0,
        reciverCount: chat ? chat.reciverCount : 0,
        last_message:chat ? chat?.last_message :null,
        isCreatedBy
      };
    });

    return res.status(200).json({
      status: true,
      message: `Fetch staff members successfully.`,
      data: usersWithChatIds,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function addStaffMember(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const onlineUserId = req?.user?.id as string;
    const userId = req.body.userProfileId;
    const type = req.body.type || "active";
    if (type == "active") {
      await PrivateChatMember.create({
        userProfileId: userId,
        createdBy: onlineUserId,
        status: "active",
      });
    } else {
      await PrivateChatMember.update(
        {
          status: "in-active",
        },
        {
          where: {
            userProfileId: userId,
          },
        }
      );
    }

    return res.status(201).json({
      status: true,
      message: `Add member successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function sendMessageToStaffMember(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const messageDirection = req.body.messageDirection;
    const onlineUserId = req?.user?.id as string;

    const type = req.body.type || "active";
    const body = req.body.body;

    const private_chat_id = req.body.private_chat_id;

    const privateChatFirst = await PrivateChatMember.findOne({
      where: {
        id: private_chat_id,
      },
    });

    const userProfile =
      privateChatFirst?.createdBy == onlineUserId
        ? privateChatFirst?.userProfileId
        : privateChatFirst?.createdBy;

    const messageSave = await Message.create({
      channelId: req.activeChannel,
      userProfileId: userProfile,
      groupId: null,
      body,
      messageDirection: messageDirection,
      deliveryStatus: "sent",
      messageTimestampUtc: new Date(),
      senderId: req.user?.id,
      isRead: false,
      status: "sent",
      url: null,
      thumbnail: null,
      reply_message_id: null,
      url_upload_type: "server",
      private_chat_id: private_chat_id,
      type: "staff_message",
    });

    return res.status(201).json({
      status: true,
      message: `send message successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function getAllMessageByPrivateChatId(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const pageSize = parseInt(req.query.pageSize as string) || 10;

    const offset = (page - 1) * pageSize;

    const messages = await Message.findAndCountAll({
      where: {
        private_chat_id: req.params.id,
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
        },
      ],
      order: [["messageTimestampUtc", "DESC"]],
      limit: pageSize,
      offset: offset,
    });

    const totalMessages = messages.count;
    const totalPages = Math.ceil(totalMessages / pageSize);

    return res.status(200).json({
      status: true,
      message: `Fetch messages successfully.`,
      data: {
        messages: messages.rows,
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
}
