import express from "express";
import { automationUpload, extractSample } from "../src/controllers/automationController";
const app = express();
app.use(express.json());
const log = (m: string) => console.log(`[${new Date().toISOString().slice(11, 23)}] ${m}`);
app.post("/extract", (req: any, _res, next) => { log("request received"); req.user = { id: "probe" }; next(); }, automationUpload, (req, res, next) => { log(`multer done, file=${req.file?.originalname} ${req.file?.size}B`); next(); }, extractSample);
app.listen(4398, () => console.log("probe server on 4398"));
