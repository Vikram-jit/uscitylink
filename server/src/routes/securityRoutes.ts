import { Router } from "express";

import { authMiddleware } from "../middleware/authMiddleware";
import { getSecurityDashboard } from "../controllers/securityController";
import {
  getEntryFormData,
  createEntry,
  getEntries,
  getEntryById,
  checkTrailerStatus,
} from "../controllers/securityEntryController";
import {
  getInspectionQuestionList,
  getInspectionOdometer,
  getInspectionVehicles,
  getVehicleInspectionHistory,
  getInspectionById,
  createInspection,
} from "../controllers/securityInspectionController";
import { autocomplete, placeDetails } from "../controllers/placesController";

const router = Router();

router.get("/dashboard", authMiddleware, getSecurityDashboard);

// NOTE: "/entries/form-data" must stay registered before "/entries/:id" —
// otherwise Express would match it as :id = "form-data" instead.
router.get("/entries/form-data", authMiddleware, getEntryFormData);
router.post("/entries/check-trailer-status", authMiddleware, checkTrailerStatus);
router.get("/entries", authMiddleware, getEntries);
router.post("/entries", authMiddleware, createEntry);
router.get("/entries/:id", authMiddleware, getEntryById);

// NOTE: same ordering rule as above — specific "/inspections/..." paths must
// stay registered before "/inspections/:id".
router.get("/inspections/questions", authMiddleware, getInspectionQuestionList);
router.get("/inspections/odometer/:truckId", authMiddleware, getInspectionOdometer);
router.get("/inspections/vehicle/:tab/:vehicleId", authMiddleware, getVehicleInspectionHistory);
router.get("/inspections", authMiddleware, getInspectionVehicles);
router.post("/inspections", authMiddleware, createInspection);
router.get("/inspections/:id", authMiddleware, getInspectionById);

router.get("/places/autocomplete", authMiddleware, autocomplete);
router.get("/places/details", authMiddleware, placeDetails);

export default router;
