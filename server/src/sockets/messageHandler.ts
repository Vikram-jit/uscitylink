//Message to channel

import { Server } from "socket.io";
import { Message } from "../models/Message";
import { CustomSocket } from "./socket";
import SocketEvents from "./socketEvents";
import UserChannel from "../models/UserChannel";
import { Op, Sequelize, where } from "sequelize";
import moment from "moment";
import Channel from "../models/Channel";
import { UserProfile } from "../models/UserProfile";
import { sendNotificationToDevice } from "../utils/fcmService";
import GroupMessage from "../models/GroupMessage";
import GroupUser from "../models/GroupUser";
import Group from "../models/Group";

export async function messageToChannelToUser(
  io: Server,
  socket: CustomSocket,
  body: string,
  url: string | null
) {
  const findUserChannel = global.driverOpenChat.find(
    (e) => e.driverId == socket?.user?.id
  );

  if (findUserChannel) {
    const message = await Message.create({
      channelId: findUserChannel.channelId,
      userProfileId: socket?.user?.id,
      body,
      messageDirection: "R",
      deliveryStatus: "sent",
      messageTimestampUtc: new Date(),
      senderId: socket?.user?.id,
      isRead: false,
      status: "sent",
      url: url,
    });

    if (message) {
      const utcTime = moment.utc().toDate();

      //Find Active Driver With Channel
      let isCheckAnyStaffOpenChat = 0;

      const promises = Object.entries(global.staffOpenChat).map(
        async ([staffId, e]) => {
          const isSocket = global.userSockets[staffId];

          if (
            e.channelId === findUserChannel.channelId &&
            socket?.user?.id === e.userId
          ) {
            if (isSocket) {
              await message.update(
                {
                  deliveryStatus: "seen",
                },
                {
                  where: {
                    id: message.id,
                  },
                }
              );
              isCheckAnyStaffOpenChat += 1;
              io.to(isSocket.id).emit(
                SocketEvents.RECEIVE_MESSAGE_BY_CHANNEL,
                message
              );
            }
          } else {
            if (e.channelId !== findUserChannel.channelId) {
              if (isSocket) {
                const channel = await Channel.findByPk(message?.channelId);
                io.to(isSocket.id).emit(
                  "notification_new_message",
                  `New Message received on ${channel?.name} channel`
                );
                await UserChannel.update(
                  {
                    sent_message_count: Sequelize.literal(
                      "sent_message_count + 1"
                    ),
                  },
                  {
                    where: {
                      userProfileId: socket?.user?.id, // The user you want to update
                      channelId: findUserChannel.channelId, // The channel to target
                    },
                  }
                );
                isCheckAnyStaffOpenChat += 1;
              }
            } else {
              if (isSocket) {
                io.to(isSocket.id).emit("new_message_count_update_staff", {
                  channelId: message?.channelId,
                  userId: message?.userProfileId,
                  message,
                });
                await UserChannel.update(
                  {
                    sent_message_count: Sequelize.literal(
                      "sent_message_count + 1"
                    ),
                  },
                  {
                    where: {
                      userProfileId: socket?.user?.id, // The user you want to update
                      channelId: findUserChannel.channelId, // The channel to target
                    },
                  }
                );
                io.to(isSocket.id).emit(
                  "notification_new_message",
                  `New Message received --`
                );
                isCheckAnyStaffOpenChat += 1;
              }
            }
          }
        }
      );

      await Promise.all(promises);

      if (isCheckAnyStaffOpenChat === 0) {
        await UserChannel.update(
          {
            sent_message_count: Sequelize.literal("sent_message_count + 1"),
          },
          {
            where: {
              userProfileId: socket?.user?.id,
              channelId: findUserChannel.channelId,
            },
          }
        );
      }

      if (isCheckAnyStaffOpenChat == 0) {
        const newPromise = Object.entries(global.staffActiveChannel).map(
          async ([staffId, el]) => {
            const isSocket = global.userSockets[staffId];

            if (
              el.role == "staff" &&
              el.channelId == findUserChannel.channelId
            ) {
              if (isSocket) {
                io.to(isSocket?.id).emit("new_message_count_update_staff", {
                  channelId: message?.channelId,
                  userId: message?.userProfileId,
                  message,
                });
                io.to(isSocket?.id).emit(
                  "notification_new_message",
                  `New Message received ++`
                );
              }
            } else {
              if (
                el.role == "staff" &&
                el.channelId != findUserChannel.channelId
              ) {
                const channel = await Channel.findByPk(message?.channelId);
                if (isSocket) {
                  io.to(isSocket?.id).emit(
                    "notification_new_message",
                    `New Message received on ${channel?.name} channel`
                  );
                }
              }
            }
          }
        );
        await Promise.all(newPromise);
      }

      await UserChannel.update(
        {
          last_message_id: message?.id,
          last_message_utc: utcTime,
        },
        {
          where: {
            userProfileId: socket?.user?.id,
            channelId: findUserChannel.channelId,
          },
        }
      );
      io.to(socket?.id).emit(SocketEvents.RECEIVE_MESSAGE_BY_CHANNEL, message);
    }
  }
}

