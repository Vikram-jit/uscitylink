import { Request, Response } from "express";
import Group from "../models/Group";
import GroupChannel from "../models/GroupChannel";
import { Op } from "sequelize";

export async function create(req: Request, res: Response): Promise<any> {
  try {
    const { name, description } = req.body;

    const group = await Group.create({
      name: name,
      description: description,
    });
    

    if (group) {
      await GroupChannel.create({
        groupId: group?.id,
        channelId: req.activeChannel,
      });
    }

    return res.status(201).json({
      status: true,
      message: `Group Created Successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function get(req: Request, res: Response): Promise<any> {
  try {

    const groupChannel = await GroupChannel.findAll({
      where:{
        channelId:req.activeChannel
      }
    })

    const groupIds = await Promise.all(groupChannel.map((e)=>e.groupId))

    const data = await Group.findAll({
      where:{
        id:{
          [Op.in]:groupIds
        }
      },
      order: [["id", "DESC"]],
    });

    return res.status(200).json({
      status: true,
      message: `Group Fetch Successfully.`,
      data:data
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}
