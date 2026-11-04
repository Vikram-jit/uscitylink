import fs from "fs";
import os from "os";
import path from "path";
import crypto from "crypto";
import { spawn } from "child_process";
import AWS from "aws-sdk";
import ffmpegPath from "ffmpeg-static";
import { RTCPeerConnection, RTCRtpCodecParameters } from "werift";
// "werift/nonstandard" is only reachable through werift's package "exports", which this project's
// TypeScript setting (moduleResolution "node") can't read. Types come from the file it points to;
// at runtime Node resolves the public entry as usual.
import type { MediaRecorder as WeriftMediaRecorder } from "werift/lib/webrtc/src/nonstandard";
// eslint-disable-next-line @typescript-eslint/no-var-requires
const { MediaRecorder } = require("werift/nonstandard") as { MediaRecorder: typeof WeriftMediaRecorder };
import { Op } from "sequelize";
import { CallRecording } from "../models/Call";

// Call recording. Calls are peer-to-peer (driver ↔ dispatcher), so the server never hears them. When
// a recorded call is answered, each side opens a second, send-only WebRTC connection to the server
// with its own microphone ("call:rec_offer"). The server writes each voice to its own file while
// the call runs; when it ends the voices are mixed (aligned by when each one started), saved as one
// .m4a with a SHA-256 hash, uploaded to S3 and listed in call_recordings.
//
// Recording on the server keeps working if either app or tab dies mid-call (each side's audio is on
// disk up to that moment), and covers web and staff-app calls alike. Server restarts: unfinished
// recordings are finished from the files on disk at the next start (recoverRecordings).
//
// Env: RECORDING_UDP_PORTS=40000-40200 (open UDP in the AWS security group), RECORDING_PUBLIC_IP
// (the server's public IP; on AWS the machine only sees its private one), RECORDING_BUCKET (default
// BUCKET_NAME), RECORDING_DIR (working files, default the OS temp dir), RECORDING_LOCAL_DIR
// (development: keep finished files in this folder instead of uploading to S3).

const ROOT = process.env.RECORDING_DIR || path.join(os.tmpdir(), "uscitylink-call-recordings");
const LOCAL_STORE = process.env.RECORDING_LOCAL_DIR || "";
const BUCKET = process.env.RECORDING_BUCKET || process.env.BUCKET_NAME || "";
const PUBLIC_IP = process.env.RECORDING_PUBLIC_IP || "";
const MIME = "audio/mp4";

function portRange(): [number, number] | undefined {
  const m = /^(\d+)-(\d+)$/.exec(process.env.RECORDING_UDP_PORTS || "");
  if (!m) return undefined;
  const range: [number, number] = [Number(m[1]), Number(m[2])];
  return range[0] < range[1] ? range : undefined;
}

interface Segment {
  userId: string;
  file: string;
  /** Wall clock of the first audio packet: lines the voices up when mixing. */
  firstPacketAt: number | null;
  pc?: RTCPeerConnection;
  recorder?: WeriftMediaRecorder;
  closed?: Promise<void>;
}

interface Session {
  callId: string;
  rowId: string;
  dir: string;
  startedAt: number;
  segments: Segment[];
  finishing?: Promise<void>;
}

const sessions = new Map<string, Session>();

const metaPath = (dir: string) => path.join(dir, "meta.json");

function saveMeta(s: Session) {
  const meta = {
    callId: s.callId,
    rowId: s.rowId,
    pid: process.pid,
    startedAt: s.startedAt,
    segments: s.segments.map((g) => ({ userId: g.userId, file: path.basename(g.file), firstPacketAt: g.firstPacketAt })),
  };
  try {
    fs.writeFileSync(metaPath(s.dir), JSON.stringify(meta));
  } catch (err: any) {
    console.warn("[recording] meta write failed:", err?.message);
  }
}

async function openSession(callId: string): Promise<Session> {
  const existing = sessions.get(callId);
  if (existing) return existing;
  const dir = path.join(ROOT, callId);
  fs.mkdirSync(dir, { recursive: true });
  const row = await CallRecording.create({ call_id: callId, status: "recording", started_at: new Date() });
  const session: Session = { callId, rowId: row.id, dir, startedAt: Date.now(), segments: [] };
  sessions.set(callId, session);
  saveMeta(session);
  return session;
}

