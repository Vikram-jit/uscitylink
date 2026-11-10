import { Router } from "express";
import { authMiddleware } from "../middleware/authMiddleware";
import { requireRole } from "../middleware/requireRole";
import {
  addProblemRest,
  driverAssignment,
  listTruckAssignments,
  liveTripRest,
  createTripRest,
  declineOfferRest,
  editTripRest,
  listTrips,
  myCurrentTrip,
  myTrips,
  parseTripText,
  resolveProblemRest,
  sendTripRest,
  showTrip,
  tripActionRest,
  undoTripRest,
} from "../controllers/tripController";

// Trips (loads). Dispatch manages them; the driver app runs its own trip (the service checks the
// trip is theirs). See services/trips.
const router = Router();
const staffOnly = [authMiddleware, requireRole("staff", "admin")];

router.get("/current", authMiddleware, myCurrentTrip);
router.get("/mine", authMiddleware, myTrips);
router.get("/", ...staffOnly, listTrips);
router.post("/parse", ...staffOnly, parseTripText);
router.get("/trucks", ...staffOnly, listTruckAssignments);
router.get("/drivers/:profileId/truck", ...staffOnly, driverAssignment);
router.post("/", ...staffOnly, createTripRest);
router.get("/:id", authMiddleware, showTrip);
router.get("/:id/live", ...staffOnly, liveTripRest);
router.patch("/:id", ...staffOnly, editTripRest);
router.post("/:id/send", ...staffOnly, sendTripRest);
router.post("/:id/decline-offer", ...staffOnly, declineOfferRest);
router.post("/:id/action", authMiddleware, tripActionRest);
router.post("/:id/undo", authMiddleware, undoTripRest);
router.post("/:id/problems", authMiddleware, addProblemRest);
router.patch("/:id/problems/:problemId/resolve", ...staffOnly, resolveProblemRest);

export default router;
