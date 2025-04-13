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
import Queue from "bull";
import Role from "../models/Role";
import User from "../models/User";
import { MessageStaff } from "../models/MessageStaff";
import PrivateChatMember from "../models/PrivateChatMember";
import { Media } from "../models/Media";

const notificationQueue = new Queue("jobQueue", {
  redis: {
    host: "127.0.0.1", // Redis host
    port: 6379, // Custom Redis port
  },
});

export const groupMessageQueue = new Queue("groupMessageQueue", {
  redis: {
    host: "127.0.0.1",
    port: 6379,
  },
});

export const groupNotificationStaffQueue = new Queue(
  "groupNotificationStaffQueue",
  {
    redis: {
      host: "127.0.0.1",
      port: 6379,
    },
  }
);

groupNotificationStaffQueue.process(async (job) => {
  const { channelId, groupId, body, senderId } = job.data;

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
  const staffIds: string[] = [];
  global.group_open_chat[groupId].map((item) => {
    if (item.channelId == channelId) {
      staffIds.push(item.userId);
    }
  });

  await Promise.all(
    users.map(async (user) => {
      if (user) {
        if (!staffIds.includes(user.id)) {
          const deviceToken = user.device_token;
          if (deviceToken) {
            const isActiveChannel =
              global.staffActiveChannel[user?.id]?.channelId == channelId
                ? "1"
                : "0";
            await sendNotificationToDevice(deviceToken, {
              title:
                `${senderProfile?.username} (${groupProfile?.name} Group)` ||
                "",
              badge: 0,
              body: body,
              data: {
                channelId: channelId,
                type: "GROUP NEW MESSAGE STAFF",
                title: groupProfile?.name,
                groupId: groupId,
                isActiveChannel,
              },
            });
          }
        }
      }
    })
  );
});

groupMessageQueue.process(async (job: any) => {
  const { userId, title, device_token, body, data } = job.data;

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
});

notificationQueue.process(async (job: any) => {
  const { title, body, channel_id, userName, userId, staffId, messageId } =
    job.data;

  const roleId = await Role.findOne({
    where: {
      name: "staff",
    },
  });

  const staffIds = Object.entries(global.staffOpenChat).map(([key, value]) => {
    if (value.channelId == channel_id && value.userId == userId) {
      return key;
    }
  });

  const channel = await Channel.findByPk(channel_id);

  const users = await UserProfile.findAll({
    where: {
      role_id: roleId?.id,
      // device_token: {
      //   [Op.ne]: null,
      // },
    },
  });

  await Promise.all(
    users.map(async (user) => {
      if (user) {
        if (!staffIds.includes(user.id)) {
          await MessageStaff.findOrCreate({
            where: {
              messageId: messageId,
              staffId: user.id,
              driverId: staffId,
            },
            defaults: {
              messageId: messageId,
              staffId: user.id,
              driverId: staffId,
              status: "un-read",
            },
          });
          const deviceToken = user.device_token;
          if (deviceToken) {
            const isActiveChannel =
              global.staffActiveChannel[user?.id]?.channelId == channel_id
                ? "1"
                : "0";

            await sendNotificationToDevice(deviceToken, {
              title: `${userName} (${channel?.name})` || "",
              badge: 0,
              body: body,
              data: {
                channelId: channel_id,
                type: "DRIVER NEW MESSAGE",
                title: userName,
                userId: userId,
                isActiveChannel,
              },
            });
          }
        }
      }
    })
  );
});

// Optional: Handle failed jobs
notificationQueue.on("failed", (job, err) => {
  console.log(`Job failed: ${job.id}, Error: ${err}`);
});

groupMessageQueue.on("failed", (job, err) => {
  console.log(`Group User Notification failed: ${job.id}, Error: ${err}`);
});

groupNotificationStaffQueue.on("failed", (job, err) => {
  console.log(`Group Staff Notification failed: ${job.id}, Error: ${err}`);
});

