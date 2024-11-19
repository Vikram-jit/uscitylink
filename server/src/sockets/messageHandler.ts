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
     console.log(global.staffActiveChannel,global.staffActiveChannel,global.onlineUsers)
    
      const utcTime = moment.utc().toDate();

     
      //Find Active Driver With Channel
      let isCheckAnyStaffOpenChat = 0;
      
      const promises = global.staffOpenChat.map(async (e) => {
        const isSocket = global.onlineUsers.find(
          (user) => user.id === e.staffId
        );
       
        if (
          e.channelId === findUserChannel.channelId &&
          socket?.user?.id === e.userId
        ) {
          if (isSocket) {
            await message.update({
              deliveryStatus: "seen",
            },{
              where:{
                id:message.id
              }
            })
            isCheckAnyStaffOpenChat += 1;
            io.to(isSocket.socketId).emit(
              SocketEvents.RECEIVE_MESSAGE_BY_CHANNEL,
              message
            );
            
          }
        } else {
          if (e.channelId !== findUserChannel.channelId) {
            if (isSocket) {
              const channel = await Channel.findByPk(message?.channelId);
              io.to(isSocket?.socketId).emit(
                "notification_new_message",
                `New Message received on ${channel?.name} channel`
              );
              isCheckAnyStaffOpenChat += 1;
            }
          } else {
            if (isSocket) {
              io.to(isSocket?.socketId).emit("new_message_count_update_staff", {
                channelId: message?.channelId,
                userId: message?.userProfileId,
                message,
              });
              isCheckAnyStaffOpenChat += 1;
              io.to(isSocket?.socketId).emit(
                "notification_new_message",
                `New Message received`
              );
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
        const newPromise = global.staffActiveChannel.map(async (el) => {
          const isSocket = global.onlineUsers.find(
            (user) => user.id === el.staffId
          );
          if (el.role == "staff" && el.channelId == findUserChannel.channelId) {
           
            if (isSocket) {
              
              io.to(isSocket?.socketId).emit("new_message_count_update_staff", {
                channelId: message?.channelId,
                userId: message?.userProfileId,
                message,
              });
              io.to(isSocket?.socketId).emit(
                "notification_new_message",
                `New Message received`
              );
            }
          } else {
            if (
              el.role == "staff" &&
              el.channelId != findUserChannel.channelId
            ) {
              const channel = await Channel.findByPk(message?.channelId);
              if (isSocket) {
                io.to(isSocket?.socketId).emit(
                  "notification_new_message",
                  `New Message received on ${channel?.name} channel`
                );
              }
            }
          }
        });
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
  const findStaffActiveChannel = global.staffActiveChannel.find(
    (user) => user?.staffId === socket?.user?.id
  );

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
  const isDriverSocket = global.onlineUsers.find(
    (driver) => driver?.id === findDriverSocket?.driverId
  );

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
      io.to(isDriverSocket?.socketId).emit(
        SocketEvents.RECEIVE_MESSAGE_BY_CHANNEL,
        message
      );
    }
  } else {
    if (isDriverSocket) {
      io.to(isDriverSocket?.socketId).emit("update_user_channel_list", message);
      io.to(isDriverSocket?.socketId).emit(
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
  global.staffOpenChat.map((e) => {
    if (e.channelId == findStaffActiveChannel?.channelId) {
      const isSocket = global.onlineUsers.find((user) => user.id === e.staffId);

      if (isSocket) {
        io.to(isSocket.socketId).emit(
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
    io.to(socket.id).emit("update_channel_sent_message_count", {
      channelId,
      userId,
    });
  }
}
