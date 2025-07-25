import { Request, Response } from "express";
import Group from "../models/Group";
import GroupChannel from "../models/GroupChannel";
import { Op, where } from "sequelize";
import GroupUser from "../models/GroupUser";
import { Message } from "../models/Message";
import { UserProfile } from "../models/UserProfile";
import GroupMessage from "../models/GroupMessage";
import User from "../models/User";
import { getSocketInstance } from "../sockets/socket";
import Channel from "../models/Channel";

export async function create(req: Request, res: Response): Promise<any> {
  try {
    const { name, description, type, members } = req.body;

    const isGroup = await Group.findOne({
      where: {
        name: name,
      },
    });
    if (isGroup) {
      const isCheck = await GroupChannel.findOne({
        where: {
          groupId: isGroup?.id,
          channelId: req.activeChannel,
        },
      });

      if (isCheck) throw new Error("Group already exist");
    }
    if (type != "group") {
      if (members?.split(",")?.length > 2)
        throw new Error(
          "This group currently has 2 members. To add a new member, you must disable or delete at least one existing member."
        );

      const isCheckMemebr: any = await GroupUser.findOne({
        where: {

          userProfileId: { [Op.in]: members?.split(",") },
          status:"active"
        },
        include: [
          {
            model: Group,
            where: {
              type: "truck",
            },
          },
          {
            model: UserProfile,
          },
        ],
      });
    
      if (isCheckMemebr) {
        const username = isCheckMemebr?.UserProfile?.username;
        const groupName = isCheckMemebr?.Group?.name;
        throw new Error(
          `${username ? username : "The driver"} has been added to ${
            groupName ? `the ${groupName} group` : "another group"
          }.`
        );
      }
    }
    const group = await Group.create({
      name: name,
      description: description,
      type: type,
    });

    if (members?.split(",")?.length > 0) {
      if (group) {
        await Promise.all(
          members?.split(",")?.map(async (e: string) => {
            await GroupUser.create({
              groupId: group?.id,
              userProfileId: e,
            });
          })
        );
      }
    }

    if (group) {
      await GroupChannel.create({
        groupId: group?.id,
        channelId: req.activeChannel,
      });
    }
    const memberList = members?.split(",") || [];
    if (group?.type == "group" && memberList.length > 0) {
      for (const user_id of memberList) {
        const userSocket = global.userSockets[user_id];

        try {
          const groupUser = await GroupUser.findOne({
            where: {
              userProfileId: user_id,
              groupId: group.id,
            },
            include: [
              {
                model: Group,
                include: [
                  {
                    model: GroupChannel,
                    as: "group_channel",
                  },
                ],
              },
            ],
          });

          if (userSocket && groupUser) {
            getSocketInstance()
              .to(userSocket.id)
              .emit("user_added_to_group", groupUser);
          }
        } catch (err) {
          console.error(`Error processing user ${user_id}:`, err);
        }
      }
    }
    const newGroup = await Group.findByPk(group.id, {
      include: [
        {
          model: GroupChannel,
          as: "group_channel",
        },
        {
          model: Message,
          as: "last_message",
        },
      ],
    });

    return res.status(201).json({
      status: true,
      message: `Group Created Successfully.`,
      data: newGroup,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function get(req: Request, res: Response): Promise<any> {
  try {
    const type = req.query.type as string;
    const page = parseInt(req.query.page as string) || 1;
    const pageSize = parseInt(req.query.pageSize as string) || 10;

    const search = (req.query.search as string) || "";

    const offset = (page - 1) * pageSize;

    const channel = await Channel.findByPk(req.activeChannel);

    const groupChannel = await GroupChannel.findAll({
      where: {
        channelId: req.activeChannel,
      },
    });

    const groupIds = await Promise.all(groupChannel.map((e) => e.groupId));

    const data = await Group.findAndCountAll({
      where: {
        type: type ?? "group",
        id: {
          [Op.in]: groupIds,
        },
        name: {
          [Op.like]: `%${search}%`,
        },
      },

      include: [
        {
          model: GroupChannel,
          as: "group_channel",
        },
        {
          model: Message,
          as: "last_message",
        },
      ],

      //order: type == "group" ? [["message_count", "DESC"]] : [["id", "DESC"]],
      order:
        type == "group" ? [["message_count", "DESC"]] : [["updatedAt", "DESC"]],
      limit: pageSize,
      offset: offset,
    });
    const total = data.count;
    const totalPages = Math.ceil(total / pageSize);
    const newData = {
      data: data.rows,
      channel,
      pagination: {
        currentPage: page,
        pageSize: pageSize,
        total,
        totalPages,
      },
    };
    return res.status(200).json({
      status: true,
      message: `Group Fetch Successfully.`,
      data: newData,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function getById(req: Request, res: Response): Promise<any> {
  try {
    const group = await Group.findByPk(req.params.id, {
      include: [
        {
          model: GroupChannel,
          as: "group_channel",
        },
      ],
    });

    const groupMembers = await GroupUser.findAll({
      where: {
        groupId: group?.id,
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
      message: `Group Fetch Successfully.`,
      data: { group, groupMembers },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function groupAddMember(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const group = await Group.findByPk(req.params.id);

    const { members } = req.body;

    //check member active count
    if (group?.type != "group" && group?.name?.trim() != "Mechanic") {
      const isCheckCount = await GroupUser.findAndCountAll({
        where: {
          groupId: group?.id,
          status: "active",
        },
      });
      if (
        members?.split(",")?.length > 2 &&
        group?.name?.trim() != "Mechanic"
      ) {
        throw new Error(
          "This group currently has 2 members. To add a new member, you must disable or delete at least one existing member."
        );
      }

      if (isCheckCount.count == 2)
        throw new Error(
          "This group currently has 2 members. To add a new member, you must disable or delete at least one existing member."
        );
    }

    await GroupUser.destroy({
      where: {
        groupId: group?.id,
        status: "active",
      },
    });

    if (members?.split(",")?.length > 0) {
      if (group) {
        await Promise.all(
          members?.split(",")?.map(async (e: string) => {
            const isCheck = await GroupUser.findOne({
              where: {
                groupId: group?.id,
                userProfileId: e,
              },
            });
            if (!isCheck) {
              await GroupUser.create({
                groupId: group?.id,
                userProfileId: e,
              });
            } else {
              await GroupUser.update(
                {
                  status: "active",
                },
                {
                  where: {
                    groupId: group?.id,
                    userProfileId: e,
                  },
                }
              );
            }
          })
        );
      }
    }

    if (group?.type == "group") {
      const memberList = members?.split(",") || [];
      if (memberList.length === 0) return;

      for (const user_id of memberList) {
        const userSocket = global.userSockets[user_id];

        try {
          const groupUser = await GroupUser.findOne({
            where: {
              userProfileId: user_id,
              groupId: group.id,
            },
            include: [
              {
                model: Group,
                include: [
                  {
                    model: GroupChannel,
                    as: "group_channel",
                  },
                ],
              },
            ],
          });

          if (userSocket && groupUser) {
            getSocketInstance()
              .to(userSocket.id)
              .emit("user_added_to_group", groupUser);
          }
        } catch (err) {
          console.error(`Error processing user ${user_id}:`, err);
        }
      }
    }

    return res.status(200).json({
      status: true,
      message: `Add Members Successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}
export async function groupRemoveMember(
  req: Request,
  res: Response
): Promise<any> {
  try {
    await GroupUser.destroy({
      where: {
        id: req.params.id,
      },
    });

    return res.status(201).json({
      status: true,
      message: `Deleted Members Successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function groupStatusMember(
  req: Request,
  res: Response
): Promise<any> {
  try {
    await GroupUser.update(
      { status: req.body.status },
      {
        where: {
          id: req.params.id,
        },
      }
    );

    return res.status(200).json({
      status: true,
      message: `Updated Members Successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function groupRemove(req: Request, res: Response): Promise<any> {
  try {
    await GroupUser.destroy({
      where: {
        groupId: req.params.id,
      },
    });

    await GroupMessage.destroy({
      where: {
        groupId: req.params.id,
      },
    });
    await GroupChannel.destroy({
      where: {
        groupId: req.params.id,
      },
    });
    await Message.destroy({
      where: {
        groupId: req.params.id,
      },
    });
    await Group.destroy({
      where: {
        id: req.params.id,
      },
    });

    return res.status(200).json({
      status: true,
      message: `Deleted Group Successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function groupUpdate(req: Request, res: Response): Promise<any> {
  try {
    await Group.update(
      {
        name: req.body.name,
        description: req.body.description,
      },
      {
        where: {
          id: req.params.id,
        },
      }
    );

    return res.status(201).json({
      status: true,
      message: `Updated Group Successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export const getMessagesByGroupId = async (
  req: Request,
  res: Response
): Promise<any> => {
  try {

    const { id } = req.params;
    const page = parseInt(req.query.page as string) || 1;
    const pageSize = parseInt(req.query.pageSize as string) || 10;

    const offset = (page - 1) * pageSize;
    const isGroup = await Group.findByPk(id);
    const isGroupMembers = await GroupUser.findAll({
      where: {
        groupId: isGroup?.id,
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
  const senderId = req.user?.id;
  const messages = await Message.findAndCountAll({
    where:{
      groupId:isGroup?.id,
      type:"default"
    },
    include: [
      {
        model: Message,
        as: "r_message",
        include: [
          {
            model: UserProfile,
            as: "sender",
            attributes: ["id", "username", "isOnline"],
            include: [{ model: User, as: "user" }],
          },
        ],
      },
      {
        model: UserProfile,
        as: "sender",
        attributes: ["id", "username", "isOnline"],
        include: [{ model: User, as: "user" }],
      },
    ],
    order: [["messageTimestampUtc", "DESC"]],
    limit: pageSize,
    offset: offset,
  })
   
    const totalMessages = messages.count;
    const totalPages = Math.ceil(totalMessages / pageSize);
    return res.status(200).json({
      status: true,
      message: `Fetch message successfully`,
      data: {
        senderId,
        group: isGroup,
        members: isGroupMembers,
        messages: messages.rows,
        pagination: {
          currentPage: page,
          pageSize: pageSize,
          total: totalMessages,
          totalPages,
        },
      },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
};
