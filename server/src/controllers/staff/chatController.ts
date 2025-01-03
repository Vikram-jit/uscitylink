import { Request, Response } from "express";
import { UserProfile } from "../../models/UserProfile";
import Channel from "../../models/Channel";
import UserChannel from "../../models/UserChannel";
import { Op } from "sequelize";
import User from "../../models/User";
import { Message } from "../../models/Message";

export async function getChatMessageUser(req: Request, res: Response): Promise<any> {
    try {
      const page = parseInt(req.query.page as string) || 1; 
      const pageSize = parseInt(req.query.pageSize as string) || 10; 
  
      const search = req.query.search as string || ''
  
      const offset = (page - 1) * pageSize;
      const data: any = await Channel.findOne({
        where: {
          id: req.activeChannel,
        },
  
      });
  
      const userChannels = await  UserChannel.findAndCountAll({
        where:{
          channelId:req.activeChannel
        },
        include: [
          {
            model: UserProfile,
            attributes: {
              exclude: ["password"],
            },
            where:{
              username: {
                [Op.like]: `%${search}%`, 
              },
            },
            include: [
              {
                model: User,
                as: "user",
              },
            ],
            
          },
          {
            model: Message,
            as: "last_message",
          },
        ],
        order: [
          [
            
            "sent_message_count",
            "DESC",
          ],
        
          [
           
            "last_message_utc",
            "DESC",
          ],
        ],
        limit: pageSize,
        offset: offset,
      })
      const total = userChannels.count;
      const totalPages = Math.ceil(total / pageSize);
      
      const newData ={
        ...data?.dataValues,
        user_channels:userChannels.rows,
        pagination: {
          currentPage: page,
          pageSize: pageSize,
          total,
          totalPages,
        }
      }
      return res.status(200).json({
        status: true,
        message: `Channel Fetch Successfully..`,
        data: newData,
      });
    } catch (err: any) {
      return res
        .status(400)
        .json({ status: false, message: err.message || "Internal Server Error" });
    }
  }

  export const getMessagesByUserId = async (
    req: Request,
    res: Response
  ): Promise<any> => {
    try {
      const { id } = req.params;
      const page = parseInt(req.query.page as string) || 1;
      const pageSize = parseInt(req.query.pageSize as string) || 10;
  
      const offset = (page - 1) * pageSize;
  
      const userProfile = await UserProfile.findByPk(id);
  
      const messages = await Message.findAndCountAll({
        where: {
          channelId: req.activeChannel,
          userProfileId: id,
          groupId: null,
        },
        include: {
          model: UserProfile,
          as: "sender",
          attributes: ["id", "username", "isOnline"],
        },
        order: [["messageTimestampUtc", "DESC"]],
        limit: pageSize,
        offset: offset,
      });
  
      const totalMessages = messages.count;
      const totalPages = Math.ceil(totalMessages / pageSize);
  
      return res.status(200).json({
        status: true,
        message: `Fetch message successfully`,
        data: {
          userProfile,
          messages: messages.rows,
          pagination: {
            currentPage: page,
            pageSize: pageSize,
            totalMessages,
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
  