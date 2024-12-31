import Channel from "../../models/Channel";
import { Request, Response } from "express";
import { UserProfile } from "../../models/UserProfile";
import UserChannel from "../../models/UserChannel";
import User from "../../models/User";

export async function getChannelListWithActive(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const [channels, activeChannel] = await Promise.all([
      Channel.findAll(),
      UserProfile.findByPk(req.user?.id),
    ]);

    const newData = channels.map((channel) => ({
      ...channel.dataValues,
      isActive: activeChannel?.channelId === channel.id,
    }));

    return res.status(200).json({
      status: true,
      message: `Channel Fetch Successfully.`,
      data: newData,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function selectedChannelMembers(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const userChannels = await UserChannel.findAll({
      where: {
        channelId: req.activeChannel,
        isGroup: 0,
      },
      include: [
        {
          model: UserProfile,
          include: [
            {
              model: User,
              as: "user",
            },
          ],
        },
      ],
    });

    return res.status(200).json({
      status: true,
      message: `Channel members Fetch Successfully.`,
      data: userChannels,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function driverList(req: Request, res: Response): Promise<any> {
  try {
    let drivers = await User.findAll({
      where: {
        user_type: "driver",
      },
      include: [
        {
          model: UserProfile,
          as: "profiles",
          attributes:["id","username"]
        },
      ],
     
    });

    const newdrivers = await Promise.all(
      drivers.map(async (driver) => {
      
        let isExsit = false;
        if (driver.profiles?.length || 0 > 0) {
          const profile = await UserChannel.findOne({
            where: {
                
              userProfileId: driver.profiles?.[0]?.id,
            },
          });
          if (profile) {
            isExsit = true;
          }
        }

        return { ...driver.dataValues, isChannelExist: isExsit };
      })
    );

    return res.status(200).json({
      status: true,
      message: `Channel members Fetch Successfully.`,
      data: newdrivers.sort((a, b) => (b.isChannelExist ? 1 : 0) - (a.isChannelExist ? 1 : 0))

      
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}