/** Marks private (non-routable) IPv4 addresses that an AWS machine sees on its own network card. */
const isPrivate = (ip: string) => /^(10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.|127\.)/.test(ip);

/**
 * On AWS the server's ICE candidates carry its private IP. Add the same candidate with the public IP
 * (RECORDING_PUBLIC_IP) so phones on mobile data can reach it; the STUN candidate covers this too
 * when the public IP isn't configured.
 */
function announcePublicIp(sdp: string): string {
  if (!PUBLIC_IP) return sdp;
  return sdp
    .split("\r\n")
    .flatMap((line) => {
      const m = /^a=candidate:(\S+) (\d) (\S+) (\d+) (\S+) (\d+) typ host(.*)$/.exec(line);
      if (!m || !isPrivate(m[5])) return [line];
      return [line, `a=candidate:${m[1]}p ${m[2]} ${m[3]} ${m[4]} ${PUBLIC_IP} ${m[6]} typ host${m[7]}`];
    })
    .join("\r\n");
}

async function closeSegment(seg: Segment): Promise<void> {
  if (!seg.closed) {
    seg.closed = (async () => {
      try {
        await seg.recorder?.stop();
      } catch (err: any) {
        console.warn("[recording] stop failed:", err?.message);
      }
      try {
        await seg.pc?.close();
      } catch {
        // already closed
      }
    })();
  }
  return seg.closed;
}

/**
 * One side of an answered call sends its microphone to be recorded. Returns the SDP answer.
 * A second offer from the same person (reconnected, switched microphone) starts a new segment;
 * the earlier one is kept.
 */
export async function answerRecordingOffer(callId: string, userId: string, offerSdp: string): Promise<string> {
  const session = await openSession(callId);
  if (session.finishing) throw new Error("This call has ended");
  for (const s of session.segments) if (s.userId === userId) await closeSegment(s);

  const index = session.segments.filter((s) => s.userId === userId).length;
  const seg: Segment = { userId, file: path.join(session.dir, `${userId}-${index}.webm`), firstPacketAt: null };
  const pc = new RTCPeerConnection({
    codecs: { audio: [new RTCRtpCodecParameters({ mimeType: "audio/opus", clockRate: 48000, channels: 2 })] },
    iceServers: [{ urls: "stun:stun.l.google.com:19302" }],
    icePortRange: portRange(),
    iceUseIpv6: false,
    // Answer quickly: the phone starts sending audio only once it has the answer
    iceStunGatherTimeout: 1,
  });
  seg.pc = pc;
  session.segments.push(seg);
  saveMeta(session);

  pc.onTrack.subscribe((track) => {
    if (track.kind !== "audio" || seg.recorder) return;
    const recorder = new MediaRecorder({ path: seg.file, numOfTracks: 1 });
    recorder.onError.subscribe((err) => console.warn("[recording] writer error:", err?.message || err));
    seg.recorder = recorder;
    track.onReceiveRtp.once(() => {
      seg.firstPacketAt = Date.now();
      saveMeta(session);
    });
    recorder.addTrack(track).catch((err) => console.warn("[recording] start failed:", err?.message || err));
  });
  pc.connectionStateChange.subscribe((state) => {
    if (state === "failed" || state === "closed") void closeSegment(seg);
  });

  await pc.setRemoteDescription({ type: "offer", sdp: offerSdp });
  await pc.setLocalDescription(await pc.createAnswer());
  if (pc.iceGatheringState !== "complete") {
    await pc.iceGatheringStateChange.watch((state) => state === "complete", 4000).catch(() => undefined);
  }
  return announcePublicIp(pc.localDescription!.sdp);
}

