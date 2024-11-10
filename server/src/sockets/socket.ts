import { Server, Socket } from "socket.io";
import { verifyToken } from "../utils/jwt";
import { UserProfile } from "../models/UserProfile";
import SocketEvents from "./socketEvents";
import { Message } from "../models/Message";

let io: Server;
interface User {
  id: string;
  name: string;
  socketId: string;
}
interface StaffActiveChannel {
  staffId: string;
  channelId: string;
}
interface StaffActiveChannelUser {
  staffId: string;
  channelId: string;
  userId: string;
}
interface staffActiveChannel {
  staffId: string;
  channelId: string;
}
declare global {
  var userSockets: Record<string, Socket>;
  var socketIO: Server;
  var userActiveRoom: Record<string, string>;
  var staffActiveChannelUser: StaffActiveChannelUser[];
  var staffActiveChannel: staffActiveChannel[];
  var onlineUsers: User[];
}
export interface CustomSocket extends Socket {
  user?: { id: string; name: string }; // Define your custom user structure
}

export const initSocket = (httpServer: any) => {
  io = new Server(httpServer, {
    cors: {
      origin: "*",
      methods: ["GET", "POST"],
    },
  });

  global.userSockets = {};
  global.socketIO = io;
  global.userActiveRoom = {};
  global.onlineUsers = [];
  global.staffActiveChannelUser = [];
  global.staffActiveChannel = [];
  //Validate User Connect With Socket

  io.use(async (socket: CustomSocket, next) => {
    const token = socket.handshake.query.token as string;

    if (!token) {
      return next(new Error("Authentication error: Token is missing"));
    }

    try {
      const decoded: any = verifyToken(token);
      if (decoded?.id) {
        const userProfile = await UserProfile.findByPk(decoded.id);

        if (userProfile) {
          socket.user = {
            id: decoded.id,
            name: userProfile.username || "Unknown",
          };
          global.userSockets[userProfile.id] = socket;
          if (
            !global.onlineUsers.find((user: any) => user.id === userProfile.id)
          ) {
            global.onlineUsers.push({
              id: decoded.id,
              name: userProfile?.username || "",
              socketId: socket.id,
            });
          }
          //Check Staff Active Channel

          if (
            !global.staffActiveChannel.find(
              (user) => user.staffId === userProfile.id
            )
          ) {
            if (userProfile?.channelId) {
              global.staffActiveChannel.push({
                staffId: userProfile.id,
                channelId: userProfile?.channelId!,
              });
            }
          } else {
            const existingUser = global.staffActiveChannel.find(
              (user) => user.staffId === userProfile.id
            );

            if (existingUser) {
              existingUser.channelId = userProfile.channelId!; // Update the channelId
              console.log(`Updated channelId for staff ${userProfile.id}`);
            }
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
    console.log(global.staffActiveChannel, "staffActiveChannel");
    console.log(global.staffActiveChannelUser, "staffActiveChannelUser");
    console.log(global.userSockets)
    socket.on(SocketEvents.ACTIVE_CHANNEL, async (channelId: string) => {
      const userId = socket.user?.id;

      console.log("User Active Channel", channelId);
      console.log("User Id", userId);
      // io.emit("message", data); // Broadcast the message
    });

    socket.on("staff_active_channel_user_update", async (userId) => {
      const isFindActiveChannel = global.staffActiveChannel.find(
        (user) => user.staffId === socket?.user?.id
      );

      if (isFindActiveChannel) {
        if (
          !global.staffActiveChannelUser.find(
            (staff) => staff.staffId === socket.user?.id
          )
        ) {
          global.staffActiveChannelUser.push({
            staffId: socket.user?.id!,
            channelId: isFindActiveChannel?.channelId,
            userId: userId,
          });
        } else {
          const existingUser = global.staffActiveChannelUser.find(
            (user) => user.staffId === socket.user?.id
          );

          if (existingUser) {
            existingUser.channelId = isFindActiveChannel?.channelId!; // Update the channelId
            existingUser.userId = userId; // Update the userId
            console.log(
              `Updated channelId and userId ${isFindActiveChannel?.channelId}`
            );
          }
        }
      }
      console.log(global.staffActiveChannelUser, "staff");
    });

    //sendMessage Event

    socket.on(
      SocketEvents.SEND_MESSAGE_TO_USER,
      async ({ userId, body, direction }) => {
        // console.log(userId)
        const findUserSocket = global.onlineUsers.find(
          (user: any) => user?.id === userId
        );
        const message = await Message.create({
          channelId: "9361a441-b99d-4ff6-83b5-e59314dff472",
          userProfileId: userId,
          body,
          messageDirection: direction,
          deliveryStatus: "sent",
          messageTimestampUtc: new Date(),
          senderId: socket?.user?.id,
          isRead: false,
          status: "sent",
        });
        if (findUserSocket) {
          socket
            .to(findUserSocket?.socketId)
            .emit(SocketEvents.RECEIVE_MESSAGE_BY_CHANNEL, message);
        }
      }
    );

    //sendMessage Event

    socket.on(
      SocketEvents.SEND_MESSAGE_TO_CHANNEL,
      async ( body ) => {

        const findUserChannel = global.staffActiveChannel.find((e)=>e.staffId == socket?.user?.id)

        if(findUserChannel){
            const message = await Message.create({
                channelId: findUserChannel.channelId,
                userProfileId: findUserChannel.staffId,
                body,
                messageDirection: "R",
                deliveryStatus: "sent",
                messageTimestampUtc: new Date(),
                senderId: socket?.user?.id,
                isRead: false,
                status: "sent",
              });
      
              //Send Message To StaffActiveChannel
              global.staffActiveChannel.forEach((el) => {
                if (el.channelId == findUserChannel.channelId) {
      
                  //Check Staff is isOnline
                  const isSocketId = global.onlineUsers.find(
                    (user) => user?.socketId === el.staffId
                  );
      
                  socket
                    .to(isSocketId?.socketId!)
                    .emit(SocketEvents.RECEIVE_MESSAGE_BY_CHANNEL, message);
                }
              });

        }
        
      }
    );

    socket.on("disconnect", () => {
      console.log("User disconnected");
      // Find the user in the global.onlineUsers array based on userId
      const findUserSocket = global.onlineUsers.find(
        (user: any) => user?.socketId === socket.id
      );

      if (findUserSocket) {
        // If the user is found, remove them from global.onlineUsers
        const index = global.onlineUsers.indexOf(findUserSocket);
        if (index > -1) {
          global.onlineUsers.splice(index, 1); // Removes 1 element at the found index
          console.log(
            `User ${socket.id} removed from global.onlineUsers due to disconnection`
          );
        }
      } else {
        console.log(`User ${socket.id} not found in global.onlineUsers.`);
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
