import { Request, Response } from "express";
import { UserProfile } from "../models/UserProfile";
import User from "../models/User";
import Role from "../models/Role";
import UserChannel from "../models/UserChannel";
import Channel from "../models/Channel";

export async function getUsers(req: Request, res: Response): Promise<any> {
  try {
    const users = await UserProfile.findAll({
        attributes: {
            exclude: ["password"],
          },
      include: [
        {
          model: User,
          as: "user",
        },
        {
          model: Role,
          as: "role",
        },
      ],
      order:[["id", "DESC"]]
    });

    return res.status(200).json({
      status: true,
      message: `Get Users Successfully.`,
      data: users,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function getChannelList(req: Request, res: Response): Promise<any> {
  try {
    const users = await UserChannel.findAll({
       where:{
        userProfileId:req.params.id
       },
      include: [
        {
          model: Channel,
         
        },
     
      ],
      order:[["id", "DESC"]]
    });

    return res.status(200).json({
      status: true,
      message: `Get Users Successfully.`,
      data: users,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}


export async function updateUserActiveChannel(req: Request, res: Response): Promise<any> {
  try {

    await UserProfile.update({
      channelId:req.body?.channelId
    }, {
      where: {
          id: req.params.id, 
      },
      returning: true,
  });

    return res.status(200).json({
      status: true,
      message: `Update Channel Successfully.`,
     
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}
