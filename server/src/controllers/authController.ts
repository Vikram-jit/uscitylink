import { Request, Response } from "express";
import { generateToken } from "../utils/jwt";
import User from "../models/User";
import { comparePasswords, hashPassword } from "../utils/passwordCrypto";
import Role from "../models/Role";
import { secondarySequelize } from "../sequelize";
import { QueryTypes } from "sequelize";
import { UserProfile } from "../models/UserProfile";
import {
  generateOTP,
  sendOTPEmail,
  sendOTPPhoneNumber,
} from "../utils/sendEmail";
import Otp from "../models/Otp";
import moment from "moment";
import { verifyOTP } from "../utils/OtpService";
import { AppVersions } from "../models/AppVersions";

function isValidEmail(email: string) {
  const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailPattern.test(email);
}

export const register = async (req: Request, res: Response): Promise<any> => {
  try {
    const {
      email,
      password,
      role,
      username,
      phone_number,
      yard_id,
      driver_number,
    } = req.body;

    const foundRole = await Role.findOne({ where: { name: role } });
    if (!foundRole) {
      return res
        .status(400)
        .json({ status: false, message: "Role not found." });
    }

    const emailExists = await User.findOne({ where: { email: email } });
    const phoneNumberExists = await User.findOne({
      where: { phone_number: phone_number },
    });

    if (emailExists || phoneNumberExists) {
      throw new Error("User already exists.");
    }
    const pass = password || "123456";
    const hashedPassword = await hashPassword(pass);

    const newUser = await User.create({
      email: email,
      phone_number: phone_number,
      user_type: role,
      yard_id: yard_id,
      driver_number: driver_number || null,
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

export async function updateAppVersion(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const { version, buildNumber, platform } = req.body;
   
    const appLiveVersion = await AppVersions.findOne({
      where: {
        version:version,
        buildNumber:buildNumber,
        status: "active",
        platform: platform,
      },
    });
    const userProfile = await UserProfile.findByPk(req.user?.id);
    if(appLiveVersion == null){
      await UserProfile.update(
        {
         
          appUpdate: "0",
        },
        {
          where: {
            id: req.user?.id,
          },
        })
      return res.status(200).json({
        status: true,
        data: "NewVersion",
        message: `App Update Version Successfully.`,
      });
    }

  

    if (userProfile?.buildNumber == null && userProfile?.version == null) {
      await UserProfile.update(
        {
          version: version,
          buildNumber: buildNumber,
          appUpdate: "1",
        },
        {
          where: {
            id: req.user?.id,
          },
        }
      );
      return res.status(200).json({
        status: true,
        data: "Update",
        message: `App Update Version Successfully.`,
      });
    }

    if (
      buildNumber == appLiveVersion?.buildNumber &&
      version == appLiveVersion?.version
    ) {
      if (userProfile?.appUpdate == "0") {
        await UserProfile.update(
          {
            version: version,
            buildNumber: buildNumber,
            appUpdate: "1",
          },
          {
            where: {
              id: req.user?.id,
            },
          }
        );
      }
      return res.status(200).json({
        status: true,
        data: "UpToDate",
        message: `App Update Version Successfully.`,
      });
    }

    if (
      buildNumber != appLiveVersion?.buildNumber &&
      version != appLiveVersion?.version
    ) {
      return res.status(200).json({
        status: true,
        data: "NewVersion",
        message: `App Update Version Successfully.`,
      });
    }
    if (version != appLiveVersion?.version) {
      return res.status(200).json({
        status: true,
        data: "NewVersion",
        message: `App Update Version Successfully.`,
      });
    }
    if (buildNumber != appLiveVersion?.buildNumber) {
      return res.status(200).json({
        status: true,
        data: "NewVersion",
        message: `App Update Version Successfully.`,
      });
    }
  } catch (err: any) {
    return res
      .status(400)
      .json({ status: false, message: err.message || "Internal Server Error" });
  }
}

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
      phone_number: req.body.phone_number,
      otp: otp,
      expires_at: expiresAt,
    });
    if (req.body.isEmail) {
      const response = await sendOTPEmail(req.body.email, otp);
    }

    if (req.body.isPhoneNumber) {
      await sendOTPPhoneNumber(req.body.phone_number, otp);
    }

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
      phone_number: req.body.phone_number,
      otp: otp,
      expires_at: expiresAt,
    });
    if (req.body.isEmail) {
      const response = await sendOTPEmail(req.body.email, otp);
    }

    if (req.body.isPhoneNumber) {
      await sendOTPPhoneNumber(req.body.phone_number, otp);
    }
    //  const response = await sendOTPEmail(req.body.email, otp);

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

    const isUser = await User.findAll({
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
    let userStaffId: string | null = null;
    let isProfile: any = null;
    isUser.forEach(async (item) => {
      item.profiles?.forEach((el) => {
        if (el.role?.name == "staff") {
          userStaffId = item.id;
          isProfile = el;
        }
      });
    });

    if (!isProfile) throw new Error("Invalid credentials");

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
        platform: null,
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

export async function loginWithToken(
  req: Request,
  res: Response
): Promise<any> {
  try {
    const key = "base64:ZZ5rmCRJD8S9awqHtgwN1z3WRa+UlXAoITHSrFUBZIU";

    const decodedInput = atob(req.params.token);

    // XOR Decrypt the input
    const decrypted = xorDecrypt(decodedInput, key);

    // Assuming the decrypted string format is "email_timestamp"
    const [email, timestamp] = decrypted.split("_"); // Split by the delimiter '_'
    // Check if the timestamp is valid (within the last 2 hours)
    if (!isTimestampValid(timestamp)) throw new Error("Invaild Login");

    const isRole = await Role.findOne({
      where: {
        name: "staff",
      },
    });

    const isUser = await User.findAll({
      where: {
        email: email,
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
    let userStaffId: string | null = null;
    let isProfile: any = null;
    isUser.forEach(async (item) => {
      item.profiles?.forEach((el) => {
        if (el.role?.name == "staff") {
          userStaffId = item.id;
          isProfile = el;
        }
      });
    });

    if (!isProfile) throw new Error("Inavild Login");

    const token = await generateToken(isProfile?.id!);

    return res.status(200).json({
      status: true,
      message: `Login with Successfully.`,
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

function xorDecrypt(input: string, key: string) {
  let decrypted = "";
  for (let i = 0; i < input.length; i++) {
    decrypted += String.fromCharCode(
      input.charCodeAt(i) ^ key.charCodeAt(i % key.length)
    );
  }
  return decrypted;
}

// Check if the timestamp is within the last 2 hours
function isTimestampValid(timestamp: any) {
  const currentTime = Date.now();
  const messageTime = new Date(timestamp * 1000).getTime(); // assuming the timestamp is in seconds
  const timeDifference = currentTime - messageTime;

  // Check if the timestamp is within 2 hours (2 hours = 2 * 60 * 60 * 1000 ms)
  return timeDifference <= 2 * 60 * 60 * 1000; // 2 hours
}
