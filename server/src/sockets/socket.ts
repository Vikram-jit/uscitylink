import { Server, Socket } from "socket.io";
import { verifyToken } from "../utils/jwt";
import { UserProfile } from "../models/UserProfile";
import SocketEvents from "./socketEvents";
import { Message } from "../models/Message";
import Role from "../models/Role";
import { staffActiveChannelUpdate, staffOpenChatUpdate } from "./staffHandler";
import { driverActiveChannelUpdate } from "./driverHandler";
import { messageToChannelToUser, messageToDriver } from "./messageHandler";

let io: Server;
interface User {
  id: string;
  name: string;
  socketId: string;
  role?: string;
}


interface staffActiveChannel {
  staffId: string;
  channelId: string;
  role: string;
}



interface driver_open_chat{
  driverId: string;
  channelId: string;
}

interface staff_open_chat{
  staffId: string;
  channelId: string;
  userId:string
}

declare global {

  var userSockets: Record<string, Socket>;
  var socketIO: Server;
  var userActiveRoom: Record<string, string>;
  var staffActiveChannel: staffActiveChannel[];
  var onlineUsers: User[];


  var driverOpenChat:driver_open_chat[];
  var staffOpenChat:staff_open_chat[];


}
export interface CustomSocket extends Socket {
  user?: { id: string; name: string }; // Define your custom user structure
}

export const initSocket = (httpServer: any) => {
  io = new Server(httpServer, {
    cors: {
      origin: "http://localhost:3000",  // Allow requests from your React app (localhost:3000)
    methods: ["GET", "POST"],
    allowedHeaders: ["Content-Type"],
    
    },
  });

  global.userSockets = {};
  global.socketIO = io;
  global.userActiveRoom = {};
  global.onlineUsers = [];
 


  global.staffActiveChannel = [];


  global.driverOpenChat = [];
  global.staffOpenChat = [];

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
          socket.user = {
            id: userProfile.id,
            name: userProfile.username || "Unknown",
          };

          global.userSockets[userProfile.id] = socket;

          //Store All onlineUsers in global variable with role
          if (
            !global.onlineUsers.find((user: any) => user.id === userProfile.id)
          ) {
          
            global.onlineUsers.push({
              id: userProfile.id,
              name: userProfile?.username || "",
              socketId: socket.id,
              role: userProfile?.role?.name || "admin",
            });
          } else {
           
            const existingUser = global.onlineUsers.find(
              (user: any) => user.id === userProfile.id
            );
          
            if (existingUser) {
              existingUser.socketId = socket.id; 
              existingUser.role = userProfile?.role?.name || "admin"; 
              console.log(`Updated socketId for user ${userProfile.id}`);
            }
          }

          //Store Staff into global variable with matched role staff with active channel

          if (
            !global.staffActiveChannel.find(
              (user) => user.staffId === userProfile.id
            ) &&
            userProfile?.role?.name === "staff"
          ) {
            if (userProfile?.channelId) {
              global.staffActiveChannel.push({
                staffId: userProfile.id,
                channelId: userProfile?.channelId!,
                role: userProfile?.role?.name,
              });
              await UserProfile.update({
                channelId:userProfile?.channelId!,
            
              },{
                where:{
                    id:userProfile.id
                }
              })
            }
          } else {
            const existingUser = global.staffActiveChannel.find(
              (user) =>
                user.staffId === userProfile.id && user.role === "driver"
            );

            if (existingUser) {
              existingUser.channelId = userProfile.channelId!; // Update the channelId
              await UserProfile.update({
                channelId:userProfile?.channelId!,
            
              },{
                where:{
                    id:userProfile.id
                }
              })
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
             
              });
              await UserProfile.update({
                channelId:userProfile?.channelId!,
            
              },{
                where:{
                    id:userProfile.id
                }
              })
            } else {
              console.log(
                `Driver ${userProfile.id} has no channelId, not added`
              );
            }
          } else {
            const existingUser = global.driverOpenChat.find(
              (user) =>
                user.driverId === userProfile.id 
            );

            if (existingUser) {
              if (existingUser.channelId !== userProfile.channelId) {
                existingUser.channelId = userProfile.channelId!;
                await UserProfile.update({
                  channelId:userProfile?.channelId!,
              
                },{
                  where:{
                      id:userProfile.id
                  }
                })
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
    


    //Staff Open Chat 

    socket.on("staff_open_chat", async (userId) => await staffOpenChatUpdate(socket,userId));
    socket.on("staff_channel_update",async (channelId) => await staffActiveChannelUpdate(socket,channelId))



    //driver web app

    socket.on("driver_open_chat",async (channelId) => await driverActiveChannelUpdate(socket,channelId))

    //sendMessage Event

    socket.on(
      SocketEvents.SEND_MESSAGE_TO_USER,
      async ({ userId, body, direction }) => await messageToDriver(io,socket,userId,body,direction)
    );

    socket.on(SocketEvents.SEND_MESSAGE_TO_CHANNEL, async (body) => await messageToChannelToUser(io,socket,body));



    socket.on("disconnect", async() => {

      // Find the user in the global.onlineUsers array based on userId
      const findUserSocket = global.onlineUsers.find(
        (user: any) => user?.socketId === socket.id
      );

      if (findUserSocket) {

         
      // await UserProfile.update(
      //   {
      //     channelId: null,
      //   },
      //   {
      //     where: {
      //       id: findUserSocket?.id,
      //     },
      //   }
      // );


        // If the user is found, remove them from global.onlineUsers
        // const index = global.onlineUsers.indexOf(findUserSocket);
        // if (index > -1) {
        //   global.onlineUsers.splice(index, 1); // Removes 1 element at the found index
        //   console.log(
        //     `User ${socket.id} removed from global.onlineUsers due to disconnection`
        //   );
        // }
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