//Message To Driver

export async function messageToDriver(
  io: Server,
  socket: CustomSocket,
  userId: string,
  body: string,
  direction: string,
  url: string | null
) {
  const findStaffActiveChannel = global.staffActiveChannel[socket?.user?.id!];

  const findDriverSocket = global.driverOpenChat.find(
    (driver) => driver?.driverId === userId
  );

  const message = await Message.create({
    channelId: findStaffActiveChannel?.channelId,
    userProfileId: userId,
    body,
    messageDirection: direction,
    deliveryStatus: "sent",
    messageTimestampUtc: new Date(),
    senderId: socket?.user?.id,
    isRead: false,
    status: "sent",
    url: url || null,
  });

  //Check Before send driver active room channel
  const isDriverSocket = global.userSockets[findDriverSocket?.driverId!];

  if (
    findDriverSocket &&
    findDriverSocket?.channelId == findStaffActiveChannel?.channelId
  ) {
    if (isDriverSocket) {
      await message.update(
        {
          deliveryStatus: "seen",
        },
        {
          where: {
            id: message.id,
          },
        }
      );
      io.to(isDriverSocket?.id).emit(
        SocketEvents.RECEIVE_MESSAGE_BY_CHANNEL,
        message
      );
    }
  } else {
    if (isDriverSocket) {
      io.to(isDriverSocket?.id).emit("update_user_channel_list", message);
      io.to(isDriverSocket?.id).emit(
        "new_message_count_update",
        message?.channelId
      );
      const isUser = await UserProfile.findOne({
        where: {
          id: userId,
        },
      });
      if (isUser) {
        if (isUser.device_token) {
          const isChannel = await Channel.findByPk(
            findStaffActiveChannel?.channelId
          );

          await sendNotificationToDevice(isUser.device_token, {
            title: isChannel?.name || "",
            body: body,
            data: {
              channelId: isChannel?.id,

              type: "NEW MESSAGE",
              title: isChannel?.name,
            },
          });
        }
      }
    } else {
      const isUser = await UserProfile.findOne({
        where: {
          id: userId,
        },
      });
      if (isUser) {
        if (isUser.device_token) {
          const isChannel = await Channel.findByPk(
            findStaffActiveChannel?.channelId
          );

          await sendNotificationToDevice(isUser.device_token, {
            title: isChannel?.name || "",
            body: body,
            data: {
              channelId: isChannel?.id,

              type: "NEW MESSAGE",
              title: isChannel?.name,
            },
          });
        }
      }
    }

    await UserChannel.update(
      {
        recieve_message_count: Sequelize.literal("recieve_message_count + 1"),
      },
      {
        where: {
          userProfileId: userId, // The user you want to update
          channelId: findStaffActiveChannel?.channelId, // The channel to target
        },
      }
    );
  }
  const utcTime = moment.utc().toDate();

  await UserChannel.update(
    {
      last_message_id: message?.id,
      last_message_utc: utcTime,
    },
    {
      where: {
        userProfileId: userId,
        channelId: findStaffActiveChannel?.channelId,
      },
    }
  );
  //Return Message To Staff After Store
  Object.entries(global.staffOpenChat).forEach(([staffId, e]) => {
    if (e.channelId === findStaffActiveChannel?.channelId) {
      const isSocket = global.userSockets[staffId]; // Use staffId as the identifier

      if (isSocket) {
        io.to(isSocket.id).emit(
          SocketEvents.RECEIVE_MESSAGE_BY_CHANNEL,
          message
        );
      }
    }
  });
}