export async function driverMessageQueueProcess(
  io: Server,
  socket: CustomSocket,
  messageId: string,
  body: string,
  url: string | null,
  channelId: string,
  thumbnail: string | null,
  r_message_id: string | null,
  url_upload_type?: string
) {
  const messageSave = await Message.create({
    channelId: channelId,
    userProfileId: socket?.user?.id,
    groupId: socket?.user?.truck_group_id || null,
    body,
    messageDirection: "R",
    deliveryStatus: "sent",
    messageTimestampUtc: new Date(),
    senderId: socket?.user?.id,
    isRead: false,
    status: "sent",
    url: url,
    thumbnail: thumbnail || null,
    reply_message_id: r_message_id || null,
    url_upload_type: url_upload_type || "server",
  });
  const message = await Message.findOne({
    where: {
      id: messageSave.id,
    },
    include: [
      {
        model: Message,
        as: "r_message",
        include: [
          {
            model: UserProfile,
            as: "sender",
            attributes: ["id", "username", "isOnline"],
            include: [
              {
                model: User,
                as: "user",
              },
            ],
          },
        ],
      },
      {
        model: UserProfile,
        as: "sender",
        attributes: ["id", "username", "isOnline"],
        include: [
          {
            model: User,
            as: "user",
          },
        ],
      },
    ],
  });
  if (message) {
    const utcTime = moment.utc().toDate();
    const openStaffChatIds: string[] = [];
    //Find Active Driver With Channel
    let isCheckAnyStaffOpenChat = 0;

    const promises = Object.entries(global.staffOpenChat).map(
      async ([staffId, e]) => {
        const isSocket = global.userSockets[staffId];

        if (e.channelId === channelId && socket?.user?.id === e.userId) {
          if (isSocket) {
            await MessageStaff.create({
              messageId: messageSave.id,
              staffId: staffId,
              driverId: socket?.user?.id,
              status: "read",
              type: "chat",
            });
            await message?.update(
              {
                deliveryStatus: "seen",
              },
              {
                where: {
                  id: messageSave.id,
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
          if (e.channelId !== channelId) {
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
                    channelId: channelId, // The channel to target
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
                sent_message_count: 1,
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
                    channelId: channelId, // The channel to target
                  },
                }
              );
              io.to(isSocket.id).emit(
                "notification_new_message",
                `New Message received`
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
            channelId: channelId,
          },
        }
      );
    }

    if (isCheckAnyStaffOpenChat == 0) {
      const newPromise = Object.entries(global.staffActiveChannel).map(
        async ([staffId, el]) => {
          const isSocket = global.userSockets[staffId];
          await MessageStaff.findOrCreate({
            where: {
              messageId: messageSave.id,
              staffId: staffId,
              driverId: socket?.user?.id,
            },
            defaults: {
              messageId: messageSave.id,
              staffId: staffId,
              driverId: socket?.user?.id,
              status: "un-read",
            },
          });
          if (el.role == "staff" && el.channelId == channelId) {
            if (isSocket) {
              io.to(isSocket?.id).emit("new_message_count_update_staff", {
                channelId: message?.channelId,
                userId: message?.userProfileId,
                message,
              });

              io.to(isSocket?.id).emit(
                "notification_new_message",
                `New Message received `
              );
            }
          } else {
            if (el.role == "staff" && el.channelId != channelId) {
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
          channelId: channelId,
        },
      }
    );
    
    if (socket?.user?.truck_group_id) {
      Object.entries(global.staffOpenTruckGroup).forEach(([staffId, e]) => {
        if (
          e.channelId === channelId &&
          socket?.user?.truck_group_id == e.groupId
        ) {
          const isSocket = global.userSockets[staffId];

          if (isSocket) {
            io.to(isSocket.id).emit("receive_message_group_truck", message);
          }
        }
      });
    }
  }



  const findChannel = await Channel.findOne({
    where: {
      id: channelId,
    },
  });

  notificationQueue.add({
    title: "",
    body,
    channel_id: channelId,
    userId: socket.user?.id,
    userName: `${findChannel?.name}`,
    staffId: socket?.user?.id,
    messageId: messageSave.id,
  });

   
    const isDriverSocket = global.userSockets[socket?.user?.id!];
    console.log("Driver Socket", isDriverSocket);
    console.log("Driver Socket",  {channelId:channelId, oldMessageId:messageId,message:message});
    io.to(isDriverSocket?.id).emit("update_queue_message_driver", {channelId:channelId, oldMessageId:messageId,message:message});
  

}

export async function messageToChannelToUser(
  io: Server,
  socket: CustomSocket,
  body: string,
  url: string | null,
  channelId: string,
  thumbnail: string | null,
  r_message_id: string | null,
  url_upload_type?: string
) {
  const findUserChannel = global.driverOpenChat.find(
    (e) => e.driverId == socket?.user?.id
  );
  if (findUserChannel) {
    const messageSave = await Message.create({
      channelId: findUserChannel.channelId || channelId,
      userProfileId: socket?.user?.id,
      groupId: socket?.user?.truck_group_id || null,
      body,
      messageDirection: "R",
      deliveryStatus: "sent",
      messageTimestampUtc: new Date(),
      senderId: socket?.user?.id,
      isRead: false,
      status: "sent",
      url: url,
      thumbnail: thumbnail || null,
      reply_message_id: r_message_id || null,
      url_upload_type: url_upload_type || "server",
    });
    const message = await Message.findOne({
      where: {
        id: messageSave.id,
      },
      include: [
        {
          model: Message,
          as: "r_message",
          include: [
            {
              model: UserProfile,
              as: "sender",
              attributes: ["id", "username", "isOnline"],
              include: [
                {
                  model: User,
                  as: "user",
                },
              ],
            },
          ],
        },
        {
          model: UserProfile,
          as: "sender",
          attributes: ["id", "username", "isOnline"],
          include: [
            {
              model: User,
              as: "user",
            },
          ],
        },
      ],
    });
    if (message) {
      const utcTime = moment.utc().toDate();
      const openStaffChatIds: string[] = [];
      //Find Active Driver With Channel
      let isCheckAnyStaffOpenChat = 0;

      const promises = Object.entries(global.staffOpenChat).map(
        async ([staffId, e]) => {
          const isSocket = global.userSockets[staffId];

          if (
            e.channelId === (findUserChannel.channelId || channelId) &&
            socket?.user?.id === e.userId
          ) {
            if (isSocket) {
              await MessageStaff.create({
                messageId: messageSave.id,
                staffId: staffId,
                driverId: socket?.user?.id,
                status: "read",
                type: "chat",
              });
              await message?.update(
                {
                  deliveryStatus: "seen",
                },
                {
                  where: {
                    id: messageSave.id,
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
                  sent_message_count: 1,
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
                  `New Message received`
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
            await MessageStaff.findOrCreate({
              where: {
                messageId: messageSave.id,
                staffId: staffId,
                driverId: socket?.user?.id,
              },
              defaults: {
                messageId: messageSave.id,
                staffId: staffId,
                driverId: socket?.user?.id,
                status: "un-read",
              },
            });
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
                  `New Message received `
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
      if (socket?.user?.truck_group_id) {
        Object.entries(global.staffOpenTruckGroup).forEach(([staffId, e]) => {
          if (
            e.channelId === channelId &&
            socket?.user?.truck_group_id == e.groupId
          ) {
            const isSocket = global.userSockets[staffId];

            if (isSocket) {
              io.to(isSocket.id).emit("receive_message_group_truck", message);
            }
          }
        });
      }
    }
    notificationQueue.add({
      title: "",
      body,
      channel_id: channelId,
      userId: findUserChannel.driverId,
      userName: `${findUserChannel.name}`,
      staffId: socket?.user?.id,
      messageId: messageSave.id,
    });
  }
}

//Message To Driver

export async function messageToDriver(
  io: Server,
  socket: CustomSocket,
  userId: string,
  body: string,
  direction: string,
  url: string | null,
  thumbnail: string | null,
  r_message_id: string | null,
  url_upload_type?: string
) {
  const findStaffActiveChannel = global.staffActiveChannel[socket?.user?.id!];

  const findDriverSocket = global.driverOpenChat.find(
    (driver) => driver?.driverId === userId
  );

  const messageSave = await Message.create({
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
    thumbnail: thumbnail || null,
    reply_message_id: r_message_id || null,
    url_upload_type: url_upload_type || "server",
  });
  const message = await Message.findOne({
    where: {
      id: messageSave.id,
    },
    include: [
      {
        model: Message,
        as: "r_message",
        include: [
          {
            model: UserProfile,
            as: "sender",
            attributes: ["id", "username", "isOnline"],
            include: [
              {
                model: User,
                as: "user",
              },
            ],
          },
        ],
      },
      {
        model: UserProfile,
        as: "sender",
        attributes: ["id", "username", "isOnline"],
      },
    ],
  });
  //Check Before send driver active room channel
  const isDriverSocket = global.userSockets[findDriverSocket?.driverId!];

  if (
    findDriverSocket &&
    findDriverSocket?.channelId == findStaffActiveChannel?.channelId
  ) {
    if (isDriverSocket) {
      await message?.update(
        {
          deliveryStatus: "seen",
        },
        {
          where: {
            id: messageSave.id,
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

          const messageCount = await UserChannel.sum("recieve_message_count", {
            where: {
              userProfileId: userId,
            },
          });

          const userGroupsCount = await GroupUser.sum("message_count", {
            where: { userProfileId: userId },
          });

          await sendNotificationToDevice(isUser.device_token, {
            title: isChannel?.name || "",
            badge: messageCount + userGroupsCount,
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
          const messageCount = await UserChannel.sum("recieve_message_count", {
            where: {
              userProfileId: userId,
            },
          });

          const userGroupsCount = await GroupUser.sum("message_count", {
            where: { userProfileId: userId },
          });
          await sendNotificationToDevice(isUser.device_token, {
            title: isChannel?.name || "",
            badge: messageCount + userGroupsCount,
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
  url: string | null,
  thumbnail: string | null,
  url_upload_type?: string
) {
  const findStaffActiveChannel = global.staffActiveChannel[socket?.user?.id!];
  const utcTime = moment.utc().toDate();
  let userIds: String[] = [];
  if (userId.length == 0) {
    const users = await GroupUser.findAll({
      where: {
        groupId: groupId,
      },
    });
    users.forEach((item) => {
      userIds.push(item.dataValues.userProfileId);
    });
  } else {
    userIds = userId.split(",");
  }
  let idsf: any = "";
  for (const driverId of userIds || []) {
    const findDriverSocket = global.driverOpenChat.find(
      (driver) => driver?.driverId === driverId
    );
    const messageSave = await Message.create({
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
      thumbnail: thumbnail || null,
      url_upload_type: url_upload_type || "server",
    });
    idsf = messageSave.id;
    const message = await Message.findOne({
      where: {
        id: messageSave.id,
      },
      include: {
        model: UserProfile,
        as: "sender",
        attributes: ["id", "username", "isOnline"],
      },
    });

    const isDriverSocket = global.userSockets[findDriverSocket?.driverId!];

    // Process each driver and emit message or update database sequentially
    if (
      findDriverSocket &&
      findDriverSocket?.channelId == findStaffActiveChannel?.channelId
    ) {
      if (isDriverSocket) {
        await messageSave.update(
          {
            deliveryStatus: "seen",
          },
          {
            where: {
              id: messageSave.id,
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
          const messageCount = await UserChannel.sum("recieve_message_count", {
            where: {
              userProfileId: userId,
            },
          });

          const userGroupsCount = await GroupUser.sum("message_count", {
            where: { userProfileId: userId },
          });
          await sendNotificationToDevice(isUser.device_token, {
            title: isChannel?.name || "",
            badge: messageCount + userGroupsCount,
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
          const messageCount = await UserChannel.sum("recieve_message_count", {
            where: {
              userProfileId: userId,
            },
          });

          const userGroupsCount = await GroupUser.sum("message_count", {
            where: { userProfileId: userId },
          });
          await sendNotificationToDevice(isUser.device_token, {
            title: isChannel?.name || "",
            badge: messageCount + userGroupsCount,
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
  await Group.update(
    {
      last_message_id: idsf,
    },
    {
      where: {
        id: groupId,
      },
    }
  );
  const group_message = await GroupMessage.create({
    groupId: groupId,
    body: body,
    senderId: socket?.user?.id,
    deliveryStatus: "sent",
    messageTimestampUtc: utcTime,
    url: url || null,
    thumbnail: thumbnail || null,
    url_upload_type: url_upload_type || "server",
  });

  const newSaveStaff = await Message.create({
    channelId: findStaffActiveChannel?.channelId,
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
    type: "default",
    thumbnail: thumbnail || null,
    url_upload_type: url_upload_type || "server",
  });

  Object.entries(global.staffOpenTruckGroup).forEach(([staffId, e]) => {
    if (
      e.channelId === findStaffActiveChannel?.channelId &&
      groupId == e.groupId
    ) {
      const isSocket = global.userSockets[staffId];

      if (isSocket) {
        io.to(isSocket.id).emit(
          SocketEvents.RECEIVE_MESSAGE_BY_GROUP,
          group_message
        );
        io.to(isSocket.id).emit("receive_message_group_truck", newSaveStaff);
      }
    }
  });
}

export async function deleteMessage(
  io: Server,
  socket: CustomSocket,
  messageId: string
) {
  if (messageId) {
    const message = await Message.findByPk(messageId);
    if (message) {
      // if(message.url){
      //   await Media.destroy({
      //     where:{
      //       key:message.url
      //     }
      //   })
      // }
    }

    await Message.destroy({
      where: {
        id: messageId,
      },
    });

    io.to(socket.id).emit("delete_message", messageId);
  }
}

export async function pinMessage(
  io: Server,
  socket: CustomSocket,
  messageId: string,
  value: string,
  type: string
) {
  if (messageId) {
    if (type == "driver") {
      await Message.update(
        {
          driverPin: value,
        },
        {
          where: {
            id: messageId,
          },
        }
      );
    } else {
      await Message.update(
        {
          staffPin: value,
        },
        {
          where: {
            id: messageId,
          },
        }
      );
    }

    io.to(socket.id).emit("pin_done", messageId, value, type);
    io.to(socket.id).emit("pin_done_web", { messageId, value, type });
  }
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
    await Message.update(
      {
        deliveryStatus: "seen",
      },
      {
        where: {
          channelId: channelId,
          userProfileId: socket?.user?.id,
          senderId: {
            [Op.ne]: socket?.user?.id,
          },
        },
      }
    );

    io.to(socket.id).emit("update_channel_message_count", channelId);
  }
}

export async function unreadAllStaffMessage(
  io: Server,
  socket: CustomSocket,
  chat_id: string,
  user_id: string,
  type: string
) {
  // console.log(chat_id, user_id, type, "staff_message");
  if (chat_id) {
    const isPrivateChat = await PrivateChatMember.findOne({
      where: {
        id: chat_id,
      },
    });

    if (type == "reciverCount") {
      await isPrivateChat?.update({
        reciverCount: 0,
      });
    }

    if (type == "senderCount") {
      await isPrivateChat?.update({
        senderCount: 0,
      });
    }

    global.userSockets[socket.user?.id!].emit("staff_chat_count_decrement", {
      type: type,
      userId: user_id,
      chat_id: chat_id,
    });

    await Message.update(
      {
        deliveryStatus: "seen",
      },
      {
        where: {
          private_chat_id: chat_id,
          userProfileId: socket.user?.id,
        },
      }
    );

    const staffChatOpen = global.staff_open_staff_chat[user_id];
    if (staffChatOpen) {
      const staffSocket = global.userSockets[user_id];
      if (staffSocket) {
        staffSocket.emit("mark_all_message_seen", {
          user_id: socket?.user?.id,
          chat_id: chat_id,
        });
      }
    }

    // io.to(socket.id).emit("update_channel_message_count", channelId);
  }
}

export async function unreadAllUserMessage(
  io: Server,
  socket: CustomSocket,
  channelId: string,
  userId: string
) {
  if (channelId) {
    await MessageStaff.update(
      {
        status: "read",
      },
      {
        where: {
          driverId: userId,
          staffId: socket?.user?.id,
          status: "un-read",
        },
      }
    );

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
  url: string | null,
  thumbnail: string | null,
  url_upload_type?: string
) {
  const group = await Group.findByPk(groupId);
  const channel = await Channel.findByPk(channelId);

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
    thumbnail: thumbnail || null,
    url_upload_type: url_upload_type || "server",
  });

  const newMessage = await Message.findByPk(message.id, {
    include: {
      model: UserProfile,
      as: "sender",
      attributes: ["id", "username", "isOnline"],
    },
  });
  const userIdActiveGroup: string[] = [];

  Object.values(global.group_open_chat[groupId]).map((e) => {
    const onlineUser = global.userSockets[e.userId];
    if (onlineUser) {
      userIdActiveGroup.push(e.userId);
      io.to(onlineUser.id).emit("new_group_message_received", newMessage);
    }
  });

  groupNotificationStaffQueue.add({
    channelId: channelId,
    groupId: groupId,
    body,
    senderId: socket?.user?.id,
  });

  Object.entries(global.staffActiveChannel).map(([key, value]) => {
    const isStaffSocket = global.userSockets[key];
    if (isStaffSocket) {
      io.to(isStaffSocket.id).emit("update_user_group_list", newMessage);

      io.to(isStaffSocket.id).emit(
        "notification_group",
        `New Group Message Received in ${group?.name} on ${channel?.name}`
      );
    }
  });

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

      groupMessageQueue.add({
        device_token: isUser?.device_token,
        userId: isUser.id,
        title: `${isGroup?.name}(Group)` || "",
        body: body,
        data: {
          groupId: isGroup?.id,
          type: "GROUP MESSAGE",
          title: `${isGroup?.name}(Group)`,
          channelId: channelId,
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
        groupId: groupId,
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
        id: groupId,
      },
    }
  );
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
          id: groupId,
        },
      }
    );

    io.to(socket.id).emit("update_group_staff_message_count", groupId);
  }
}

export async function unreadAllGroupMessageByStaffGroup(
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
          id: groupId,
        },
      }
    );
  }
}

export async function notifiyFileUploadStaffToDriver(
  io: Server,
  socket: CustomSocket,
  channelId: string,
  messageId: string,
  type: string,
  userId: string
) {
  const findUserChannel = global.driverOpenChat.find(
    (e) => e.driverId == userId && e.channelId == channelId
  );

  if (findUserChannel) {
    socket.emit("update_file_upload_status", {
      status: type,
      messageId: messageId,
    });
  }

  const promises = Object.entries(global.staffOpenChat).map(
    async ([staffId, e]) => {
      const isSocket = global.userSockets[staffId];

      if (e.channelId === channelId && socket?.user?.id === e.userId) {
        if (isSocket) {
          isSocket.emit("update_file_sent_status", {
            status: type,
            messageId: messageId,
          });
        } else {
          const userProfile = await UserProfile.findOne({
            where: {
              id: socket?.user?.id,
            },
          });
          if (userProfile) {
            if (userProfile.device_token) {
              await sendNotificationToDevice(userProfile.device_token, {
                badge: 0,
                title: "Upload Media",
                body: "Send media successfully",
                data: {},
              });
            }
          }
        }
      }
    }
  );
  await Promise.all(promises);
}

export async function notifiyFileUploadStaffToStaff(
  io: Server,
  socket: CustomSocket,
  channelId: string,
  messageId: string,
  type: string,
  userId: string,
  private_chat_id?: string
) {
  const privateChatMember = await PrivateChatMember.findOne({
    where: {
      id: private_chat_id,
    },
  });
  if (privateChatMember) {
    const staff1 = global.staff_open_staff_chat[privateChatMember.createdBy!];
    const staff2 =
      global.staff_open_staff_chat[privateChatMember.userProfileId!];

    if (staff1 == private_chat_id) {
      const staff1Socket = global.userSockets[privateChatMember.createdBy!];

      if (staff1Socket) {
        staff1Socket.emit("update_file_sent_status_staff", {
          status: type,
          messageId: messageId,
        });
      } else {
        if (privateChatMember.createdBy == userId) {
          const userProfile = await UserProfile.findOne({
            where: {
              id: privateChatMember.createdBy!,
            },
          });
          if (userProfile) {
            if (userProfile.device_token) {
              await sendNotificationToDevice(userProfile.device_token, {
                badge: 0,
                title: "Upload Media",
                body: "Send media successfully",
                data: {},
              });
            }
          }
        }
      }
    }

    if (staff2 == private_chat_id) {
      const staff2Socket = global.userSockets[privateChatMember.userProfileId!];

      if (staff2Socket) {
        staff2Socket.emit("update_file_sent_status_staff", {
          status: type,
          messageId: messageId,
        });
      } else {
        if (privateChatMember.userProfileId == userId) {
          const userProfile = await UserProfile.findOne({
            where: {
              id: privateChatMember.userProfileId!,
            },
          });
          if (userProfile) {
            if (userProfile.device_token) {
              await sendNotificationToDevice(userProfile.device_token, {
                badge: 0,
                title: "Upload Media",
                body: "Send media successfully",
                data: {},
              });
            }
          }
        }
      }
    }
  }
}

export async function notifiyFileUploadDriverToStaffGroup(
  io: Server,
  socket: CustomSocket,
  groupId: string,
  channelId: string,
  messageId: string,
  type: string,
  userId: string
) {
  let isCheckUserInGroup = true;
  Object.values(global.group_open_chat[groupId]).map((e) => {
    if (e.userId == userId) {
      isCheckUserInGroup = false;
    }
    const onlineUser = global.userSockets[e.userId];
    if (onlineUser) {
      // userIdActiveGroup.push(e.userId);
      io.to(onlineUser.id).emit("update_file_upload_status_group", {
        groupId,
        status: type,
        messageId: messageId,
      });
    }
  });
  if (isCheckUserInGroup) {
    const userProfile = await UserProfile.findOne({
      where: {
        id: userId,
      },
    });
    if (userProfile) {
      if (userProfile.device_token) {
        await sendNotificationToDevice(userProfile.device_token, {
          badge: 0,
          title: "Upload Group Media",
          body: "Send group media successfully",
          data: {},
        });
      }
    }
  }
}

export async function notifiyFileUploadDriverToStaff(
  io: Server,
  socket: CustomSocket,
  channelId: string,
  messageId: string,
  type: string,
  userId: string
) {
  const findUserChannel = global.driverOpenChat.find(
    (e) => e.driverId == socket?.user?.id && e.channelId == channelId
  );

  if (findUserChannel) {
    socket.emit("update_file_upload_status", {
      status: type,
      messageId: messageId,
    });
  } else {
    const userProfile = await UserProfile.findOne({
      where: {
        id: userId,
      },
    });
    if (userProfile) {
      if (userProfile.device_token) {
        await sendNotificationToDevice(userProfile.device_token, {
          badge: 0,
          title: "Upload Media",
          body: "Send media successfully",
          data: {},
        });
      }
    }
  }

  const promises = Object.entries(global.staffOpenChat).map(
    async ([staffId, e]) => {
      const isSocket = global.userSockets[staffId];

      if (e.channelId === channelId && socket?.user?.id === e.userId) {
        if (isSocket) {
          isSocket.emit("update_file_recivied_status", {
            status: type,
            messageId: messageId,
          });
        }
      }
    }
  );
  await Promise.all(promises);
}

export async function notifiyFileUploadTruckGroupMembers(
  io: Server,
  socket: CustomSocket,
  channelId: string,
  groupId: string,
  messageId: string,
  type: string,
  userId: string,
  groupMessageId: string
) {
  const users = await GroupUser.findAll({
    where: {
      groupId: groupId,
    },
  });
  await Promise.all(
    users.map(async (item) => {
      const findUserChannel = global.driverOpenChat.find(
        (e) =>
          e.driverId == item.dataValues.userProfileId &&
          e.channelId == channelId
      );

      if (findUserChannel) {
        const driverSocket = global.userSockets[findUserChannel.driverId];
        driverSocket.emit("update_file_upload_status", {
          status: type,
          messageId: messageId,
        });
      }
    })
  );

  const promises = Object.entries(global.staffOpenTruckGroup).map(
    async ([staffId, e]) => {
      const isSocket = global.userSockets[staffId];
      if (e.groupId == groupId && channelId == e.channelId) {
        if (isSocket) {
          isSocket.emit("update_url_status_truck_group", {
            status: type,
            messageId: groupMessageId,
          });
        }
      }
    }
  );
  await Promise.all(promises);
}

export async function sendMessageToStaffMember(
  io: Server,
  socket: CustomSocket,
  body: string,
  messageDirection: string,
  type: string,
  private_chat_id: string,
  url: string,
  thumbnail: string,
  r_message_id?: string,
  url_upload_type?: string
) {
  const onlineUserId = socket.user?.id as string;

  const privateChatFirst = await PrivateChatMember.findOne({
    where: {
      id: private_chat_id,
    },
  });

  const userProfile =
    privateChatFirst?.createdBy == onlineUserId
      ? privateChatFirst?.userProfileId
      : privateChatFirst?.createdBy;

  const activeChannel = global.staffActiveChannel[onlineUserId];

  const messageSave = await Message.create({
    channelId: activeChannel.channelId,
    userProfileId: userProfile,
    groupId: null,
    body,
    messageDirection: messageDirection,
    deliveryStatus: "sent",
    messageTimestampUtc: new Date(),
    senderId: onlineUserId,
    isRead: false,
    status: "sent",
    url: url || null,
    thumbnail: thumbnail || null,
    reply_message_id: r_message_id || null,
    url_upload_type: url_upload_type || "server",
    private_chat_id: private_chat_id,
    type: "staff_message",
  });
  const message = await Message.findOne({
    where: {
      id: messageSave.id,
    },
    include: [
      {
        model: Message,
        as: "r_message",
        include: [
          {
            model: UserProfile,
            as: "sender",
            attributes: ["id", "username", "isOnline"],
            include: [
              {
                model: User,
                as: "user",
              },
            ],
          },
        ],
      },
      {
        model: UserProfile,
        as: "sender",
        attributes: ["id", "username", "isOnline"],
      },
    ],
  });

  await PrivateChatMember.update(
    {
      last_message_id: message?.id,
    },
    {
      where: {
        id: private_chat_id,
      },
    }
  );

  const isSocket = global.userSockets[userProfile!];
  const isCheckCreatedBy = await PrivateChatMember.findOne({
    where: {
      id: private_chat_id,
    },
  });
  let notifiFactionId: string = "";
  if (isCheckCreatedBy?.createdBy == socket.user?.id) {
    const socketU = global.userSockets[isCheckCreatedBy?.userProfileId!];
    if (socketU) {
      socketU.emit("staff_chat_count_increment", {
        type: "reciverCount",
        userId: isCheckCreatedBy?.userProfileId,
        chat_id: private_chat_id,
      });
      notifiFactionId = isCheckCreatedBy?.userProfileId!;
    }
    await isCheckCreatedBy?.update({
      reciverCount: Sequelize.literal("reciverCount + 1"),
    });
  } else {
    const socketL = global.userSockets[isCheckCreatedBy?.createdBy!];
    if (socketL) {
      socketL.emit("staff_chat_count_increment", {
        type: "senderCount",
        userId: isCheckCreatedBy?.createdBy,
        chat_id: private_chat_id,
      });
      notifiFactionId = isCheckCreatedBy?.createdBy!;
    }
    await isCheckCreatedBy?.update({
      senderCount: Sequelize.literal("senderCount + 1"),
    });
  }

  if (global.staff_open_staff_chat[notifiFactionId] == private_chat_id) {
    if (isSocket) {
      await message?.update({
        deliveryStatus: "seen",
      });

      isSocket.emit("send_message_compelete", message);
    }
  } else {
    if (isSocket) {
      io.to(isSocket.id).emit(
        "notification_new_message",
        `New Message Received in Staff Chat`
      );
    }
  }
  socket.emit("send_message_compelete", message);
}
