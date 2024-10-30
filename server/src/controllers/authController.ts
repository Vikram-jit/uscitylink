import { Request, Response } from "express";
import { generateToken } from "../utils/jwt";
import User from "../models/User";
import { comparePasswords, hashPassword } from "../utils/passwordCrypto";
import Role from "../models/Role";
import { secondarySequelize } from "../sequelize";
import { QueryTypes } from "sequelize";
import { UserProfile } from "../models/UserProfile";

function isValidEmail(email: string) {
  const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailPattern.test(email);
}

export const register = async (req: Request, res: Response): Promise<any> => {
  try {
    const { email, password, role, username } = req.body;

    // Check if the role exists
    const foundRole = await Role.findOne({ where: { name: role } });
    if (!foundRole) {
      return res
        .status(400)
        .json({ status: false, message: "Role not found." });
    }

    const isEmailValid = isValidEmail(email);
    const queryValue = isEmailValid ? email : email; // This can be simplified

    // Check if the user already exists with the given email or phone number
    const existingUser = await User.findOne({
      where: { [isEmailValid ? "email" : "phone_number"]: queryValue },
    });

    if (existingUser) {
      // Check if the user has any profiles with the specified role
      const userWithRole = await UserProfile.findOne({
        where: { userId: existingUser.id, role_id: foundRole.id },
      });

      if (userWithRole) {
        throw new Error("User already exists with this role.");
      }
    }
     const pass = password || "123456"
    // Hash the password
    const hashedPassword = await hashPassword(pass);

    // If user does not exist, create a new user
    const newUser =
      existingUser ||
      (await User.create({
        [isEmailValid ? "email" : "phone_number"]: queryValue,
      }));

    // Create the user profile
    await UserProfile.create({
      username,
      password: hashedPassword,
      userId: newUser.id,
      isOnline: false,
      role_id: foundRole.id,
      status:"active"
    });

    return res.status(201).json({
      status: true,
      message: "Registered successfully",
    });
  } catch (error: any) {
    console.error(error);
    return res.status(500).json({ status: false, message: error?.message });
  }
};

export const login = async (req: Request, res: Response): Promise<any> => {
  try {
    const { email } = req.body;

    const isEmailValid = isValidEmail(email);
    const queryValue = isEmailValid ? email : email;

    const isUser = await User.findOne({
      where: {
        [isEmailValid ? "email" : "phone_number"]: queryValue,
      },

      include: [
        {
          model: UserProfile,
          as: "profiles",
          attributes: {
            exclude: ["password"],
          },
          include: [
            {
              model: Role,
              as: "role",
            },
          ],
        },
      ],
    });

    if (isUser) {
      return res.status(200).json({
        status: true,
        message: `Login Successfully.`,
        data: isUser,
      });
    }

    // Fetch dispatchers based on email or phone
    const dispatchers = await secondarySequelize.query<any>(
      `SELECT * FROM dispatches WHERE ${
        isEmailValid ? "email" : "phone"
      } = :value`,
      {
        replacements: { value: queryValue },
        type: QueryTypes.SELECT,
      }
    );

    // Fetch drivers based on email or phone_number
    const drivers = await secondarySequelize.query<any>(
      `SELECT * FROM drivers WHERE ${
        isEmailValid ? "email" : "phone_number"
      } = :value`,
      {
        replacements: { value: queryValue },
        type: QueryTypes.SELECT,
      }
    );

    if (dispatchers?.length === 0 && drivers?.length === 0) {
      throw new Error("Invalid credentials");
    }

    const userDetails: any =
      dispatchers.length > 0 ? dispatchers?.[0] : drivers?.[0];

    const newUser = await User.create({
      email: userDetails.email,
      phone_number:
        dispatchers.length > 0
          ? dispatchers?.[0]?.phone
          : drivers?.[0]?.phone_number,
    });

    const roleId = dispatchers.length > 0 ? "staff" : "driver"; // 2 for Dispatcher, 3 for Driver

    const role = await Role.findOne({
      where: {
        name: roleId,
      },
    });

    await UserProfile.create({
      username: userDetails.name,
      password: userDetails.password,
      userId: newUser.id,
      isOnline: false,
      role_id: role?.id!,
      status:"active"
    });

    const newUserProfile = await User.findOne({
      where: {
        [isEmailValid ? "email" : "phone_number"]: queryValue,
      },
      include: [
        {
          model: UserProfile,
          as: "profiles",
          include: [
            {
              model: Role,
              as: "role",
            },
          ],
        },
      ],
    });
    return res.status(200).json({
      status: true,
      message: `Login Successfully.`,
      data: newUserProfile,
    });
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
};

//login With Password
export async function loginWithPassword(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const { email, password, role } = req.body;

    const isEmailValid = isValidEmail(email);
    const queryValue = isEmailValid ? email : email;

    const isRole = await Role.findOne({
      where: {
        name: role,
      },
    });

    const isUser = await User.findOne({
      where: {
        [isEmailValid ? "email" : "phone_number"]: queryValue,
      },
    });

    const isProfile = await UserProfile.findOne({
      where: {
        userId: isUser?.id,
        role_id: isRole?.id,
      },

      include: [
        {
          model: Role,
          as: "role",
        },
      ],
    });

    const isMatch = await comparePasswords(password, isProfile?.password!);

    if (!isMatch) throw new Error("Invalid credentials");

    const token = await generateToken(isProfile?.id!);

    return res.status(200).json({
      status: true,
      message: `Login Successfully.`,
      data: {
        access_toke: token,
        user: isProfile,
      },
    });
  } catch (err: any) {
    return res
      .status(500)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

//Send OTP
export function sendOtp() {}

//Send Re-Send OTP
export function resendOtp() {}

//Validate OTP AND Login
export function validateOtp() {}

//login With Password
export async function loginWithWeb(req: Request, res: Response): Promise<any> {
  try {
    const { email, password } = req.body;

    const isEmailValid = isValidEmail(email);
    const queryValue = isEmailValid ? email : email;

    const isUser = await User.findOne({
      where: {
        [isEmailValid ? "email" : "phone_number"]: queryValue,
      },
    });

    if (!isUser) throw new Error("Invalid credentials");

    const isProfile = await UserProfile.findOne({
      where: {
        userId: isUser?.id,
      },

      include: [
        {
          model: Role,
          as: "role",
        },
      ],
    });

    const isMatch = await comparePasswords(password, isProfile?.password!);

    if (!isMatch) throw new Error("Invalid credentials");

    const token = await generateToken(isProfile?.id!);

    return res.status(200).json({
      status: true,
      message: `Login Successfully.`,
      data: {
        access_token: token,
        user: isProfile,
      },
    });
  } catch (err: any) {
    return res
      .status(500)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}
