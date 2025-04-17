import { Server, Socket } from "socket.io";
import { verifyToken } from "../utils/jwt";
import { UserProfile } from "../models/UserProfile";
import SocketEvents from "./socketEvents";
import Role from "../models/Role";
import {
  staffActiveChannelUpdate,
  staffOpenChatUpdate,
  staffOpenTruckGroupUpdate,
} from "./staffHandler";
import { driverActiveChannelUpdate } from "./driverHandler";
import {
  deleteMessage,
  driverMessageQueueProcess,
  messageToChannelToUser,
  messageToDriver,
  messageToDriverByTruckGroup,
  messageToGroup,
  pinMessage,
  sendMessageToStaffMember,
  unreadAllGroupMessageByStaff,
  unreadAllGroupMessageByStaffGroup,
  unreadAllGroupMessageByUser,
  unreadAllMessage,
  unreadAllStaffMessage,
  unreadAllUserMessage,
} from "./messageHandler";
import moment from "moment";
import { AppVersions } from "../models/AppVersions";
import GroupUser from "../models/GroupUser";
import Group from "../models/Group";
import PrivateChatMember from "../models/PrivateChatMember";
import { Message } from "../models/Message";
import { Op } from "sequelize";

let io: Server;
interface User {
  name: string;
  socketId: string;
  role?: string;
}

interface staffActiveChannel {
  channelId: string;
  role: string;
  name: string;
}

interface driver_open_chat {
  driverId: string;
  channelId: string;
  name: string;
}

interface staff_open_chat {
  channelId: string;
  userId: string;
}
interface group_chat {
  channelId: string;
  userId: string;
}

interface staff_open_truck_group {
  groupId: string;
  channelId: string;
}

declare global {
  var userSockets: Record<string, Socket>;
  var socketIO: Server;
  var userActiveRoom: Record<string, string>;
  var staffActiveChannel: Record<string, staffActiveChannel>;
  var staffOpenChat: Record<string, staff_open_chat>;
  var staffOpenTruckGroup: Record<string, staff_open_truck_group>;
  var onlineUsers: Record<string, User>;
  var driverOpenChat: driver_open_chat[];
  var group_open_chat: Record<string, group_chat[]>;
  var staff_open_staff_chat: Record<string, string>;
}
export interface CustomSocket extends Socket {
  user?: { id: string; name: string; truck_group_id: string };
}

