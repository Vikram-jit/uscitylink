// Run: npx ts-node -T scripts/trips/truckGroup.check.ts
// A load sent in a TRUCK chat (a group of 1-2 drivers) against the LOCAL databases (refuses anything
// else): one load per send — never one per member —, the standard load message shows in the truck
// group for staff and for every member, and the trip card is on the truck's main driver.
// Throwaway drivers / group with no phone token; removes everything it created at the end.
import "dotenv/config";
process.env.TRIP_ETA_SNAPSHOT = "off";
import assert from "assert";
import http from "http";
import { Op, QueryTypes } from "sequelize";
import { primarySequelize, secondarySequelize } from "../../src/sequelize";
import { initSocket } from "../../src/sockets/socket";
import { messageToDriverByTruckGroup } from "../../src/sockets/messageHandler";
import { UserProfile } from "../../src/models/UserProfile";
import User from "../../src/models/User";
import UserChannel from "../../src/models/UserChannel";
import Role from "../../src/models/Role";
import Channel from "../../src/models/Channel";
import Group from "../../src/models/Group";
import GroupUser from "../../src/models/GroupUser";
import GroupChannel from "../../src/models/GroupChannel";
import GroupMessage from "../../src/models/GroupMessage";
import { MessageStaff } from "../../src/models/MessageStaff";
import { Message } from "../../src/models/Message";
import { ChatLoad, ChatTrip, ChatTripEvent, ChatTripStop } from "../../src/models/ChatTrip";
import { registerTripHooks } from "../../src/services/trips/tripAssistant";
import { addLoad, convertMessageToLoad, loadFromText } from "../../src/services/trips/loadService";

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
const wait = (ms: number) => new Promise((r) => setTimeout(r, ms));

UserProfile.associate({ User, Role, Channel, UserChannel, GroupUser });
UserChannel.associate({ UserProfile, Channel });
Group.associate({ Channel, GroupUser, GroupChannel });
GroupUser.associate({ UserProfile, Group });
GroupChannel.associate({ Group, Channel });
MessageStaff.associate({ UserProfile });

const TAG = `${Date.now() % 100000}`;
const LOAD_NO = `ZZ${TAG}G`;
const LOAD = (no: string) => `LOAD # ${no}\nTRAILER # WILL ADVISE\nTEMP # REFER BILLS\nPICK #\nZZ 4Earth Farms\n5555 E Olympic Blvd\nCommerce, CA 90022\n11/20/2026 07:00PM\nDROP #\nZZ WCD Franklin\n4040 Scottsville Rd\nFranklin, KY 42134\n11/22/2026 12:01AM`;

