import { Request, Response } from "express";
import Channel from "../models/Channel";
import UserChannel from "../models/UserChannel";
import { UserProfile } from "../models/UserProfile";
import GroupChannel from "../models/GroupChannel";
import Group from "../models/Group";
import User from "../models/User";
import { getSocketInstance } from "../sockets/socket";
import { Message } from "../models/Message";

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

    const newData = channels.map((channel) => ({
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
    const { ids } = req.body; // Assuming ids is an array of userProfileIds

    if (!Array.isArray(ids) || ids.length === 0) {
      throw new Error("No user IDs provided.");
    }

    
    const existingUserChannels = await UserChannel.findAll({
      where: {
        channelId: req.activeChannel,
        userProfileId: ids,
      },
    });

    
    const existingUserIds = existingUserChannels.map(
      (channel) => channel.userProfileId
    );

  
    const newUserIds = ids.filter(
      (user_id) => !existingUserIds.includes(user_id)
    );

    // Create UserChannel entries for the new user IDs
    const createPromises = newUserIds.map((user_id) => {
      return UserChannel.create({
        channelId: req.activeChannel,
        userProfileId: user_id,
      });
    });

    await Promise.all(createPromises);

    
     // After users have been added to the channel, check if they are online
     for (const user_id of newUserIds) {
      const userSocket = global.onlineUsers.find(
        (user) => user.id === user_id
      );

      // Get UserChannel details for the user
      const userChannel = await UserChannel.findOne({
        where: {
          userProfileId: user_id,
          channelId: req.activeChannel, // Make sure the channel matches
        },
        include: [
          {
            model: Channel, // Assuming the channel is associated with UserChannel
          },
          {
            model: Message, // Assuming the last message is associated with UserChannel
            as: "last_message", // Alias for last_message relationship
          },
        ],
      });

      // Emit the data to the user's socket if they are online
      if (userSocket && userChannel) {
        getSocketInstance().to(userSocket.socketId).emit('user_added_to_channel', userChannel);
      }
    }

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
        id: req.activeChannel,
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

export async function getMembers(req: Request, res: Response): Promise<any> {
  try {
    const data: any = await Channel.findOne({
      where: {
        id: req.activeChannel,
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
              include: [
                {
                  model: User,
                  as: "user",
                },
              ],
            },
          ],
        },
      ],
    });

    return res.status(200).json({
      status: true,
      message: `Channel Fetch Successfully.`,
      data: data,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function getActiveChannel(
  req: Request,
  res: Response
): Promise<any> {
  try {
    let channel: any = {};

    const userProfile = await UserProfile.findByPk(req.user?.id);
    
    
    if (userProfile) {
      channel = await Channel.findByPk(userProfile?.dataValues?.channelId || "");
    }

    return res.status(200).json({
      status: true,
      message: `Active channel Fetch Successfully.`,
      data: channel,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}
