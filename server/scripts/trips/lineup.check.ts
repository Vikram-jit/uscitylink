// Run: npx ts-node -T scripts/trips/lineup.check.ts
// A driver's lineup against the LOCAL databases (refuses anything else): loads lined up for one driver
// are numbered in the order added, dispatch reorders them, #1 is what gets offered when the current
// load rolls / is delivered, blocked legs are skipped, a pickup before the previous delivery is flagged,
// sending #1 moves #2 up, and a load can be taken off the driver.
// Throwaway test drivers with no phone token; removes everything it created at the end.
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
import { ChatLoad, ChatTrip, ChatTripEvent } from "../../src/models/ChatTrip";
import { act, createTrip, sendLoad } from "../../src/services/trips/tripService";
import { assignLeg, createLoad } from "../../src/services/trips/loadService";
import { lineupOf, removeFromLineup, reorderLineup } from "../../src/services/trips/lineup";
import { driversBoard } from "../../src/services/trips/equipment";

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

/** pickup → drop with local appointments (California) */
const route = (tag: string, pickup: string, drop: string) => [
  { type: "pickup" as const, name: `ZZ PICK ${tag}`, city: "FRESNO", state: "CA", appointment: pickup },
  { type: "drop" as const, name: `ZZ DROP ${tag}`, city: "FONTANA", state: "CA", appointment: drop },
];

