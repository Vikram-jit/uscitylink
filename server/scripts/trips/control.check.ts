// Run: npx ts-node -T scripts/trips/control.check.ts
// Full control of a load against the LOCAL databases (refuses anything else): hand a moving load to
// another driver / truck mid-way, undo it, same driver on a new truck (breakdown), correct times,
// typed miles, miles by driver / truck, change the load type, the load's history.
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
import { ChatLoad, ChatTrip, ChatTripEvent, ChatTripStop } from "../../src/models/ChatTrip";
import { act, addMileage, createTrip, sendLoad, upcomingFor } from "../../src/services/trips/tripService";
import { getLoad } from "../../src/services/trips/loadService";
import { changeType, correctTimes, releaseLeg, setMiles, splitLeg, undoSplit } from "../../src/services/trips/loadControl";
import { milesReport } from "../../src/services/trips/milesReport";
import { lineupOf } from "../../src/services/trips/lineup";

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

const STOPS = [
  { type: "pickup" as const, name: "ZZ PICK", city: "FRESNO", state: "CA", appointment: "2026-11-10T08:00" },
  { type: "drop" as const, name: "ZZ DROP ONE", city: "PHOENIX", state: "AZ", appointment: "2026-11-11T08:00" },
  { type: "drop" as const, name: "ZZ DROP TWO", city: "DALLAS", state: "TX", appointment: "2026-11-13T08:00" },
];
const KINGMAN = { type: "switch" as const, name: "ZZ TA KINGMAN", city: "KINGMAN", state: "AZ" };
const types = (stops?: ChatTripStop[]) => [...(stops || [])].sort((a, b) => a.seq - b.seq).map((s) => `${s.type}:${s.name}`);
const lastMsg = async (id: string, re: RegExp) =>
  String((await Message.findAll({ where: { userProfileId: id }, order: [["createdAt", "DESC"]], limit: 10 })).find((m) => re.test(String(m.body)))?.body || "");

