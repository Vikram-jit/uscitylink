import { Server, Socket } from "socket.io";
import { verifyToken } from "../utils/jwt";
import { UserProfile } from "../models/UserProfile";
import SocketEvents from "./socketEvents";
import { Message } from "../models/Message";
import Role from "../models/Role";
import {
  staffActiveChannelUpdate,
  staffOpenChatUpdate,
  staffOpenTruckGroupUpdate,
} from "./staffHandler";
import { driverActiveChannelUpdate } from "./driverHandler";
import {
  messageToChannelToUser,
  messageToDriver,
  messageToDriverByTruckGroup,
  messageToGroup,
  unreadAllGroupMessageByStaff,
  unreadAllGroupMessageByUser,
  unreadAllMessage,
  unreadAllUserMessage,
} from "./messageHandler";
import moment from "moment";
import { disconnect } from "process";

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
}
export interface CustomSocket extends Socket {
  user?: { id: string; name: string }; // Define your custom user structure
}

export const initSocket = (httpServer: any) => {
  io = new Server(httpServer, {
    cors: {
      origin: "*", // Allow requests from your React app (localhost:3000)
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

          socket.user = {
            id: userProfile.id,
            name: userProfile.username || "Unknown",
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
      console.log(group_open_chat);
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
      "update_group_message_count",
      async (groupId) => await unreadAllGroupMessageByUser(io, socket, groupId)
    );

    //driver web app

    socket.on(
      "driver_open_chat",
      async (channelId) => await driverActiveChannelUpdate(socket, channelId)
    );
    socket.on(
      "update_channel_message_count",
      async (channelId) => await unreadAllMessage(io, socket, channelId)
    );

    //sendMessage Event

    socket.on(
      SocketEvents.SEND_MESSAGE_TO_USER,
      async ({ userId, body, direction, url }) =>
        await messageToDriver(io, socket, userId, body, direction, url)
    );

    socket.on(
      SocketEvents.SEND_MESSAGE_TO_USER_BY_GROUP,
      async ({ userId, groupId, body, direction, url }) =>
        await messageToDriverByTruckGroup(
          io,
          socket,
          userId,
          groupId,
          body,
          direction,
          url
        )
    );

    socket.on(
      "send_group_message",
      async ({ groupId, channelId, body, direction, url }) =>
        await messageToGroup(
          io,
          socket,
          groupId,
          channelId,
          body,
          direction,
          url
        )
    );

    socket.on(
      SocketEvents.SEND_MESSAGE_TO_CHANNEL,
      async ({ body, url = null }) =>
        await messageToChannelToUser(io, socket, body, url)
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
      console.log(userId,"socket logout")
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
            platform: null
          });
          Object.entries(global.staffActiveChannel).map(([key, value]) => {
            const isSocket = global.userSockets[key];
            if (isSocket) {
              io.to(isSocket.id).emit("user_online", null);
            }
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
