import { Request, Response } from "express";
import { Message } from "../models/Message";
import { UserProfile } from "../models/UserProfile";

export const createMessage = async (req: Request, res: Response):Promise<any> => {
    try {
      const { channelId, userProfileId, groupId, body, messageDirection, deliveryStatus, senderId } = req.body;
  
      const newMessage = await Message.create({
        channelId,
        userProfileId,
        groupId,
        body,
        messageDirection,
        deliveryStatus,
        messageTimestampUtc: new Date(),
        senderId,
        isRead: false,
        status: 'sent', 
      });
  
      return res.status(201).json({
        status: true,
        message: `Message sent successfully`,
      });

    } catch (err: any) {
      return res
        .status(400)
        .json({ status: false, message: err.message || "Internal Server Error" });
    }
  };

  export const getMessages = async (req: Request, res: Response):Promise<any> => {
    try {
        
      const { channelId } = req.params;
    
      const messages = await Message.findAll({
        where:{
            channelId:channelId,
            userProfileId:req.user?.id
        },
        order: [['messageTimestampUtc', 'DESC']]
      })
  
      return res.status(200).json({
        status: true,
        message: `Fetch message successfully`,
        data:messages
      });

    } catch (err: any) {
      return res
        .status(400)
        .json({ status: false, message: err.message || "Internal Server Error" });
    }
  };

  export const getMessagesByUserId = async (req: Request, res: Response):Promise<any> => {
    try {
        
      const { id } = req.params;
    
      const userProfile = await UserProfile.findByPk(id)

      const messages = await Message.findAll({
        where:{
            channelId:req.activeChannel,
            userProfileId:id
        },
        include: {
          model: UserProfile,
          as: 'sender', 
          attributes: ['id', 'username','isOnline'], 
        },
        order: [['messageTimestampUtc', 'ASC']]
      })
  
      return res.status(200).json({
        status: true,
        message: `Fetch message successfully`,
        data:{userProfile,messages}
      });

    } catch (err: any) {
      return res
        .status(400)
        .json({ status: false, message: err.message || "Internal Server Error" });
    }
  };