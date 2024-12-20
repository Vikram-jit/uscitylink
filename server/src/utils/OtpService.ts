import { Op } from "sequelize";
import OTP from "../models/Otp";
import crypto from 'crypto'
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


  export function generateNumericPassword(length = 8) {
    const min = Math.pow(10, length - 1); // Minimum value for an N-digit number
    const max = Math.pow(10, length) - 1; // Maximum value for an N-digit number
    
    return crypto.randomInt(min, max + 1).toString();
  }
  