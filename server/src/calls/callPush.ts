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
let apnsSession: http2.ClientHttp2Session | null = null;

const apnsConfigured = () =>
  !!(process.env.APNS_KEY_PATH && process.env.APNS_KEY_ID && process.env.APNS_TEAM_ID && process.env.APNS_BUNDLE_ID);

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

function apnsClient(): http2.ClientHttp2Session {
  if (apnsSession && !apnsSession.closed && !apnsSession.destroyed) return apnsSession;
  const host = process.env.APNS_PRODUCTION === "true" ? "https://api.push.apple.com" : "https://api.sandbox.push.apple.com";
  apnsSession = http2.connect(host);
  apnsSession.on("error", () => (apnsSession = null));
  apnsSession.on("goaway", () => (apnsSession = null));
  return apnsSession;
}

function apnsVoip(deviceToken: string, payload: Record<string, any>): Promise<number> {
  return new Promise((resolve) => {
    try {
      const req = apnsClient().request({
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
      req.on("end", async () => {
        if (status === 410 || /BadDeviceToken|Unregistered/.test(body)) {
          await UserProfile.update({ voip_token: null }, { where: { voip_token: deviceToken } }).catch(() => undefined);
        } else if (status !== 200) {
          console.warn(`[calls] APNs VoIP push ${status}: ${body}`);
        }
        resolve(status);
      });
      req.on("error", (err) => {
        console.warn("[calls] APNs error:", err.message);
        resolve(0);
      });
      req.setTimeout(8000, () => req.close());
      req.end(JSON.stringify(payload));
    } catch (err: any) {
      console.warn("[calls] APNs push failed:", err?.message || err);
      resolve(0);
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
    if (profile.voip_token && apnsConfigured()) {
      await apnsVoip(profile.voip_token, { aps: {}, ...data });
      return;
    }
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