(async () => {
  const io = initSocket(http.createServer()) as any;
  registerTripHooks();
  const driverRole = await Role.findOne({ where: { name: "driver" } });
  const staffRole = await Role.findOne({ where: { name: "staff" } });
  const yardIds: number[] = [];
  const users: User[] = [];
  const people: UserProfile[] = [];
  for (const n of ["A", "B"]) {
    const [yardId] = await secondarySequelize.query(`INSERT INTO drivers (name, created_at, updated_at) VALUES (:n, NOW(), NOW())`, {
      replacements: { n: `ZZ TEST TRUCKGRP ${n}` },
      type: QueryTypes.INSERT,
    });
    yardIds.push(Number(yardId));
    const user = await User.create({ driver_number: `zztg${n}${TAG}`, status: "active", yard_id: Number(yardId) } as any);
    users.push(user);
    people.push(await UserProfile.create({ userId: user.id, role_id: driverRole!.id, username: `ZZ TruckGrp Driver ${n}`, device_token: null } as any));
  }
  const [a, b] = people;
  const staff = await UserProfile.findOne({ where: { role_id: staffRole!.id } });
  const channel = await primarySequelize.query<{ id: string }>(`SELECT id FROM channels WHERE name = 'demo' LIMIT 1`, { type: QueryTypes.SELECT });
  const channelId = channel[0].id;
  for (const p of people) await UserChannel.create({ userProfileId: p.id, channelId } as any);
  const group = await Group.create({ name: `ZZTRUCK${TAG}`, type: "truck", description: "test" } as any);
  for (const p of people) await GroupUser.create({ groupId: group.id, userProfileId: p.id, status: "active" } as any);
  (global as any).staffActiveChannel[staff!.id] = { channelId, groupId: group.id };
  const socket = { user: { id: staff!.id, name: staff!.username } } as any;
  const loadIds = new Set<number>();
  const sendInGroup = async (text: string, members = [a.id, b.id]) => {
    await messageToDriverByTruckGroup(io, socket, members.join(","), group.id, text, "S", "", null);
    await wait(3500);
  };
  const legsOf = async (no: string) => {
    const load = await ChatLoad.findOne({ where: { invoice_no: no } });
    if (load) loadIds.add(load.id);
    return load ? ChatTrip.findAll({ where: { load_id: load.id }, order: [["leg_no", "ASC"]] }) : [];
  };

  try {
    await test("a load pasted in a truck chat with 2 members makes ONE load, for the truck's first driver", async () => {
      await sendInGroup(LOAD(LOAD_NO));
      const legs = (await legsOf(LOAD_NO)).filter((l) => l.status !== "cancelled");
      assert.equal(legs.length, 1, `one leg, got ${legs.length}`);
      assert.equal(legs[0].driver_profile_id, a.id, "the main driver");
      assert.equal(legs[0].leg_no, 1);
      assert.equal(await ChatLoad.count({ where: { invoice_no: LOAD_NO } }), 1, "one load");
    });

    await test("the load stays in the truck chat exactly as dispatch pasted it: once for staff and once per member — nothing rewritten or added, no duplicates", async () => {
      const raw = LOAD(LOAD_NO).trim();
      const rows = await Message.findAll({ where: { groupId: group.id, body: { [Op.like]: `%LOAD # ${LOAD_NO}%` } }, order: [["createdAt", "ASC"]] });
      assert(rows.every((m) => String(m.body).trim() === raw), "every copy is the pasted text, unchanged");
      const staffView = rows.filter((m) => m.type === "default");
      assert.equal(staffView.length, 1, `staff see the load once in the truck chat, got ${staffView.length}`);
      for (const p of [a, b]) {
        const mine = rows.filter((m) => m.type === "truck_group" && m.userProfileId === p.id);
        assert.equal(mine.length, 1, `${p.username} sees the load once in the truck group, got ${mine.length}`);
      }
      assert.equal(await Message.count({ where: { groupId: group.id, body: { [Op.like]: `LOAD # ${LOAD_NO}\n\nTRUCK #%` } } }), 0, "no standard-layout copy");
      const trip = (await legsOf(LOAD_NO))[0];
      assert.equal(trip.message_id, staffView[0].id, "the load is that message");
    });

    await test("the same send from the Send load button / pasted box (loadFromText) shows in the truck chat once, word for word", async () => {
      const no = `${LOAD_NO}B`;
      const text = LOAD(no).trim();
      // From the truck chat: no driver given — the truck's main driver is used (A is on the first load: end it)
      await loadFromText(text, null, { role: "dispatcher", id: staff!.id, name: staff!.username }, { endDriverCurrent: true, endPrevious: true }, channelId, group.id).catch((e) => {
        throw new Error(`loadFromText: ${e.message}`);
      });
      await wait(1500);
      const legs = (await legsOf(no)).filter((l) => l.status !== "cancelled");
      assert.equal(legs.length, 1, "one load, the message did not make another");
      const rows = await Message.findAll({ where: { groupId: group.id, body: { [Op.like]: `%LOAD # ${no}\n%` } } });
      assert(rows.every((m) => m.body === text), "the pasted text exactly");
      assert.equal(rows.filter((m) => m.type === "default").length, 1, "the truck chat got the load once");
      assert.deepEqual(rows.filter((m) => m.type === "truck_group").map((m) => m.userProfileId).sort(), [a.id, b.id].sort(), "each member got it once");
      assert(rows.every((m) => m.senderId === staff!.id && !m.is_automated), "the dispatcher's own message in the truck chat (their name, normal bubble), not the Dispatch Assistant's");
      assert.equal(legs[0].driver_profile_id, a.id, "on the main driver");
      assert(legs[0].driver_id_2, "the team mate is linked");
    });

    await test("Convert to load on a truck chat message: one load on the main driver, team mate linked, nothing posted to the members", async () => {
      const no = `${LOAD_NO}C`;
      const skipped = await Message.create({ channelId, groupId: group.id, userProfileId: staff!.id, senderId: staff!.id, body: LOAD(no), messageDirection: "S", deliveryStatus: "sent", status: "sent", messageTimestampUtc: new Date(), type: "default", is_automated: true } as any);
      const before = await Message.count({ where: { groupId: group.id } });
      const out = await convertMessageToLoad(skipped.id, { role: "dispatcher", id: staff!.id, name: staff!.username });
      loadIds.add(out.data.load.id);
      const leg = out.data.legs[0];
      assert.equal(leg.driver_profile_id, a.id, "main driver");
      assert(leg.driver_id_2, "team mate linked");
      assert.equal(leg.truck_number, group.name, "the truck of this chat");
      assert.equal(leg.sent_at, null, "not sent");
      assert.equal(await Message.count({ where: { groupId: group.id } }), before, "nothing posted in the truck chat");
    });

    await test("no driver / team named: the truck's members are the team (driver + team mate, by name in the load detail); an explicit 'no team' is kept", async () => {
      const mk = async (no: string, extra: any) => {
        const res = await addLoad({ loadNo: no, driverProfileId: a.id, truckNumber: group.name, stops: [{ type: "drop", name: "ZZ DROP", city: "FRESNO", state: "CA" }], ...extra }, { role: "dispatcher", id: staff!.id, name: staff!.username }, { send: false });
        loadIds.add(res.load.id);
        return res;
      };
      // Only a truck + driver given (team not mentioned) → the other member joins
      const auto = await mk(`${LOAD_NO}T1`, {});
      assert(auto.legs[0].driver_id_2, "the other member is the team mate");
      assert.equal((auto as any).teamNames[String(auto.legs[0].id)], b.username, "the load detail names the team mate, not '+ team'");
      assert.equal(auto.driverNames[a.id], a.username);
      // The form says "no team" on purpose (null) → kept
      const none = await mk(`${LOAD_NO}T2`, { teamDriverProfileId: null });
      assert.equal(none.legs[0].driver_id_2, null);
      assert.deepEqual((none as any).teamNames, {});
      // Only a truck number (no driver, no team) → main driver + team mate from the group
      const res = await addLoad({ loadNo: `${LOAD_NO}T3`, truckNumber: group.name, stops: [{ type: "drop", name: "ZZ DROP", city: "FRESNO", state: "CA" }] }, { role: "dispatcher", id: staff!.id, name: staff!.username }, { send: false });
      loadIds.add(res.load.id);
      assert.equal(res.legs[0].driver_profile_id, a.id);
      assert(res.legs[0].driver_id_2);
    });

    await test("a plain (non-load) message to the group still reaches every member once", async () => {
      const tripsBefore = await ChatTrip.count({ where: { driver_profile_id: [a.id, b.id] } });
      await sendInGroup("please call dispatch");
      const rows = await Message.findAll({ where: { groupId: group.id, body: "please call dispatch" } });
      assert.equal(rows.filter((m) => m.type === "default").length, 1);
      assert.equal(rows.filter((m) => m.type === "truck_group").length, 2);
      assert.equal(await ChatTrip.count({ where: { driver_profile_id: [a.id, b.id] } }), tripsBefore, "no load from plain text");
    });
  } finally {
    const trips = await ChatTrip.findAll({ where: { [Op.or]: [{ load_id: [...loadIds] }, { driver_profile_id: people.map((p) => p.id) }] } });
    const ids = trips.map((t) => t.id);
    const allLoads = [...new Set([...loadIds, ...trips.map((t) => t.load_id).filter(Boolean)])] as number[];
    if (ids.length) {
      await ChatTripEvent.destroy({ where: { chat_trip_id: ids } });
      await ChatTripStop.destroy({ where: { chat_trip_id: ids } });
      await ChatTrip.destroy({ where: { id: ids } });
    }
    if (allLoads.length) await ChatLoad.destroy({ where: { id: allLoads } });
    const pids = people.map((p) => p.id);
    // groups.last_message_id points at a message: let go of it first
    await Group.update({ last_message_id: null as any }, { where: { id: group.id } });
    await Message.destroy({ where: { [Op.or]: [{ groupId: group.id }, { userProfileId: pids }] } });
    await GroupMessage.destroy({ where: { groupId: group.id } });
    await GroupUser.destroy({ where: { groupId: group.id } });
    await Group.destroy({ where: { id: group.id } });
    delete (global as any).staffActiveChannel[staff!.id];
    await UserChannel.destroy({ where: { userProfileId: pids } });
    await primarySequelize.query(`DELETE FROM driver_trips WHERE driver_id IN (:ids)`, { replacements: { ids: pids } });
    await UserProfile.destroy({ where: { id: pids } });
    await User.destroy({ where: { id: users.map((u) => u.id) } });
    await secondarySequelize.query(`DELETE FROM drivers WHERE id IN (:ids)`, { replacements: { ids: yardIds } });
  }
  console.log(results.join("\n"));
  process.exit(results.some((r) => r.startsWith("FAIL")) ? 1 : 0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
