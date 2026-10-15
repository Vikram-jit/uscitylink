import { Request, Response, NextFunction } from "express";
import { UserProfile } from "../models/UserProfile";
import Role from "../models/Role";

export const STAFF_ROLES = ["staff", "admin"];

// admin can do everything staff can, plus manage automation
export const isStaffRole = (roleName?: string | null) => !!roleName && STAFF_ROLES.includes(roleName);

// Use after authMiddleware
export const requireRole =
  (...roles: string[]) =>
  async (req: Request, res: Response, next: NextFunction): Promise<any> => {
    try {
      const profile = await UserProfile.findByPk(req.user?.id, {
        include: [{ model: Role, as: "role" }],
      });
      if (!profile?.role?.name || !roles.includes(profile.role.name)) {
        return res.status(403).json({ status: false, message: "You do not have access to this area" });
      }
      next();
    } catch (err) {
      return res.status(403).json({ status: false, message: "You do not have access to this area" });
    }
  };