export const initSocket = (httpServer: any) => {
  io = new Server(httpServer, {
    cors: {
      origin: "*",
      methods: ["GET", "POST"],
      allowedHeaders: ["Content-Type"],
    },
  });

  global.userSockets = {};
  global.socketIO = io;
  global.userActiveRoom = {};
  global.onlineUsers = {};
  global.staffActiveChannel = {};
  global.driverOpenChat = [];
  global.staffOpenChat = {};
  global.staffOpenTruckGroup = {};
  global.group_open_chat = {};
  global.staff_open_staff_chat = {};
  //Validate User Connect With Socket
  io.use(async (socket: CustomSocket, next) => {
    const token = socket.handshake.query.token as string;

    if (!token) {
      return next(new Error("Authentication error: Token is missing"));
    }

    try {
      const decoded: any = verifyToken(token);

      if (decoded?.id) {
        const userProfile = await UserProfile.findByPk(decoded.id, {
          include: [
            {
              model: Role,
              as: "role",
            },
          ],
        });

        if (userProfile) {
          await UserProfile.update(
            {
              isOnline: true,
              last_login: moment.utc(),
            },
            {
              where: {
                id: userProfile.id,
              },
            }
          );
          const groupUser = await GroupUser.findOne({
            where: {
              userProfileId: userProfile.id,
            },
          });

          socket.user = {
            id: userProfile.id,
            name: userProfile.username || "Unknown",
            truck_group_id: groupUser ? groupUser.dataValues.groupId : "",
          };

          global.userSockets[userProfile.id] = socket;

          //Store Staff into global variable with matched role staff with active channel

          if (
            !global.staffActiveChannel[userProfile.id] &&
            userProfile?.role?.name === "staff"
          ) {
            if (userProfile?.channelId) {
              // Add staff to the global object
              global.staffActiveChannel[userProfile.id] = {
                channelId: userProfile.channelId,
                role: userProfile.role?.name,
                name: userProfile.username ?? "",
              };

              // Update the UserProfile with the channelId
              await UserProfile.update(
                {
                  channelId: userProfile?.channelId!,
                },
                {
                  where: {
                    id: userProfile.id,
                  },
                }
              );
            }
          } else {
            // Check if the user is a driver and update their channelId
            const existingUser = global.staffActiveChannel[userProfile.id];

            if (existingUser && existingUser.role === "driver") {
              existingUser.channelId = userProfile.channelId!; // Update the channelId

              // Update the UserProfile with the new channelId
              await UserProfile.update(
                {
                  channelId: userProfile?.channelId!,
                },
                {
                  where: {
                    id: userProfile.id,
                  },
                }
              );
              console.log(`Updated channelId for staff ${userProfile.id}`);
            }
          }

          //Store Driver into global variable with matched role driver
          if (
            !global.driverOpenChat.find(
              (user) => user.driverId === userProfile.id
            ) &&
            userProfile?.role?.name === "driver"
          ) {
            if (userProfile?.channelId) {
              global.driverOpenChat.push({
                driverId: userProfile.id,
                channelId: userProfile.channelId,
                name: userProfile?.username ?? "",
              });
              await UserProfile.update(
                {
                  channelId: userProfile?.channelId!,
                },
                {
                  where: {
                    id: userProfile.id,
                  },
                }
              );
            } else {
              global.driverOpenChat.push({
                driverId: userProfile.id,
                channelId: "",
                name: userProfile?.username ?? "",
              });
              console.log(
                `Driver ${userProfile.id} has no channelId, not added`
              );
            }
          } else {
            const existingUser = global.driverOpenChat.find(
              (user) => user.driverId === userProfile.id
            );

            if (existingUser) {
              if (existingUser.channelId !== userProfile.channelId) {
                existingUser.channelId = userProfile.channelId!;
                await UserProfile.update(
                  {
                    channelId: userProfile?.channelId!,
                  },
                  {
                    where: {
                      id: userProfile.id,
                    },
                  }
                );
              } else {
                console.log(
                  `Driver ${userProfile.id} already has the same channelId`
                );
              }
            } else {
              console.log(
                `Driver ${userProfile.id} not found in active channels`
              );
            }
          }
          if (userProfile.role?.name === "driver") {
            Object.entries(global.staffActiveChannel).forEach(
              ([key, value]) => {
                const isSocket = global.userSockets[key];
                if (isSocket) {
                  io.to(isSocket.id).emit("user_online", {
                    userId: key,
                    channelId: value.channelId,
                  });
                  io.to(isSocket.id).emit("user_online_driver", {
                    userId: userProfile?.id,
                    channelId: value.channelId,
                    isOnline: true,
                  });
                }
              }
            );
          }
          console.log(
            `${userProfile.username} connected with socket ID ${socket.id}`
          );
        } else {
          return next(new Error("User not found in the database"));
        }
      } else {
        return next(new Error("Authentication error: Invalid token"));
      }

      next();
    } catch (error) {
      console.error("Authentication error:", error);
      return next(new Error("Authentication error: Invalid token"));
    }
  });

  io.on("connection", (socket: CustomSocket) => {
    socket.on("group_user_add", async ({ group_id, channel_id }) => {
      const user_id = socket?.user?.id!;

      if (!group_open_chat[group_id]) {
        group_open_chat[group_id] = [];
      }

      const existingEntry = group_open_chat[group_id].find(
        (entry) => entry.userId === user_id
      );

      if (!existingEntry) {
        group_open_chat[group_id].push({
          channelId: channel_id,
          userId: user_id,
        });

        // Emit socket event to the user
        const userSocket = global.userSockets[user_id];

        if (userSocket) {
          getSocketInstance().to(userSocket.id).emit("user_added_to_group", {
            groupId: group_id,
            channelId: channel_id,
            userId: user_id,
          });
        }
      } else {
        console.log(`User ${user_id} is already in the group ${group_id}`);
      }
      console.log(global.group_open_chat);
    });

    socket.on("user_removed_from_group", (group_id) => {
      if (group_open_chat[group_id]) {
        const user_id = socket?.user?.id!;

        const updatedGroup = group_open_chat[group_id].filter(
          (entry) => entry.userId !== user_id
        );

        if (updatedGroup.length !== group_open_chat[group_id].length) {
          group_open_chat[group_id] = updatedGroup;
        } else {
          console.log(`User ${user_id} is not in the group ${group_id}`);
        }
      } else {
        console.log(`Group ${group_id} does not exist`);
      }
    });

    //Staff Open Chat

    socket.on(
      "staff_open_chat",
      async (userId) => await staffOpenChatUpdate(socket, userId)
    );
    socket.on(
      "staff_open_truck_group",
      async (groupId) => await staffOpenTruckGroupUpdate(socket, groupId)
    );
    socket.on(
      "staff_channel_update",
      async (channelId) => await staffActiveChannelUpdate(socket, channelId)
    );

    socket.on(
      "update_channel_sent_message_count",
      async ({ channelId, userId }) =>
        await unreadAllUserMessage(io, socket, channelId, userId)
    );

    socket.on(
      "update_group_staff_message_count",
      async (groupId) => await unreadAllGroupMessageByStaff(io, socket, groupId)
    );
    socket.on(
      "update_group_staff_message_count_staff",
      async (groupId) =>
        await unreadAllGroupMessageByStaffGroup(io, socket, groupId)
    );

    socket.on(
      "staff_message_send",
      async ({
        body,
        messageDirection,
        type,
        private_chat_id,
        url,
        thumbnail,
        r_message_id,
      }) =>
        await sendMessageToStaffMember(
          io,
          socket,
          body,
          messageDirection,
          type,
          private_chat_id,
          url,
          thumbnail,
          r_message_id
        )
    );

    socket.on(
      "update_group_message_count",
      async (groupId) => await unreadAllGroupMessageByUser(io, socket, groupId)
    );

    //driver web app

    socket.on(
      "driver_open_chat",
      async (channelId) => await driverActiveChannelUpdate(socket, channelId)
    );

    socket.on("get_driver_message_queue", async (data) => {
      const { channelId } = data;
      const messages = await Message.findAll({
        where: {
          channelId: channelId,
          userProfileId: socket.user?.id,
          type: {
            [Op.ne]: "group",
          },
          status: "queue",
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
              },
            ],
          },
          {
            model: UserProfile,
            as: "sender",
            attributes: ["id", "username", "isOnline"],
          },
        ],
        order: [["messageTimestampUtc", "ASC"]],
      });

      socket.emit("get_driver_messages_queues", messages);
    });

    socket.on("update_message_status_queue", async (data) => {
      const { messageId } = data;
      const message = await Message.findByPk(messageId);
      if (message) {
        await message.update({ status: "sent", groupId: socket?.user?.truck_group_id || null });
      }
    });

    socket.on(
      "update_channel_message_count",
      async (channelId) => await unreadAllMessage(io, socket, channelId)
    );

    socket.on(
      "pin_message",
      async ({ messageId, value, type }) =>
        await pinMessage(io, socket, messageId, value, type)
    );

    socket.on(
      "delete_message",
      async ({ messageId }) => await deleteMessage(io, socket, messageId)
    );
    //sendMessage Event

    socket.on(
      SocketEvents.SEND_MESSAGE_TO_USER,
      async ({ userId, body, direction, url, thumbnail, r_message_id }) =>
        await messageToDriver(
          io,
          socket,
          userId,
          body,
          direction,
          url,
          thumbnail,
          r_message_id
        )
    );

    socket.on("unread_staff_message", async ({ chat_id, user_id, type }) =>
      unreadAllStaffMessage(io, socket, chat_id, user_id, type)
    );

    socket.on(
      "UPDATE_APP_VERSION",
      async ({ version, buildNumber, platform }) => {
        try {
          const appLiveVersion = await AppVersions.findOne({
            where: {
              version: version,
              buildNumber: buildNumber,
              status: "active",
              platform: platform,
            },
          });
          const userProfile = await UserProfile.findByPk(socket?.user?.id);
          if (appLiveVersion == null) {
            await UserProfile.update(
              {
                appUpdate: "0",
              },
              {
                where: {
                  id: socket?.user?.id,
                },
              }
            );
            socket.emit("UPDATE_APP_VERSION_INFO", "NewVersion");
            return;
          }

          if (
            userProfile?.buildNumber == null &&
            userProfile?.version == null
          ) {
            await UserProfile.update(
              {
                version: version,
                buildNumber: buildNumber,
                appUpdate: "1",
              },
              {
                where: {
                  id: socket?.user?.id,
                },
              }
            );
            if (appLiveVersion == null) {
              socket.emit("UPDATE_APP_VERSION_INFO", "Update");
              return;
            }
          }

          if (
            buildNumber == appLiveVersion?.buildNumber &&
            version == appLiveVersion?.version
          ) {
            if (userProfile?.appUpdate == "0") {
              await UserProfile.update(
                {
                  version: version,
                  buildNumber: buildNumber,
                  appUpdate: "1",
                },
                {
                  where: {
                    id: socket?.user?.id,
                  },
                }
              );
            }

            socket.emit("UPDATE_APP_VERSION_INFO", "UpToDate");
            return;
          }

          if (
            buildNumber != appLiveVersion?.buildNumber &&
            version != appLiveVersion?.version
          ) {
            socket.emit("UPDATE_APP_VERSION_INFO", "NewVersion");
            return;
          }
          if (version != appLiveVersion?.version) {
            socket.emit("UPDATE_APP_VERSION_INFO", "NewVersion");
            return;
          }
          if (buildNumber != appLiveVersion?.buildNumber) {
            socket.emit("UPDATE_APP_VERSION_INFO", "NewVersion");
            return;
          }
        } catch (error) {
          console.log(error);
        }
      }
    );

    socket.on(
      SocketEvents.SEND_MESSAGE_TO_USER_BY_GROUP,
      async ({ userId, groupId, body, direction, url, thumbnail }) =>
        await messageToDriverByTruckGroup(
          io,
          socket,
          userId,
          groupId,
          body,
          direction,
          url,
          thumbnail
        )
    );

    socket.on("staff_list_update_driver_online", (data) => {});

    socket.on(
      "send_group_message",
      async ({ groupId, channelId, body, direction, url, thumbnail }) =>
        await messageToGroup(
          io,
          socket,
          groupId,
          channelId,
          body,
          direction,
          url,
          thumbnail
        )
    );

    socket.on("update_staff_open_staff_chat", (chat_id) => {
      global.staff_open_staff_chat[socket.user!.id] = chat_id;
    });

    socket.on(
      "typing_staff_to_staff_chat",
      async ({ chat_id, user_id, isTyping }) => {
        const staff = global.staffActiveChannel[socket?.user?.id!];
        const findActiveChat = global.staff_open_staff_chat[user_id];
        if (findActiveChat == chat_id) {
          const isSocket = global.userSockets[user_id];
          if (isSocket) {
            io.to(isSocket.id).emit("typingStaffChat", {
              chat_id: chat_id,
              typing: isTyping,
              message: `${staff.name} is typing...`,
            });
          }
        }
      }
    );

    socket.on(
      SocketEvents.SEND_MESSAGE_TO_CHANNEL,
      async ({ body, url = null, channelId, thumbnail, r_message_id,url_upload_type }) =>
        await messageToChannelToUser(
          io,
          socket,
          body,
          url,
          channelId,
          thumbnail,
          r_message_id,
          url_upload_type
        )
    );

    socket.on(
      "driver_message_queue",
      async ({
        messageId,
        body,
        url = null,
        channelId,
        thumbnail,
        r_message_id,
      }) =>
        await driverMessageQueueProcess(
          io,
          socket,
          messageId,
          body,
          url,
          channelId,
          thumbnail,
          r_message_id
        )
    );

    //Typing Staff Event

    socket.on("typing", (data) => {
      const staff = global.staffActiveChannel[socket?.user?.id!];
      const driver = global.driverOpenChat.find(
        (e) => e.driverId == data.userId
      );
      if (driver) {
        const isSocket = global.userSockets[driver.driverId];

        if (isSocket) {
          //driver emit typing
          io.to(isSocket.id).emit("typingStaff", {
            typing: data.isTyping,
            message: `${staff.name} is typing...`,
          });
        }
      }
    });

    socket.on("groupTyping", (data) => {
      const { groupId, isTyping } = data;

      const userName: string[] = [];
      Object.values(global.group_open_chat[groupId]).map((e) => {
        const onlineUser: any = global.userSockets[e.userId];
        if (onlineUser && e.userId == socket.user?.id) {
          userName.push(onlineUser.user?.name);
        }
      });
      Object.values(global.group_open_chat[groupId]).map((e) => {
        const onlineUser = global.userSockets[e.userId];
        if (e.userId != socket.user?.id) {
          if (onlineUser) {
            io.to(onlineUser.id).emit("groupTypingRecive", {
              userId: socket.user?.id,
              groupId: groupId,
              typing: isTyping,
              message: `${userName?.join(",")} typing...`,
            });
          }
        }
      });
    });

    socket.on("driverTyping", (data) => {
      const userId = socket?.user?.id;
      const driver = global.driverOpenChat.find((e) => e.driverId == userId);
      Object.entries(global.staffOpenChat).map(([key, value]) => {
        if (value.channelId == data.channelId && value.userId == userId) {
          const isStaffSocket = global.userSockets[key];
          let message = `User Typing....`;
          if (driver) {
            message = `${driver.name} Typing....`;
          }

          io.to(isStaffSocket.id).emit("typingUser", {
            ...data,
            userId,
            message,
          });
        }
      });
    });

    socket.on("driverLogout", () => {
      const userId = socket?.user?.id!;

      delete global.staffOpenChat[userId];
      delete global.staffActiveChannel[userId];
      delete global.userSockets[userId];

      //  global.onlineUsers = global.onlineUsers.filter((user) => user.socketId !== socket?.id);
    });

    socket.on("logout", async () => {
      const userId = socket?.user?.id!;

      delete global.staffOpenChat[userId];
      delete global.staffActiveChannel[userId];
      delete global.userSockets[userId];
      // global.onlineUsers = global.onlineUsers.filter((user) => user.socketId !== socket?.id);
      global.driverOpenChat = global.driverOpenChat.filter(
        (user) => user.driverId !== userId
      );

      const isUser = await UserProfile.findByPk(userId, {
        include: [
          {
            model: Role,
            as: "role",
          },
        ],
      });

      if (isUser) {
        if (isUser?.role?.name == "driver") {
          await isUser.update({
            isOnline: false,
            channelId: null,
            last_login: moment.utc(),
            device_token: null,
            platform: null,
          });
          Object.entries(global.staffActiveChannel).map(([key, value]) => {
            const isSocket = global.userSockets[key];
            if (isSocket) {
              io.to(isSocket.id).emit("user_online", null);
            }
          });
        } else {
          await isUser.update({
            isOnline: false,
            last_login: moment.utc(),
            device_token: null,
            platform: null,
          });
        }
      }
    });
    socket.on("reconnect_attempt", (attemptNumber) => {
      console.log(`Reconnection attempt #${attemptNumber}`);
    });

    socket.on("reconnect", () => {
      console.log("Successfully reconnected!");
    });

    socket.on("reconnect_failed", () => {
      console.log("Reconnection failed");
    });
    socket.on("ping", () => {
      console.log("Received ping from client");
      socket.emit("pong"); // Send back pong message
    });
    socket.on("disconnect", async () => {
      console.log("disconnect");
      const userId = socket?.user?.id!;

      delete global.staffOpenChat[userId];
      delete global.staffActiveChannel[userId];

      delete global.userSockets[userId];
      // global.onlineUsers = global.onlineUsers.filter((user) => user.socketId !== socket?.id);
      global.driverOpenChat = global.driverOpenChat.filter(
        (user) => user.driverId !== userId
      );

      const isUser = await UserProfile.findByPk(userId, {
        include: [
          {
            model: Role,
            as: "role",
          },
        ],
      });

      if (isUser) {
        if (isUser?.role?.name == "driver") {
          await isUser.update({
            isOnline: false,
            channelId: null,
            last_login: moment.utc(),
          });

          Object.entries(global.staffActiveChannel).map(([key, value]) => {
            const isSocket = global.userSockets[key];
            if (isSocket) {
              io.to(isSocket.id).emit("user_online", null);
              io.to(isSocket.id).emit("user_online_driver", {
                userId: socket.user?.id,
                channelId: value.channelId,
                isOnline: false,
              });
            }
          });
        } else {
          // await isUser.update({
          //   last_login: moment.utc(),
          //   device_token:"",
          //   platform:""
          // });
        }
      }
    });
  });
};

export const getSocketInstance = () => {
  if (!io) {
    throw new Error("Socket is not initialized");
  }
  return io;
};