/** The call ended: stop recording and turn the voices into the stored file. Never throws. */
export function finishRecording(callId: string): Promise<void> {
  const session = sessions.get(callId);
  if (!session) return Promise.resolve();
  if (!session.finishing) {
    session.finishing = (async () => {
      await Promise.all(session.segments.map(closeSegment));
      saveMeta(session);
      await finalize(session.callId, session.rowId, session.dir);
      sessions.delete(callId);
    })().catch((err) => console.error("[recording] finish failed:", err));
  }
  return session.finishing;
}

interface SavedSegment {
  userId: string;
  file: string;
  firstPacketAt: number | null;
}

function runFfmpeg(args: string[]): Promise<string> {
  return new Promise((resolve, reject) => {
    if (!ffmpegPath) return reject(new Error("ffmpeg is not available"));
    const proc = spawn(ffmpegPath, args, { stdio: ["ignore", "ignore", "pipe"] });
    let log = "";
    proc.stderr.on("data", (d) => (log = (log + d).slice(-20000)));
    proc.on("error", reject);
    proc.on("close", (code) => (code === 0 ? resolve(log) : reject(new Error(`ffmpeg exited ${code}: ${log.slice(-500)}`))));
  });
}

const sha256File = (file: string) =>
  new Promise<string>((resolve, reject) => {
    const hash = crypto.createHash("sha256");
    fs.createReadStream(file)
      .on("data", (d) => hash.update(d))
      .on("end", () => resolve(hash.digest("hex")))
      .on("error", reject);
  });

/**
 * Whether ffmpeg can read audio from a voice file, and how much. A side whose connection never
 * delivered audio leaves a file with only a header ("End of file"): it is left out of the mix
 * instead of failing the whole recording.
 */
async function audioSeconds(file: string): Promise<number> {
  try {
    const log = await runFfmpeg(["-hide_banner", "-i", file, "-f", "null", "-"]);
    const times = [...log.matchAll(/time=(\d+):(\d+):(\d+\.\d+)/g)];
    const last = times[times.length - 1];
    return last ? Number(last[1]) * 3600 + Number(last[2]) * 60 + Number(last[3]) : 0;
  } catch {
    return 0;
  }
}

/** Mixes the voices in [dir], stores the result and updates the call_recordings row. */
async function finalize(callId: string, rowId: string, dir: string): Promise<void> {
  const row = await CallRecording.findByPk(rowId);
  if (!row) return;
  try {
    await row.update({ status: "processing" });
    const meta = JSON.parse(fs.readFileSync(metaPath(dir), "utf8")) as { segments: SavedSegment[] };
    const candidates = meta.segments
      .map((s) => ({ ...s, file: path.join(dir, s.file) }))
      .filter((s) => s.firstPacketAt && fs.existsSync(s.file) && fs.statSync(s.file).size > 0);
    const voices: typeof candidates = [];
    for (const v of candidates) {
      if ((await audioSeconds(v.file)) > 0) voices.push(v);
      else console.warn(`[recording] ${callId}: no audio in ${path.basename(v.file)}, left out of the mix`);
    }
    if (!voices.length) throw new Error("No audio was received from either side");
    // Who joined the recording but sent no usable audio (listed so the gap is explained)
    const silent = [...new Set(meta.segments.map((s) => s.userId))].filter((u) => !voices.some((v) => v.userId === u));

    // Line the voices up: each starts after the earliest one by the gap between their first packets
    const t0 = Math.min(...voices.map((v) => v.firstPacketAt!));
    const inputs = voices.flatMap((v) => ["-i", v.file]);
    const chains = voices.map((v, i) => {
      const delay = Math.max(0, v.firstPacketAt! - t0);
      return `[${i}:a]aresample=48000,adelay=${delay}:all=1[a${i}]`;
    });
    const mix = `${voices.map((_, i) => `[a${i}]`).join("")}amix=inputs=${voices.length}:duration=longest:normalize=0[out]`;
    const out = path.join(dir, `${callId}.m4a`);
    const log = await runFfmpeg([
      "-y", "-hide_banner", ...inputs,
      "-filter_complex", [...chains, mix].join(";"),
      "-map", "[out]", "-ac", "1", "-c:a", "aac", "-b:a", "48k", "-movflags", "+faststart", out,
    ]);
    const times = [...log.matchAll(/time=(\d+):(\d+):(\d+\.\d+)/g)];
    const last = times[times.length - 1];
    const durationSec = last ? Math.round(Number(last[1]) * 3600 + Number(last[2]) * 60 + Number(last[3])) : null;

    const size = fs.statSync(out).size;
    const sha256 = await sha256File(out);
    const key = await store(callId, out, sha256);
    const users = [...new Set(voices.map((v) => v.userId))];
    await row.update({
      status: "ready",
      s3_key: key,
      mime: MIME,
      duration_sec: durationSec,
      size_bytes: size,
      sha256,
      tracks: [
        ...users.map((userId) => {
          const mine = voices.filter((v) => v.userId === userId);
          return { userId, segments: mine.length, startedOffsetMs: Math.min(...mine.map((v) => v.firstPacketAt! - t0)) };
        }),
        ...silent.map((userId) => ({ userId, segments: 0, startedOffsetMs: -1 })),
      ],
      error: silent.length ? `No audio was received from ${silent.length === 1 ? "one side" : "some sides"}` : null,
      completed_at: new Date(),
    });
    fs.rmSync(dir, { recursive: true, force: true });
    console.log(`[recording] ${callId} saved (${durationSec ?? "?"}s, ${Math.round(size / 1024)} KB)`);
  } catch (err: any) {
    // Files stay on disk so a failed upload can be retried (recoverRecordings) without losing audio
    await row.update({ status: "failed", error: String(err?.message || err).slice(0, 2000) }).catch(() => undefined);
    console.error(`[recording] ${callId} failed:`, err?.message || err);
  }
}

