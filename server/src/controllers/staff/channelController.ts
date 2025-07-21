import Channel from "../../models/Channel";
import { Request, Response } from "express";
import { UserProfile } from "../../models/UserProfile";
import UserChannel from "../../models/UserChannel";
import User from "../../models/User";
import Role from "../../models/Role";
import { MessageStaff } from "../../models/MessageStaff";
import { primarySequelize } from "../../sequelize";

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
        status: "active",
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
          attributes: ["id", "username"],
        },
      ],
      order: [
        [{ model: UserProfile, as: "profiles" }, "username", "ASC"], // Sort by username
      ],
    });

    const newdrivers = await Promise.all(
      drivers.map(async (driver) => {
        let isExsit = false;
        if (driver.profiles?.length || 0 > 0) {
          const profile = await UserChannel.findOne({
            where: {
              channelId: req.activeChannel,
              userProfileId: driver.profiles?.[0]?.id,
            },
          });
          if (profile && profile.status == "active") {
            isExsit = true;
          }
        }

        return { ...driver.dataValues, isChannelExist: isExsit };
      })
    );

    return res.status(200).json({
      status: true,
      message: `Channel members Fetch Successfully.`,
      data: newdrivers.sort(
        (a, b) => (b.isChannelExist ? 1 : 0) - (a.isChannelExist ? 1 : 0)
      ),
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function addOrRemoveDriverFromChannel(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const userChannels = await UserChannel.findOne({
      where: {
        channelId: req.activeChannel,
        userProfileId: req.body.id,
        isGroup: 0,
      },
    });

    if (userChannels) {
      await UserChannel.update(
        {
          status: userChannels.status == "active" ? "inactive" : "active",
        },
        {
          where: {
            id: userChannels.id,
          },
        }
      );
    } else {
      await UserChannel.create({
        channelId: req.activeChannel,
        userProfileId: req.body.id,
        last_message_utc: null,
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

export async function getDrivers(req: Request, res: Response): Promise<any> {
  try {
    const isDriverRole = await Role.findOne({
      where: {
        name: "driver",
      },
    });
    const page = parseInt(req.query.page as string) || 1;
    const pageSize = parseInt(req.query.pageSize as string) || 20;

    const offset = (page - 1) * pageSize;

    const users = await UserProfile.findAndCountAll({
      where: {
        role_id: isDriverRole?.id,
      },
      attributes: {
        exclude: ["password"],
      },
      include: [
        {
          model: User,
          as: "user",
          where: {
            status: "active",
          },
        },
        {
          model: Role,
          as: "role",
        },
        {
          model: UserChannel,
          as: "userChannels",
          required: false,
          where: {
            channelId: req.activeChannel,
          },
        },
      ],
      order: [["id", "DESC"]],
      limit: pageSize,
      offset: offset,
    });
    const total = users.count;
    const totalPages = Math.ceil(total / pageSize);

    return res.status(200).json({
      status: true,
      message: `Get Driver Users Successfully.`,
      data: {
        driver: users.rows,
        pagination: {
          currentPage: page,
          pageSize: pageSize,
          total,
          totalPages,
        },
      },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function markAllUnReadMessage(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const limit = parseInt(req.query.limit as string) || 100;

    await primarySequelize.transaction(async (t) => {
      const unreadMessages = await MessageStaff.findAll({
        where: {
          staffId: req.user?.id,
          status: "un-read",
        },
        limit,
        transaction: t,
        lock: t.LOCK.UPDATE,
      });

      for (const message of unreadMessages) {
        await message.update({ status: "read" }, { transaction: t });
      }
    });

    // await MessageStaff.update(
    //   {
    //     status: "read",
    //   },
    //   {
    //     where: {
    //       staffId: req.user?.id,
    //     },
    //   }
    // );
    return res.status(200).json({
      status: true,
      message: `Marked read chat successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}
