// Run: npx ts-node -T scripts/trips/tracking.check.ts
// The public tracking link against the LOCAL databases: every load has its own token; the page shows
// stops and activity in plain words, never driver names or internal notes; it expires once the load
// is completed. Throwaway driver with no phone token; cleans up after itself.
import "dotenv/config";
process.env.TRIP_ETA_SNAPSHOT = "off";
import assert from "assert";
import http from "http";
import { QueryTypes } from "sequelize";
import { primarySequelize, secondarySequelize } from "../../src/sequelize";
import { initSocket } from "../../src/sockets/socket";
import { UserProfile } from "../../src/models/UserProfile";
import User from "../../src/models/User";
import UserChannel from "../../src/models/UserChannel";
import Role from "../../src/models/Role";
import Channel from "../../src/models/Channel";
import Group from "../../src/models/Group";
import GroupUser from "../../src/models/GroupUser";
import GroupChannel from "../../src/models/GroupChannel";
import { MessageStaff } from "../../src/models/MessageStaff";
import { Message } from "../../src/models/Message";
import { ChatLoad, ChatTrip, ChatTripEvent, ChatTripStop } from "../../src/models/ChatTrip";
import { act } from "../../src/services/trips/tripService";
import { addLoad, getLoad } from "../../src/services/trips/loadService";
import { endLegNow } from "../../src/services/trips/loadControl";
import { allowLookup, MAX_TRIES, trackingByCode, trackingView } from "../../src/services/trips/publicTracking";

const local = (h?: string) => !h || /^(localhost|127\.0\.0\.1)$/.test(h);
if (!local(process.env.DB_PRIMARY_HOST) || !local(process.env.DB_SECONDARY_HOST)) {
  console.error("Refusing to run: the databases in .env are not local");
  process.exit(2);
}
const results: string[] = [];
const test = async (name: string, fn: () => Promise<void> | void) => {
  try {
    await fn();
    results.push(`ok   ${name}`);
  } catch (e: any) {
    results.push(`FAIL ${name}: ${e.message}`);
  }
};
UserProfile.associate({ User, Role, Channel, UserChannel, GroupUser });
UserChannel.associate({ UserProfile, Channel });
Group.associate({ Channel, GroupUser, GroupChannel });
GroupUser.associate({ UserProfile, Group });
GroupChannel.associate({ Group, Channel });
MessageStaff.associate({ UserProfile });

