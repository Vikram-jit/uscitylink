import { Request, Response } from "express";
import { UserProfile } from "../models/UserProfile";
import User from "../models/User";
import Role from "../models/Role";
import UserChannel from "../models/UserChannel";
import Channel from "../models/Channel";
import { Message } from "../models/Message";
import GroupUser from "../models/GroupUser";
import Group from "../models/Group";
import GroupChannel from "../models/GroupChannel";
import { secondarySequelize } from "../sequelize";
import { Op, QueryTypes, Sequelize } from "sequelize";
import { comparePasswords, hashPassword } from "../utils/passwordCrypto";

export async function getUsers(req: Request, res: Response): Promise<any> {
  try {
    const role = req.query.role as string;

    const page = parseInt(req.query.page as string) || 1;

    const pageSize = parseInt(req.query.pageSize as string) || 10;

    const search = (req.query.search as string) || "";

    const offset = (page - 1) * pageSize;

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

    const users = await UserProfile.findAndCountAll({
      where: {
        ...whereCondition,
        ...(page != -1 && {
          username: {
            [Op.like]: `%${search}%`,
          },
        }),
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
      ],

      order: [["username", "ASC"]],
      ...(page !== -1 && { limit: pageSize, offset }),
    });

    const total = users.count;
    const totalPages = Math.ceil(total / pageSize);

    return res.status(200).json({
      status: true,
      message: `Get Users Successfully.`,
      data: {
        users: users.rows,
        pagination: {
          currentPage: page,
          pageSize: pageSize,
          total,
          totalPages,
        },
      },
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
        status: "active",
      },
      include: [
        {
          model: Channel,
        },
        {
          model: Message,
          as: "last_message",
        },
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

export async function getGroupList(req: Request, res: Response): Promise<any> {
  try {
    const users = await GroupUser.findAll({
      where: {
        userProfileId: req.user?.id,
        status: "active",
      },
      include: [
        {
          model: Group,
          where: {
            type: "group",
          },
          include: [
            {
              model: GroupChannel,
              as: "group_channel",
            },
          ],
        },
        {
          model: Message,
          as: "last_message",
        },
      ],
      order: [["message_count", "DESC"]],
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

export async function getUserProfile(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const user = await UserProfile.findByPk(req.user?.id);

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
    console.log(req.body);
    await UserProfile.update(
      {
        device_token: req.body.device_token,
        platform: req.body.platform,
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

export async function syncUser(req: Request, res: Response): Promise<any> {
  try {
    const isRole = await Role.findOne({
      where: {
        name: "staff",
      },
    });
    const dispatchers = await secondarySequelize.query<any>(
      `SELECT * FROM dispatches`,
      {
        type: QueryTypes.SELECT,
      }
    );

    if (Array.isArray(dispatchers)) {
      await Promise.all(
        dispatchers.map(async (e) => {
          const isCheckRegister = await User.findOne({
            where: {
              email: e.email,
            },
          });
          if (isCheckRegister) {
          } else {
            const isUser = await User.create({
              email: e.email,
              phone_number: e?.phone,
              status: "active",
            });

            if (isUser) {
              await UserProfile.create({
                username: e.name,
                userId: isUser?.id,
                role_id: isRole?.id!,
                password: e.password,
                status: "active",
              });
            }
          }
        })
      );
    }

    return res.status(200).json({
      status: true,
      message: `Update Device Token Successfully.`,
      data: dispatchers,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function syncDriver(req: Request, res: Response): Promise<any> {
  try {
    const isRole = await Role.findOne({
      where: {
        name: "driver",
      },
    });
    const drivers = await secondarySequelize.query<any>(
      `SELECT * FROM drivers`,
      {
        type: QueryTypes.SELECT,
      }
    );

    if (Array.isArray(drivers)) {
      await Promise.all(
        drivers.map(async (e) => {
          const isCheckRegister = await User.findOne({
            where: {
              email: e.email,
            },
          });
          if (isCheckRegister) {
          } else {
            const isUser = await User.create({
              email: e.email,
              phone_number: e?.phone_number,
              status: "active",
            });

            if (isUser) {
              const pass = "123456";
              // Hash the password
              const hashedPassword = await hashPassword(pass);
              await UserProfile.create({
                username: e.name,
                userId: isUser?.id,
                role_id: isRole?.id!,
                password: hashedPassword,
                status: "active",
              });
            }
          }
        })
      );
    }

    return res.status(200).json({
      status: true,
      message: `Sync Driver Successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function changePassword(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const { old_password, new_password, confirm_password } = req.body;

    const isUser = await UserProfile.findOne({
      where: {
        id: req.user?.id,
      },
    });

    if (!isUser) throw new Error("User not found");

    const isMatch = await comparePasswords(old_password, isUser?.password!);

    if (!isMatch) throw new Error("Old Password not matched");

    if (new_password !== confirm_password)
      throw new Error("New password and Confirm password not matched");

    const hash = await hashPassword(confirm_password);

    await UserProfile.update(
      {
        password: hash,
      },
      {
        where: {
          id: req.user?.id,
        },
      }
    );

    return res.status(200).json({
      status: true,
      message: `Password updated successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}


export async function dashboard(
  req: Request,
  res: Response
): Promise<any> {
  try {
    
    const userChannelCount = await UserChannel.count({where:{
      userProfileId:req?.user?.id,
      status:"active"
    }});


    const userTotalMessage = await Message.count({where:{
      userProfileId:req?.user?.id,
    }});

    const userTotalGroups = await GroupUser.count({where:{
      userProfileId:req?.user?.id,
      status:"active"
    }});

    const truckCount = await secondarySequelize.query<any>(
      `SELECT COUNT(*) AS truckCount FROM trucks`,
      {
        type: QueryTypes.SELECT,
      }
    );
    const trailerCount = await secondarySequelize.query<any>(
      `SELECT COUNT(*) AS trailerCount FROM trailers`,
      {
        type: QueryTypes.SELECT,
      }
    );

    const distinctChannelIds = await UserChannel.findAll({
      where: {
        userProfileId: req?.user?.id,
        last_message_id: { [Op.not]: null }
      },
    
      raw: true,
      order:[['last_message_utc','DESC']],
      limit:2
    });
    
    const channelIds = distinctChannelIds.map(item => item.channelId); 

    const latestMessage = await Message.findAll({
      where: {
        userProfileId: req?.user?.id,
        channelId: { [Op.in]: channelIds },
        groupId: null, // Use the dynamic groupIds
       
      },
      include: [
        {
          model: UserProfile,
          as: 'sender',
          attributes: ['id', 'username', 'isOnline'],
        },
        {
          model: Channel,
          as: 'channel',
          attributes: ['id', 'name'],
        },
      ],
      order: [['messageTimestampUtc', 'DESC']],
      limit: 2,
    });
    
   

    const distinctGroupIds = await GroupUser.findAll({
      where: {
        userProfileId: req?.user?.id,
        last_message_id: { [Op.not]: null }
      },
    
      raw: true,
      order:[['updatedAt','DESC']],
      limit:2
    });
    
    const groupIds = distinctGroupIds.map(item => item.groupId); 
    
    const latestGroupMessages = await Message.findAll({
      where: {
        
        groupId: { [Op.in]: groupIds }, // Use the dynamic groupIds
        channelId: { [Op.not]: null },
      },
      include: [
        {
          model: UserProfile,
          as: 'sender',
          attributes: ['id', 'username', 'isOnline'],
        },
        {
          model: Channel,
          as: 'channel',
          attributes: ['id', 'name'],
        },
      ],
      order: [['messageTimestampUtc', 'DESC']],
      limit: 2,
    });
    
    let messagesWithGroup = [];
    if (latestGroupMessages.length > 0) {
      
       messagesWithGroup = await Promise.all(
        latestGroupMessages.map(async (message) => {
          
          const group = await Group.findByPk(
            message?.groupId! ,
          );
    
          
          return { ...message.dataValues, group };
        })
      );
    
      
    }
    
   
    return res.status(200).json({
      status: true,
      message: `Dashboard fetch successfully.`,
      data:{
        channelCount:userChannelCount,
        messageCount:userTotalMessage,
        groupCount:userTotalGroups,
        truckCount:truckCount?.[0]?.truckCount,
        trailerCount:trailerCount?.[0]?.trailerCount,
        latestMessage,
        latestGroupMessage:messagesWithGroup,
        distinctChannelIds
      }
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}
