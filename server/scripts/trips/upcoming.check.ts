// Run: npx ts-node -T scripts/trips/upcoming.check.ts
// The driver's Upcoming loads and Accept / Reject, against the LOCAL databases (refuses anything else): every
// lined-up load is listed in order, Accept is remembered (the load goes out as accepted when the current one
// ends), Reject sends it back to dispatch flagged with the reason, the next load takes over the main card
// when the current one is delivered, and only the load's own driver can answer. Throwaway drivers; removes
// everything it created.
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
import { addLoad } from "../../src/services/trips/loadService";
import { act, currentTripFor, upcomingFor } from "../../src/services/trips/tripService";
import { respondToLoad } from "../../src/services/trips/driverResponse";
import { driverPayload } from "../../src/services/trips/driverView";
import { myCurrentTrip } from "../../src/controllers/tripController";

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
const NO = `ZZ${TAG}U`;
const STOPS = (tag: string) => [
  { type: "pickup" as const, name: `ZZ PICK ${tag}`, city: "FRESNO", state: "CA", appointment: "2027-03-01T08:00" },
  { type: "drop" as const, name: `ZZ DROP ${tag}`, city: "FONTANA", state: "CA", appointment: "2027-03-01T18:00" },
];

(async () => {
  initSocket(http.createServer());
  registerTripHooks();
  const driverRole = await Role.findOne({ where: { name: "driver" } });
  const staffRole = await Role.findOne({ where: { name: "staff" } });
  const yardIds: number[] = [];
  const users: User[] = [];
  const people: UserProfile[] = [];
  for (const n of ["A", "B"]) {
    const [yardId] = await secondarySequelize.query(`INSERT INTO drivers (name, created_at, updated_at) VALUES (:n, NOW(), NOW())`, { replacements: { n: `ZZ TEST UPCOMING ${n}` }, type: QueryTypes.INSERT });
    yardIds.push(Number(yardId));
    const user = await User.create({ driver_number: `zzup${n}${TAG}`, status: "active", yard_id: Number(yardId) } as any);
    users.push(user);
    people.push(await UserProfile.create({ userId: user.id, role_id: driverRole!.id, username: `ZZ Upcoming Driver ${n}`, device_token: null } as any));
  }
  const [a, b] = people;
  const staff = await UserProfile.findOne({ where: { role_id: staffRole!.id } });
  const channel = await primarySequelize.query<{ id: string }>(`SELECT id FROM channels WHERE name = 'demo' LIMIT 1`, { type: QueryTypes.SELECT });
  const channelId = channel[0].id;
  for (const p of people) await UserChannel.create({ userProfileId: p.id, channelId } as any);
  const dispatcher = { role: "dispatcher" as const, id: staff!.id, name: staff!.username };
  const asA = { role: "driver" as const, id: a.id, name: a.username };
  const asB = { role: "driver" as const, id: b.id, name: b.username };
  const loadIds = new Set<number>();
  const chatOf = async (id: string) => (await Message.findAll({ where: { userProfileId: id }, order: [["createdAt", "ASC"]] })).map((m) => String(m.body));
  const leg = async (id: number) => (await ChatTrip.findByPk(id))!;
  const add = async (tag: string, o: any = {}) => {
    const r = await addLoad({ loadNo: `${NO}${tag}`, driverProfileId: a.id, stops: STOPS(tag), notes: `driver note ${tag}`, reviewNotes: [`secret ${tag}`], ...o.input }, dispatcher, o.opts || {});
    loadIds.add(r.load.id);
    return r.legs[0].id as number;
  };

  try {
    // A is on L1 (sent, Got it, rolling). Dispatch lines up L2 ("line up after the current one") and L3 (saved for later)
    const l1 = await add("1", { opts: { send: true } });
    await act(l1, "accept", asA);
    await act(l1, "rolling", asA);
    const l2 = await add("2", { opts: { send: true, lineUp: true } });
    const l3 = await add("3", { opts: { send: false } });
    const l4 = await add("4", { opts: { send: false } });

    await test("every lined-up load is the driver's Upcoming, in order, with only what a driver sees", async () => {
      const up = await upcomingFor(a.id);
      assert.deepEqual(up.trips.map((t) => t.id), [l2, l3, l4], "in lineup order");
      const cur = await currentTripFor(a.id);
      assert.equal(cur!.trip.id, l1, "the main load is the one on the road");
      // what the app gets from GET /trips/current
      const res: any = { body: null, json(b: any) { this.body = b; return this; }, status() { return this; } };
      await myCurrentTrip({ user: { id: a.id } } as any, res);
      const d = res.body.data;
      assert.equal(d.trip.id, l1);
      assert.deepEqual(d.upcoming.map((t: any) => t.id), [l2, l3, l4]);
      const one = d.upcoming[0];
      assert.equal(one.notes, "driver note 2", "the driver's own notes");
      assert.equal(one.stops.length, 2);
      for (const k of ["review_notes", "raw_text", "needs_review", "queue_pos", "auto_send", "events", "created_by_name", "driver_response_note"]) assert(!(k in one), `${k} hidden`);
      assert.equal(one.driver_response ?? null, null, "not answered yet");
      assert.equal((await upcomingFor(b.id)).trips.length, 0, "another driver sees none of A's");
    });

    await test("Accept on an upcoming load is remembered (status unchanged), told to dispatch, and repeating it changes nothing", async () => {
      await respondToLoad(l2, asA, "accept");
      let t = await leg(l2);
      assert.equal(t.status, "scheduled", "still lined up");
      assert.equal(t.driver_response, "accepted");
      assert(t.driver_response_at);
      await respondToLoad(l2, asA, "accept");
      const ev = await ChatTripEvent.findAll({ where: { chat_trip_id: l2, type: "driver_response" } });
      assert.equal(ev.length, 1, "logged once");
      assert.match(String(ev[0].note), /accepted the upcoming load/);
      assert.equal(driverPayload({ trip: await currentTripFor(a.id).then((c) => c!.trip), upcoming: (await upcomingFor(a.id)).trips }).upcoming[0].driver_response, "accepted", "the app sees it");
    });

    await test("Reject an upcoming load: it goes back to dispatch with no driver, flagged with the reason, alerted, logged; the driver's list drops it", async () => {
      await respondToLoad(l3, asA, "reject", "  trailer is far from my route  ");
      const t = await leg(l3);
      assert.equal(t.driver_profile_id, null, "no driver");
      assert.equal(t.status, "scheduled");
      assert.equal(t.queue_pos, null);
      assert.equal(t.driver_response, "rejected");
      assert.equal(t.driver_response_note, "trailer is far from my route");
      assert.equal(t.needs_review, true);
      assert.match(String(t.review_notes), /Rejected by ZZ Upcoming Driver A: trailer is far from my route/);
      const ev = await ChatTripEvent.findOne({ where: { chat_trip_id: l3, type: "rejected" } });
      assert.match(String(ev?.note), /Rejected by ZZ Upcoming Driver A: trailer is far from my route/);
      assert.deepEqual((await upcomingFor(a.id)).trips.map((x) => x.id), [l2, l4], "gone from the driver's Upcoming");
      assert((await chatOf(a.id)).some((m) => m.includes(`rejected load ${NO}3`) && m.startsWith("❌")), "a line in the driver's chat tells dispatch");
      // dispatch's System Messages
      const sys = await UserProfile.findOne({ include: [{ model: User, as: "user", where: { driver_number: "system001" }, required: true }] });
      if (sys) {
        const note = await Message.findOne({ where: { userProfileId: sys.id, body: { [Op.like]: `%ZZ Upcoming Driver A rejected load ${NO}3%` } }, order: [["createdAt", "DESC"]] });
        assert(note, "a System Message for dispatch");
        await Message.destroy({ where: { id: note!.id } });
      }
      assert.equal((await ChatTrip.findByPk(l3))!.status, "scheduled", "dispatch can send it to someone else");
    });

    await test("only the load's own driver can answer, and dispatch can't answer for them", async () => {
      await assert.rejects(respondToLoad(l4, asB, "accept"), /isn't your load/);
      await assert.rejects(respondToLoad(l4, dispatcher as any, "accept"), /isn't your load/);
      assert.equal((await leg(l4)).driver_response, null);
    });

    await test("the driver delivers L1 → L2 takes over the main card at once, already accepted: the next button is 'Loaded — rolling'; the load message reaches the chat", async () => {
      assert(!(await chatOf(a.id)).some((m) => m.startsWith(`LOAD # ${NO}2`)), "not in the chat while it was only upcoming");
      await act(l1, "end", asA);
      await wait(1500);
      const cur = await currentTripFor(a.id);
      assert.equal(cur!.trip.id, l2, "L2 is the main load now");
      assert.equal(cur!.trip.status, "accepted", "it was accepted earlier");
      assert.equal(cur!.next?.action, "rolling");
      assert.equal(cur!.next?.label, "Loaded — rolling");
      assert((await chatOf(a.id)).some((m) => m.startsWith(`LOAD # ${NO}2`)), "its load message was sent when it took over");
      assert.deepEqual((await upcomingFor(a.id)).trips.map((x) => x.id), [l4], "L4 is the upcoming now");
    });

    await test("delivered again → L4 (saved for later, not answered yet) takes over too, with Accept / Reject; Reject sends it back", async () => {
      await act(l2, "rolling", asA);
      await act(l2, "end", asA);
      await wait(1500);
      const cur = await currentTripFor(a.id);
      assert.equal(cur!.trip.id, l4, "saved-for-later loads take over as well");
      assert.equal(cur!.trip.status, "planned", "not answered: Accept / Reject");
      assert.equal(cur!.next?.action, "accept");
      await respondToLoad(l4, asA, "reject", "");
      const t = await leg(l4);
      assert.equal(t.driver_profile_id, null);
      assert.equal(t.driver_response, "rejected");
      assert.match(String(t.review_notes), /Rejected by ZZ Upcoming Driver A$/m, "no reason given");
      const after = await currentTripFor(a.id);
      assert(!after || (after.trip.id !== l4), "the rejected load left the driver's main card");
    });

    await test("Accept on the load just sent is the usual Got it; once accepted, Reject is no longer allowed", async () => {
      const l5 = await add("5", { input: { driverProfileId: b.id }, opts: { send: true } });
      assert.equal((await leg(l5)).status, "planned");
      await respondToLoad(l5, asB, "accept");
      assert.equal((await leg(l5)).status, "accepted");
      assert((await chatOf(b.id)).some((m) => /accepted load/.test(m)), "Got it is said in the chat (the driver's own tap)");
      await assert.rejects(respondToLoad(l5, asB, "reject", "no"), /already accepted/);
      assert.equal((await leg(l5)).driver_profile_id, b.id);
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
