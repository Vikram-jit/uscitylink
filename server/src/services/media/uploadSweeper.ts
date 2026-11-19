// Chat files the background upload queue never copied to S3.
//
// An upload is first saved on this server (public/uscitylink/<file>) and marked "local" (media) /
// "not-upload" (messages); a queue job (Redis) then copies it to S3 and marks it "server". When that job
// is lost — Redis down, a crash, a restart — the file stays on this server and the rows stay "local"
// for good. Every 10 minutes this job takes such files older than 30 minutes and:
//   · copies the file to S3 if it is still on this server, or
//   · confirms it is already in S3 (the job uploaded it but died before updating the rows),
// then marks media.upload_type = "server" and messages / group messages url_upload_type = "server",
// and removes the server copy (as the queue job does). Files in neither place are left as they are.
//
// Runs only where MEDIA_UPLOAD_SWEEP=on (the production API server): a developer machine must not copy
// its test files into the real bucket.

import fs from "fs";
import path from "path";
import { Op } from "sequelize";
import { HeadObjectCommand, PutObjectCommand, S3Client } from "@aws-sdk/client-s3";

import { Media } from "../../models/Media";
import { Message } from "../../models/Message";
import GroupMessage from "../../models/GroupMessage";

const EVERY_MS = 10 * 60_000;
/** While a backlog is being worked off (a run found a full load), the next run comes sooner */
const BACKLOG_EVERY_MS = 60_000;
/** Younger files are still in the queue's hands */
export const OLDER_THAN_MIN = 30;
/** Older ones are not looked at again (a file missing everywhere would otherwise be checked forever) */
const LOOK_BACK_DAYS = 30;
const PER_RUN = 200;
/** Files are sent in small batches with a pause in between, so a backlog of thousands never floods the
 *  server (disk reads, memory, S3 connections, database) or holds up the chat */
export const BATCH = 10;
const BATCH_PAUSE_MS = 2_000;
/** A file found nowhere is not looked for again for a day (it would block the newest-first list) */
const MISSING_RETRY_MS = 24 * 3600_000;
const missingSince = new Map<string, number>();
const skipped = (now: number) => {
  for (const [k, at] of missingSince) if (now - at > MISSING_RETRY_MS) missingSince.delete(k);
  return [...missingSince.keys()];
};

const PUBLIC_DIR = path.join(__dirname, "../../../public");
const PENDING_MESSAGE = ["not-upload", "failed", "local"];

const bucket = () => process.env.BUCKET_NAME || "ciity-sms";
let client: S3Client | null = null;
const s3 = () =>
  (client ??= new S3Client({
    region: "us-west-1",
    credentials: {
      accessKeyId: process.env.AWS_ACCESS_KEY_ID || "",
      secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || "",
    },
  }));

export interface SweepDeps {
  /** Path of the server copy of [key] (uscitylink/<file>) */
  localPath(key: string): string;
  inS3(key: string): Promise<boolean>;
  upload(key: string, file: string, contentType?: string): Promise<void>;
}

export const realDeps: SweepDeps = {
  localPath: (key) => path.join(PUBLIC_DIR, key),
  inS3: async (key) => {
    try {
      await s3().send(new HeadObjectCommand({ Bucket: bucket(), Key: key }));
      return true;
    } catch (e: any) {
      if (e?.$metadata?.httpStatusCode === 404 || e?.name === "NotFound") return false;
      throw e;
    }
  },
  upload: async (key, file, contentType) => {
    await s3().send(
      new PutObjectCommand({
        Bucket: bucket(),
        Key: key,
        Body: fs.createReadStream(file),
        ContentLength: fs.statSync(file).size,
        ...(contentType ? { ContentType: contentType } : {}),
      })
    );
  },
};

export interface SweepResult {
  checked: number;
  uploaded: string[];
  alreadyInS3: string[];
  missing: string[];
  errors: { key: string; error: string }[];
}

