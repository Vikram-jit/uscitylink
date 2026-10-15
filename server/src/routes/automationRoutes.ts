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
} from "../controllers/automationController";

const router = Router();
const adminOnly = [authMiddleware, requireRole("admin")];

// Staff: document data shown on chat attachments
router.get("/me", authMiddleware, automationMe);
router.get("/message-documents", authMiddleware, getMessageDocuments);
router.get("/message-documents/:messageId", authMiddleware, getMessageDocument);
router.post("/message-documents/:id/correct", authMiddleware, correctMessageDocument);
router.post("/message-documents/:messageId/reanalyze", authMiddleware, reanalyzeMessage);

// Admin: document types and training examples
router.get("/doc-types", ...adminOnly, listDocTypes);
router.post("/doc-types", ...adminOnly, createDocType);
router.get("/doc-types/:id", ...adminOnly, getDocType);
router.put("/doc-types/:id", ...adminOnly, updateDocType);
router.get("/doc-types/:id/suggested-keywords", ...adminOnly, suggestDocTypeKeywords);
router.delete("/doc-types/:id", ...adminOnly, deleteDocType);
router.post("/extract", ...adminOnly, automationUpload, extractSample);
router.post("/doc-types/:id/examples", ...adminOnly, createExample);
router.get("/examples/candidates", ...adminOnly, listCandidateExamples);
router.put("/examples/:exampleId", ...adminOnly, updateExample);
router.delete("/examples/:exampleId", ...adminOnly, deleteExample);

// Admin: flows
router.get("/meta", ...adminOnly, builderMeta);
router.get("/flows", ...adminOnly, listFlows);
router.post("/flows", ...adminOnly, createFlow);
router.post("/flows/test", ...adminOnly, automationUpload, testFlow);
router.get("/flows/:id", ...adminOnly, getFlow);
router.put("/flows/:id", ...adminOnly, updateFlow);
router.patch("/flows/:id/toggle", ...adminOnly, toggleFlow);
router.delete("/flows/:id", ...adminOnly, deleteFlow);

// Admin: monitoring
router.get("/runs", ...adminOnly, listRuns);
router.get("/review-queue", ...adminOnly, reviewQueue);
router.get("/stats", ...adminOnly, automationStats);
router.get("/usage", ...adminOnly, usageReport);

export default router;
