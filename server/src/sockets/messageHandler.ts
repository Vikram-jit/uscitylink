
//Message to channel

import { Server } from "socket.io";
import { Message } from "../models/Message";
import { CustomSocket } from "./socket";
import SocketEvents from "./socketEvents";

export async function messageToChannelToUser(io:Server, socket:CustomSocket,body:string) {

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
        if(message){
          io.to(socket?.id).emit(
            SocketEvents.RECEIVE_MESSAGE_BY_CHANNEL,
            message
          );
        }
         
        
        //Find Active Driver With Channel

         global.staffOpenChat.map((e)=>{
          
          if(e.channelId == findUserChannel.channelId){
            
            const isSocket = global.onlineUsers.find((user) => user.id === e.staffId)

            if(isSocket){
              io.to(isSocket.socketId).emit(
                SocketEvents.RECEIVE_MESSAGE_BY_CHANNEL,
                message
              );
            }
          }
        })
        
      }
}

//Message To Driver


export async function messageToDriver(io:Server, socket:CustomSocket,userId:string,body:string,direction:string){


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
      });

      //Check Before send driver active room channel
      console.log(findDriverSocket , findDriverSocket?.channelId , findStaffActiveChannel?.channelId)
      if (findDriverSocket && findDriverSocket?.channelId == findStaffActiveChannel?.channelId) {

        const isDriverSocket = global.onlineUsers.find(
          (driver) => driver?.id === findDriverSocket?.driverId
        );
        
        if(isDriverSocket){
          io
          .to(isDriverSocket?.socketId)
          .emit(SocketEvents.RECEIVE_MESSAGE_BY_CHANNEL, message);
        }
       
      }
    
      //Return Message To Staff After Store
      global.staffOpenChat.map((e)=>{
      
        if(e.channelId == findStaffActiveChannel?.channelId){
          const isSocket = global.onlineUsers.find((user) => user.id === e.staffId)

          if(isSocket){
            io.to(isSocket.socketId).emit(
              SocketEvents.RECEIVE_MESSAGE_BY_CHANNEL,
              message
            );
          }
        }
      })
}