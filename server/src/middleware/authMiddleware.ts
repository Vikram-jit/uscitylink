import { Request, Response, NextFunction } from "express";
import { verifyToken } from "../utils/jwt";
import { JwtPayload } from "jsonwebtoken";
import { UserProfile } from "../models/UserProfile";

declare global {
  namespace Express {
    interface Request {
      user?: JwtPayload;
      activeChannel?: string;
    }
  }
}

export const authMiddleware = async (
  req: Request,
  res: Response,
  next: NextFunction
): Promise<any> => {
  const token = req.headers.authorization?.split(" ")[1];
  if (!token) {
    return res.status(403).json({ message: "No token provided" });
  }

  try {
    const decoded: any = verifyToken(token);
  
    if (decoded?.id) {
      const userProfile = await UserProfile.findByPk(decoded?.id);
     
      if (userProfile) {
        req.activeChannel = userProfile?.dataValues?.channelId || "";
      }
      req.user = decoded as any; 
      
    }else{
      return res.status(401).json({ message: "Unauthorized" });
    }

    next();
  } catch (error) {
    return res.status(401).json({ message: "Unauthorized" });
  }
};
