import { Router } from "express";
import { authMiddleware } from "../middleware/authMiddleware";
import { requireRole } from "../middleware/requireRole";
import {
  callConfig,
  declineCallRest,
  endCallRest,
  getCall,
  getCallSettings,
  listCalls,
  saveCallQuality,
  saveVoipToken,
  updateCallSettings,
} from "../calls/callController";

// Voice calls. Signalling itself runs over Socket.IO (calls/callSocket.ts); these are the helpers.
const router = Router();

router.get("/config", authMiddleware, callConfig);
router.put("/voip-token", authMiddleware, saveVoipToken);
router.get("/settings", authMiddleware, getCallSettings);
router.put("/settings", authMiddleware, requireRole("admin"), updateCallSettings);
router.get("/", authMiddleware, listCalls);
router.get("/:id", authMiddleware, getCall);
router.post("/:id/quality", authMiddleware, saveCallQuality);
router.post("/:id/decline", authMiddleware, declineCallRest);
router.post("/:id/end", authMiddleware, endCallRest);

export default router;
