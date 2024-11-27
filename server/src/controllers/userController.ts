import { Request, Response } from "express";
import { UserProfile } from "../models/UserProfile";
import User from "../models/User";
import Role from "../models/Role";
import UserChannel from "../models/UserChannel";
import Channel from "../models/Channel";
import { Message } from "../models/Message";

export async function getUsers(req: Request, res: Response): Promise<any> {
  try {

    const  role  = req.query.role as string;

    let whereCondition = {};
    if (role) {
      const isDriverRole = await Role.findOne({
        where: { name: role }, 
      });

      
      if (!isDriverRole) {
        return res.status(404).json({
          status: false,
          message: `Role '${role}' not found.`,
        });
      }

     
      whereCondition = {
        role_id: isDriverRole.id, 
      };
    }

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
      where:whereCondition,
      order: [["id", "DESC"]],
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

export async function getChannelList(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const users = await UserChannel.findAll({
      where: {
        userProfileId: req.user?.id,
      },
      include: [
        {
          model: Channel,
        },
        {
          model: Message,
         as:"last_message"
        
        }
        
      ],
      order: [["recieve_message_count", "DESC"]],
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

export async function updateUserActiveChannel(
  req: Request,
  res: Response
): Promise<any> {
  try {
    await UserProfile.update(
      {
        channelId: req.body?.channelId,
      },
      {
        where: {
          id: req.user?.id,
        },
        returning: true,
      }
    );

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

export async function getUserWithoutChannel(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const isDriverRole = await Role.findOne({
      where: {
        name: "driver",
      },
    });

    const users: any = await UserProfile.findAll({
      where: {
        role_id: isDriverRole?.id,
      },
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
        {
          model: UserChannel,
          as: "userChannels",
          required: false,
          where: {
            channelId: req.activeChannel,
          },
        },
      ],
      order: [["id", "DESC"]],
    });

    const filteredUsers = users?.filter((user: any) => {
      return (
        !user.userChannels ||
        user.userChannels.length === 0 ||
        !user.userChannels.some(
          (channel: any) => channel.channelId === req.activeChannel
        )
      );
    });

    return res.status(200).json({
      status: true,
      message: `Get Driver Users Successfully.`,
      data: filteredUsers,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function getUserProfile( req: Request,
  res: Response):Promise<any>{
  try {

    const user = await UserProfile.findByPk(req.user?.id)
    
    return res.status(200).json({
      status: true,
      message: `Get Profile User Successfully.`,
      data: user,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}


export async function updateDeviceToken(
  req: Request,
  res: Response
): Promise<any> {
  try {
    console.log(req.body)
    await UserProfile.update(
      {
        device_token: req.body.device_token,
        platform:req.body.platform
      },
      {
        where: {
          id: req.user?.id,
        },
        returning: true,
      }
    );

    return res.status(200).json({
      status: true,
      message: `Update Device Token Successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}