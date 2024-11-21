//Message to channel

import { Server } from "socket.io";
import { Message } from "../models/Message";
import { CustomSocket } from "./socket";
import SocketEvents from "./socketEvents";
import UserChannel from "../models/UserChannel";
import { Sequelize } from "sequelize";
import moment from "moment";
import Channel from "../models/Channel";

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
      url: url ,
    });

    if (message) {
     console.log(global.staffActiveChannel,global.staffOpenChat,global.onlineUsers)
    
      const utcTime = moment.utc().toDate();

     
      //Find Active Driver With Channel
      let isCheckAnyStaffOpenChat = 0;
      
      // const promises = global.staffOpenChat.map(async (e) => {
      //   const isSocket = global.onlineUsers.find(
      //     (user) => user.id === e.staffId
      //   );
       
      //   if (
      //     e.channelId === findUserChannel.channelId &&
      //     socket?.user?.id === e.userId
      //   ) {
      //     if (isSocket) {
      //       await message.update({
      //         deliveryStatus: "seen",
      //       },{
      //         where:{
      //           id:message.id
      //         }
      //       })
      //       isCheckAnyStaffOpenChat += 1;
      //       io.to(isSocket.socketId).emit(
      //         SocketEvents.RECEIVE_MESSAGE_BY_CHANNEL,
      //         message
      //       );
            
      //     }
      //   } else {
      //     if (e.channelId !== findUserChannel.channelId) {
      //       if (isSocket) {
      //         const channel = await Channel.findByPk(message?.channelId);
      //         io.to(isSocket?.socketId).emit(
      //           "notification_new_message",
      //           `New Message received on ${channel?.name} channel`
      //         );
      //         isCheckAnyStaffOpenChat += 1;
      //       }
      //     } else {
      //       if (isSocket) {
      //         io.to(isSocket?.socketId).emit("new_message_count_update_staff", {
      //           channelId: message?.channelId,
      //           userId: message?.userProfileId,
      //           message,
      //         });
      //         isCheckAnyStaffOpenChat += 1;
      //         io.to(isSocket?.socketId).emit(
      //           "notification_new_message",
      //           `New Message received`
      //         );
      //       }
      //     }
      //   }
      // });

      const promises = Object.entries(global.staffOpenChat).map(async ([staffId, e]) => {
        const isSocket = global.userSockets[staffId]
        // console.log(e.channelId,findUserChannel.channelId,socket.user,e.userId)
        // console.log(isSocket)
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
                  sent_message_count: Sequelize.literal("sent_message_count + 1"),
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
                  sent_message_count: Sequelize.literal("sent_message_count + 1"),
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
      });

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
            
            if (el.role == "staff" && el.channelId == findUserChannel.channelId) {
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
    url:url || null
  });

  //Check Before send driver active room channel
  const isDriverSocket = global.userSockets[findDriverSocket?.driverId!]

  if (
    findDriverSocket &&
    findDriverSocket?.channelId == findStaffActiveChannel?.channelId
  ) {
    if (isDriverSocket) {
      await message.update({
        deliveryStatus: "seen",
      },{
        where:{
          id:message.id
        }
      })
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

   const isDriverActiveChat = global.driverOpenChat.find((driver) => driver.channelId  == channelId);

    if(isDriverActiveChat){
      const isDriverSocket =  global.userSockets[isDriverActiveChat.driverId];
      console.log(isDriverActiveChat,isDriverSocket);
      if(isDriverSocket){
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