export async function messageToDriverByTruckGroup(
  io: Server,
  socket: CustomSocket,
  userId: string,
  groupId: string,
  body: string,
  direction: string,
  url: string | null
) {
  const findStaffActiveChannel = global.staffActiveChannel[socket?.user?.id!];
  const utcTime = moment.utc().toDate();
  const userIds = userId.split(",");

  for (const driverId of userIds || []) {
    const findDriverSocket = global.driverOpenChat.find(
      (driver) => driver?.driverId === driverId
    );
    const message = await Message.create({
      channelId: findStaffActiveChannel?.channelId,
      groupId: groupId,
      userProfileId: driverId,
      body,
      messageDirection: direction,
      deliveryStatus: "sent",
      messageTimestampUtc: utcTime,
      senderId: socket?.user?.id,
      isRead: false,
      status: "sent",
      url: url || null,
      type: "truck_group",
    });

    const isDriverSocket = global.userSockets[findDriverSocket?.driverId!];

    // Process each driver and emit message or update database sequentially
    if (
      findDriverSocket &&
      findDriverSocket?.channelId == findStaffActiveChannel?.channelId
    ) {
      if (isDriverSocket) {
        await message.update(
          {
            deliveryStatus: "seen",
          },
          {
            where: {
              id: message.id,
            },
          }
        );
        io.to(isDriverSocket?.id).emit(
          SocketEvents.RECEIVE_MESSAGE_BY_CHANNEL,
          message
        );
      }
    } else {
      if (isDriverSocket) {
        io.to(isDriverSocket?.id).emit("update_user_channel_list", message);
        io.to(isDriverSocket?.id).emit(
          "new_message_count_update",
          message?.channelId
        );
        const isUser = await UserProfile.findOne({
          where: {
            id: driverId,
          },
        });
        if (isUser && isUser.device_token) {
          const isChannel = await Channel.findByPk(
            findStaffActiveChannel?.channelId
          );
          await sendNotificationToDevice(isUser.device_token, {
            title: isChannel?.name || "",
            body: body,
            data: {
              channelId: isChannel?.id,
              type: "NEW MESSAGE",
              title: isChannel?.name,
            },
          });
        }
      } else {
        const isUser = await UserProfile.findOne({
          where: {
            id: driverId,
          },
        });
        if (isUser && isUser.device_token) {
          const isChannel = await Channel.findByPk(
            findStaffActiveChannel?.channelId
          );
          await sendNotificationToDevice(isUser.device_token, {
            title: isChannel?.name || "",
            body: body,
            data: {
              channelId: isChannel?.id,
              type: "NEW MESSAGE",
              title: isChannel?.name,
            },
          });
        }
      }

      await UserChannel.update(
        {
          recieve_message_count: Sequelize.literal("recieve_message_count + 1"),
        },
        {
          where: {
            userProfileId: driverId, // The user you want to update
            channelId: findStaffActiveChannel?.channelId, // The channel to target
          },
        }
      );
    }

    await UserChannel.update(
      {
        last_message_id: message?.id,
        last_message_utc: utcTime,
      },
      {
        where: {
          userProfileId: driverId,
          channelId: findStaffActiveChannel?.channelId,
        },
      }
    );
  }

  const group_message = await GroupMessage.create({
    groupId: groupId,
    body: body,
    senderId: socket?.user?.id,
    deliveryStatus: "sent",
    messageTimestampUtc: utcTime,
    url: url || null,
  });

  Object.entries(global.staffOpenTruckGroup).forEach(([staffId, e]) => {
    if (
      e.channelId === findStaffActiveChannel?.channelId &&
      groupId == e.groupId
    ) {
      const isSocket = global.userSockets[staffId]; // Use staffId as the identifier

      if (isSocket) {
        io.to(isSocket.id).emit(
          SocketEvents.RECEIVE_MESSAGE_BY_GROUP,
          group_message
        );
      }
    }
  });
}

export async function unreadAllMessage(
  io: Server,
  socket: CustomSocket,
  channelId: string
) {
  if (channelId) {
    await UserChannel.update(
      {
        recieve_message_count: 0,
      },
      {
        where: {
          channelId: channelId,
          userProfileId: socket?.user?.id,
        },
      }
    );

    io.to(socket.id).emit("update_channel_message_count", channelId);
  }
}

