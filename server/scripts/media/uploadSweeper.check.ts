// Run: npx ts-node -T scripts/media/uploadSweeper.check.ts
// The job that finishes chat uploads the queue never copied to S3, against the LOCAL database (refuses
// anything else) with a fake S3 and a temp folder for the server copies: nothing reaches the real bucket.
// Only its own rows (keys uscitylink/zz-sweep-…) are created, swept and removed.
import "dotenv/config";
import assert from "assert";
import fs from "fs";
import os from "os";
import path from "path";
import { Op } from "sequelize";
import { primarySequelize } from "../../src/sequelize";
import { Media } from "../../src/models/Media";
import { Message } from "../../src/models/Message";
import GroupMessage from "../../src/models/GroupMessage";
import { sweepUploads, SweepDeps } from "../../src/services/media/uploadSweeper";

const host = (primarySequelize.config as any).host || "localhost";
if (!["localhost", "127.0.0.1", "", undefined].includes(host)) throw new Error(`refusing to run against ${host}`);

const CHANNEL = "1cb8a91e-921f-40fc-873f-af30d2ee3da0";
const DRIVER = "f645478e-9938-4e66-94c5-023793a035d1";
const GROUP = "9e0fe7cb-e410-4b66-9500-58f98c9dc4d4";
const STAFF = "c83b1608-432e-4aa7-957b-b3863d27eb35";
const run = Date.now();
const key = (name: string) => `uscitylink/zz-sweep-${run}-${name}.jpg`;
const minutesAgo = (m: number) => new Date(Date.now() - m * 60_000);

const dir = fs.mkdtempSync(path.join(os.tmpdir(), "zz-sweep-"));
const inBucket = new Set<string>();
const uploads: string[] = [];
let failUploadOf = "";
const deps: SweepDeps = {
  localPath: (k) => path.join(dir, k),
  inS3: async (k) => inBucket.has(k),
  upload: async (k, file) => {
    assert.ok(fs.existsSync(file));
    uploads.push(k);
    if (k !== failUploadOf) inBucket.add(k);
  },
};
const onServer = (k: string) => {
  fs.mkdirSync(path.dirname(deps.localPath(k)), { recursive: true });
  fs.writeFileSync(deps.localPath(k), "jpg");
};

async function makeRows(k: string, ageMin: number, group = false) {
  const media = await Media.create({ user_profile_id: DRIVER, channelId: CHANNEL, key: k, file_name: path.basename(k), mime_type: "image/jpeg", upload_type: "local", upload_source: "message" } as any);
  const msg = await Message.create({ channelId: CHANNEL, userProfileId: DRIVER, senderId: DRIVER, body: "", messageDirection: "R", deliveryStatus: "sent", messageTimestampUtc: new Date(), status: "sent", type: "default", url: k, url_upload_type: "not-upload" } as any);
  const g = group ? await GroupMessage.create({ groupId: GROUP, senderId: STAFF, body: "", deliveryStatus: "sent", messageTimestampUtc: new Date(), url: k, url_upload_type: "not-upload" } as any) : null;
  const at = minutesAgo(ageMin);
  await Media.update({ createdAt: at } as any, { where: { id: media.id }, silent: true } as any);
  await Message.update({ createdAt: at } as any, { where: { id: msg.id }, silent: true } as any);
  if (g) await GroupMessage.update({ createdAt: at } as any, { where: { id: g.id }, silent: true } as any);
}
const state = async (k: string) => ({
  media: (await Media.findOne({ where: { key: k } }))?.upload_type,
  message: (await Message.findOne({ where: { url: k } }))?.url_upload_type,
  group: (await GroupMessage.findOne({ where: { url: k } }) as any)?.url_upload_type,
});

let pass = 0;
const ok = async (name: string, fn: () => Promise<void>) => {
  await fn();
  pass++;
  console.log("  ✓", name);
};

