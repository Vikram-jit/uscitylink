import { Router, Request, Response } from "express";
import { trackingByCode, TrackingNotFound, trackingView } from "../services/trips/publicTracking";

// No login: the shipper / customer tracking page (/track/<token> on the web).
const router = Router();

router.get("/track/:token", async (req: Request, res: Response): Promise<any> => {
  try {
    const token = String(req.params.token || "");
    if (!/^[A-Za-z0-9_-]{16,40}$/.test(token)) return res.status(404).json({ status: false, message: "Tracking link not found" });
    res.setHeader("Cache-Control", "no-store");
    return res.json({ status: true, data: await trackingView(token) });
  } catch (err: any) {
    if (err instanceof TrackingNotFound) return res.status(404).json({ status: false, message: err.message });
    console.error("[track]", err);
    return res.status(500).json({ status: false, message: "Tracking is not available right now" });
  }
});

/** The app's "Track a load" screen: the short code dispatch gives the customer (e.g. K7M2QX). */
router.get("/track-code/:code", async (req: Request, res: Response): Promise<any> => {
  try {
    res.setHeader("Cache-Control", "no-store");
    return res.json({ status: true, data: await trackingByCode(String(req.params.code || "")) });
  } catch (err: any) {
    if (err instanceof TrackingNotFound) return res.status(404).json({ status: false, message: "No load found with that tracking code" });
    console.error("[track]", err);
    return res.status(500).json({ status: false, message: "Tracking is not available right now" });
  }
});

export default router;
