import { Request, Response } from "express";
import Group from "../models/Group";
import GroupChannel from "../models/GroupChannel";
import { Op } from "sequelize";
import GroupUser from "../models/GroupUser";
import { Message } from "../models/Message";
import { UserProfile } from "../models/UserProfile";
import GroupMessage from "../models/GroupMessage";
import User from "../models/User";
import { getSocketInstance } from "../sockets/socket";

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

    return res.status(201).json({
      status: true,
      message: `Group Created Successfully.`,
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

    const groupChannel = await GroupChannel.findAll({
      where: {
        channelId: req.activeChannel,
      },
    });

    const groupIds = await Promise.all(groupChannel.map((e) => e.groupId));

    const data = await Group.findAll({
      where: {
        type: type ?? "group",
        id: {
          [Op.in]: groupIds,
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

      order: type == "group" ? [["message_count", "DESC"]] : [["id", "DESC"]],
    });

    return res.status(200).json({
      status: true,
      message: `Group Fetch Successfully.`,
      data: data,
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
    if (group?.type != "group") {
      const isCheckCount = await GroupUser.findAndCountAll({
        where: {
          groupId: group?.id,
          status: "active",
        },
      });

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
    await Message.destroy({
      where: {
        groupId: req.params.id,
      },
    });
    await GroupUser.destroy({
      where: {
        groupId: req.params.id,
      },
    });
    await GroupChannel.destroy({
      where: {
        groupId: req.params.id,
      },
    });
    await GroupMessage.destroy({
      where: {
        groupId: req.params.id,
      },
    });
    await Group.destroy({
      where: {
        id: req.params.id,
      },
    });

    return res.status(201).json({
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

    const messages = await GroupMessage.findAll({
      where: {
        groupId: isGroup?.id,
      },
      include: {
        model: UserProfile,
        as: "sender",
        attributes: ["id", "username", "isOnline"],
      },
      order: [["messageTimestampUtc", "ASC"]],
    });

    return res.status(200).json({
      status: true,
      message: `Fetch message successfully`,
      data: { group: isGroup, members: isGroupMembers, messages },
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
};