(async () => {
  const A = key("on-server"), B = key("young"), C = key("already-in-s3"), D = key("nowhere"), E = key("upload-lost");
  const all = [A, B, C, D, E];
  try {
    await makeRows(A, 45, true); onServer(A);
    await makeRows(B, 10); onServer(B);
    await makeRows(C, 120);
    inBucket.add(C);
    await makeRows(D, 120);
    await makeRows(E, 60); onServer(E); failUploadOf = E;

    const r = await sweepUploads({ only: all, deps, pauseMs: 0 });

    await ok("a file still on the server after 30 min goes to S3; media, message and group message say server; server copy removed", async () => {
      assert.deepEqual(r.uploaded, [A]);
      assert.deepEqual(await state(A), { media: "server", message: "server", group: "server" });
      await new Promise((res) => setTimeout(res, 50));
      assert.equal(fs.existsSync(deps.localPath(A)), false);
    });
    await ok("a file younger than 30 min is left to the queue", async () => {
      assert.ok(!uploads.includes(B));
      assert.deepEqual(await state(B), { media: "local", message: "not-upload", group: undefined });
      assert.ok(fs.existsSync(deps.localPath(B)));
    });
    await ok("already in S3 (the queue died before updating the rows): only the rows are fixed", async () => {
      assert.deepEqual(r.alreadyInS3, [C]);
      assert.deepEqual(await state(C), { media: "server", message: "server", group: undefined });
    });
    await ok("in neither place: reported, rows untouched", async () => {
      assert.deepEqual(r.missing, [D]);
      assert.deepEqual(await state(D), { media: "local", message: "not-upload", group: undefined });
    });
    await ok("an upload S3 doesn't confirm is an error: rows untouched, server copy kept for the next run", async () => {
      assert.equal(r.errors.length, 1);
      assert.equal(r.errors[0].key, E);
      assert.deepEqual(await state(E), { media: "local", message: "not-upload", group: undefined });
      assert.ok(fs.existsSync(deps.localPath(E)));
    });
    await ok("the next run picks up only what is still waiting; a file found nowhere waits a day before it is looked for again", async () => {
      failUploadOf = "";
      const again = await sweepUploads({ only: all, deps, pauseMs: 0 });
      assert.deepEqual(again.uploaded, [E]);
      assert.deepEqual(again.missing, [], "D was skipped");
      assert.equal(again.checked, 1);
    });
    await ok("a backlog goes up in batches of 10, one batch after another with a pause in between", async () => {
      const many = Array.from({ length: 23 }, (_, i) => key(`bulk-${String(i).padStart(2, "0")}`));
      all.push(...many);
      for (const k of many) {
        await makeRows(k, 40);
        onServer(k);
      }
      let inFlight = 0, most = 0;
      const timed: SweepDeps = {
        ...deps,
        upload: async (k, f) => {
          inFlight++;
          most = Math.max(most, inFlight);
          await new Promise((res) => setTimeout(res, 5));
          await deps.upload(k, f);
          inFlight--;
        },
      };
      const t = Date.now();
      const bulk = await sweepUploads({ only: many, deps: timed, pauseMs: 300 });
      assert.equal(bulk.batches, 3, "10 + 10 + 3");
      assert.equal(bulk.uploaded.length, 23);
      assert.equal(most, 1, "never more than one upload at a time");
      assert.ok(Date.now() - t >= 600, "two pauses between the three batches");
      for (const k of many) assert.equal((await state(k)).media, "server");
    });
  } finally {
    await GroupMessage.destroy({ where: { url: { [Op.in]: all } } as any });
    await Message.destroy({ where: { url: { [Op.in]: all } } });
    await Media.destroy({ where: { key: { [Op.in]: all } } });
    fs.rmSync(dir, { recursive: true, force: true });
  }
  console.log(`\n${pass} passed`);
  process.exit(0);
})().catch((e) => {
  console.error("FAILED:", e);
  process.exit(1);
});