const s3 = () => new AWS.S3({ region: process.env.AWS_REGION || "us-west-1" });

async function store(callId: string, file: string, sha256: string): Promise<string> {
  const now = new Date();
  const key = `call-recordings/${now.getUTCFullYear()}/${String(now.getUTCMonth() + 1).padStart(2, "0")}/${callId}.m4a`;
  if (LOCAL_STORE) {
    const dest = path.join(LOCAL_STORE, key);
    fs.mkdirSync(path.dirname(dest), { recursive: true });
    fs.copyFileSync(file, dest);
    return key;
  }
  if (!BUCKET) throw new Error("No S3 bucket configured (RECORDING_BUCKET / BUCKET_NAME)");
  await s3()
    .upload({
      Bucket: BUCKET,
      Key: key,
      Body: fs.createReadStream(file),
      ContentType: MIME,
      ServerSideEncryption: "AES256",
      Metadata: { "call-id": callId, sha256 },
    })
    .promise();
  return key;
}

/** Short-lived link to play/download a stored recording (S3 presigned URL, or the dev folder). */
export function recordingUrl(key: string, expiresSec = 900): string | { localPath: string } {
  if (LOCAL_STORE) return { localPath: path.join(LOCAL_STORE, key) };
  return s3().getSignedUrl("getObject", { Bucket: BUCKET, Key: key, Expires: expiresSec });
}

const processAlive = (pid: number) => {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
};

/**
 * At startup: finish recordings a restart interrupted (or whose upload failed) from the files on
 * disk. Skips ones another running server process is still recording.
 */
export async function recoverRecordings(): Promise<void> {
  try {
    const rows = await CallRecording.findAll({ where: { status: { [Op.in]: ["recording", "processing", "failed"] } } });
    for (const row of rows) {
      if (sessions.has(row.call_id)) continue;
      const dir = path.join(ROOT, row.call_id);
      if (!fs.existsSync(metaPath(dir))) {
        if (row.status !== "failed") await row.update({ status: "failed", error: "Server restarted before any audio was saved" });
        continue;
      }
      const meta = JSON.parse(fs.readFileSync(metaPath(dir), "utf8"));
      if (meta.pid && meta.pid !== process.pid && processAlive(meta.pid) && row.status === "recording") continue;
      await finalize(row.call_id, row.id, dir);
    }
  } catch (err) {
    console.error("[recording] recovery failed:", err);
  }
}
