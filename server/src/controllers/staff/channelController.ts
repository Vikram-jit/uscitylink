import Channel from "../../models/Channel";
import { Request, Response } from "express";
import { UserProfile } from "../../models/UserProfile";
import UserChannel from "../../models/UserChannel";
import User from "../../models/User";

export async function updateStaffActiceChannel(
  req: Request,
  res: Response
): Promise<any> {
  try {
    await UserProfile.update(
      {
        channelId: req.body?.id,
      },
      {
        where: {
          id: req.user?.id,
        },
        returning: true,
      }
    );

    return res.status(200).json({
      status: true,
      message: `Switch Channel Successfully.`,
     
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}



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
              channelId:req.activeChannel,
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



export async function addOrRemoveDriverFromChannel(req: Request, res: Response): Promise<any> {
  try {
      
    console.log(req.activeChannel)
    
    const userChannels = await UserChannel.findOne({
      where: {
        channelId: req.activeChannel,
        userProfileId:req.body.id,
        isGroup: 0,
      },
     
     });
     
    if(userChannels){
      await UserChannel.destroy({
        where:{
          id:userChannels.id
        }
      })
    }else{
      await UserChannel.create({
        channelId: req.activeChannel,
        userProfileId: req.body.id,
        last_message_utc:null
      });
    }
    
    return res.status(200).json({
      status: true,
      message: `Channel members updated Successfully.`,
    
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}