export async function unreadAllUserMessage(
  io: Server,
  socket: CustomSocket,
  channelId: string,
  userId: string
) {
  if (channelId) {
    await UserChannel.update(
      {
        sent_message_count: 0,
      },
      {
        where: {
          channelId: channelId,
          userProfileId: userId,
        },
      }
    );
    await Message.update(
      {
        deliveryStatus: "seen",
      },
      {
        where: {
          channelId: channelId,
          userProfileId: userId,
          senderId: userId,
        },
      }
    );

    //check driver active channel

    const isDriverActiveChat = global.driverOpenChat.find(
      (driver) => driver.channelId == channelId
    );

    if (isDriverActiveChat) {
      const isDriverSocket = global.userSockets[isDriverActiveChat.driverId];

      if (isDriverSocket) {
        io.to(isDriverSocket.id).emit("update_all_message_seen", {
          channelId,
          userId,
        });
      }
    }

    io.to(socket.id).emit("update_channel_sent_message_count", {
      channelId,
      userId,
    });
  }
}

export async function messageToGroup(
  io: Server,
  socket: CustomSocket,
  groupId: string,
  channelId: string,
  body: string,
  direction: string,
  url: string | null
) {
  const group = await Group.findByPk(groupId)
  const channel = await Channel.findByPk(channelId)
  // console.log(groupId,channelId,body,direction,url)
  const utcTime = moment.utc().toDate();

  const message = await Message.create({
    channelId: channelId,
    groupId: groupId,
    userProfileId: socket?.user?.id,
    body,
    messageDirection: direction,
    deliveryStatus: "sent",
    messageTimestampUtc: utcTime,
    senderId: socket?.user?.id,
    isRead: false,
    status: "sent",
    url: url || null,
    type: "group",
  });

  const newMessage = await Message.findByPk(message.id,{
    include: {
      model: UserProfile,
      as: "sender",
      attributes: ["id", "username", "isOnline"],
    },
  })
  const userIdActiveGroup: string[] = [];

  Object.values(global.group_open_chat[groupId]).map((e) => {
    const onlineUser = global.userSockets[e.userId];
    if (onlineUser) {
      userIdActiveGroup.push(e.userId);
      io.to(onlineUser.id).emit("new_group_message_received", newMessage);
    }
  });

  Object.entries(global.staffActiveChannel).map(([key,value])=>{
    
    const isStaffSocket = global.userSockets[key]
    if(isStaffSocket ){
      io.to(isStaffSocket.id).emit("update_user_group_list", newMessage);
   
    io.to(isStaffSocket.id).emit("notification_group",`New Group Message Received in ${group?.name} on ${channel?.name}`) }
  })


  const usersToUpdate = await GroupUser.findAll({
    where: {
      groupId: groupId,
      userProfileId: {
        [Op.notIn]: userIdActiveGroup, 
      },
    },
    attributes: ["userProfileId"], 
  });

  for (const user of usersToUpdate) {

    const onlineUser = global.userSockets[user.userProfileId];
    if (onlineUser) {
     
      io.to(onlineUser.id).emit("update_user_group_list", newMessage);
    }

    await GroupUser.update(
      {
        message_count: Sequelize.literal("message_count + 1"),
      },
      {
        where: {
          groupId: groupId,
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
      const isGroup = await Group.findByPk(groupId);
      await sendNotificationToDevice(isUser.device_token, {
        title: isGroup?.name || "",
        body: body,
        data: {
          groupId: isGroup?.id,
          type: "GROUP MESSAGE",
          title: `${isGroup?.name}(Group)`,
          channelId:channelId,
          name:isGroup?.name
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
        groupId: groupId,
      },
    }
  );



  await Group.update({
    message_count: Sequelize.literal("message_count + 1"),
    last_message_id: message.id,
  },{
    where:{
      id:groupId
    }
  })
}
export async function unreadAllGroupMessageByUser(
  io: Server,
  socket: CustomSocket,
  groupId: string
) {
  if (groupId) {
    await GroupUser.update(
      {
        message_count: 0,
      },
      {
        where: {
          groupId: groupId,
          userProfileId: socket?.user?.id,
        },
      }
    );

    io.to(socket.id).emit("update_group_message_count", groupId);
  }
}

export async function unreadAllGroupMessageByStaff(
  io: Server,
  socket: CustomSocket,
  groupId: string
) {
  if (groupId) {
    await Group.update(
      {
        message_count: 0,
      },
      {
        where: {
         id:groupId
        },
      }
    );

    io.to(socket.id).emit("update_group_staff_message_count", groupId);
  }
}