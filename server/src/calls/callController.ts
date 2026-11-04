import { Request, Response } from "express";
import { Op, fn, col } from "sequelize";
import fs from "fs";
import { Call, CallParticipant, CallRecording } from "../models/Call";
import { UserProfile } from "../models/UserProfile";
import Role from "../models/Role";
import { isStaffRole } from "../middleware/requireRole";
import {
  isCallRecordingEnabled,
  isCallVideoRecordingEnabled,
  isCallsEnabled,
  setCallRecordingEnabled,
  setCallVideoRecordingEnabled,
  setCallsEnabled,
} from "../services/documentAi/settings";
import { recordingUrl } from "./callRecorder";
import { iceServersFor } from "./iceServers";
import { availableStaff, callService } from "./callSocket";
import { ERRORS } from "./callService";

const fail = (res: Response, err: any, code = 400) =>
  res.status(code).json({ status: false, message: err?.message || "Something went wrong" });

const me = async (req: Request) => UserProfile.findByPk(req.user?.id, { include: [{ model: Role, as: "role" }] });

// GET /calls/config — whether calling is on, plus fresh STUN/TURN servers
export async function callConfig(req: Request, res: Response): Promise<any> {
  try {
    return res.json({ status: true, data: { enabled: await isCallsEnabled(), ...iceServersFor(String(req.user?.id)) } });
  } catch (err) {
    return fail(res, err, 500);
  }
}

// PUT /calls/voip-token { token } — iOS PushKit token (null clears it)
export async function saveVoipToken(req: Request, res: Response): Promise<any> {
  try {
    const token = req.body?.token ? String(req.body.token).trim() : null;
    if (token && !/^[0-9a-fA-F]{32,200}$/.test(token)) throw new Error("Invalid VoIP token");
    if (token) await UserProfile.update({ voip_token: null }, { where: { voip_token: token, id: { [Op.ne]: req.user?.id } } });
    await UserProfile.update({ voip_token: token }, { where: { id: req.user?.id } });
    return res.json({ status: true, message: "Saved" });
  } catch (err) {
    return fail(res, err);
  }
}

const NAME_ATTRS = ["id", "username"];

// GET /calls/available-staff — staff who can be added to a call (online; busy ones flagged)
export async function listAvailableStaff(req: Request, res: Response): Promise<any> {
  try {
    const user = await me(req);
    if (!isStaffRole(user?.role?.name)) return res.status(403).json({ status: false, message: "Staff only" });
    return res.json({ status: true, data: await availableStaff(String(req.user?.id)) });
  } catch (err) {
    return fail(res, err, 500);
  }
}

/** Latest recording of each call (a call has one, unless recording was retried). */
async function recordingsFor(callIds: string[]) {
  if (!callIds.length) return new Map<string, CallRecording>();
  const rows = await CallRecording.findAll({ where: { call_id: callIds }, order: [["createdAt", "ASC"]] });
  return new Map(rows.map((r) => [r.call_id, r]));
}

const recordingSummary = (r?: CallRecording) =>
  r
    ? {
        status: r.status,
        duration_sec: r.duration_sec ?? null,
        size_bytes: r.size_bytes ?? null,
        has_video: !!r.video_s3_key,
        video_size_bytes: r.video_size_bytes ?? null,
      }
    : null;

