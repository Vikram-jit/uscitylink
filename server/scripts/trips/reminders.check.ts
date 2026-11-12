// Run: npx ts-node -T scripts/trips/reminders.check.ts
// Trip reminders against the LOCAL databases (refuses anything else): no "Got it" 30 / 60 min after a
// load is sent → driver reminded in chat + dispatch System Message; "Got it" but the pickup time passed
// → both alerted once. Never twice. Throwaway driver with no phone token; cleans up after itself.
import "dotenv/config";
process.env.TRIP_ETA_SNAPSHOT = "off";
import assert from "assert";
import http from "http";
import { Op, QueryTypes } from "sequelize";
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
import { addLoad } from "../../src/services/trips/loadService";
import { runReminders } from "../../src/services/trips/reminders";

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

const MIN = 60_000;
const STOPS = [
  { type: "pickup" as const, name: "ZZ REM PICK", city: "FRESNO", state: "CA" },
  { type: "drop" as const, name: "ZZ REM DROP", city: "FREMONT", state: "CA" },
];

(async () => {
  initSocket(http.createServer());
  const driverRole = await Role.findOne({ where: { name: "driver" } });
  const staffRole = await Role.findOne({ where: { name: "staff" } });
  const [yardId] = await secondarySequelize.query(`INSERT INTO drivers (name, created_at, updated_at) VALUES ('ZZ TEST REMINDER', NOW(), NOW())`, { type: QueryTypes.INSERT });
  const user = await User.create({ driver_number: "zzrem01", status: "active", yard_id: Number(yardId) } as any);
  const driver = await UserProfile.create({ userId: user.id, role_id: driverRole!.id, username: "ZZ Reminder Driver", device_token: null } as any);
  const staff = await UserProfile.findOne({ where: { role_id: staffRole!.id } });
  const channel = await primarySequelize.query<{ id: string }>(`SELECT id FROM channels WHERE name = 'demo' LIMIT 1`, { type: QueryTypes.SELECT });
  await UserChannel.create({ userProfileId: driver.id, channelId: channel[0].id } as any);
  const dispatcher = { role: "dispatcher" as const, id: staff!.id, name: staff!.username };
  const sys = await UserProfile.findOne({ include: [{ model: User, as: "user", where: { driver_number: "system001" }, required: true }] });
  const loadIds: number[] = [];
  const NO = `ZZR${Date.now() % 100000}`;
  const driverMsgs = async (re: RegExp) => (await Message.findAll({ where: { userProfileId: driver.id } })).filter((m) => re.test(String(m.body))).length;
  const systemMsgs = async (re: RegExp) => (sys ? (await Message.findAll({ where: { userProfileId: sys.id, body: { [Op.like]: `%${NO}%` } } })).filter((m) => re.test(String(m.body))) : []);

  try {
    let tripId = 0;

    await test("no Got it after 30 min: driver reminded + dispatch System Message; not twice", async () => {
      const res = await addLoad({ loadNo: NO, driverProfileId: driver.id, stops: STOPS }, dispatcher, { send: true });
      loadIds.push(res.load.id);
      tripId = res.legs[0].id;
      await runReminders();
      assert.equal(await driverMsgs(/Reminder: trip/), 0, "too early");
      await ChatTrip.update({ sent_at: new Date(Date.now() - 31 * MIN) }, { where: { id: tripId } });
      await runReminders();
      await runReminders();
      assert.equal(await driverMsgs(/Reminder: trip .* tap "Got it"/), 1, "driver reminded once");
      if (sys) {
        const sm = await systemMsgs(/hasn't tapped "Got it"/);
        assert.equal(sm.length, 1, "one System Message");
        assert((await MessageStaff.count({ where: { messageId: sm[0].id, status: "un-read" } })) > 0, "unread for staff");
      }
    });

    await test("still no Got it at 60 min: second reminder, then nothing more", async () => {
      await ChatTrip.update({ sent_at: new Date(Date.now() - 61 * MIN) }, { where: { id: tripId } });
      await runReminders();
      await runReminders();
      assert.equal(await driverMsgs(/Reminder: trip/), 2);
      if (sys) assert.equal((await systemMsgs(/second reminder/)).length, 1);
      await ChatTrip.update({ sent_at: new Date(Date.now() - 120 * MIN) }, { where: { id: tripId } });
      await runReminders();
      assert.equal(await driverMsgs(/Reminder: trip/), 2, "stops after two");
    });

    await test("Got it, pickup time passed, not rolling: both alerted once", async () => {
      await act(tripId, "accept", { role: "driver", id: driver.id, name: driver.username });
      const pickup = (await ChatTripStop.findAll({ where: { chat_trip_id: tripId } })).find((s) => s.type === "pickup")!;
      await pickup.update({ appointment_at: new Date(Date.now() + 30 * MIN), appointment_local: "2026-11-12T10:00" });
      await runReminders();
      assert.equal(await driverMsgs(/pickup time .* has passed/), 0, "not before the appointment");
      await pickup.update({ appointment_at: new Date(Date.now() - 20 * MIN) });
      await runReminders();
      await runReminders();
      assert.equal(await driverMsgs(/pickup time .* has passed/), 1, "driver alerted once");
      if (sys) assert.equal((await systemMsgs(/Pickup time passed: ZZ Reminder Driver/)).length, 1, "dispatch alerted once");
      // Rolling: nothing more
      await act(tripId, "rolling", { role: "driver", id: driver.id, name: driver.username });
      await runReminders();
      assert.equal(await driverMsgs(/pickup time .* has passed/), 1);
    });

    await test("old loads (sent hours ago) don't start reminding", async () => {
      const res = await addLoad({ loadNo: `${NO}B`, driverProfileId: driver.id, stops: STOPS }, dispatcher, { send: true, endDriverCurrent: true });
      loadIds.push(res.load.id);
      await ChatTrip.update({ sent_at: new Date(Date.now() - 5 * 60 * MIN) }, { where: { id: res.legs[0].id } });
      const before = await driverMsgs(/Reminder: trip/);
      await runReminders();
      assert.equal(await driverMsgs(/Reminder: trip/), before);
    });
  } finally {
    const trips = await ChatTrip.findAll({ where: { load_id: loadIds } });
    const ids = trips.map((t) => t.id);
    if (sys) {
      const sm = await Message.findAll({ where: { userProfileId: sys.id, body: { [Op.like]: `%${NO}%` } }, attributes: ["id"] });
      await MessageStaff.destroy({ where: { messageId: sm.map((m) => m.id) } });
      await Message.destroy({ where: { id: sm.map((m) => m.id) } });
    }
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
  console.log(`system user: ${sys ? "found" : "MISSING (System Message checks skipped)"}`);
  console.log(results.join("\n"));
  process.exit(results.some((r) => r.startsWith("FAIL")) ? 1 : 0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
