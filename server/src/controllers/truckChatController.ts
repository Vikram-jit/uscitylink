import { Request, Response } from "express";
import Channel from "../models/Channel";
import GroupChannel from "../models/GroupChannel";
import Group from "../models/Group";
import { Op } from "sequelize";
import { Message } from "../models/Message";

export async function truckGroups(req: Request, res: Response): Promise<any> {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const pageSize = parseInt(req.query.pageSize as string) || 10;

    const search = (req.query.search as string) || "";

    const offset = (page - 1) * pageSize;

    const channel = await Channel.findByPk(req.activeChannel);

    const groupChannel = await GroupChannel.findAll({
      where: {
        channelId: req.activeChannel,
      },
    });

    const groupIds = await Promise.all(groupChannel.map((e) => e.groupId));

    const data = await Group.findAndCountAll({
      where: {
        type:"truck",
        id: {
          [Op.in]: groupIds,
        },
        name: {
          [Op.like]: `%${search}%`,
        },
      },

      include: [
        {
          model: GroupChannel,
          as: "group_channel",
        },
        {
          model: Message,
          as: "last_message",
        },
      ],

     
      order:[["updatedAt", "DESC"]],
      limit: pageSize,
      offset: offset,
    });
    const total = data.count;
    const totalPages = Math.ceil(total / pageSize);
    const newData = {
      data: data.rows,
      channel,
      pagination: {
        currentPage: page,
        pageSize: pageSize,
        total,
        totalPages,
      },
    };
    return res.status(200).json({
      status: true,
      message: `Truck Chat Group Fetch Successfully.`,
      data: newData,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}
