import { Server, Socket } from "socket.io";
import { verifyToken } from "../utils/jwt";
import { UserProfile } from "../models/UserProfile";
import SocketEvents from "./socketEvents";
import { Message } from "../models/Message";
import Role from "../models/Role";
import { staffActiveChannelUpdate, staffOpenChatUpdate } from "./staffHandler";
import { driverActiveChannelUpdate } from "./driverHandler";
import { messageToChannelToUser, messageToDriver, unreadAllMessage, unreadAllUserMessage } from "./messageHandler";

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
      origin: "*",  // Allow requests from your React app (localhost:3000)
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
              global.driverOpenChat.push({
                driverId: userProfile.id,
                channelId:"",
             
              });
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
    

    console.log(onlineUsers,driverOpenChat)
    //Staff Open Chat 

    socket.on("staff_open_chat", async (userId) => await staffOpenChatUpdate(socket,userId));
    socket.on("staff_channel_update",async (channelId) => await staffActiveChannelUpdate(socket,channelId))

    socket.on("update_channel_sent_message_count",async ({channelId,userId}) => await unreadAllUserMessage(io,socket,channelId,userId))

    //driver web app

    socket.on("driver_open_chat",async (channelId) => await driverActiveChannelUpdate(socket,channelId))
    socket.on("update_channel_message_count",async (channelId) => await unreadAllMessage(io,socket,channelId))

    //sendMessage Event

    socket.on(
      SocketEvents.SEND_MESSAGE_TO_USER,
      async ({ userId, body, direction,url }) => await messageToDriver(io,socket,userId,body,direction,url)
    );

    socket.on(SocketEvents.SEND_MESSAGE_TO_CHANNEL, async ({body,url=null}) => await messageToChannelToUser(io,socket,body,url));

    socket.on("driverLogout",()=>{
      console.log("hello driver logout")
      const userId = socket?.user?.id!
      console.log("hello driver logout",userId)
    global.staffOpenChat = global.staffOpenChat.filter((chat) => chat.staffId !== userId);
   global.staffActiveChannel = global.staffActiveChannel.filter((chat) => chat.staffId !== userId);
   global.onlineUsers = global.onlineUsers.filter((user) => user.socketId !== socket?.id);
    })

    socket.on("logout",async ()=>{
      const userId = socket?.user?.id!
 
      global.staffOpenChat = global.staffOpenChat.filter((chat) => chat.staffId !== userId);
      global.staffActiveChannel = global.staffActiveChannel.filter((chat) => chat.staffId !== userId);
      global.onlineUsers = global.onlineUsers.filter((user) => user.socketId !== socket?.id);
      global.driverOpenChat = global.driverOpenChat.filter((user) => user.driverId !== userId);

      

      const isUser = await UserProfile.findByPk(userId,{
        include:[
          {
            model:Role,
            as:"role"
          }
        ]
      })

      if(isUser){
        if(isUser?.role?.name == "driver"){
         await isUser.update({
            channelId:null
          })
        }
      }

    })

    socket.on("disconnect", async() => {

      const userId = socket?.user?.id!

      global.staffOpenChat = global.staffOpenChat.filter((chat) => chat.staffId !== userId);
      global.staffActiveChannel = global.staffActiveChannel.filter((chat) => chat.staffId !== userId);
      global.onlineUsers = global.onlineUsers.filter((user) => user.socketId !== socket?.id);
      global.driverOpenChat = global.driverOpenChat.filter((user) => user.driverId !== userId);
      console.log(global.onlineUsers,global.driverOpenChat)
      const isUser = await UserProfile.findByPk(userId,{
        include:[
          {
            model:Role,
            as:"role"
          }
        ]
      })

      if(isUser){
        if(isUser?.role?.name == "driver"){
         await isUser.update({
            channelId:null
          })
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
