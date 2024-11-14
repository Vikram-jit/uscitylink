import { UserProfile } from "../models/UserProfile";
import { CustomSocket } from "./socket";

export async function staffActiveChannelUpdate(
  socket: CustomSocket,
  channelId: string
) {
  if (
    !global.staffActiveChannel.find((user) => user.staffId === socket?.user?.id)
  ) {
    if (channelId) {
      global.staffActiveChannel.push({
        staffId: socket?.user?.id!,
        channelId: channelId,
        role: "staff",
      });
      global.staffOpenChat = global.staffOpenChat.filter((chat) => chat.staffId !== socket?.user?.id);
    }
  } else {
    const existingUser = global.staffActiveChannel.find(
      (user) => user.staffId === socket?.user?.id
    );

    if (existingUser) {
      existingUser.channelId = channelId;
      global.staffOpenChat = global.staffOpenChat.filter((chat) => chat.staffId !== socket?.user?.id);
      console.log(`Updated channelId for staff ${socket?.user?.id}`);
    }
  }
  socket.emit("update_channel",{channelId,userId:socket?.user?.id})
  await UserProfile.update({
    channelId:channelId,

  },{
    where:{
        id:socket?.user?.id!
    }
  })
}

export async function staffOpenChatUpdate(
  socket: CustomSocket,
  userId: string
) {
  const isActiveChannel = global.staffActiveChannel.find(
    (user) => user.staffId === socket?.user?.id
  );
  if (isActiveChannel) {
    if (
      !global.staffOpenChat.find((staff) => staff.staffId === socket.user?.id)
    ) {
      global.staffOpenChat.push({
        staffId: socket.user?.id!,
        channelId: isActiveChannel?.channelId,
        userId: userId,
      });
    } else {
      const existingUser = global.staffOpenChat.find(
        (user) => user.staffId === socket.user?.id
      );

      if (existingUser) {
        existingUser.channelId = isActiveChannel?.channelId;
        existingUser.userId = userId;
       
      }
    }
  }
}
