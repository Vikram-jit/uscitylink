import { Request, Response } from "express";
import { UserProfile } from "../models/UserProfile";
import User from "../models/User";
import Role from "../models/Role";

export async function getUsers(req: Request, res: Response): Promise<any> {
  try {
    const users = await UserProfile.findAll({
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
