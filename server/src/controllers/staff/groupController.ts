import { Request, Response } from "express";
import Channel from "../../models/Channel";
import GroupChannel from "../../models/GroupChannel";
import Group from "../../models/Group";
import { Op, QueryTypes } from "sequelize";
import { Message } from "../../models/Message";
import { secondarySequelize } from "../../sequelize";

export async function get(req: Request, res: Response): Promise<any> {
  try {
    const type = req.query.type as string;
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
        type: type ?? "group",
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

      order: type == "group" ? [["message_count", "DESC"],["last_message_id", "DESC"]] : [["id", "DESC"]],
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
      message: `Group Fetch Successfully.`,
      data: newData,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function getTruckList(req: Request, res: Response): Promise<any> {
  try {
    const groupTruckList = await GroupChannel.findAll({
      where: {
        channelId: req.activeChannel,
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

    const truckIds: any = groupTruckList?.map((el) => el.dataValues.Group.name);

    const trucks = await secondarySequelize.query<any>(
      `SELECT number FROM trucks WHERE number NOT IN (:id)`,
      {
        replacements: { id: truckIds }, // Passing the array of truck IDs to the query
        type: QueryTypes.SELECT,
      }
    );

    return res.status(200).json({
      status: true,
      message: `Get Trucks Successfully.`,
      data: trucks,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}
