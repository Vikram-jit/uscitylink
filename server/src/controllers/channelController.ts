import { Request, Response } from "express";
import Channel from "../models/Channel";
import UserChannel from "../models/UserChannel";
import { UserProfile } from "../models/UserProfile";
import GroupChannel from "../models/GroupChannel";
import Group from "../models/Group";
import User from "../models/User";
import { getSocketInstance } from "../sockets/socket";
import { Message } from "../models/Message";
import { Op } from "sequelize";
import { getUnrepliedMessagesCount } from "./userController";
import GroupUser from "../models/GroupUser";

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
      const userSocket = global.userSockets[user_id];

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
        getSocketInstance()
          .to(userSocket.id)
          .emit("user_added_to_channel", userChannel);
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
    const page = parseInt(req.query.page as string) || 1; 
    const pageSize = parseInt(req.query.pageSize as string) || 10; 

    const search = req.query.search as string || ''

    const offset = (page - 1) * pageSize;
    const data: any = await Channel.findOne({
      where: {
        id: req.activeChannel,
      },

    });

    const userChannels = await  UserChannel.findAndCountAll({
      where:{
        channelId:req.activeChannel,
        status:"active"
      },
      include: [
        {
          model: UserProfile,
          attributes: {
            exclude: ["password"],
          },
          where:{
            username: {
              [Op.like]: `%${search}%`, 
            },
          },
          include: [
            {
              model: User,
              as: "user",
            },
          ],
          
        },
        {
          model: Message,
          as: "last_message",
        },
      ],
      order: [
        [
          
          "sent_message_count",
          "DESC",
        ],
      
        [
         
          "last_message_utc",
          "DESC",
        ],
      ],
      limit: pageSize,
      offset: offset,
    })
    const total = userChannels.count;
    const totalPages = Math.ceil(total / pageSize);
    
    const newData ={
      ...data?.dataValues,
      user_channels:userChannels.rows,
      pagination: {
        currentPage: page,
        pageSize: pageSize,
        total,
        totalPages,
      }
    }
    return res.status(200).json({
      status: true,
      message: `Channel Fetch Successfully..`,
      data: newData,
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
      channel = await Channel.findByPk(
        userProfile?.dataValues?.channelId || ""
      );
    }
    const userUnMessage = await UserChannel.sum("sent_message_count",{
      where:{
        channelId:req.activeChannel,
        isGroup:0
      }
    });
    const groupCount = await Group.sum('message_count');
    return res.status(200).json({
      status: true,
      message: `Active channel Fetch Successfully.`,
      data: {channel,messages:userUnMessage,group:groupCount},
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}


export async function channelRemoveMember(
  req: Request,
  res: Response
): Promise<any> {
  try {
    await UserChannel.destroy({
      where: {
        id: req.params.id,
      },
    });

    return res.status(200).json({
      status: true,
      message: `Deleted Channel Members Successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function channelStatusMember(
  req: Request,
  res: Response
): Promise<any> {
  try {
    await UserChannel.update(
      { status: req.body.status },
      {
        where: {
          id: req.params.id,
        },
      }
    );

    return res.status(200).json({
      status: true,
      message: `Updated Members Successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}


export async function countMessageAndGroup(
  req: Request,
  res: Response
): Promise<any> {
  try {
  const messageCount =  await UserChannel.sum("recieve_message_count",{
      where:{
        userProfileId:req.user?.id,
        
      }
    })

    const userGroupsCount  = await GroupUser.sum("message_count",{
      where:{userProfileId:req.user?.id}
    })

    return res.status(200).json({
      status: true,
      message: `Get count Successfully.`,
      data: {total:messageCount + userGroupsCount,channel:messageCount,group:userGroupsCount}
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

