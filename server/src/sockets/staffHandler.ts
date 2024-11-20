import { UserProfile } from "../models/UserProfile";
import { CustomSocket } from "./socket";

export async function staffActiveChannelUpdate(
  socket: CustomSocket,
  channelId: string
) {
  const userId = socket?.user?.id!;

  // Check if the staffId already exists in the global.staffActiveChannel object
  if (!global.staffActiveChannel[userId]) {
    // If the staffId doesn't exist, add it
    if (channelId) {
      global.staffActiveChannel[userId] = {
        channelId: channelId,
        role: "staff",
      };
      // Remove from staffOpenChat if the user is being activated
      delete global.staffOpenChat[userId!]; 
    }
  } else {
    // If the staffId exists, update the channelId
    const existingUser = global.staffActiveChannel[userId];

    if (existingUser) {
      existingUser.channelId = channelId;
      // Remove from staffOpenChat if the user is being updated
      delete global.staffOpenChat[userId!]; 
      console.log(`Updated channelId for staff ${userId}`);
    }
  }

  // Emit the update to the client
  socket.emit("update_channel", { channelId, userId });

  // Update the UserProfile in the database
  await UserProfile.update(
    {
      channelId: channelId,
    },
    {
      where: {
        id: userId!,
      },
    }
  );

  console.log(global.staffActiveChannel)

}
export async function staffOpenChatUpdate(
  socket: CustomSocket,
  userId: string | null | undefined
) {

  console.log(userId,"staff_open_chat")
  const staffId = socket?.user?.id!;

  // Check if userId is empty (null or undefined)
  if (!userId) {
    // If userId is empty, remove the entry from staffOpenChat if it exists
    delete global.staffOpenChat[staffId!]; // Remove the staff entry from the object
    console.log(global.staffOpenChat,"after remove")
    return;
  }

  // Find the active channel for the current staff using the staffId (now the staffId is the key)
  const isActiveChannel = global.staffActiveChannel[staffId!];

  if (isActiveChannel) {
    // Check if this staff member does not yet have an open chat
    if (!global.staffOpenChat[staffId!]) {
      // Add a new open chat for this staff member
      global.staffOpenChat[staffId!] = {
        channelId: isActiveChannel.channelId,
        userId: userId,
      };
    } else {
      // Update the existing open chat with the new userId
      global.staffOpenChat[staffId!].channelId = isActiveChannel.channelId;
      global.staffOpenChat[staffId!].userId = userId;
    }
  }
  console.log(global.staffOpenChat)
}
