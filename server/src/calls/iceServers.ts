import crypto from "crypto";

// ICE servers handed to the web/app before every call.
//
// STUN finds the public address; TURN (our own coturn, see docs/calls/coturn.md) relays the audio
// when a direct path is blocked — common for drivers on 4G/5G carrier NAT. Credentials follow
// coturn's `use-auth-secret` scheme: username = "<expiry unix>:<userId>", password =
// base64(HMAC-SHA1(TURN_SECRET, username)), so nothing is stored per user and they expire.
//
//   TURN_URLS   comma separated, e.g. "turn:turn.example.com:3478?transport=udp,
//               turn:turn.example.com:3478?transport=tcp,turns:turn.example.com:5349?transport=tcp"
//   TURN_SECRET same value as static-auth-secret in turnserver.conf
//   TURN_TTL_SEC credential lifetime (default 6 h — longer than any call)
//   STUN_URLS   optional, defaults to Google's public STUN

export interface IceServer {
  urls: string[];
  username?: string;
  credential?: string;
}

const list = (v?: string) =>
  (v || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);

export function turnCredentials(userId: string, secret: string, ttlSec: number, now = Date.now()) {
  const username = `${Math.floor(now / 1000) + ttlSec}:${userId}`;
  const credential = crypto.createHmac("sha1", secret).update(username).digest("base64");
  return { username, credential };
}

export function iceServersFor(userId: string): { iceServers: IceServer[]; ttlSec: number; relay: boolean } {
  const ttlSec = Number(process.env.TURN_TTL_SEC) || 6 * 3600;
  const stun = list(process.env.STUN_URLS);
  const iceServers: IceServer[] = [
    { urls: stun.length ? stun : ["stun:stun.l.google.com:19302", "stun:stun1.l.google.com:19302"] },
  ];

  const turnUrls = list(process.env.TURN_URLS);
  const secret = process.env.TURN_SECRET;
  if (turnUrls.length && secret) {
    iceServers.push({ urls: turnUrls, ...turnCredentials(userId, secret, ttlSec) });
  }
  return { iceServers, ttlSec, relay: turnUrls.length > 0 && !!secret };
}
