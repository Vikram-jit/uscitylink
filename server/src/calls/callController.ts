import { Request, Response } from "express";
import { Op, fn, col } from "sequelize";
import { Call, CallParticipant } from "../models/Call";
import { UserProfile } from "../models/UserProfile";
import Role from "../models/Role";
import { isStaffRole } from "../middleware/requireRole";
import { isCallsEnabled, setCallsEnabled } from "../services/documentAi/settings";
import { iceServersFor } from "./iceServers";
import { callService } from "./callSocket";
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

    return res.json({
      status: true,
      data: {
        calls: rows.map((r) => ({
          ...r.toJSON(),
          rang_count: Number(rang.find((x) => x.call_id === r.id)?.n || 0),
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
    const ids = [...new Set([call.driver_id, call.initiator_id, call.answered_by, ...participants.map((p) => p.user_profile_id)].filter(Boolean) as string[])];
    const people = await UserProfile.findAll({ where: { id: ids }, attributes: NAME_ATTRS });
    const name = (id?: string | null) => (id ? people.find((p) => p.id === id)?.username || null : null);
    return res.json({
      status: true,
      data: {
        ...call.toJSON(),
        driver_name: name(call.driver_id),
        initiator_name: name(call.initiator_id),
        answered_by_name: name(call.answered_by),
        direction: call.initiator_id === call.driver_id ? "driver_to_dispatch" : "dispatch_to_driver",
        participants: participants.map((p) => ({
          user_profile_id: p.user_profile_id,
          name: name(p.user_profile_id),
          role: p.role,
          // answered | declined | missed (rang, no answer) | left (someone else answered) | caller
          outcome: p.role === "caller" ? "caller" : p.user_profile_id === call.answered_by ? "answered" : p.state,
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

// GET/PUT /calls/settings — admin switch for calling
export async function getCallSettings(_req: Request, res: Response): Promise<any> {
  return res.json({ status: true, data: { enabled: await isCallsEnabled() } });
}

export async function updateCallSettings(req: Request, res: Response): Promise<any> {
  try {
    const enabled = await setCallsEnabled(req.body?.enabled !== false, req.user?.id);
    return res.json({ status: true, message: enabled ? "Calling is on" : "Calling is off", data: { enabled } });
  } catch (err) {
    return fail(res, err);
  }
}

// POST /calls/:id/decline and /calls/:id/end — for a phone that was woken from a killed state and
// whose socket isn't connected yet when the user taps Decline / End on the native call screen.
export async function declineCallRest(req: Request, res: Response): Promise<any> {
  const result = await callService.decline(req.params.id, String(req.user?.id));
  return result.ok ? res.json({ status: true }) : res.status(409).json({ status: false, message: ERRORS[result.error] || result.error });
}

export async function endCallRest(req: Request, res: Response): Promise<any> {
  const result = await callService.hangup(req.params.id, String(req.user?.id));
  return result.ok ? res.json({ status: true }) : res.status(409).json({ status: false, message: ERRORS[result.error] || result.error });
}
