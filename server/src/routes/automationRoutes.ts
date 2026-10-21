import { Router } from "express";
import { authMiddleware } from "../middleware/authMiddleware";
import { requireRole } from "../middleware/requireRole";
import {
  automationMe,
  automationStats,
  automationUpload,
  builderMeta,
  correctMessageDocument,
  createDocType,
  createExample,
  createFlow,
  deleteDocType,
  deleteExample,
  suggestDocTypeKeywords,
  deleteFlow,
  extractSample,
  getDocType,
  getFlow,
  getMessageDocument,
  getMessageDocuments,
  listCandidateExamples,
  listDocTypes,
  listFlows,
  listRuns,
  reanalyzeMessage,
  reviewQueue,
  testFlow,
  toggleFlow,
  updateDocType,
  updateExample,
  updateFlow,
  usageReport,
  getAutomationSettings,
  updateAutomationSettings,
  listScaleChecks,
  getScaleCheckByMessage,
  approveScaleCheck,
  rejectScaleCheck,
  listRuleSets,
  createRuleSetVersion,
  reviewRuleSet,
  recheckScaleCheck,
  recordScaleAdjustment,
  scaleCheckReport,
  listEquipment,
  saveEquipment,
  deleteEquipment,
  importEquipment,
  getDriverTrip,
  listTrips,
  saveDriverTrip,
  closeDriverTrip,
} from "../controllers/automationController";

const router = Router();
const adminOnly = [authMiddleware, requireRole("admin")];
// Staff can read everything in Automation; only admins change it
const staffRead = [authMiddleware, requireRole("staff", "admin")];
// Compliance (scale checks, routes, weight rules, equipment): full control for staff and admins
const compliance = [authMiddleware, requireRole("staff", "admin")];

// Staff: document data shown on chat attachments
router.get("/me", authMiddleware, automationMe);
router.get("/message-documents", authMiddleware, getMessageDocuments);
router.get("/message-documents/:messageId", authMiddleware, getMessageDocument);
router.post("/message-documents/:id/correct", authMiddleware, correctMessageDocument);
router.post("/message-documents/:messageId/reanalyze", authMiddleware, reanalyzeMessage);

// Staff: scale ticket checks and the dispatcher release decision
router.get("/scale-checks", ...compliance, listScaleChecks);
router.get("/scale-checks/by-message/:messageId", ...compliance, getScaleCheckByMessage);
router.post("/scale-checks/:id/approve", ...compliance, approveScaleCheck);
router.post("/scale-checks/:id/reject", ...compliance, rejectScaleCheck);
router.post("/scale-checks/:id/recheck", ...compliance, recheckScaleCheck);
router.post("/scale-checks/:id/adjustment", ...compliance, recordScaleAdjustment);
router.get("/scale-checks/:id/report", ...compliance, scaleCheckReport);
// Dispatch: the route a driver is on (states, road types, permits)
router.get("/trips", ...compliance, listTrips);
router.get("/trips/driver/:driverId", ...compliance, getDriverTrip);
router.put("/trips/driver/:driverId", ...compliance, saveDriverTrip);
router.post("/trips/driver/:driverId/close", ...compliance, closeDriverTrip);

// Admin: document types and training examples
router.get("/doc-types", ...staffRead, listDocTypes);
router.post("/doc-types", ...adminOnly, createDocType);
router.get("/doc-types/:id", ...staffRead, getDocType);
router.put("/doc-types/:id", ...adminOnly, updateDocType);
router.get("/doc-types/:id/suggested-keywords", ...staffRead, suggestDocTypeKeywords);
router.delete("/doc-types/:id", ...adminOnly, deleteDocType);
router.post("/extract", ...adminOnly, automationUpload, extractSample);
router.post("/doc-types/:id/examples", ...adminOnly, createExample);
router.get("/examples/candidates", ...staffRead, listCandidateExamples);
router.put("/examples/:exampleId", ...adminOnly, updateExample);
router.delete("/examples/:exampleId", ...adminOnly, deleteExample);

// Admin: flows
router.get("/meta", ...staffRead, builderMeta);
router.get("/flows", ...staffRead, listFlows);
router.post("/flows", ...adminOnly, createFlow);
router.post("/flows/test", ...adminOnly, automationUpload, testFlow);
router.get("/flows/:id", ...staffRead, getFlow);
router.put("/flows/:id", ...adminOnly, updateFlow);
router.patch("/flows/:id/toggle", ...adminOnly, toggleFlow);
router.delete("/flows/:id", ...adminOnly, deleteFlow);

// Admin: monitoring
router.get("/runs", ...staffRead, listRuns);
router.get("/review-queue", ...staffRead, reviewQueue);
router.get("/stats", ...staffRead, automationStats);
router.get("/usage", ...staffRead, usageReport);
router.get("/settings", ...staffRead, getAutomationSettings);
router.put("/settings", ...adminOnly, updateAutomationSettings);
router.get("/rule-sets", ...compliance, listRuleSets);
router.post("/rule-sets", ...compliance, createRuleSetVersion);
router.post("/rule-sets/:id/review", ...compliance, reviewRuleSet);
router.get("/equipment", ...compliance, listEquipment);
router.post("/equipment", ...compliance, saveEquipment);
router.put("/equipment/:id", ...compliance, saveEquipment);
router.delete("/equipment/:id", ...compliance, deleteEquipment);
router.post("/equipment/import", ...compliance, importEquipment);

export default router;
