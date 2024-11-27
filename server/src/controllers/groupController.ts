import { channelId } from "./../../node_modules/aws-sdk/clients/supportapp.d";
import { Request, Response } from "express";
import Group from "../models/Group";
import GroupChannel from "../models/GroupChannel";
import { Op } from "sequelize";
import GroupUser from "../models/GroupUser";
import { Message } from "../models/Message";
import { UserProfile } from "../models/UserProfile";
import GroupMessage from "../models/GroupMessage";
import User from "../models/User";

export async function create(req: Request, res: Response): Promise<any> {
  try {
    const { name, description, type, members } = req.body;

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
      order: [["id", "DESC"]],
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
    const group = await Group.findByPk(req.params.id);

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
    await GroupUser.destroy({
      where:{
        groupId: group?.id,
      }
    })
    if (members?.split(",")?.length > 0) {
      if (group) {
        await Promise.all(
          members?.split(",")?.map(async (e: string) => {
            const isCheck = await GroupUser.findOne({
              where:{
                groupId: group?.id,
                userProfileId: e,
              }
            });
            if (!isCheck) {
              await GroupUser.create({
                groupId: group?.id,
                userProfileId: e,
              });
            }
          })
        );
      }
    }

    return res.status(201).json({
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

export async function groupRemove(
  req: Request,
  res: Response
): Promise<any> {
  try {

    await Message.destroy({
      where:{
        groupId:req.params.id
      }
    })
    await GroupUser.destroy({
      where:{
        groupId: req.params.id
      }
    })
    await GroupChannel.destroy({
      where:{
        groupId: req.params.id
      }
    })
    await GroupMessage.destroy({
      where:{
        groupId: req.params.id
      }
    })
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

export async function groupUpdate(
  req: Request,
  res: Response
): Promise<any> {
  try {
    await Group.update({
      name:req.body.name,
      description:req.body.description
    },{
      
      where: {
        id: req.params.id,
      },
      
    });

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
          include:[
            {
              model:User,
              as:"user"
            }
          ]
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
