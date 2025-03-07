import { Request, Response } from "express";
import { UserProfile } from "../../models/UserProfile";
import Channel from "../../models/Channel";
import UserChannel from "../../models/UserChannel";
import { Op, Sequelize } from "sequelize";
import User from "../../models/User";
import { Message } from "../../models/Message";
import GroupUser from "../../models/GroupUser";
import Group from "../../models/Group";
import moment from "moment";
import { getSocketInstance } from "../../sockets/socket";
import { sendNotificationToDevice } from "../../utils/fcmService";
import Role from "../../models/Role";
import Queue from "bull";


export const groupMessageQueueApi = new Queue('groupMessageQueueApi', {
  redis: {
    host: '127.0.0.1',  
    port: 6379,          
  }
});

export const groupNotificationStaffQueueApi = new Queue('groupNotificationStaffQueueApi', {
  redis: {
    host: '127.0.0.1',  
    port: 6379,          
  }
});

groupNotificationStaffQueueApi.process(async (job)=>{
  
  const {channelId,groupId, body, senderId} = job.data;

  const senderProfile = await UserProfile.findByPk(senderId);
  const groupProfile = await Group.findByPk(groupId);

  const roleId = await Role.findOne({
    where: {
      name: "staff",
    },
  });

  const users = await UserProfile.findAll({
    where: {
      role_id: roleId?.id,
      device_token: {
        [Op.ne]: null,
      },
    },
  });
 
  const staffIds:string[] = [];
  //  global.group_open_chat[groupId].map((item)=>{
  //   if(item.channelId == channelId){
  //     staffIds.push(item.userId)
  //   }
  // })

 
  await Promise.all(
    users.map(async (user) => {
      if (user) {
    
        if (!staffIds.includes(user.id)) {
          const deviceToken = user.device_token;
          
          if (deviceToken) {
            const isActiveChannel =   global.staffActiveChannel[user?.id]?.channelId == channelId ? "1" : "0"
            await sendNotificationToDevice(deviceToken, {
              title: `${senderProfile?.username} (${groupProfile?.name} Group)` || "",
              badge: 0,
              body: body,
              data: {
                channelId: channelId,
                type: "GROUP NEW MESSAGE STAFF",
                title: groupProfile?.name,
                groupId:groupId,
                isActiveChannel
              },
            });
          }
        }
      }
    })
  );

})



groupMessageQueueApi.process(async (job:any)=>{

  const {userId,title,device_token,body,data} = job.data;

  const messageCount = await UserChannel.sum("recieve_message_count", {
    where: {
      userProfileId: userId,
    },
  });

  const userGroupsCount = await GroupUser.sum("message_count", {
    where: { userProfileId: userId },
  });

  await sendNotificationToDevice(device_token, {
    title: title,
    badge: messageCount + userGroupsCount,
    body: body,
    data: data,
  });


})  