(async () => {
  initSocket(http.createServer());
  const driverRole = await Role.findOne({ where: { name: "driver" } });
  const staffRole = await Role.findOne({ where: { name: "staff" } });
  const yardIds: number[] = [];
  const users: User[] = [];
  const people: UserProfile[] = [];
  for (const n of ["A", "B"]) {
    const [yardId] = await secondarySequelize.query(`INSERT INTO drivers (name, created_at, updated_at) VALUES (:n, NOW(), NOW())`, {
      replacements: { n: `ZZ TEST LINEUP ${n}` },
      type: QueryTypes.INSERT,
    });
    yardIds.push(Number(yardId));
    const user = await User.create({ driver_number: `zzline${n}`, status: "active", yard_id: Number(yardId) } as any);
    users.push(user);
    people.push(await UserProfile.create({ userId: user.id, role_id: driverRole!.id, username: `ZZ Lineup Driver ${n}`, device_token: null } as any));
  }
  const [a, b] = people;
  const staff = await UserProfile.findOne({ where: { role_id: staffRole!.id } });
  const channel = await primarySequelize.query<{ id: string }>(`SELECT id FROM channels WHERE name = 'demo' LIMIT 1`, { type: QueryTypes.SELECT });
  for (const p of people) await UserChannel.create({ userProfileId: p.id, channelId: channel[0].id } as any);
  const dispatcher = { role: "dispatcher" as const, id: staff!.id, name: staff!.username };
  const asA = { role: "driver" as const, id: a.id, name: a.username };
  const tripIds: number[] = [];
  const loadIds: number[] = [];
  const add = async (tag: string, pickup: string, drop: string) => {
    const t = (await createTrip({ driverProfileId: a.id, stops: route(tag, pickup, drop) }, dispatcher))!;
    tripIds.push(t.id);
    loadIds.push(t.load_id!);
    return t;
  };
  const order = async () => (await lineupOf(a.id)).next.map((x) => x.tripId);

  try {
    let l1 = 0;
    let l2 = 0;
    let l3 = 0;
    let current = 0;

    await test("loads lined up for a driver are numbered in the order added (not by date)", async () => {
      l1 = (await add("1", "2026-11-20T08:00", "2026-11-20T18:00")).id;
      l2 = (await add("2", "2026-11-15T08:00", "2026-11-15T18:00")).id;
      l3 = (await add("3", "2026-11-25T08:00", "2026-11-25T18:00")).id;
      assert.deepEqual(await order(), [l1, l2, l3]);
      assert.deepEqual((await lineupOf(a.id)).next.map((x) => x.position), [1, 2, 3]);
      const board = (await driversBoard()).find((d) => d.profileId === a.id)!;
      assert.equal(board.lineup, 3);
      assert.equal(board.next?.tripId, l1);
    });

    await test("dispatch reorders the lineup; it's recorded on each moved load", async () => {
      await reorderLineup(a.id, [l3, l1, l2], dispatcher);
      assert.deepEqual(await order(), [l3, l1, l2]);
      const ev = await ChatTripEvent.findAll({ where: { chat_trip_id: l3, type: "edit" } });
      assert(ev.some((e) => e.note === "Lineup: now #1"));
    });

    await test("a leg still waiting for its first leg shows blocked and is skipped when offering", async () => {
      const res = await createLoad(
        {
          type: "via_yard",
          legs: [
            { driverProfileId: b.id, stops: [route("Y", "2026-11-12T08:00", "2026-11-12T18:00")[0], { type: "yard", name: "ZZ YARD", city: "FONTANA", state: "CA" }] },
            { stops: [route("Y", "", "2026-11-13T09:00")[1]] },
          ],
        },
        dispatcher
      );
      loadIds.push(res.load.id);
      const leg2 = res.legs[1];
      tripIds.push(...res.legs.map((l) => l.id));
      await assignLeg(res.load.id, leg2.id, { driverProfileId: a.id }, dispatcher);
      // Put it first: it still can't go before its leg 1
      await reorderLineup(a.id, [leg2.id, l3, l1, l2], dispatcher);
      const lineup = await lineupOf(a.id);
      assert.equal(lineup.next[0].tripId, leg2.id);
      assert.equal(lineup.next[0].blockedBy?.legNo, 1);
    });

    await test("the current load rolls: #1 that can go (load 3) is offered, not the earliest date", async () => {
      const c = (await createTrip({ driverProfileId: a.id, stops: route("NOW", "2026-11-11T08:00", "2026-11-22T10:00") }, dispatcher))!;
      tripIds.push(c.id);
      loadIds.push(c.load_id!);
      current = c.id;
      await sendLoad(current, dispatcher);
      await act(current, "accept", asA);
      await act(current, "rolling", asA);
      await new Promise((r) => setTimeout(r, 600));
      assert.equal((await ChatTrip.findByPk(l3))?.status, "offered");
      assert.equal((await ChatTrip.findByPk(l2))?.status, "scheduled", "earliest date is not jumped ahead");
      const lineup = await lineupOf(a.id);
      assert.equal(lineup.now?.tripId, current);
    });

    await test("a pickup before the previous delivery is flagged", async () => {
      const lineup = await lineupOf(a.id);
      const item = (id: number) => lineup.next.find((x) => x.tripId === id)!;
      assert.equal(item(l3).fit, null, "11/25 pickup is after the current 11/22 delivery");
      assert.match(String(item(l1).fit), /Pickup 11\/20 08:00 AM is before #\d's delivery 11\/25 06:00 PM/);
    });

    await test("sending #1 moves the next one up", async () => {
      const before = await order();
      await sendLoad(l3, dispatcher);
      const after = await order();
      assert.deepEqual(after, before.filter((id) => id !== l3));
    });

    await test("a load can be taken off the driver; new loads go to the end", async () => {
      await removeFromLineup(a.id, l2, dispatcher);
      const l2row = await ChatTrip.findByPk(l2);
      assert.equal(l2row?.driver_profile_id, null);
      assert(!(await order()).includes(l2));
      const l4 = (await add("4", "2026-11-28T08:00", "2026-11-28T18:00")).id;
      const list = await order();
      assert.equal(list[list.length - 1], l4);
      assert.deepEqual((await lineupOf(a.id)).next.map((x) => x.position), list.map((_, i) => i + 1));
    });
  } finally {
    const trips = await ChatTrip.findAll({ where: { load_id: loadIds } });
    const ids = [...new Set([...tripIds, ...trips.map((t) => t.id)])];
    const routeIds = trips.map((t) => t.driver_pay_details_id).filter(Boolean);
    if (routeIds.length) {
      await secondarySequelize.query(`DELETE FROM driver_pay_mileages WHERE driver_pay_details_id IN (:ids)`, { replacements: { ids: routeIds } });
      await secondarySequelize.query(`DELETE FROM driver_expenses WHERE driver_pay_details_id IN (:ids)`, { replacements: { ids: routeIds } });
      await secondarySequelize.query(`DELETE FROM driver_pay_details WHERE id IN (:ids)`, { replacements: { ids: routeIds } });
    }
    if (ids.length) {
      await ChatTripEvent.destroy({ where: { chat_trip_id: ids } });
      await ChatTrip.destroy({ where: { id: ids } });
    }
    if (loadIds.length) await ChatLoad.destroy({ where: { id: loadIds } });
    const pids = people.map((p) => p.id);
    await Message.destroy({ where: { userProfileId: pids } });
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