// GET /calls?driverId=&channelId=&status=&page=&pageSize= — staff see all, drivers their own
export async function listCalls(req: Request, res: Response): Promise<any> {
  try {
    const user = await me(req);
    const page = Math.max(1, Number(req.query.page) || 1);
    const pageSize = Math.min(100, Math.max(1, Number(req.query.pageSize) || 20));
    const where: any = {};
    if (isStaffRole(user?.role?.name)) {
      if (req.query.driverId) where.driver_id = String(req.query.driverId);
      if (req.query.channelId) where.channel_id = String(req.query.channelId);
    } else {
      where.driver_id = user?.id;
    }
    if (req.query.status) where.status = String(req.query.status).split(",");

    const { rows, count } = await Call.findAndCountAll({
      where,
      order: [["started_at", "DESC"]],
      limit: pageSize,
      offset: (page - 1) * pageSize,
    });
    const ids = [...new Set(rows.flatMap((r) => [r.driver_id, r.initiator_id, r.answered_by].filter(Boolean) as string[]))];
    const people = await UserProfile.findAll({ where: { id: ids }, attributes: NAME_ATTRS });
    const name = (id?: string | null) => (id ? people.find((p) => p.id === id)?.username || null : null);
    const rang = (await CallParticipant.findAll({
      attributes: ["call_id", [fn("COUNT", col("id")), "n"]],
      where: { call_id: rows.map((r) => r.id), role: "callee" },
      group: ["call_id"],
      raw: true,
    })) as unknown as { call_id: string; n: number }[];
    // People who were on each call (2 = normal call, 3+ = group call)
    const onCall = (await CallParticipant.findAll({
      attributes: ["call_id", [fn("COUNT", col("id")), "n"]],
      where: { call_id: rows.map((r) => r.id), joined_at: { [Op.ne]: null } },
      group: ["call_id"],
      raw: true,
    })) as unknown as { call_id: string; n: number }[];

    const recordings = await recordingsFor(rows.map((r) => r.id));

    return res.json({
      status: true,
      data: {
        calls: rows.map((r) => ({
          ...r.toJSON(),
          recording: recordingSummary(recordings.get(r.id)),
          rang_count: Number(rang.find((x) => x.call_id === r.id)?.n || 0),
          people: Number(onCall.find((x) => x.call_id === r.id)?.n || 0),
          driver_name: name(r.driver_id),
          initiator_name: name(r.initiator_id),
          answered_by_name: name(r.answered_by),
          direction: r.initiator_id === r.driver_id ? "driver_to_dispatch" : "dispatch_to_driver",
        })),
        total: count,
        page,
        pageSize,
      },
    });
  } catch (err) {
    return fail(res, err, 500);
  }
}

// GET /calls/:id — the full log: who it rang, what each dispatcher did, wait/queue/talk times
export async function getCall(req: Request, res: Response): Promise<any> {
  try {
    const user = await me(req);
    const call = await Call.findByPk(req.params.id);
    if (!call || (!isStaffRole(user?.role?.name) && call.driver_id !== user?.id)) {
      return res.status(404).json({ status: false, message: "Call not found" });
    }
    const participants = await CallParticipant.findAll({ where: { call_id: call.id }, order: [["invited_at", "ASC"]] });
    const ids = [
      ...new Set(
        [call.driver_id, call.initiator_id, call.answered_by, ...participants.flatMap((p) => [p.user_profile_id, p.invited_by])].filter(
          Boolean
        ) as string[]
      ),
    ];
    const people = await UserProfile.findAll({ where: { id: ids }, attributes: NAME_ATTRS });
    const name = (id?: string | null) => (id ? people.find((p) => p.id === id)?.username || null : null);
    const recording = (await recordingsFor([call.id])).get(call.id);
    return res.json({
      status: true,
      data: {
        ...call.toJSON(),
        recording: recording
          ? { ...recordingSummary(recording), sha256: recording.sha256, error: recording.error ?? null }
          : null,
        driver_name: name(call.driver_id),
        initiator_name: name(call.initiator_id),
        answered_by_name: name(call.answered_by),
        direction: call.initiator_id === call.driver_id ? "driver_to_dispatch" : "dispatch_to_driver",
        participants: participants.map((p) => ({
          user_profile_id: p.user_profile_id,
          name: name(p.user_profile_id),
          role: p.role,
          // answered | declined | missed (rang, no answer) | left (someone else answered) | caller;
          // people added to the answered call: joined | declined | missed | cancelled
          outcome:
            p.role === "caller"
              ? "caller"
              : p.role === "added"
                ? p.joined_at
                  ? "joined"
                  : p.state
                : p.user_profile_id === call.answered_by
                  ? "answered"
                  : p.state,
          invited_by: p.invited_by || null,
          join_type: p.join_type || null,
          invited_by_name: name(p.invited_by),
          invited_at: p.invited_at,
          joined_at: p.joined_at,
          left_at: p.left_at,
        })),
      },
    });
  } catch (err) {
    return fail(res, err, 500);
  }
}

// POST /calls/:id/quality { rttMs, jitterMs, packetLossPct, relay, codec, ... } — end-of-call stats
export async function saveCallQuality(req: Request, res: Response): Promise<any> {
  try {
    const call = await Call.findByPk(req.params.id);
    const uid = req.user?.id;
    if (!call || (call.initiator_id !== uid && call.answered_by !== uid)) {
      return res.status(404).json({ status: false, message: "Call not found" });
    }
    const allowed = ["rttMs", "jitterMs", "packetLossPct", "bytesSent", "bytesReceived", "relay", "codec", "localCandidate", "remoteCandidate", "iceRestarts", "platform"];
    const stats: Record<string, any> = {};
    for (const k of allowed) if (req.body?.[k] !== undefined) stats[k] = req.body[k];
    await call.update({ quality: { ...(call.quality || {}), [uid!]: { ...stats, at: new Date().toISOString() } } });
    return res.json({ status: true, message: "Saved" });
  } catch (err) {
    return fail(res, err);
  }
}

