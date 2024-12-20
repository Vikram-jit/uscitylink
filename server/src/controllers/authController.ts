import { Request, Response } from "express";
import { generateToken } from "../utils/jwt";
import User from "../models/User";
import { comparePasswords, hashPassword } from "../utils/passwordCrypto";
import Role from "../models/Role";
import { secondarySequelize } from "../sequelize";
import { QueryTypes, where } from "sequelize";
import { UserProfile } from "../models/UserProfile";
import { generateOTP, sendOTPEmail } from "../utils/sendEmail";
import Otp from "../models/Otp";
import moment from "moment";
import { verifyOTP } from "../utils/OtpService";

function isValidEmail(email: string) {
  const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailPattern.test(email);
}

export const register = async (req: Request, res: Response): Promise<any> => {
  try {
    const { email, password, role, username, phone_number } = req.body;

    const foundRole = await Role.findOne({ where: { name: role } });
    if (!foundRole) {
      return res
        .status(400)
        .json({ status: false, message: "Role not found." });
    }

    const emailExists = await User.findOne({ where: { email: email } });
    const phoneNumberExists = await User.findOne({ where: { phone_number: phone_number } });

    if (emailExists || phoneNumberExists) {


      throw new Error("User already exists.");

    }
    const pass = password || "123456";
    const hashedPassword = await hashPassword(pass);

    const newUser = await User.create({
      "email": email,
      "phone_number": phone_number
    });

    await UserProfile.create({
      username,
      password: hashedPassword,
      userId: newUser.id,
      isOnline: false,
      role_id: foundRole.id,
      status: "active",
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
      `SELECT * FROM dispatches WHERE ${isEmailValid ? "email" : "phone"
      } = :value`,
      {
        replacements: { value: queryValue },
        type: QueryTypes.SELECT,
      }
    );

    // Fetch drivers based on email or phone_number
    const drivers = await secondarySequelize.query<any>(
      `SELECT * FROM drivers WHERE ${isEmailValid ? "email" : "phone_number"
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
      status: "active",
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
export async function sendOtp(req: Request, res: Response): Promise<any> {
  try {
    const expiresAt = moment().add(10, "minutes").toDate();
    const otp = generateOTP(6);
    await Otp.create({
      user_email: req.body.email,
      otp: otp,
      expires_at: expiresAt,
    });
    const response = await sendOTPEmail(req.body.email, otp);

    return res.status(200).json({
      status: true,
      message: `Sent Otp Successfully`,
    });
  } catch (err: any) {
    return res
      .status(500)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

//Send Re-Send OTP
export async function resendOtp(req: Request, res: Response): Promise<any> {
  try {
    const expiresAt = moment().add(10, "minutes").toDate();
    const otp = generateOTP(6);
    await Otp.create({
      user_email: req.body.email,
      otp: otp,
      expires_at: expiresAt,
    });
    const response = await sendOTPEmail(req.body.email, otp);

    return res.status(200).json({
      status: true,
      message: `Re-Sent Otp Successfully`,
    });
  } catch (err: any) {
    return res
      .status(500)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }

}

//Validate OTP AND Login
export async function validateOtp(req: Request, res: Response): Promise<any> {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      throw new Error("Email and OTP are required");

    }

    const isVerified = await verifyOTP(email, otp);
    if (!isVerified) {
      throw new Error("Invalid or expired OTP");
    }

    const isEmailValid = isValidEmail(email);
    const isUser = await User.findOne({
      where: {
        [isEmailValid ? "email" : "phone_number"]: email,
      },
    });

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

    const token = await generateToken(isProfile?.id!);

    return res.status(200).json({
      status: true,
      message: `OTP verified successfully`,
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


export async function logout(req: Request, res: Response): Promise<any> {
  try {

    await UserProfile.update(
      {
        device_token: null,
        platform: null
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
      message: `Logout Successfully.`,

    });
  } catch (err: any) {
    return res
      .status(500)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}
