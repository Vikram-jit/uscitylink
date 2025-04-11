import { Request, Response } from "express";
import { Message } from "../models/Message";
import { Op } from "sequelize";
import { UserProfile } from "../models/UserProfile";
import Group from "../models/Group";
import GroupChannel from "../models/GroupChannel";

export const getMessagesV2 = async (
  req: Request,
  res: Response
): Promise<any> => {
  try {

    const { channelId } = req.params;
    const driverPin = req.query.driverPin;


    const page = parseInt(req.query.page as string) || 1;
    const pageSize = parseInt(req.query.pageSize as string) || 10;

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