// GET/PUT /calls/settings — admin switches for calling and call recording
export async function getCallSettings(_req: Request, res: Response): Promise<any> {
  return res.json({
    status: true,
    data: { enabled: await isCallsEnabled(), recording: await isCallRecordingEnabled(), videoRecording: await isCallVideoRecordingEnabled() },
  });
}

export async function updateCallSettings(req: Request, res: Response): Promise<any> {
  try {
    if (req.body?.enabled !== undefined) await setCallsEnabled(req.body.enabled !== false, req.user?.id);
    if (req.body?.recording !== undefined) await setCallRecordingEnabled(req.body.recording !== false, req.user?.id);
    if (req.body?.videoRecording !== undefined) await setCallVideoRecordingEnabled(req.body.videoRecording === true, req.user?.id);
    const data = {
      enabled: await isCallsEnabled(),
      recording: await isCallRecordingEnabled(),
      videoRecording: await isCallVideoRecordingEnabled(),
    };
    return res.json({ status: true, message: "Call settings saved", data });
  } catch (err) {
    return fail(res, err);
  }
}

// GET /calls/:id/recording — staff only: a link (valid 15 min) to play or download the recording
export async function getCallRecording(req: Request, res: Response): Promise<any> {
  try {
    const user = await me(req);
    if (!isStaffRole(user?.role?.name)) return res.status(403).json({ status: false, message: "Only staff can open call recordings" });
    const recording = (await recordingsFor([String(req.params.id)])).get(String(req.params.id));
    if (!recording) return res.status(404).json({ status: false, message: "This call wasn't recorded" });
    if (recording.status !== "ready" || !recording.s3_key) {
      return res.status(409).json({ status: false, message: recording.status === "failed" ? "The recording failed" : "The recording is still being saved", data: recordingSummary(recording) });
    }
    console.log(`[recording] ${user?.username} (${user?.id}) opened the recording of call ${recording.call_id}`);
    const toUrl = (key: string, kind: "audio" | "video") => {
      const link = recordingUrl(key);
      return typeof link === "string" ? link : `${req.protocol}://${req.get("host")}${req.baseUrl}/${recording.call_id}/recording/file?kind=${kind}`;
    };
    return res.json({
      status: true,
      data: {
        url: toUrl(recording.s3_key, "audio"),
        mime: recording.mime,
        duration_sec: recording.duration_sec,
        size_bytes: recording.size_bytes,
        sha256: recording.sha256,
        // Video calls with "Record video" on: everyone's camera in a grid, with the audio
        video_url: recording.video_s3_key ? toUrl(recording.video_s3_key, "video") : null,
        video_size_bytes: recording.video_size_bytes ?? null,
        video_sha256: recording.video_sha256 ?? null,
        expires_in_sec: 900,
      },
    });
  } catch (err) {
    return fail(res, err, 500);
  }
}

// GET /calls/:id/recording/file — development only (RECORDING_LOCAL_DIR): streams the local file
export async function getCallRecordingFile(req: Request, res: Response): Promise<any> {
  const recording = (await recordingsFor([String(req.params.id)])).get(String(req.params.id));
  const video = req.query.kind === "video";
  const key = video ? recording?.video_s3_key : recording?.s3_key;
  const link = key ? recordingUrl(key) : null;
  if (!link || typeof link === "string" || !fs.existsSync(link.localPath)) return res.status(404).end();
  res.setHeader("Content-Type", video ? "video/mp4" : recording!.mime || "audio/mp4");
  fs.createReadStream(link.localPath).pipe(res);
}

// POST /calls/:id/decline and /calls/:id/end — for a phone that was woken from a killed state and
// whose socket isn't connected yet when the user taps Decline / End on the native call screen.
export async function declineCallRest(req: Request, res: Response): Promise<any> {
  console.log(`[calls] ${req.params.id}: declined by ${req.user?.id} (app REST, ${req.ip})`);
  const result = await callService.decline(req.params.id, String(req.user?.id));
  return result.ok ? res.json({ status: true }) : res.status(409).json({ status: false, message: ERRORS[result.error] || result.error });
}

export async function endCallRest(req: Request, res: Response): Promise<any> {
  console.log(`[calls] ${req.params.id}: hung up by ${req.user?.id} (app REST, ${req.ip})`);
  const result = await callService.hangup(req.params.id, String(req.user?.id));
  return result.ok ? res.json({ status: true }) : res.status(409).json({ status: false, message: ERRORS[result.error] || result.error });
}
