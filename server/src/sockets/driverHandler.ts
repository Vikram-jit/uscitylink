import { UserProfile } from "../models/UserProfile";
import { CustomSocket } from "./socket";

export async function driverActiveChannelUpdate(
    socket: CustomSocket,
    channelId: string
  ) {
    if (
      !global.driverOpenChat.find((driver) => driver.driverId === socket?.user?.id)
    ) {
      if (channelId) {
        const userProfile  = await UserProfile.findByPk(socket?.user?.id);
        global.driverOpenChat.push({
          driverId: socket?.user?.id!,
          channelId: channelId,
          name:userProfile?.username ?? ''
        });
      }
    } else {
      const existingDriver = global.driverOpenChat.find(
        (driver) => driver.driverId === socket?.user?.id
      );
  
      if (existingDriver) {
        // if (!channelId || channelId.trim() === '') {
          // If channelId is empty, remove the driver from driverOpenChat
        //   global.driverOpenChat = global.driverOpenChat.filter(
        //     (driver) => driver.driverId !== socket?.user?.id
        //   );
        //   console.log(`Removed driver ${socket?.user?.id} from driverOpenChat due to empty channelId`);
        // } else {
          // If channelId is not empty, update the channelId for the driver
          existingDriver.channelId = channelId;
          console.log(`Updated channelId for driver ${socket?.user?.id}`);
        //}
      }
    }

    await UserProfile.update(
        {
          channelId: channelId || null,
        },
        {
          where: {
            id: socket?.user?.id,
          },
        }
      );
  }
  