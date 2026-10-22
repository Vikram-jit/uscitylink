import { Router } from "express";
import { authMiddleware } from "../middleware/authMiddleware";
import { requireRole } from "../middleware/requireRole";
import { createAppVersion, deleteAppVersion, listAppVersions, listInstallUsers, listInstalls, updateAppVersionRow } from "../controllers/appVersionController";

// Admin → App versions: which mobile builds count as up to date
const router = Router();
const adminOnly = [authMiddleware, requireRole("admin")];

router.get("/", ...adminOnly, listAppVersions);
router.get("/installs", ...adminOnly, listInstalls);
router.get("/installs/users", ...adminOnly, listInstallUsers);
router.post("/", ...adminOnly, createAppVersion);
router.put("/:id", ...adminOnly, updateAppVersionRow);
router.delete("/:id", ...adminOnly, deleteAppVersion);

export default router;
