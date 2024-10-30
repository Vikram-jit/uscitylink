import { Request, Response } from "express";
import Group from "../models/Group";
import GroupChannel from "../models/GroupChannel";

export async function create(req: Request, res: Response): Promise<any> {
  try {
    const { name, description, channelId } = req.body;

    const group = await Group.create({
      name: name,
      description: description,
    });

    if (group) {
      await GroupChannel.create({
        groupId: group?.id,
        channelId: channelId,
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
    const data = await Group.findAll({
      order: [["id", "DESC"]],
    });

    return res.status(200).json({
      status: true,
      message: `Group Fetch Successfully.`,
      data,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}
