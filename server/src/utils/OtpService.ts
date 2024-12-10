import { Op } from "sequelize";
import OTP from "../models/Otp";

export const verifyOTP = async (email: string, otp: string): Promise<boolean> => {
    try {
      const otpRecord = await OTP.findOne({
        where: {
          user_email: email,
          otp: otp,
          expires_at: {
            [Op.gte]: new Date(), 
          },
        },
      });
  
      if (!otpRecord) {
        throw new Error('Invalid or expired OTP');
      }
  
      // OTP is valid and not expired
      console.log(`OTP for ${email} verified successfully!`);
      return true;
    } catch (error:any) {
      console.error('Error verifying OTP:', error.message);
      return false;
    }
  };