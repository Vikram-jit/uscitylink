import { Router } from "express";
import { authMiddleware } from "../middleware/authMiddleware";
import { requireRole } from "../middleware/requireRole";
import {
  addLegRest,
  assignLegRest,
  conflictsRest,
  createLoadRest,
  equipmentRest,
  lineupRest,
  listLoadsRest,
  changeTypeRest,
  correctTimesRest,
  milesRest,
  setMilesRest,
  splitLegRest,
  releaseLegRest,
  truckPlaceRest,
  undoSplitRest,
  removeFromLineupRest,
  reorderLineupRest,
  placeStopRest,
  searchPlacesRest,
  showLoadRest,
  updateLoadRest,
  yardStopRest,
} from "../controllers/loadController";

// Loads with legs + the equipment board (dispatch only). Each leg's own actions stay under /trips.
const router = Router();
const staffOnly = [authMiddleware, requireRole("staff", "admin")];

router.get("/", ...staffOnly, listLoadsRest);
router.post("/", ...staffOnly, createLoadRest);
router.get("/yard-stop", ...staffOnly, yardStopRest);
router.get("/places/search", ...staffOnly, searchPlacesRest);
router.get("/lineup/:profileId", ...staffOnly, lineupRest);
router.get("/miles", ...staffOnly, milesRest);
router.get("/legs/:legId/truck-place", ...staffOnly, truckPlaceRest);
router.put("/lineup/:profileId", ...staffOnly, reorderLineupRest);
router.delete("/lineup/:profileId/:tripId", ...staffOnly, removeFromLineupRest);
router.get("/places/:placeId", ...staffOnly, placeStopRest);
router.get("/equipment/check", ...staffOnly, conflictsRest);
router.get("/equipment/:kind", ...staffOnly, equipmentRest);
router.get("/:id", ...staffOnly, showLoadRest);
router.patch("/:id", ...staffOnly, updateLoadRest);
router.post("/:id/legs", ...staffOnly, addLegRest);
router.post("/:id/legs/:legId/assign", ...staffOnly, assignLegRest);
router.post("/:id/legs/:legId/split", ...staffOnly, splitLegRest);
router.post("/:id/legs/:legId/undo-split", ...staffOnly, undoSplitRest);
router.post("/:id/legs/:legId/release", ...staffOnly, releaseLegRest);
router.patch("/:id/legs/:legId/times", ...staffOnly, correctTimesRest);
router.patch("/:id/legs/:legId/miles", ...staffOnly, setMilesRest);
router.patch("/:id/type", ...staffOnly, changeTypeRest);

export default router;
