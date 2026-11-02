import fs from "fs";
import http2 from "http2";
import jwt from "jsonwebtoken";
import * as admin from "firebase-admin";
import "../utils/fcmService"; // initialises firebase-admin
import { UserProfile } from "../models/UserProfile";
import { sendNotificationToDevice } from "../utils/fcmService";

// Rings a phone whose app is closed / in the background.
//   Android: FCM data-only, high priority → the app shows the full-screen incoming-call UI itself.
//   iOS:     APNs VoIP push (PushKit) → CallKit. Needs an APNs auth key:
//            APNS_KEY_PATH (.p8), APNS_KEY_ID, APNS_TEAM_ID, APNS_BUNDLE_ID, APNS_PRODUCTION=true|false.
//            Without it (or without a VoIP token yet) iOS falls back to a normal notification.
// Nothing here throws: a failed push just means that phone doesn't ring.

export interface IncomingCallPush {
  callId: string;
  callerId: string;
  callerName: string;
  callerRole: string;
  channelId: string;
  channelName: string;
  type: string;
}

const RING_TTL_MS = 45_000;

async function fcmData(token: string, data: Record<string, string>, ttlMs: number) {
  try {
    await admin.messaging().send({ token, data, android: { priority: "high", ttl: ttlMs } });
  } catch (err: any) {
    if (err?.code === "messaging/registration-token-not-registered" || err?.code === "messaging/invalid-registration-token") {
      await UserProfile.update({ device_token: null }, { where: { device_token: token } });
    } else {
      console.warn("[calls] FCM call push failed:", err?.message || err);
    }
  }
}

// ---- APNs (VoIP) over HTTP/2 with a token-based (JWT, ES256) auth key ----

let apnsJwt: { token: string; at: number } | null = null;
const apnsSessions = new Map<string, http2.ClientHttp2Session>();

const APNS_PROD = "https://api.push.apple.com";
const APNS_SANDBOX = "https://api.sandbox.push.apple.com";
// Builds run from Xcode get sandbox VoIP tokens; TestFlight/App Store builds get production ones.
// APNS_PRODUCTION picks which server is tried first; a token from the other kind of build is retried
// there, so one server rings both. Remembered per token to skip the failed try next time.
const tokenHost = new Map<string, string>();

const apnsConfigured = () =>
  !!(process.env.APNS_KEY_PATH && process.env.APNS_KEY_ID && process.env.APNS_TEAM_ID && process.env.APNS_BUNDLE_ID);

/** Logged at startup: without APNs, iPhones only get a notification for calls, not the call screen. */
export function logCallPushSetup() {
  if (!apnsConfigured()) {
    console.warn(
      "[calls] iOS VoIP push is OFF (APNS_KEY_PATH / APNS_KEY_ID / APNS_TEAM_ID / APNS_BUNDLE_ID missing): " +
        "iPhones get a plain notification for calls instead of the full-screen call. See docs/calls/README.md"
    );
    return;
  }
  if (!fs.existsSync(process.env.APNS_KEY_PATH!)) {
    console.warn(`[calls] iOS VoIP push key not found at ${process.env.APNS_KEY_PATH}`);
    return;
  }
  console.log(
    `[calls] iOS VoIP push ready (key ${process.env.APNS_KEY_ID}, ${
      process.env.APNS_PRODUCTION === "true" ? "production" : "sandbox"
    } first)`
  );
}

function apnsAuthToken(): string {
  // Apple accepts a token for up to an hour and rejects refreshing more than every 20 min
  if (apnsJwt && Date.now() - apnsJwt.at < 40 * 60 * 1000) return apnsJwt.token;
  const key = fs.readFileSync(process.env.APNS_KEY_PATH!, "utf8");
  const token = jwt.sign({ iss: process.env.APNS_TEAM_ID, iat: Math.floor(Date.now() / 1000) }, key, {
    algorithm: "ES256",
    header: { alg: "ES256", kid: process.env.APNS_KEY_ID! },
  } as any);
  apnsJwt = { token, at: Date.now() };
  return token;
}

// One HTTP/2 connection per Apple server, reused for every push
function apnsClient(host: string): http2.ClientHttp2Session {
  const open = apnsSessions.get(host);
  if (open && !open.closed && !open.destroyed) return open;
  const session = http2.connect(host);
  const drop = () => apnsSessions.get(host) === session && apnsSessions.delete(host);
  session.on("error", drop);
  session.on("goaway", drop);
  session.on("close", drop);
  apnsSessions.set(host, session);
  return session;
}

interface ApnsResult {
  status: number;
  reason: string;
}

