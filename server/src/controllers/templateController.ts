import { Request, Response } from "express";
import { Template } from "../models/Template";

export async function create(req: Request, res: Response): Promise<any> {
  try {
    const { name, body, url } = req.body;

    await Template.create({
      user_profile_id: req.user?.id,
      channelId: req.activeChannel,
      name: name,
      body: body,
      url: url,
    });

    return res.status(201).json({
      status: true,
      message: `Template Created Successfully.`,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function get(req: Request, res: Response): Promise<any> {
  try {
   const result  = await Template.findAll({where:{
    channelId: req.activeChannel,
   }});

    return res.status(200).json({
      status: true,
      message: `Template fetched Successfully.`,
      data:result
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}