(async () => {
  initSocket(http.createServer());
  const driverRole = await Role.findOne({ where: { name: "driver" } });
  const staffRole = await Role.findOne({ where: { name: "staff" } });
  const [yardId] = await secondarySequelize.query(`INSERT INTO drivers (name, created_at, updated_at) VALUES ('ZZ TEST TRACKING', NOW(), NOW())`, { type: QueryTypes.INSERT });
  const user = await User.create({ driver_number: "zztrk01", status: "active", yard_id: Number(yardId) } as any);
  const driver = await UserProfile.create({ userId: user.id, role_id: driverRole!.id, username: "ZZ Secret Driver Name", device_token: null } as any);
  const staff = await UserProfile.findOne({ where: { role_id: staffRole!.id } });
  const channel = await primarySequelize.query<{ id: string }>(`SELECT id FROM channels WHERE name = 'demo' LIMIT 1`, { type: QueryTypes.SELECT });
  await UserChannel.create({ userProfileId: driver.id, channelId: channel[0].id } as any);
  const dispatcher = { role: "dispatcher" as const, id: staff!.id, name: staff!.username };
  const NO = `ZZT${Date.now() % 100000}`;
  const loadIds: number[] = [];
  try {
    let token = "";
    let legId = 0;
    await test("every load gets its own unguessable tracking token", async () => {
      const res = await addLoad(
        {
          loadNo: NO,
          driverProfileId: driver.id,
          truckNumber: "ZZ505",
          notes: "INTERNAL: pay driver extra",
          stops: [
            { type: "pickup", name: "ZZ COLD STORAGE", street: "1 Main St", city: "FRESNO", state: "CA", zip: "93701", appointment: "2026-11-20T08:00" },
            { type: "drop", name: "ZZ WAREHOUSE", street: "2 Main St", city: "FREMONT", state: "CA", zip: "94538", appointment: "2026-11-20T18:00" },
          ],
        },
        dispatcher,
        { send: true }
      );
      loadIds.push(res.load.id);
      legId = res.legs[0].id;
      token = (await ChatLoad.findByPk(res.load.id))!.track_token!;
      assert.match(token, /^[A-Za-z0-9_-]{24}$/);
      const other = await addLoad({ loadNo: `${NO}B`, driverProfileId: driver.id, stops: [{ type: "pickup", city: "FRESNO", state: "CA" }, { type: "drop", city: "FREMONT", state: "CA" }] }, dispatcher, { send: false });
      loadIds.push(other.load.id);
      assert.notEqual((await ChatLoad.findByPk(other.load.id))!.track_token, token);
      // The short code for the app: 6 easy characters, its own per load, finds the same view
      const code = (await ChatLoad.findByPk(res.load.id))!.track_code!;
      assert.match(code, /^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{6}$/);
      assert.notEqual((await ChatLoad.findByPk(other.load.id))!.track_code, code);
      const byCode: any = await trackingByCode(` ${code.toLowerCase()} `);
      assert.equal(byCode.loadNo, NO);
      await assert.rejects(trackingByCode("ZZZZZZ"), /No load with that tracking code/);
      // The load number works as the code too (zeros don't matter), and so does the old random code
      assert.equal(((await trackingByCode(NO)) as any).loadNo, NO);
      assert.equal(((await trackingByCode(` ${NO.toLowerCase()} `)) as any).loadNo, NO);
      assert.equal(((await trackingByCode(code)) as any).loadNo, NO);
      const numeric = String(Date.now() % 1000000).padStart(6, "8");
      const nr = await addLoad({ loadNo: `00${numeric}`, driverProfileId: driver.id, stops: [{ type: "pickup", city: "FRESNO", state: "CA" }, { type: "drop", city: "FREMONT", state: "CA" }] }, dispatcher, { send: false });
      loadIds.push(nr.load.id);
      assert.equal(((await trackingByCode(`00${numeric}`)) as any).loadNo, `00${numeric}`, "the number as staff typed it");
      await assert.rejects(trackingByCode(numeric), /No load with that tracking code/);
      await assert.rejects(trackingByCode("12"), /No load with that tracking code/);
      // Guessing is limited: 30 tries per 10 minutes from one device
      for (let i = 0; i < MAX_TRIES; i++) assert.equal(allowLookup("1.2.3.4", 1_000), true);
      assert.equal(allowLookup("1.2.3.4", 1_000), false);
      assert.equal(allowLookup("1.2.3.4", 1_000 + 11 * 60_000), true, "allowed again later");
      assert.equal(allowLookup("5.6.7.8", 1_000), true, "other devices are not affected");
    });

    await test("the page: load #, steps, stops with appointments, plain activity — no names or notes", async () => {
      const v: any = await trackingView(token);
      assert.equal(v.expired, false);
      assert.equal(v.loadNo, NO);
      assert.equal(v.phase, "dispatched");
      assert.deepEqual(v.stops.map((s: any) => [s.type, s.name, s.appointment]), [
        ["pickup", "ZZ COLD STORAGE", "2026-11-20T08:00"],
        ["drop", "ZZ WAREHOUSE", "2026-11-20T18:00"],
      ]);
      assert.deepEqual(v.activity.map((a: any) => a.text).reverse(), ["Load booked", "Dispatched to the driver"]);
      const json = JSON.stringify(v);
      assert(!json.includes("ZZ Secret Driver Name"), "no driver name");
      assert(!json.includes("INTERNAL"), "no internal notes");
      assert(!json.includes("profile"), "no ids of people");
    });

    await test("delivered → still shows; completed → the link expires", async () => {
      await act(legId, "accept", { role: "driver", id: driver.id, name: driver.username });
      await endLegNow(legId, dispatcher);
      await new Promise((r) => setTimeout(r, 31_000)); // past the 30 s cache
      const v: any = await trackingView(token);
      assert.equal(v.phase, "delivered");
      assert(v.activity.some((a: any) => a.text === "Delivered"));
      await act(legId, "complete", dispatcher);
      await getLoad(loadIds[0]);
      await new Promise((r) => setTimeout(r, 31_000));
      const done: any = await trackingView(token);
      assert.equal(done.expired, true);
      assert.equal(done.loadNo, NO);
      assert(!("stops" in done), "nothing else once expired");
    });
  } finally {
    const trips = await ChatTrip.findAll({ where: { load_id: loadIds } });
    const ids = trips.map((t) => t.id);
    if (ids.length) {
      await ChatTripEvent.destroy({ where: { chat_trip_id: ids } });
      await ChatTripStop.destroy({ where: { chat_trip_id: ids } });
      await ChatTrip.destroy({ where: { id: ids } });
    }
    if (loadIds.length) await ChatLoad.destroy({ where: { id: loadIds } });
    await Message.destroy({ where: { userProfileId: driver.id } });
    await UserChannel.destroy({ where: { userProfileId: driver.id } });
    await primarySequelize.query(`DELETE FROM driver_trips WHERE driver_id = :id`, { replacements: { id: driver.id } });
    await UserProfile.destroy({ where: { id: driver.id } });
    await User.destroy({ where: { id: user.id } });
    await secondarySequelize.query(`DELETE FROM drivers WHERE id = :id`, { replacements: { id: yardId } });
  }
  console.log(results.join("\n"));
  process.exit(results.some((r) => r.startsWith("FAIL")) ? 1 : 0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