(async () => {
  initSocket(http.createServer());
  const driverRole = await Role.findOne({ where: { name: "driver" } });
  const staffRole = await Role.findOne({ where: { name: "staff" } });
  const yardIds: number[] = [];
  const users: User[] = [];
  const people: UserProfile[] = [];
  for (const n of ["A", "B"]) {
    const [yardId] = await secondarySequelize.query(`INSERT INTO drivers (name, created_at, updated_at) VALUES (:n, NOW(), NOW())`, {
      replacements: { n: `ZZ TEST CONTROL ${n}` },
      type: QueryTypes.INSERT,
    });
    yardIds.push(Number(yardId));
    const user = await User.create({ driver_number: `zzctl${n}`, status: "active", yard_id: Number(yardId) } as any);
    users.push(user);
    people.push(await UserProfile.create({ userId: user.id, role_id: driverRole!.id, username: `ZZ Control Driver ${n}`, device_token: null } as any));
  }
  const [a, b] = people;
  const staff = await UserProfile.findOne({ where: { role_id: staffRole!.id } });
  const channel = await primarySequelize.query<{ id: string }>(`SELECT id FROM channels WHERE name = 'demo' LIMIT 1`, { type: QueryTypes.SELECT });
  for (const p of people) await UserChannel.create({ userProfileId: p.id, channelId: channel[0].id } as any);
  const dispatcher = { role: "dispatcher" as const, id: staff!.id, name: staff!.username };
  const asA = { role: "driver" as const, id: a.id, name: a.username };
  const asB = { role: "driver" as const, id: b.id, name: b.username };
  const loadIds: number[] = [];
  const t0 = new Date(Date.now() - 6 * 3600_000);

  try {
    let leg1 = 0;
    let loadId = 0;
    let leg2 = 0;

    await test("hand over a moving load: leg 1 ends at the place, leg 2 takes the rest with the new driver / truck", async () => {
      const trip = (await createTrip({ driverProfileId: a.id, truckNumber: "ZZT1", trailerNumbers: ["ZZTR1"], stops: STOPS }, dispatcher))!;
      leg1 = trip.id;
      loadId = trip.load_id!;
      loadIds.push(loadId);
      await sendLoad(leg1, dispatcher);
      await act(leg1, "accept", asA);
      await act(leg1, "rolling", asA);
      const stops = (await ChatTripStop.findAll({ where: { chat_trip_id: leg1 } })).sort((x, y) => x.seq - y.seq);
      await act(leg1, "arrive", asA, { stopId: stops[1].id });
      const res = await splitLeg(leg1, { when: "now", place: KINGMAN, driverProfileId: b.id, truckNumber: "ZZT2", reason: "breakdown", note: "engine light" }, dispatcher);
      leg2 = res.next;
      const one = (await ChatTrip.findByPk(leg1, { include: [{ model: ChatTripStop, as: "stops" }] }))!;
      const two = (await ChatTrip.findByPk(leg2, { include: [{ model: ChatTripStop, as: "stops" }] }))!;
      assert.equal(one.status, "ended");
      assert(one.ended_at, "ended at the handover");
      assert.equal(one.handover_reason, "breakdown");
      assert.deepEqual(types(one.stops), ["pickup:ZZ PICK", "drop:ZZ DROP ONE", "switch:ZZ TA KINGMAN"]);
      assert([...one.stops!].find((s) => s.type === "switch")?.arrived_at, "handover stop arrived");
      assert.deepEqual(types(two.stops), ["switch:ZZ TA KINGMAN", "drop:ZZ DROP TWO"]);
      assert.equal(two.trip_no, `${one.trip_no}-2`);
      assert.equal(two.driver_profile_id, b.id);
      assert.equal(two.truck_number, "ZZT2");
      assert.equal(two.trailer_numbers, "ZZTR1", "trailer carried over");
      assert.equal(two.status, "offered");
      assert.equal((await lineupOf(b.id)).next[0]?.tripId, leg2, "#1 in B's lineup");
      const load = (await ChatLoad.findByPk(loadId))!;
      assert.equal(load.type, "relay");
      assert.match(await lastMsg(a.id, /handed over/), /handed over at ZZ TA KINGMAN · KINGMAN, AZ \(breakdown\)/);
      const detail = await getLoad(loadId);
      const t = detail.history.find((h) => h.type === "transfer" && h.legNo === 1);
      assert.match(String(t?.note), /Breakdown: ZZ Control Driver A \/ truck ZZT1 → ZZ Control Driver B \/ truck ZZT2 at ZZ TA KINGMAN · KINGMAN, AZ — engine light/);
      assert.deepEqual(detail.segments.map((s) => [s.legNo, s.truck, s.drivers[0]]), [
        [1, "ZZT1", "ZZ Control Driver A"],
        [2, "ZZT2", "ZZ Control Driver B"],
      ]);
    });

    await test("undo the handover before leg 2 starts: everything goes back to leg 1", async () => {
      await undoSplit(leg2, dispatcher);
      const one = (await ChatTrip.findByPk(leg1, { include: [{ model: ChatTripStop, as: "stops" }] }))!;
      assert.equal(one.status, "rolling");
      assert.equal(one.ended_at, null);
      assert.equal(one.handover_reason, null);
      assert.deepEqual(types(one.stops), ["pickup:ZZ PICK", "drop:ZZ DROP ONE", "drop:ZZ DROP TWO"]);
      assert.equal((await ChatTrip.findByPk(leg2))?.status, "cancelled");
      assert.equal((await ChatLoad.findByPk(loadId))?.type, "direct");
      assert.match(await lastMsg(a.id, /continues with you/), /undid the handover/);
      assert(!(await lineupOf(b.id)).next.some((x) => x.tripId === leg2));
    });

    await test("breakdown, same driver on a new truck: two legs, same driver, different trucks", async () => {
      const res = await splitLeg(leg1, { when: "now", place: KINGMAN, driverProfileId: a.id, truckNumber: "ZZT3", reason: "breakdown", send: true }, dispatcher);
      leg2 = res.next;
      const two = (await ChatTrip.findByPk(leg2))!;
      assert.equal(two.driver_profile_id, a.id);
      assert.equal(two.truck_number, "ZZT3");
      assert.equal(two.status, "planned", "sent right away");
      assert.equal((await ChatTrip.findByPk(leg1))?.truck_number, "ZZT1");
    });

    await test("handing over a leg that itself started at a meet point doesn't pass that start on", async () => {
      for (const x of ["accept", "rolling"] as const) await act(leg2, x, asA);
      const res = await splitLeg(leg2, { when: "now", place: { type: "switch", name: "ZZ TA BARSTOW", city: "BARSTOW", state: "CA" }, driverProfileId: b.id, reason: "out_of_hours" }, dispatcher);
      const three = (await ChatTrip.findByPk(res.next, { include: [{ model: ChatTripStop, as: "stops" }] }))!;
      assert.deepEqual(types(three.stops), ["switch:ZZ TA BARSTOW", "drop:ZZ DROP TWO"]);
      const two = (await ChatTrip.findByPk(leg2, { include: [{ model: ChatTripStop, as: "stops" }] }))!;
      assert.deepEqual(types(two.stops), ["switch:ZZ TA KINGMAN", "switch:ZZ TA BARSTOW"]);
      await undoSplit(res.next, dispatcher);
      const back = (await ChatTrip.findByPk(leg2, { include: [{ model: ChatTripStop, as: "stops" }] }))!;
      assert.equal(back.status, "rolling");
      assert.deepEqual(types(back.stops), ["switch:ZZ TA KINGMAN", "drop:ZZ DROP TWO"]);
    });

    await test("correct times: wrong order refused; a real fix is recorded with before / after", async () => {
      const one = (await ChatTrip.findByPk(leg1))!;
      const start = new Date(one.started_at!);
      await assert.rejects(correctTimes(leg1, { endedAt: new Date(start.getTime() - 3600_000).toISOString() }, "typo", dispatcher), /end can't be before the start/);
      await assert.rejects(correctTimes(leg1, { endedAt: new Date(Date.now() + 86400_000).toISOString() }, "typo", dispatcher), /in the future/);
      await assert.rejects(correctTimes(leg1, { endedAt: new Date().toISOString() }, "", dispatcher), /Say why/);
      // The driver really rolled 5 h ago and handed over 1 h ago
      const sec = (ms: number) => new Date(Math.floor(ms / 1000) * 1000); // stored to the second
      const rolled = sec(Date.now() - 5 * 3600_000);
      const fixed = sec(Date.now() - 3600_000);
      await correctTimes(leg1, { startedAt: rolled.toISOString(), endedAt: fixed.toISOString() }, "Driver tapped late", dispatcher);
      const after = (await ChatTrip.findByPk(leg1))!;
      assert.equal(new Date(after.started_at!).getTime(), rolled.getTime());
      assert.equal(new Date(after.ended_at!).getTime(), fixed.getTime());
      const ev = await ChatTripEvent.findOne({ where: { chat_trip_id: leg1, type: "time_correction" } });
      assert.equal(ev?.note, "Driver tapped late");
      assert(ev?.data?.before?.leg?.ended_at && ev?.data?.after?.leg?.ended_at);
    });

    await test("typed miles are kept (Samsara won't overwrite) and recorded", async () => {
      await setMiles(leg1, 512.5, "Samsara offline — odometer photo", dispatcher);
      await addMileage(leg1);
      const one = (await ChatTrip.findByPk(leg1))!;
      assert.equal(Number(one.total_mileage), 512.5);
      assert.equal(one.miles_source, "manual");
      await assert.rejects(setMiles(leg1, 12, "", dispatcher), /Say why/);
      // Leg 2 runs and is typed too
      await act(leg2, "end", asA);
      await setMiles(leg2, 300, "Odometer", dispatcher);
    });

    await test("miles by driver and by truck; a team leg counts for both drivers", async () => {
      const range = { from: new Date(t0.getTime() - 86400_000), to: new Date(Date.now() + 86400_000) };
      let byDriver = await milesReport({ by: "driver", ...range, q: "ZZ TEST CONTROL" });
      assert.equal(byDriver.rows.find((r) => r.name === "ZZ TEST CONTROL A")?.miles, 812.5);
      const byTruck = await milesReport({ by: "truck", ...range, q: "ZZT" });
      const truck = (n: string) => byTruck.rows.find((r) => r.key === n)?.miles;
      assert.equal(truck("ZZT1"), 512.5);
      assert.equal(truck("ZZT3"), 300);
      await ChatTrip.update({ driver_id_2: yardIds[1] }, { where: { id: leg2 } });
      byDriver = await milesReport({ by: "driver", ...range, q: "ZZ TEST CONTROL" });
      assert.equal(byDriver.rows.find((r) => r.name === "ZZ TEST CONTROL B")?.miles, 300);
      assert.equal(byDriver.rows.find((r) => r.name === "ZZ TEST CONTROL A")?.miles, 812.5);
    });

    await test("a split load completes without a yard Route List entry", async () => {
      await act(leg1, "complete", dispatcher);
      await act(leg2, "complete", dispatcher, { invoiceNo: "ZZTEST-CTL-1" });
      const legs = await ChatTrip.findAll({ where: { load_id: loadId, status: "completed" } });
      assert.equal(legs.length, 2);
      assert(legs.every((l) => !l.driver_pay_details_id));
    });

    await test("planned handover to a driver with no chat yet: heads-up once they're in a channel, offered when leg 1 hands over", async () => {
      // A third driver who isn't in any channel yet (like a new driver added the same day)
      const [yardC] = await secondarySequelize.query(`INSERT INTO drivers (name, created_at, updated_at) VALUES ('ZZ TEST CONTROL C', NOW(), NOW())`, { type: QueryTypes.INSERT });
      yardIds.push(Number(yardC));
      const userC = await User.create({ driver_number: "zzctlC", status: "active", yard_id: Number(yardC) } as any);
      users.push(userC);
      const c = await UserProfile.create({ userId: userC.id, role_id: driverRole!.id, username: "ZZ Control Driver C", device_token: null } as any);
      people.push(c);

      const trip = (await createTrip({ driverProfileId: a.id, stops: STOPS }, dispatcher))!;
      loadIds.push(trip.load_id!);
      await sendLoad(trip.id, dispatcher);
      // Planned: the load changes hands after drop one, to driver C
      const s1 = (await ChatTripStop.findAll({ where: { chat_trip_id: trip.id } })).sort((x, y) => x.seq - y.seq)[1];
      const res = await splitLeg(trip.id, { when: "plan", afterSeq: s1.seq, place: KINGMAN, driverProfileId: c.id, reason: "planned" }, dispatcher);
      assert.equal((await ChatTrip.findByPk(res.next))?.channel_id, null, "no channel yet");

      // C joins a channel later; leg 1 runs and hands over at the meet point → leg 2 offered to C, message arrives
      await UserChannel.create({ userProfileId: c.id, channelId: channel[0].id } as any);
      for (const x of ["accept", "rolling", "end"] as const) await act(trip.id, x, asA);
      const two = (await ChatTrip.findByPk(res.next))!;
      assert.equal(two.status, "offered");
      assert.equal(two.channel_id, channel[0].id, "channel found and saved");
      assert.match(await lastMsg(c.id, /waiting for dispatch/), /lined up/);
      await sendLoad(res.next, dispatcher);
      assert.equal((await ChatTrip.findByPk(res.next))?.status, "planned");

      // And with a channel already there, a planned handover tells the new driver right away
      const t2 = (await createTrip({ driverProfileId: a.id, stops: STOPS }, dispatcher))!;
      loadIds.push(t2.load_id!);
      const s2 = (await ChatTripStop.findAll({ where: { chat_trip_id: t2.id } })).sort((x, y) => x.seq - y.seq)[1];
      const r2 = await splitLeg(t2.id, { when: "plan", afterSeq: s2.seq, place: KINGMAN, driverProfileId: c.id, reason: "planned" }, dispatcher);
      const heads = await lastMsg(c.id, /You're lined up for trip/);
      assert.match(heads, new RegExp(`You're lined up for trip ${(await ChatTrip.findByPk(r2.next))!.trip_no}: you take over at ZZ TA KINGMAN · KINGMAN, AZ from ZZ Control Driver A`));
      // The whole load is in it (read-only until dispatch confirms), and it's in the app's "Up next"
      assert.match(heads, /GO TO \(SWITCH TRAILER\)\nZZ TA KINGMAN[\s\S]*DROP\nZZ DROP TWO/);
      assert.match(heads, /Dispatch confirms before you start/);
      const up = await upcomingFor(c.id);
      const mine = up.trips.find((t: any) => t.id === r2.next) as any;
      assert(mine, "in Up next");
      assert.match(String(mine.waits_for), /^Leg 1 \(L\d+\) handing over$/);
      assert(mine.stops?.length === 2, "with its stops");
    });

    await test("dispatch marks the handover (leg 1 never tapped Rolling) and sends leg 2 to the new driver", async () => {
      const t = (await createTrip({ driverProfileId: a.id, truckNumber: "ZZT1", stops: STOPS }, dispatcher))!;
      loadIds.push(t.load_id!);
      await sendLoad(t.id, dispatcher);
      const s1 = (await ChatTripStop.findAll({ where: { chat_trip_id: t.id } })).sort((x, y) => x.seq - y.seq)[1];
      const r = await splitLeg(t.id, { when: "plan", afterSeq: s1.seq, place: KINGMAN, driverProfileId: b.id, truckNumber: "ZZT2", reason: "planned" }, dispatcher);
      await assert.rejects(sendLoad(r.next, dispatcher), /isn't delivered yet/);
      await releaseLeg(r.next, {}, dispatcher);
      const one = (await ChatTrip.findByPk(t.id, { include: [{ model: ChatTripStop, as: "stops" }] }))!;
      assert.equal(one.status, "ended");
      assert(one.ended_at);
      assert([...one.stops!].sort((x, y) => x.seq - y.seq).pop()?.arrived_at, "handover stop marked arrived");
      const two = (await ChatTrip.findByPk(r.next))!;
      assert.equal(two.status, "planned", "sent to the new driver");
      assert.match(await lastMsg(b.id, /TRIP #/), new RegExp(`TRIP #${two.trip_no}[\\s\\S]*DROP\\nZZ DROP TWO`));
      assert.match(await lastMsg(a.id, /handed over/), /handed over at ZZ TA KINGMAN/);
      // B's app: it's the current trip now with its Got it button
      const ev = await ChatTripEvent.findOne({ where: { chat_trip_id: t.id, type: "status", to_status: "ended" } });
      assert.match(String(ev?.note), /marked by dispatch \(the driver hadn't tapped Rolling\)/);
    });

    await test("change type on a planned load: Direct → Via yard splits after the pickup; back to Direct merges", async () => {
      const trip = (await createTrip({ driverProfileId: b.id, stops: STOPS }, dispatcher))!;
      loadIds.push(trip.load_id!);
      await changeType(trip.load_id!, { type: "via_yard", place: { name: "ZZ YARD", city: "FONTANA", state: "CA" } }, dispatcher);
      let legs = (await getLoad(trip.load_id!)).legs.filter((l) => l.status !== "cancelled");
      assert.equal(legs.length, 2);
      assert.deepEqual(types(legs[0].stops), ["pickup:ZZ PICK", "yard:ZZ YARD"]);
      assert.deepEqual(types(legs[1].stops), ["yard:ZZ YARD", "drop:ZZ DROP ONE", "drop:ZZ DROP TWO"]);
      assert.equal((await ChatLoad.findByPk(trip.load_id!))?.type, "via_yard");
      await changeType(trip.load_id!, { type: "direct" }, dispatcher);
      legs = (await getLoad(trip.load_id!)).legs.filter((l) => l.status !== "cancelled");
      assert.equal(legs.length, 1);
      assert.deepEqual(types(legs[0].stops), ["pickup:ZZ PICK", "drop:ZZ DROP ONE", "drop:ZZ DROP TWO"]);
      assert.equal((await ChatLoad.findByPk(trip.load_id!))?.type, "direct");
    });
  } finally {
    const trips = await ChatTrip.findAll({ where: { load_id: loadIds } });
    const ids = trips.map((t) => t.id);
    const routeIds = trips.map((t) => t.driver_pay_details_id).filter(Boolean);
    if (routeIds.length) {
      await secondarySequelize.query(`DELETE FROM driver_pay_mileages WHERE driver_pay_details_id IN (:ids)`, { replacements: { ids: routeIds } });
      await secondarySequelize.query(`DELETE FROM driver_expenses WHERE driver_pay_details_id IN (:ids)`, { replacements: { ids: routeIds } });
      await secondarySequelize.query(`DELETE FROM driver_pay_details WHERE id IN (:ids)`, { replacements: { ids: routeIds } });
    }
    if (ids.length) {
      await ChatTripEvent.destroy({ where: { chat_trip_id: ids } });
      await ChatTripStop.destroy({ where: { chat_trip_id: ids } });
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
