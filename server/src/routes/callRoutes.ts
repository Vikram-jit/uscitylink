import { Router } from "express";
import { authMiddleware } from "../middleware/authMiddleware";
import { requireRole } from "../middleware/requireRole";
import {
  callbackTarget,
  callConfig,
  declineCallRest,
  endCallRest,
  getCall,
  getCallRecording,
  getCallRecordingFile,
  getCallSettings,
  listAvailableStaff,
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
router.get("/available-staff", authMiddleware, listAvailableStaff);
router.get("/callback-target", authMiddleware, callbackTarget);
router.get("/", authMiddleware, listCalls);
router.get("/:id", authMiddleware, getCall);
router.get("/:id/recording", authMiddleware, getCallRecording);
// Dev-only stream of a locally stored recording (no auth header possible from <audio src>); returns
// 404 unless RECORDING_LOCAL_DIR is set — production plays from a presigned S3 link instead.
router.get("/:id/recording/file", getCallRecordingFile);
router.post("/:id/quality", authMiddleware, saveCallQuality);
router.post("/:id/decline", authMiddleware, declineCallRest);
router.post("/:id/end", authMiddleware, endCallRest);

export default router;