export async function getChatMessageUser(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const pageSize = parseInt(req.query.pageSize as string) || 10;

    const search = (req.query.search as string) || "";

    const offset = (page - 1) * pageSize;
    const data: any = await Channel.findOne({
      where: {
        id: req.activeChannel,
      },
    });

    const userChannels = await UserChannel.findAndCountAll({
      where: {
        channelId: req.activeChannel,
        status: "active",
      },
      include: [
        {
          model: UserProfile,
          attributes: {
            exclude: ["password"],
          },
          where: {
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
        ["sent_message_count", "DESC"],

        ["last_message_utc", "DESC"],
      ],
      limit: pageSize,
      offset: offset,
    });

    const total = userChannels.count;
    const totalPages = Math.ceil(total / pageSize);

    const newData = {
      ...data?.dataValues,
      user_channels: userChannels.rows,
      pagination: {
        currentPage: page,
        pageSize: pageSize,
        total,
        totalPages,
      },
    };
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

export const getMessagesByUserId = async (
  req: Request,
  res: Response
): Promise<any> => {
  try {
    const { id, channelId } = req.params;
    const page = parseInt(req.query.page as string) || 1;
    const pageSize = parseInt(req.query.pageSize as string) || 10;

    const offset = (page - 1) * pageSize;

    const userProfile = await UserProfile.findByPk(id);

    const messages = await Message.findAndCountAll({
      where: {
        channelId: channelId,
        userProfileId: id,
        groupId: null,
      },
      include: {
        model: UserProfile,
        as: "sender",
        attributes: ["id", "username", "isOnline"],
      },
      order: [["messageTimestampUtc", "DESC"]],
      limit: pageSize,
      offset: offset,
    });

    const totalMessages = messages.count;
    const totalPages = Math.ceil(totalMessages / pageSize);

    const groupUser = await GroupUser.findAll({
      where: {
        userProfileId: id,
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
    const truckNumbers = await Promise.all(
      groupUser.map((e) => e.dataValues.Group.name)
    );

    return res.status(200).json({
      status: true,
      message: `Fetch message successfully`,
      data: {
        userProfile,
        messages: messages.rows,
        truckNumbers: truckNumbers ? truckNumbers?.join(",") : null,
        pagination: {
          currentPage: page,
          pageSize: pageSize,
          totalMessages,
          totalPages,
        },
      },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
};

export const deletedByUserId = async (
  req: Request,
  res: Response
): Promise<any> => {
  try {
    const { id } = req.params;

    const userChannels = await UserChannel.findOne({
      where: {
        channelId: req.activeChannel,
        userProfileId: id,
        isGroup: 0,
      },
    });

    if (userChannels) {
      await UserChannel.update(
        {
          status: "inactive",
        },
        {
          where: {
            id: userChannels.id,
          },
        }
      );
    }

    return res.status(200).json({
      status: true,
      message: `Deleted chat successfully`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
};

export const messageToGroup = async (
  req: Request,
  res: Response
): Promise<any> => {
  try {
   
    const body = req.body.message;
    const groupName = req.body.group_name || "Staff Group";
    const channelName = req.body.channel_name || "U S CITYLINK INC";
    const group = await Group.findOne({
      where: {
        name: groupName,
      },
    });
    
    const channel = await Channel.findOne({
      where: {
        name: channelName,
      },
    });
   
    const utcTime = moment.utc().toDate();

    const systemProfie = await UserProfile.findOne({
      where: {
        username: req.body.user_name || "System",
      },
    });
    
    const message = await Message.create({
      channelId: channel?.id,
      groupId: group?.id,
      userProfileId: systemProfie?.id,
      body: body,
      messageDirection: "S",
      deliveryStatus: "sent",
      messageTimestampUtc: utcTime,
      senderId: systemProfie?.id,
      isRead: false,
      status: "sent",
      url: null,
      type: "group",
      thumbnail: null,
    });
   
    const newMessage = await Message.findByPk(message.id, {
      include: {
        model: UserProfile,
        as: "sender",
        attributes: ["id", "username", "isOnline"],
      },
    });
    const userIdActiveGroup: string[] = [];

    if (global.group_open_chat && global.group_open_chat[group?.id!]) {
      Object.values(global.group_open_chat[group?.id!]).map((e) => {
        const onlineUser = global.userSockets[e.userId];
      if (onlineUser) {
        userIdActiveGroup.push(e.userId);
        getSocketInstance()
          .to(onlineUser.id)
          .emit("new_group_message_received", newMessage);
      }
      });
    } else {
      console.log("group_open_chat or group ID is undefined");
    }
   
   
    groupNotificationStaffQueueApi.add({
      channelId: channel?.id,
      groupId: group?.id,
      body,
      senderId: systemProfie?.id,
    });
 
    if (global.staffActiveChannel) {
    Object.entries(global.staffActiveChannel).map(([key, value]) => {
      const isStaffSocket = global.userSockets[key];
      if (isStaffSocket) {
        getSocketInstance()
          .to(isStaffSocket.id)
          .emit("update_user_group_list", newMessage);

        getSocketInstance()
          .to(isStaffSocket.id)
          .emit(
            "notification_group",
            `New Group Message Received in ${group?.name} on ${channel?.name}`
          );
      }
    });
  }

    const usersToUpdate = await GroupUser.findAll({
      where: {
        groupId: group?.id,
        userProfileId: {
          [Op.notIn]: userIdActiveGroup,
        },
      },
      attributes: ["userProfileId"],
    });

    for (const user of usersToUpdate) {
      const onlineUser = global.userSockets[user.userProfileId];
      if (onlineUser) {
        getSocketInstance()
          .to(onlineUser.id)
          .emit("update_user_group_list", newMessage);
      }

      await GroupUser.update(
        {
          message_count: Sequelize.literal("message_count + 1"),
        },
        {
          where: {
            groupId: group?.id,
            userProfileId: user.userProfileId,
          },
        }
      );

      const isUser = await UserProfile.findOne({
        where: {
          id: user.userProfileId,
        },
      });
   
      if (isUser && isUser.device_token) {
        const isGroup = await Group.findByPk(group?.id);

        groupMessageQueueApi.add({
          device_token: isUser?.device_token,
          userId: isUser.id,
          title: `${isGroup?.name}(Group)` || "",
          body: body,
          data: {
            groupId: isGroup?.id,
            type: "GROUP MESSAGE",
            title: `${isGroup?.name}(Group)`,
            channelId: channel?.id,
            name: isGroup?.name,
          },
        });
      }
    }

    await GroupUser.update(
      {
        last_message_id: message.id,
      },
      {
        where: {
          groupId: group?.id,
        },
      }
    );

    await Group.update(
      {
        message_count: Sequelize.literal("message_count + 1"),
        last_message_id: message.id,
      },
      {
        where: {
          id: group?.id,
        },
      }
    );
    return res
      .status(200)
      .json({ status: true, message: "Sent message successfully." });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
};
