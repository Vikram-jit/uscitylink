import { Request, Response } from "express";
import Channel from "../models/Channel";
import UserChannel from "../models/UserChannel";
import { UserProfile } from "../models/UserProfile";
import GroupChannel from "../models/GroupChannel";
import Group from "../models/Group";

export async function create(req: Request, res: Response): Promise<any> {
  try {
    const { name, description } = req.body;

    await Channel.create({
      name: name,
      description: description,
    });

    return res.status(201).json({
      status: true,
      message: `Channel Created Successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function get(req: Request, res: Response): Promise<any> {
  try {

    const [channels, activeChannel] = await Promise.all([
      Channel.findAll(),
      UserProfile.findByPk(req.user?.id),
    ]);

   
    const newData = channels.map(channel => ({
      ...channel.dataValues,
      isActive: activeChannel?.channelId === channel.id,
    }));

    return res.status(200).json({
      status: true,
      message: `Channel Fetch Successfully.`,
      data: newData,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function userAddToChannel(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const { user_id, channel_id } = req.body;

    const isFound = await UserChannel.findOne({
      where: {
        channelId: channel_id,
        userProfileId: user_id,
      },
    });

    if (isFound) throw new Error("Already added into channel.");

    await UserChannel.create({
      channelId: channel_id,
      userProfileId: user_id,
    });

    return res.status(200).json({
      status: true,
      message: `Added into channel successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function getById(req: Request, res: Response): Promise<any> {
  try {
    const data: any = await Channel.findOne({
      where: {
        id: req.params.id,
      },
      include: [
        {
          model: UserChannel,
          as: "user_channels",
          include: [
            {
              model: UserProfile,
              attributes: {
                exclude: ["password"],
              },
            },
          ],
        },
        {
          model: GroupChannel,
          as: "group_channels",
          include: [
            {
              model: Group,
            },
          ],
        },
      ],
    });

    const mergedResponse: any = {
      id: data?.id,
      name: data?.name,
      description: data?.description,
      createdAt: data?.createdAt,
      updatedAt: data?.updatedAt,
      members: [],
    };

    // Add user channels to the members array
    data?.user_channels?.forEach((userChannel: any) => {
      mergedResponse.members.push({
        type: "user",
        id: userChannel.UserProfile.id,
        image: "",
        username: userChannel.UserProfile.username,
        status: userChannel.UserProfile.status,
        isOnline: userChannel.UserProfile.isOnline,
      });
    });

    // Add group channels to the members array
    data.group_channels.forEach((groupChannel: any) => {
      mergedResponse.members.push({
        type: "group",
        id: groupChannel.Group.id,
        image: "",
        username: groupChannel.Group.name,
        description: groupChannel.Group.description,
        isOnline: false,
      });
    });

    return res.status(200).json({
      status: true,
      message: `Channel Fetch Successfully.`,
      data: mergedResponse,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}
