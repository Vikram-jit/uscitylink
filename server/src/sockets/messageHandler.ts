//Message to channel

import { Server } from "socket.io";
import { Message } from "../models/Message";
import { CustomSocket } from "./socket";
import SocketEvents from "./socketEvents";
import UserChannel from "../models/UserChannel";
import { Sequelize, where } from "sequelize";
import moment from "moment";

export async function messageToChannelToUser(
  io: Server,
  socket: CustomSocket,
  body: string
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
    });

    if (message) {
      io.to(socket?.id).emit(SocketEvents.RECEIVE_MESSAGE_BY_CHANNEL, message);
      const utcTime = moment.utc().toDate();

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

      //Find Active Driver With Channel

      global.staffOpenChat.map((e) => {
        if (e.channelId == findUserChannel.channelId) {
          const isSocket = global.onlineUsers.find(
            (user) => user.id === e.staffId
          );

          if (isSocket) {
            io.to(isSocket.socketId).emit(
              SocketEvents.RECEIVE_MESSAGE_BY_CHANNEL,
              message
            );
          }
        }
      });
    }
  }
}

//Message To Driver

export async function messageToDriver(
  io: Server,
  socket: CustomSocket,
  userId: string,
  body: string,
  direction: string
) {
  const findStaffActiveChannel = global.staffActiveChannel.find(
    (user) => user?.staffId === socket?.user?.id
  );

  const findDriverSocket = global.driverOpenChat.find(
    (driver) => driver?.driverId === userId
  );
  console.log(findDriverSocket);
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
      io.to(isDriverSocket?.socketId).emit(
        SocketEvents.RECEIVE_MESSAGE_BY_CHANNEL,
        message
      );
    }
  } else {
    console.log(isDriverSocket);
    if (isDriverSocket) {



      io.to(isDriverSocket?.socketId).emit("update_user_channel_list", message);
      io.to(isDriverSocket?.socketId).emit("new_message_count_update", message?.channelId);
      
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
  if(channelId){
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