/** File keys (uscitylink/…) waiting for S3 longer than [OLDER_THAN_MIN], newest first. */
export async function pendingKeys(now = new Date(), only?: string[]): Promise<Map<string, string | undefined>> {
  const before = new Date(now.getTime() - OLDER_THAN_MIN * 60_000);
  const after = new Date(now.getTime() - LOOK_BACK_DAYS * 24 * 3600_000);
  const when = { [Op.lt]: before, [Op.gt]: after };
  const skip = skipped(now.getTime());
  const keyFilter: any = only ? { [Op.in]: only } : { [Op.like]: "uscitylink/%" };
  if (skip.length) keyFilter[Op.notIn] = skip;

  const [media, messages, groupMessages] = await Promise.all([
    Media.findAll({
      attributes: ["key", "mime_type"],
      where: { upload_type: "local", key: keyFilter, createdAt: when },
      order: [["createdAt", "DESC"]],
      limit: PER_RUN,
    }),
    Message.findAll({
      attributes: ["url"],
      where: { url_upload_type: { [Op.in]: PENDING_MESSAGE }, url: keyFilter, createdAt: when },
      order: [["createdAt", "DESC"]],
      limit: PER_RUN,
    }),
    GroupMessage.findAll({
      attributes: ["url"],
      where: { url_upload_type: { [Op.in]: PENDING_MESSAGE }, url: keyFilter, createdAt: when } as any,
      order: [["createdAt", "DESC"]],
      limit: PER_RUN,
    }),
  ]);
  const keys = new Map<string, string | undefined>();
  for (const m of media) if (m.key) keys.set(m.key, m.mime_type || undefined);
  for (const m of [...messages, ...groupMessages] as any[]) if (m.url && !keys.has(m.url)) keys.set(m.url, undefined);
  return new Map([...keys].slice(0, PER_RUN));
}

/** Every row that points at [key] now says the file is in S3. */
async function markInS3(key: string) {
  await Promise.all([
    Media.update({ upload_type: "server" }, { where: { key, upload_type: "local" } }),
    Message.update({ url_upload_type: "server" }, { where: { url: key, url_upload_type: { [Op.in]: PENDING_MESSAGE } } }),
    GroupMessage.update({ url_upload_type: "server" } as any, { where: { url: key, url_upload_type: { [Op.in]: PENDING_MESSAGE } } as any }),
  ]);
}

export async function sweepUploads(
  opts: { now?: Date; only?: string[]; deps?: SweepDeps; batch?: number; pauseMs?: number } = {}
): Promise<SweepResult & { batches: number }> {
  const deps = opts.deps ?? realDeps;
  const keys = [...(await pendingKeys(opts.now, opts.only))];
  const result = { checked: keys.length, uploaded: [] as string[], alreadyInS3: [] as string[], missing: [] as string[], errors: [] as { key: string; error: string }[], batches: 0 };
  const size = opts.batch ?? BATCH;
  const pause = opts.pauseMs ?? BATCH_PAUSE_MS;

  for (let i = 0; i < keys.length; i += size) {
    if (i > 0 && pause > 0) await new Promise((r) => setTimeout(r, pause));
    result.batches++;
    // one batch: its files one after another
    for (const [key, mime] of keys.slice(i, i + size)) await sweepOne(key, mime, deps, result);
  }
  return result;
}

async function sweepOne(key: string, mime: string | undefined, deps: SweepDeps, result: SweepResult) {
    try {
      const file = deps.localPath(key);
      if (!path.resolve(file).startsWith(path.resolve(deps.localPath("")))) throw new Error("bad key");
      const onServer = fs.existsSync(file);
      if (onServer) {
        await deps.upload(key, file, mime);
        if (!(await deps.inS3(key))) throw new Error("not in S3 after upload");
        await markInS3(key);
        fs.unlink(file, () => undefined);
        result.uploaded.push(key);
      } else if (await deps.inS3(key)) {
        await markInS3(key);
        result.alreadyInS3.push(key);
      } else {
        result.missing.push(key);
        missingSince.set(key, Date.now());
      }
    } catch (e: any) {
      result.errors.push({ key, error: e?.message || String(e) });
    }
}

let timer: NodeJS.Timeout | null = null;
let running = false;

export function startUploadSweeper() {
  if (timer || process.env.MEDIA_UPLOAD_SWEEP !== "on") return;
  const run = async () => {
    if (running) return;
    running = true;
    let backlog = false;
    try {
      const r = await sweepUploads();
      backlog = r.checked >= PER_RUN;
      if (r.uploaded.length || r.alreadyInS3.length || r.errors.length) {
        console.log(
          `[uploads] to S3: ${r.uploaded.length} uploaded, ${r.alreadyInS3.length} already there, ${r.missing.length} missing, ${r.errors.length} errors (${r.batches} batches of ${BATCH})${backlog ? " — more waiting, next run in 1 min" : ""}`,
          r.errors.slice(0, 3)
        );
      }
    } catch (e: any) {
      console.warn("[uploads] sweep:", e?.message || e);
    } finally {
      running = false;
      timer = setTimeout(run, backlog ? BACKLOG_EVERY_MS : EVERY_MS);
    }
  };
  timer = setTimeout(run, 60_000); // first run a minute after start
}