/** Sends a VoIP push, trying the other Apple server when the token belongs to the other kind of build. */
async function apnsVoip(deviceToken: string, payload: Record<string, any>): Promise<boolean> {
  const preferred = process.env.APNS_PRODUCTION === "true" ? APNS_PROD : APNS_SANDBOX;
  const first = tokenHost.get(deviceToken) ?? preferred;
  const second = first === APNS_PROD ? APNS_SANDBOX : APNS_PROD;

  let res = await apnsSend(first, deviceToken, payload);
  if (res.status === 400 && res.reason === "BadDeviceToken") {
    const retry = await apnsSend(second, deviceToken, payload);
    if (retry.status === 200) {
      tokenHost.set(deviceToken, second);
      return true;
    }
    res = retry;
  }
  if (res.status === 200) {
    tokenHost.set(deviceToken, first);
    return true;
  }
  // Dead token (app deleted / token rejected by both servers): forget it, the app sends a new one
  if (res.status === 410 || res.reason === "BadDeviceToken" || res.reason === "Unregistered") {
    tokenHost.delete(deviceToken);
    await UserProfile.update({ voip_token: null }, { where: { voip_token: deviceToken } }).catch(() => undefined);
  }
  console.warn(`[calls] APNs VoIP push failed ${res.status}: ${res.reason || "no response"}`);
  return false;
}

function apnsSend(host: string, deviceToken: string, payload: Record<string, any>): Promise<ApnsResult> {
  return new Promise((resolve) => {
    try {
      const req = apnsClient(host).request({
        ":method": "POST",
        ":path": `/3/device/${deviceToken}`,
        authorization: `bearer ${apnsAuthToken()}`,
        "apns-topic": `${process.env.APNS_BUNDLE_ID}.voip`,
        "apns-push-type": "voip",
        "apns-priority": "10",
        "apns-expiration": String(Math.floor((Date.now() + RING_TTL_MS) / 1000)),
      });
      let status = 0;
      let body = "";
      req.on("response", (h) => (status = Number(h[":status"]) || 0));
      req.on("data", (c) => (body += c));
      req.on("end", () => {
        let reason = "";
        try {
          reason = body ? JSON.parse(body).reason || "" : "";
        } catch {
          reason = body;
        }
        resolve({ status, reason });
      });
      req.on("error", (err) => resolve({ status: 0, reason: err.message }));
      req.setTimeout(8000, () => req.close());
      req.end(JSON.stringify(payload));
    } catch (err: any) {
      resolve({ status: 0, reason: err?.message || String(err) });
    }
  });
}

/** Ring one person's phone. Respects the staff "mute notifications" setting. */
export async function pushIncomingCall(profile: UserProfile, call: IncomingCallPush): Promise<void> {
  const muted = profile.notifications_muted_until && new Date(profile.notifications_muted_until).getTime() > Date.now();
  if (muted) return;

  const data: Record<string, string> = {
    type: "CALL_INCOMING",
    callId: call.callId,
    callerId: call.callerId,
    callerName: call.callerName,
    callerRole: call.callerRole,
    channelId: call.channelId,
    channelName: call.channelName,
    callType: call.type,
    expiresAt: String(Date.now() + RING_TTL_MS),
  };

  if (profile.platform === "ios") {
    // VoIP push → full-screen CallKit call. If it can't be sent, a plain notification still tells
    // the driver someone is calling.
    if (profile.voip_token && apnsConfigured() && (await apnsVoip(profile.voip_token, { aps: {}, ...data }))) return;
    if (profile.device_token) {
      await sendNotificationToDevice(profile.device_token, {
        title: `Incoming call · ${call.callerName}`,
        body: "Open USCityLink to answer",
        badge: 0,
        data,
      });
    }
    return;
  }
  if (profile.device_token) await fcmData(profile.device_token, data, RING_TTL_MS);
}

/** Stop a phone ringing (answered elsewhere / cancelled / timed out). Android only: iOS ends via the socket. */
export async function pushCallEnded(profile: UserProfile, callId: string, reason: string): Promise<void> {
  if (profile.platform === "ios" || !profile.device_token) return;
  await fcmData(profile.device_token, { type: "CALL_ENDED", callId, reason }, 60_000);
}

/** "Missed call" notification after the ringing stops. */
export async function pushMissedCall(profile: UserProfile, callerName: string, channelId: string): Promise<void> {
  const muted = profile.notifications_muted_until && new Date(profile.notifications_muted_until).getTime() > Date.now();
  if (muted || !profile.device_token) return;
  await sendNotificationToDevice(profile.device_token, {
    title: "Missed call",
    body: `${callerName} tried to call you`,
    badge: 0,
    data: { type: "CALL_MISSED", channelId },
  });
}
