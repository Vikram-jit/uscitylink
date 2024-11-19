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
  userId: string | null | undefined
) {
  
  // Check if userId is empty (null or undefined)
  if (!userId) {
    // If userId is empty, remove the entry from staffOpenChat if it exists
    const index = global.staffOpenChat.findIndex(
      (chat) => chat.staffId === socket.user?.id
    );
    if (index !== -1) {
      global.staffOpenChat.splice(index, 1); // Remove the staff entry
    }
    return;
  }

  // Find the active channel for the current staff
  const isActiveChannel = global.staffActiveChannel.find(
    (user) => user.staffId === socket?.user?.id
  );

  if (isActiveChannel) {
    // Check if this staff member does not yet have an open chat
    const existingChat = global.staffOpenChat.find(
      (staff) => staff.staffId === socket.user?.id
    );

    if (!existingChat) {
      // Add a new open chat for this staff member
      global.staffOpenChat.push({
        staffId: socket.user?.id!,
        channelId: isActiveChannel.channelId,
        userId: userId,
      });
    } else {
      // Update the existing open chat with the new userId
      existingChat.channelId = isActiveChannel.channelId;
      existingChat.userId = userId;
    }
  }
}
