import { Request, Response } from "express";
import Channel from "../models/Channel";

export async function create(req: Request, res: Response): Promise<any> {
  try {
    
    const {name,description} = req.body


    await Channel.create({
        name:name,
        description:description
    })

    return res.status(201).json({
      status: true,
      message: `Channel Created Successfully.`,
     
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function get(req: Request, res: Response): Promise<any> {
    try {
      
    
     const data = await Channel.findAll()
  
      return res.status(200).json({
        status: true,
        message: `Channel Fetch Successfully.`,
        data
      });
    } catch (err: any) {
      return res
        .status(400)
        .json({ status: false, message: err.message || "Internal Server Error" });
    }
  }
  