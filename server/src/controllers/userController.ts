import { Request, Response } from "express";
import { UserProfile } from "../models/UserProfile";
import User from "../models/User";
import Role from "../models/Role";
import UserChannel from "../models/UserChannel";
import Channel from "../models/Channel";
import { Message } from "../models/Message";
import GroupUser from "../models/GroupUser";
import Group from "../models/Group";
import GroupChannel from "../models/GroupChannel";
import { secondarySequelize } from "../sequelize";
import { Op, QueryTypes, Sequelize } from "sequelize";
import { comparePasswords, hashPassword } from "../utils/passwordCrypto";
import { generateNumericPassword } from "../utils/OtpService";
import { sendNewPasswordEmail } from "../utils/sendEmail";
import { Template } from "../models/Template";
import { Training } from "../models/Training";
import moment from "moment";
import { MessageStaff } from "../models/MessageStaff";
import PrivateChatMember from "../models/PrivateChatMember";

export async function getUsers(req: Request, res: Response): Promise<any> {
  try {
    const role = req.query.role as string;

    const page = parseInt(req.query.page as string) || 1;

    const pageSize = parseInt(req.query.pageSize as string) || 5;

    const search = (req.query.search as string) || "";

    const offset = (page - 1) * pageSize;

    let whereCondition = {};
    if (role) {
      const isDriverRole = await Role.findOne({
        where: { name: role },
      });

      if (!isDriverRole) {
        return res.status(404).json({
          status: false,
          message: `Role '${role}' not found.`,
        });
      }

      whereCondition = {
        role_id: isDriverRole.id,
      };
    }

    const users = await UserProfile.findAndCountAll({
      where: {
        ...whereCondition,
        ...(page != -1 && {
          username: {
            [Op.like]: `%${search}%`,
          },
        }),
      },
      attributes: {
        exclude: ["password"],
      },
      include: [
        {
          model: User,
          as: "user",
        },
        {
          model: Role,
          as: "role",
        },
      ],

      order: [["username", "ASC"]],
      ...(page !== -1 && { limit: pageSize, offset }),
    });

    const total = users.count;
    const totalPages = Math.ceil(total / pageSize);

    return res.status(200).json({
      status: true,
      message: `Get Users Successfully.`,
      data: {
        users: users.rows,
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

export async function getChannelList(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const users = await UserChannel.findAll({
      where: {
        userProfileId: req.user?.id,
        status: "active",
      },
      include: [
        {
          model: Channel,
        },
        {
          model: Message,
          as: "last_message",
        },
      ],
      order: [["recieve_message_count", "DESC"]],
    });

    return res.status(200).json({
      status: true,
      message: `Get Users Successfully.`,
      data: users,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function getGroupList(req: Request, res: Response): Promise<any> {
  try {
    const users = await GroupUser.findAll({
      where: {
        userProfileId: req.user?.id,
        status: "active",
      },
      include: [
        {
          model: Group,
          where: {
            type: "group",
          },
          include: [
            {
              model: GroupChannel,
              as: "group_channel",
            },
          ],
        },
        {
          model: Message,
          as: "last_message",
        },
      ],
      order: [["message_count", "DESC"]],
    });

    return res.status(200).json({
      status: true,
      message: `Get Users Successfully.`,
      data: users,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function updateUserActiveChannel(
  req: Request,
  res: Response
): Promise<any> {
  try {
    await UserProfile.update(
      {
        channelId: req.body?.channelId,
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
      message: `Update Channel Successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function getUserWithoutChannel(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const type = req.query.type || "";

    const isDriverRole = await Role.findOne({
      where: {
        name: "driver",
      },
    });

    const users: any = await UserProfile.findAll({
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
    });

    const filteredUsers = users?.filter((user: any) => {
      return (
        !user.userChannels ||
        user.userChannels.length === 0 ||
        user.userChannels.some(
          (channel: any) =>
            channel.channelId === req.activeChannel &&
            channel.status == "inactive"
        )
      );
    });

    return res.status(200).json({
      status: true,
      message: `Get Driver Users Successfully.`,
      data: type == "training" ? users : filteredUsers,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function getUserProfile(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const user = await UserProfile.findByPk(req.user?.id, {
      include: [
        {
          model: User,
          as: "user",
        },
        { model: Role, as: "role" },
      ],
    });
     if(user && user?.dataValues?.user?.user_type === "driver" && user?.dataValues?.user?.yard_id){ 
     const documents = await secondarySequelize.query<any>(
      `SELECT * FROM documents WHERE item_id = :id AND type = :type`,
      {
        replacements: { id:  user?.dataValues?.user?.yard_id, type: "driver" },
        type: QueryTypes.SELECT,
      }
    );
     user!.dataValues.documents = documents;
  }
   
    return res.status(200).json({
      status: true,
      message: `Get Profile User Successfully.`,
      data: user,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function getUserProfileById(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const user = await UserProfile.findByPk(req.params?.id, {
      include: [
        {
          model: User,
          as: "user",
        },
      ],
    });

    return res.status(200).json({
      status: true,
      message: `Get Profile User Successfully.`,
      data: user,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function updateDeviceToken(
  req: Request,
  res: Response
): Promise<any> {
  try {
    await UserProfile.update(
      {
        device_token: req.body.device_token,
        platform: req.body.platform,
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
      message: `Update Device Token Successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function syncUser(req: Request, res: Response): Promise<any> {
  try {
    const isRole = await Role.findOne({
      where: {
        name: "staff",
      },
    });
    const dispatchers = await secondarySequelize.query<any>(
      `SELECT * FROM dispatches`,
      {
        type: QueryTypes.SELECT,
      }
    );

    if (Array.isArray(dispatchers)) {
      await Promise.all(
        dispatchers.map(async (e) => {
          const isCheckRegister = await User.findOne({
            where: {
              email: e.email,
            },
          });
          if (isCheckRegister) {
            await User.update(
              { yard_id: e.id, user_type: "staff" },
              {
                where: {
                  email: e.email,
                },
              }
            );
          } else {
            const isUser = await User.create({
              email: e.email,
              phone_number: e?.phone,
              status: "active",
              user_type: "staff",
              yard_id: e.id,
            });

            if (isUser) {
              const pass = "123456";
              // Hash the password
              const hashedPassword = await hashPassword(pass);
              await UserProfile.create({
                username: e.name,
                userId: isUser?.id,
                role_id: isRole?.id!,
                password: hashedPassword,
                status: "active",
              });
            }
          }
        })
      );
    }

    return res.status(200).json({
      status: true,
      message: `Update Device Token Successfully.`,
      data: dispatchers,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function syncDriver(req: Request, res: Response): Promise<any> {
  try {
    const isRole = await Role.findOne({
      where: {
        name: "driver",
      },
    });
    const drivers = await secondarySequelize.query<any>(
      `SELECT * FROM drivers`,
      {
        type: QueryTypes.SELECT,
      }
    );

    if (Array.isArray(drivers)) {
      await Promise.all(
        drivers.map(async (e) => {
          const isCheckRegister = await User.findOne({
            where: {
              email: e.email,
              user_type: "driver",
            },
          });
          if (isCheckRegister) {
            await User.update(
              {
                yard_id: e.id,
                user_type: "driver",
                driver_number: e.driver_number,
              },
              {
                where: {
                  id: isCheckRegister.id,
                },
              }
            );
          } else {
            const isUser = await User.create({
              email: e.email,
              phone_number: e?.phone_number,
              status: "active",
              user_type: "driver",
              yard_id: e.id,
              driver_number: e.driver_number,
            });

            if (isUser) {
              const pass = "123456";
              // Hash the password
              const hashedPassword = await hashPassword(pass);
              await UserProfile.create({
                username: e.name,
                userId: isUser?.id,
                role_id: isRole?.id!,
                password: hashedPassword,
                status: "active",
              });
            }
          }
        })
      );
    }

    return res.status(200).json({
      status: true,
      message: `Sync Driver Successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function changePassword(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const { old_password, new_password, confirm_password } = req.body;

    const isUser = await UserProfile.findOne({
      where: {
        id: req.user?.id,
      },
    });

    if (!isUser) throw new Error("User not found");

    const isMatch = await comparePasswords(old_password, isUser?.password!);

    if (!isMatch) throw new Error("Old Password not matched");

    if (new_password !== confirm_password)
      throw new Error("New password and Confirm password not matched");

    const hash = await hashPassword(confirm_password);

    await UserProfile.update(
      {
        password: hash,
      },
      {
        where: {
          id: req.user?.id,
        },
      }
    );

    return res.status(200).json({
      status: true,
      message: `Password updated successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function dashboard(req: Request, res: Response): Promise<any> {
  try {
   const driverId = req.user?.id;

const groupUser = await GroupUser.findOne({
  where: {
    userProfileId: driverId,
  },
  include: [
    {
      model: Group,
      where: {
        type: "truck",
        name: {
          [Op.ne]: "Mechanic",
        },
      },
    },
  ],
});

const getTruck = await secondarySequelize.query<any>(
  `SELECT * FROM trucks WHERE number = :truckNumber`,
  {
    type: QueryTypes.SELECT,
    replacements: {
      truckNumber: groupUser?.dataValues.Group?.name,
    },
  }
);
const truckId = getTruck[0]?.id;

// Get the latest inspection for this truck
const latestInspection = await secondarySequelize.query<any>(
  `SELECT * FROM daily_vehicle_inspections 
   WHERE truck_id = :id 
   ORDER BY id DESC 
   LIMIT 1`,
  {
    type: QueryTypes.SELECT,
    replacements: {
      id: truckId,
    },
  }
);
// Check if inspection was done and if 24 hours have passed
let inspectionDoneToday = false;


if (latestInspection && latestInspection.length > 0) {
  const lastInspectionTime = new Date(latestInspection[0].inspected_at);
  const now = new Date();
  
  console.log('Last inspection time:', lastInspectionTime);
  console.log('Current time:', now);
  
  // Calculate the time difference in milliseconds (absolute value to avoid negatives)
  const timeDifference = Math.abs(now.getTime() - lastInspectionTime.getTime());
  
  console.log('Time difference:', timeDifference);
  console.log('24 hours in ms:', 24 * 60 * 60 * 1000);
  
  // Check if less than 24 hours (86400000 milliseconds) have passed
  inspectionDoneToday = timeDifference < 24 * 60 * 60 * 1000;
  
  console.log('Inspection done today:', inspectionDoneToday);
}

    const userChannelCount = await UserChannel.count({
      where: {
        userProfileId: req?.user?.id,
        status: "active",
      },
    });

    const userTotalMessage = await Message.count({
      where: {
        userProfileId: req?.user?.id,
        messageDirection: "S",
        deliveryStatus: "sent",
      },
    });

    const userTotalGroups = await GroupUser.count({
      where: {
        userProfileId: req?.user?.id,
        status: "active",
      },
    });

    const groupUsers = await GroupUser.findAll({
      where: {
        userProfileId: req.user?.id,
      },
      include: [
        {
          model: Group,
          where: {
            type: "truck",
          },
          attributes: ["name"],
        },
      ],
    });
    const truckIds = groupUsers.map((e: any, index) => {
      return e?.Group?.name;
    });
    const truckCount = await secondarySequelize.query<any>(
      `SELECT COUNT(*) AS truckCount FROM trucks`,
      {
        type: QueryTypes.SELECT,
      }
    );
    const trailerCount = await secondarySequelize.query<any>(
      `SELECT COUNT(*) AS trailerCount FROM trailers`,
      {
        type: QueryTypes.SELECT,
      }
    );
    const userProfile = await UserProfile.findByPk(req.user?.id);
    const user = await User.findByPk(userProfile?.userId);
    const totalAmount = await secondarySequelize.query<any>(
      `SELECT SUM(amount) AS totalAmount
       FROM driver_pays 
       WHERE driver_id = :driverId 
      `,
      {
        replacements: {
          driverId: user?.yard_id,
        },
        type: QueryTypes.SELECT,
      }
    );

    const distinctChannelIds = await UserChannel.findAll({
      where: {
        userProfileId: req?.user?.id,
        last_message_id: { [Op.not]: null },
      },

      raw: true,
      order: [["last_message_utc", "DESC"]],
      limit: 2,
    });

    const channelIds = distinctChannelIds.map((item) => item.channelId);

    const latestMessage = await Message.findAll({
      where: {
        userProfileId: req?.user?.id,
        channelId: { [Op.in]: channelIds },
        groupId: null, // Use the dynamic groupIds
      },
      include: [
        {
          model: UserProfile,
          as: "sender",
          attributes: ["id", "username", "isOnline"],
        },
        {
          model: Channel,
          as: "channel",
          attributes: ["id", "name"],
        },
      ],
      order: [["messageTimestampUtc", "DESC"]],
      limit: 2,
    });

    // const assginedTruck = await

    const distinctGroupIds = await GroupUser.findAll({
      where: {
        userProfileId: req?.user?.id,
        last_message_id: { [Op.not]: null },
      },

      raw: true,
      order: [["updatedAt", "DESC"]],
      limit: 2,
    });

    const groupIds = distinctGroupIds.map((item) => item.groupId);

    const latestGroupMessages = await Message.findAll({
      where: {
        groupId: { [Op.in]: groupIds }, // Use the dynamic groupIds
        channelId: { [Op.not]: null },
      },
      include: [
        {
          model: UserProfile,
          as: "sender",
          attributes: ["id", "username", "isOnline"],
        },
        {
          model: Channel,
          as: "channel",
          attributes: ["id", "name"],
        },
      ],
      order: [["messageTimestampUtc", "DESC"]],
      limit: 2,
    });

    let messagesWithGroup = [];
    if (latestGroupMessages.length > 0) {
      messagesWithGroup = await Promise.all(
        latestGroupMessages.map(async (message) => {
          const group = await Group.findByPk(message?.groupId!);

          return { ...message.dataValues, group };
        })
      );
    }
    const channel = await Channel.findOne();

    const driverDocuments = await secondarySequelize.query<any>(
      `SELECT * FROM documents 
       WHERE type = 'driver' 
       AND item_id = :id 
       AND expire_date < NOW()`,
      {
        replacements: {
          id: user?.yard_id,
        },
        type: QueryTypes.SELECT,
      }
    );
    console.log(inspectionDoneToday)
    return res.status(200).json({
      status: true,
      message: `Dashboard fetch successfully.`,
      data: {
        isInspectionDone: !inspectionDoneToday,

        totalAmount: totalAmount?.[0]?.totalAmount
          ? parseFloat(totalAmount?.[0]?.totalAmount.toFixed(2))
          : 0,
        trucks: truckIds ? truckIds?.join(",") : "",
        channel: channel,
        channelCount: userChannelCount,
        messageCount: userTotalMessage,
        groupCount: userTotalGroups,
        truckCount: truckCount?.[0]?.truckCount,
        trailerCount: trailerCount?.[0]?.trailerCount,
        latestMessage,
        latestGroupMessage: messagesWithGroup,
        distinctChannelIds,
        isDocumentExpired: driverDocuments.length > 0 ? true : false,
      },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function updateProfile(req: Request, res: Response): Promise<any> {
  try {
    const yard_id = req.params?.id;
    const role = req.params?.role;

    const isUser = await User.findOne({
      where: {
        yard_id: yard_id,
        user_type: role,
      },
    });

    const isUserProfile = await UserProfile.findOne({
      where: {
        userId: isUser?.id,
      },
    });

    if (!isUserProfile) throw new Error("User not found");

    await UserProfile.update(
      {
        username: req.body.username,
        status: req.body.status,
      },
      {
        where: {
          id: isUserProfile.id,
        },
      }
    );

    await User.update(
      {
        email: req.body.email,
        phone_number: req.body.phone_number,
        status: req.body.status,
        driver_number: req.body.driver_number || isUser?.driver_number,
      },
      {
        where: {
          id: isUser?.id,
        },
      }
    );

    return res.status(200).json({
      status: true,
      message: `Update profile  successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function updateProfileByWeb(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const userId = req.params?.id;

    const isUserProfile = await UserProfile.findOne({
      where: {
        id: userId,
      },
    });

    if (!isUserProfile) throw new Error("User not found");

    await UserProfile.update(
      {
        username: req.body.username,
        status: req.body.status,
      },
      {
        where: {
          id: isUserProfile.id,
        },
      }
    );

    return res.status(200).json({
      status: true,
      message: `Update profile  successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function gernateNewPassword(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const userId = req.params?.id;

    const isUserProfile = await UserProfile.findOne({
      where: {
        id: userId,
      },
      include: [
        {
          model: User,
          as: "user",
        },
      ],
    });

    if (!isUserProfile) throw new Error("User not found");

    const password = await generateNumericPassword();

    const hash = await hashPassword(password);

    await UserProfile.update(
      {
        password: hash,
      },
      {
        where: {
          id: isUserProfile.id,
        },
      }
    );
    const user = await User.findByPk(isUserProfile?.userId);

    await sendNewPasswordEmail(user!.email!, password);

    return res.status(200).json({
      status: true,
      message: `Update profile  successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function getProfile(req: Request, res: Response): Promise<any> {
  try {
    const userProfile = await UserProfile.findByPk(req.user?.id);

    const user = await User.findByPk(userProfile?.userId || "");

    const driver = await secondarySequelize.query<any>(
      `SELECT * FROM drivers WHERE id = :id`,
      {
        replacements: {
          id: user?.yard_id,
        },
        type: QueryTypes.SELECT,
      }
    );
    const driverDocuments = await secondarySequelize.query<any>(
      `SELECT * FROM documents  WHERE  type = 'driver' AND item_id = :id`,
      {
        replacements: {
          id: user?.yard_id,
        },
        type: QueryTypes.SELECT,
      }
    );

   
    const expiredDocuments = driverDocuments.map((doc) => {
      const expiryDate = moment(doc.expire_date);
      const now = moment();
      const oneMonthLater = moment().add(1, "month");

      let status = "Valid"; // Default status

      if (expiryDate.isBefore(now)) {
        status = "Expired"; // Document already expired
      } else if (expiryDate.isBefore(oneMonthLater)) {
        status = "Expire Soon"; // Document will expire within a month
      }

      return {
        ...doc,
        expired_status: status, // Add new key
      };
    });

    const driverCountryStatus = await secondarySequelize.query<any>(
      `SELECT * FROM driver_country_statuses  WHERE driver_id = :id`,
      {
        replacements: {
          id: user?.yard_id,
        },
        type: QueryTypes.SELECT,
      }
    );
    if (driverCountryStatus?.length > 0) {
      const expiryDate = moment(driverCountryStatus?.[0].expiry_date);
      const now = moment();
      const oneMonthLater = moment().add(1, "month");

      let status = "Valid"; // Default status

      if (expiryDate.isBefore(now)) {
        status = "Expired"; // Document already expired
      } else if (expiryDate.isBefore(oneMonthLater)) {
        status = "Expire Soon"; // Document will expire within a month
      }

      expiredDocuments.push({
        title: "Country Status",
        file: driverCountryStatus?.[0].document,
        issue_date: driverCountryStatus?.[0].issue_date,
        expire_date: driverCountryStatus?.[0].expiry_date,
        created_at: driverCountryStatus?.[0].created_at,
        updated_at: driverCountryStatus?.[0].updated_at,
        doc_type: "server",
        item_id: driverCountryStatus?.[0].id,
        id: driverCountryStatus?.[0].id,
        type: driverCountryStatus?.[0].country_status,
        expired_status: status,
      });
    }

    
    return res.status(200).json({
      status: true,
      message: `Get profile from yard successfully.`,
      data: {
        driver: driver.length > 0 ? driver?.[0] : null,
        countryStatus:
          driverCountryStatus?.length > 0 ? driverCountryStatus?.[0] : null,
        document: expiredDocuments,
      },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

const formatUSDate = (date: string | Date | null) => {
  if (!date) return null;
  return new Date(date).toLocaleDateString('en-US');
};
export async function dashboardNew(req: Request, res: Response): Promise<any> {
  try {

    const userChannelCount = await Channel.count({});
    const templateCount = await Template.count({
      where: {
        channelId: req.activeChannel,
      },
    });
    const userTotalMessage = await Message.count({
      where: {
        channelId: req.activeChannel,
      },
    });

    const userUnMessage = await MessageStaff.count({
      where: {
        staffId: req.user?.id,
        status: "un-read",
        type: "chat",
      },
    });

   
    const driverCount = await User.count({
      where: {
        user_type: "driver",
      },
    });
  
    const userTotalTruckGroups = await GroupChannel.count({
      where: {
        channelId: req.activeChannel,
      },
      include: [
        {
          model: Group,
          where: {
            type: "truck",
          },
        },
      ],
    });
    const lastFiveDriver = await User.findAll({
      where: {
        user_type: "driver",
      },
      include: [
        {
          model: UserProfile,
          as: "profiles",
          attributes: ["username", "id"],
        },
      ],
      order: [["createdAt", "DESC"]],
      limit: 5,
    });

     const trucksgroup = await Group.findAll({
      where: {
        type: "truck",
      },
      include: [
        {
          model:GroupChannel,
          as:"group_channel"
        },
        {
          model:GroupUser,
          as:"group_users"
        }
      ],
      order: [["updatedAt", "DESC"]],
      limit: 5,
    });

     let onlineDrivers = await User.findAll({
  where: {
    user_type: "driver",
   
   
  },
  attributes: ["id", "phone_number", "email", "driver_number", "status", "createdAt"],
  include: [
    {
      model: UserProfile,
      as: "profiles",
      attributes: ["isOnline", "last_login","username", "id"],
      required: true, // 👈 IMPORTANT: forces join so column exists
      where:{
        isOnline:true
      }
    },
  ],
  order: [[{ model: UserProfile, as: "profiles" }, "last_login", "DESC"]],
  limit: 5,
});
// STEP 2: If online < 5 ⇒ get remaining drivers by last login
if (onlineDrivers.length < 5) {
  const needed = 5 - onlineDrivers.length;

  const fallbackDrivers = await User.findAll({
    where: {
      user_type: "driver",
     
    },
    attributes: ["id", "phone_number", "email", "driver_number", "status", "createdAt"],
    include: [
      {
        model: UserProfile,
        as: "profiles",
        attributes: ["isOnline", "last_login","username", "id"],
      }
    ],
    order: [[{ model: UserProfile, as: "profiles" }, "last_login", "DESC"]],
    limit: needed,
  });

  // MERGE THEM
  onlineDrivers = [...onlineDrivers, ...fallbackDrivers];
}

   
    return res.status(200).json({
      status: true,
      message: `Dashboard fetch successfully.`,
      data: {
        templateCount,
        truckGroupCount: userTotalTruckGroups,
        channelCount: userChannelCount,
        messageCount: userTotalMessage,
        userUnMessage,
        lastFiveDriver: lastFiveDriver,
        driverCount,
        channelId: req.activeChannel,
        onlineDrivers,
        trucksgroups:trucksgroup
    
      },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function dashboardWeb(req: Request, res: Response): Promise<any> {
  try {
    let countUnRead = 0;
    const staffUnReadCount1 = await PrivateChatMember.findAll({
      where: {
        createdBy: req.user?.id,
      },
    });

    await Promise.all(
      staffUnReadCount1.map((e) => {
        countUnRead = e.senderCount ?? 0 + countUnRead;
      })
    );

    const userChannelCount = await Channel.count({});
    const templateCount = await Template.count({
      where: {
        channelId: req.activeChannel,
      },
    });
    const trainingCount = await Training.count();
    const userTotalMessage = await Message.count({
      where: {
        channelId: req.activeChannel,
      },
    });

    const userUnMessage = await MessageStaff.count({
      where: {
        staffId: req.user?.id,
        status: "un-read",
        type: "chat",
      },
    });

    const userUnReadMessage = await getUnrepliedMessages(
      req.activeChannel || ""
    );
    const driverCount = await User.count({
      where: {
        user_type: "driver",
      },
    });
    const userTotalGroups = await GroupChannel.count({
      where: {
        channelId: req.activeChannel,
      },
      include: [
        {
          model: Group,
          where: {
            type: "group",
          },
        },
      ],
    });
    const userTotalTruckGroups = await GroupChannel.count({
      where: {
        channelId: req.activeChannel,
      },
      include: [
        {
          model: Group,
          where: {
            type: "truck",
          },
        },
      ],
    });
    const lastFiveDriver = await User.findAll({
      where: {
        user_type: "driver",
      },
      include: [
        {
          model: UserProfile,
          as: "profiles",
          attributes: ["username", "id"],
        },
      ],
      order: [["createdAt", "DESC"]],
      limit: 2,
    });
    const staffGroupCount = await Group.findOne({
      where: {
        name: "Staff",
      },
    });
    const alertGroupCount = await Group.findOne({
      where: {
        name: "Alert",
      },
    });
    return res.status(200).json({
      status: true,
      message: `Dashboard fetch successfully.`,
      data: {
        templateCount,
        trainingCount,
        truckGroupCount: userTotalTruckGroups,
        channelCount: userChannelCount,
        messageCount: userTotalMessage,
        groupCount: userTotalGroups,
        userUnMessage,
        lastFiveDriver: lastFiveDriver,
        driverCount,
        channelId: req.activeChannel,
        userUnReadMessage: userUnReadMessage,
        staffGroupCount: staffGroupCount?.message_count ?? 0,
        alertGroupCount: alertGroupCount?.message_count ?? 0,
        staffcountUnRead: countUnRead,
      },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function getUnrepliedMessagesCount(
  channelId: string
): Promise<number> {
  try {
    // Fetch all received messages (R)
    const receivedMessages = await Message.findAll({
      where: {
        channelId: channelId,
        messageDirection: "R",
        type: {
          [Op.ne]: "group",
        },
        deliveryStatus: "sent",
      },
      attributes: ["id", "userProfileId", "channelId", "createdAt"],
    });
    return receivedMessages.length;

    let unrepliedMessagesCount = 0;

    // Loop through each received message to check if it has a corresponding reply
    for (const receivedMessage of receivedMessages) {
      // Check if there is a sent message replying to this received message
      const replyExists = await Message.findOne({
        where: {
          type: {
            [Op.ne]: "group", // Exclude messages where the type is 'group'
          },
          userProfileId: receivedMessage.userProfileId,
          channelId: receivedMessage.channelId,
          messageDirection: "S", // Sent message (reply)
          createdAt: {
            [Op.gt]: receivedMessage.createdAt, // Sent message must be after the received one
          },
        },
      });

      if (!replyExists) {
        unrepliedMessagesCount += 1;
      }
      console.log(unrepliedMessagesCount);
    }

    return unrepliedMessagesCount;
  } catch (error) {
    console.error("Error counting unreplied messages:", error);
    throw new Error("Internal server error");
  }
}

export async function getUnrepliedMessages(channelId: string): Promise<any[]> {
  try {
    const receivedMessages = await Message.findAll({
      where: {
        channelId: channelId,
        messageDirection: "R",
        type: {
          [Op.ne]: "group",
        },
      },
      include: {
        model: UserProfile,
        as: "sender",
        attributes: ["id", "username", "isOnline"],
        include: [
          {
            model: User,
            as: "user",
          },
        ],
      },

      order: [["messageTimestampUtc", "DESC"]],
      limit: 2,
      // attributes: ["id", "userProfileId", "channelId", "createdAt","body"],
    });

    const unrepliedMessages: any[] = [];

    const trackedMessages = new Set(); // To track unique userProfileId and channelId combinations

    for (const receivedMessage of receivedMessages) {
      const { userProfileId, channelId } = receivedMessage;

      // Check if this combination of userProfileId and channelId has already been processed
      const messageKey = `${userProfileId}-${channelId}`;
      if (trackedMessages.has(messageKey)) {
        continue; // Skip if the combination has already been processed
      }

      // Look for a reply in the database
      const replyExists = await Message.findOne({
        where: {
          type: {
            [Op.ne]: "group", // Exclude group messages
          },
          userProfileId,
          channelId,
          messageDirection: "S", // Sent message (reply)
          createdAt: {
            [Op.gt]: receivedMessage.createdAt, // Reply should be after the received message
          },
        },
        order: [["messageTimestampUtc", "DESC"]], // Order by messageTimestampUtc
      });

      // If no reply exists, push the first message for this combination to the unrepliedMessages array
      if (!replyExists) {
        unrepliedMessages.push(receivedMessage);
        trackedMessages.add(messageKey); // Mark this combination as processed
      }
    }

    return unrepliedMessages;
  } catch (error) {
    console.error("Error fetching unreplied messages:", error);
    throw new Error("Internal server error");
  }
}
