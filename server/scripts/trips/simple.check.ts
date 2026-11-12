// Run: npx ts-node -T scripts/trips/simple.check.ts
// Simple loads against the LOCAL databases (refuses anything else): dispatch adds a direct load with
// its Load #; the same Load # again is the next leg; dispatch is asked before anything is ended;
// dispatch can end a load the driver didn't; miles per leg and total; typed loads; the Load # parser.
// Throwaway test drivers with no phone token; removes everything it created at the end.
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
import { act, currentTripFor, tripsForDriver } from "../../src/services/trips/tripService";
import { addLoad, answerTypedLoad, getLoad, loadFromChat, lookupLoad, NeedsAnswer } from "../../src/services/trips/loadService";
import { endLegNow, setMiles } from "../../src/services/trips/loadControl";
import { milesReport } from "../../src/services/trips/milesReport";
import { parseLoad } from "../../src/services/trips/parseLoad";
import { registerTripHooks } from "../../src/services/trips/tripAssistant";

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

const NO = `ZZ${Date.now() % 100000}`; // a Load # nobody uses
const OTHER = `${NO}B`;
const CHD_AMB = [
  { type: "pickup" as const, name: "ZZ PICK CHANDIGARH", city: "CHANDIGARH", state: "CH", appointment: "2026-11-13T10:00" },
  { type: "drop" as const, name: "ZZ DROP AMBALA", city: "AMBALA", state: "HR" },
];
const AMB_DEL = [
  { type: "pickup" as const, name: "ZZ DROP AMBALA", city: "AMBALA", state: "HR" },
  { type: "drop" as const, name: "ZZ DELIVERY DELHI", city: "DELHI", state: "DL" },
];
const msgs = async (id: string) => (await Message.findAll({ where: { userProfileId: id }, order: [["createdAt", "DESC"]], limit: 12 })).map((m) => String(m.body));
const asks = async (p: Promise<any>, needs: string) => {
  try {
    await p;
  } catch (e: any) {
    assert(e instanceof NeedsAnswer, `expected a question, got: ${e.message}`);
    assert.equal(e.needs, needs);
    return e;
  }
  throw new Error(`expected dispatch to be asked (${needs})`);
};

(async () => {
  initSocket(http.createServer());
  registerTripHooks();
  const driverRole = await Role.findOne({ where: { name: "driver" } });
  const staffRole = await Role.findOne({ where: { name: "staff" } });
  const yardIds: number[] = [];
  const users: User[] = [];
  const people: UserProfile[] = [];
  for (const n of ["A", "B"]) {
    const [yardId] = await secondarySequelize.query(`INSERT INTO drivers (name, created_at, updated_at) VALUES (:n, NOW(), NOW())`, {
      replacements: { n: `ZZ TEST SIMPLE ${n}` },
      type: QueryTypes.INSERT,
    });
    yardIds.push(Number(yardId));
    const user = await User.create({ driver_number: `zzsim${n}`, status: "active", yard_id: Number(yardId) } as any);
    users.push(user);
    people.push(await UserProfile.create({ userId: user.id, role_id: driverRole!.id, username: `ZZ Simple Driver ${n}`, device_token: null } as any));
  }
  const [a, b] = people;
  const staff = await UserProfile.findOne({ where: { role_id: staffRole!.id } });
  const channel = await primarySequelize.query<{ id: string }>(`SELECT id FROM channels WHERE name = 'demo' LIMIT 1`, { type: QueryTypes.SELECT });
  for (const p of people) await UserChannel.create({ userProfileId: p.id, channelId: channel[0].id } as any);
  const dispatcher = { role: "dispatcher" as const, id: staff!.id, name: staff!.username };
  const asA = { role: "driver" as const, id: a.id, name: a.username };
  const asB = { role: "driver" as const, id: b.id, name: b.username };
  const loadIds = new Set<number>();

  try {
    let loadId = 0;

    await test("the Load # is required; parser reads LOAD # / INVOICE #", async () => {
      await assert.rejects(addLoad({ driverProfileId: a.id, stops: CHD_AMB }, dispatcher), /Enter the Load #/);
      assert.equal(parseLoad("LOAD # 1011\nTRUCK # 101\nPICK\nCOLD LINK\n1 MAIN ST\nFRESNO, CA 93701\nDROP\nSYSCO\n2 MAIN ST\nFREMONT, CA 94538")?.loadNo, "1011");
      assert.equal(parseLoad("INVOICE #: 55-AB\nPICK\nCOLD LINK\n1 MAIN ST\nFRESNO, CA 93701\nDROP\nSYSCO\n2 MAIN ST\nFREMONT, CA 94538")?.loadNo, "55-AB");
      assert.equal(parseLoad("LOADED TRAILER\nDROP\nSYSCO\n2 MAIN ST\nFREMONT, CA 94538")?.loadNo, null);
    });

    await test("add a direct load: Chandigarh → Ambala, driver A, truck 101, trailer 10010 — trip # is the Load #", async () => {
      const look = await lookupLoad(NO);
      assert.equal(look.load, null, "new load");
      const res = await addLoad({ loadNo: NO, driverProfileId: a.id, truckNumber: "ZZ101", trailerNumbers: ["ZZ10010"], stops: CHD_AMB }, dispatcher, { send: true });
      loadId = res.load.id;
      loadIds.add(loadId);
      assert.equal(res.load.type, "direct");
      assert.equal(res.load.invoice_no, NO);
      assert.equal(res.legs[0].trip_no, NO);
      assert.equal(res.legs[0].status, "planned", "sent");
      assert.match((await msgs(a.id)).join("\n"), new RegExp(`TRIP #${NO}`));
      await act(res.legs[0].id, "accept", asA);
      await act(res.legs[0].id, "rolling", asA);
    });

    await test("same Load # to driver B: dispatch is asked to end A's leg first; then A's leg ends and leg 2 goes to B", async () => {
      const look = await lookupLoad(NO, b.id);
      assert.equal(look.nextLegNo, 2);
      assert.equal(look.prev?.driverName, "ZZ Simple Driver A");
      assert.equal(look.prev?.open, true);
      await asks(addLoad({ loadNo: NO, driverProfileId: b.id, truckNumber: "ZZ202", stops: AMB_DEL }, dispatcher, { send: true }), "endPrevious");
      assert.equal((await ChatTrip.count({ where: { load_id: loadId } })), 1, "nothing created while asking");
      const res = await addLoad({ loadNo: NO, driverProfileId: b.id, truckNumber: "ZZ202", stops: AMB_DEL }, dispatcher, { send: true, endPrevious: true });
      const [one, two] = res.legs.filter((l) => l.status !== "cancelled");
      assert.equal(one.status, "ended");
      assert(one.ended_at);
      assert.equal(two.trip_no, `${NO}-2`);
      assert.equal(two.driver_profile_id, b.id);
      assert.equal(two.status, "planned");
      assert.equal(two.trailer_numbers, "ZZ10010", "trailer carried over");
      assert.equal(res.load.type, "relay", "shown as Transfer");
      // A's app: the load is gone (delivered); A was told. B's app: leg 2 is the current trip
      assert.match((await msgs(a.id)).join("\n"), /handed over at ZZ DROP AMBALA/);
      const cur = await currentTripFor(a.id);
      assert(!cur || cur.trip.status === "ended", "A has nothing to drive");
      assert.equal((await currentTripFor(b.id))?.trip.id, two.id);
      assert.match((await msgs(b.id)).join("\n"), new RegExp(`TRIP #${NO}-2[\\s\\S]*ZZ DELIVERY DELHI`));
    });

    await test("miles: each leg its own, the load the total, the report split by driver and truck", async () => {
      const legs = (await getLoad(loadId)).legs.filter((l) => l.status !== "cancelled");
      for (const x of ["end"] as const) await act(legs[1].id, "accept", asB).then(() => act(legs[1].id, "rolling", asB)).then(() => act(legs[1].id, x, asB));
      await setMiles(legs[0].id, 30, "test", dispatcher);
      await setMiles(legs[1].id, 125, "test", dispatcher);
      const res = await getLoad(loadId);
      assert.equal(res.milesTotals.miles, 155);
      const r = await milesReport({ by: "driver", from: new Date(Date.now() - 86400000), to: new Date(Date.now() + 86400000), q: "ZZ TEST SIMPLE" });
      assert.equal(r.rows.find((x) => x.name === "ZZ TEST SIMPLE A")?.miles, 30);
      assert.equal(r.rows.find((x) => x.name === "ZZ TEST SIMPLE B")?.miles, 125);
      const t = await milesReport({ by: "truck", from: new Date(Date.now() - 86400000), to: new Date(Date.now() + 86400000), q: "ZZ" });
      assert.equal(t.rows.find((x) => x.key === "ZZ101")?.miles, 30);
      assert.equal(t.rows.find((x) => x.key === "ZZ202")?.miles, 125);
    });

    await test("a leg ending at our yard makes the load Via yard", async () => {
      const yardNo = `${NO}Y`;
      const r1 = await addLoad(
        { loadNo: yardNo, driverProfileId: a.id, stops: [CHD_AMB[0], { type: "yard", name: "ZZ OUR YARD", city: "AMBALA", state: "HR" }] },
        dispatcher,
        { send: true }
      );
      loadIds.add(r1.load.id);
      const r2 = await addLoad({ loadNo: yardNo, driverProfileId: b.id, stops: AMB_DEL }, dispatcher, { endPrevious: true, send: false });
      assert.equal(r2.load.type, "via_yard");
    });

    await test("driver busy on another load: asked; End & send ends it; Line up keeps it for later", async () => {
      // B is on yardNo leg? — give B a fresh load to be busy with
      const r1 = await addLoad({ loadNo: OTHER, driverProfileId: b.id, stops: CHD_AMB }, dispatcher, { send: true });
      loadIds.add(r1.load.id);
      const busyId = r1.legs[0].id;
      const third = `${NO}C`;
      await asks(addLoad({ loadNo: third, driverProfileId: b.id, stops: AMB_DEL }, dispatcher, { send: true }), "driverBusy");
      const lined = await addLoad({ loadNo: third, driverProfileId: b.id, stops: AMB_DEL }, dispatcher, { send: true, lineUp: true });
      loadIds.add(lined.load.id);
      assert.equal(lined.legs[0].status, "scheduled", "lined up, not sent");
      assert.equal((await ChatTrip.findByPk(busyId))?.status, "planned", "current load untouched");
      const fourth = `${NO}D`;
      const sent = await addLoad({ loadNo: fourth, driverProfileId: b.id, stops: AMB_DEL }, dispatcher, { send: true, endDriverCurrent: true });
      loadIds.add(sent.load.id);
      assert.equal((await ChatTrip.findByPk(busyId))?.status, "ended", "B's old load ended");
      assert.equal(sent.legs[0].status, "planned");
      assert.equal((await currentTripFor(b.id))?.trip.id, sent.legs[0].id, "B's app shows the new load");
    });

    await test("dispatch ends a load the driver only got (never tapped Rolling)", async () => {
      const no = `${NO}E`;
      const r = await addLoad({ loadNo: no, driverProfileId: a.id, stops: CHD_AMB }, dispatcher, { send: true });
      loadIds.add(r.load.id);
      await endLegNow(r.legs[0].id, dispatcher);
      const leg = (await ChatTrip.findByPk(r.legs[0].id))!;
      assert.equal(leg.status, "ended");
      const ev = await ChatTripEvent.findOne({ where: { chat_trip_id: leg.id, to_status: "ended" } });
      assert.match(String(ev?.note), /Ended by dispatch \(the driver hadn't tapped Rolling\)/);
      assert.match((await msgs(a.id)).join("\n"), new RegExp(`Trip ${no} ended by dispatch`));
    });

    await test("driver card: delivered load stays until dispatch completes it, then only in history; old loads don't come back", async () => {
      // An older load A delivered and never completed
      const old = await addLoad({ loadNo: `${NO}O`, driverProfileId: a.id, stops: CHD_AMB }, dispatcher, { send: true, endDriverCurrent: true });
      loadIds.add(old.load.id);
      for (const x of ["accept", "rolling", "end"] as const) await act(old.legs[0].id, x, asA);
      // The newest load, delivered: on the card (send the paperwork)
      const cur = await addLoad({ loadNo: `${NO}N`, driverProfileId: a.id, stops: CHD_AMB }, dispatcher, { send: true });
      loadIds.add(cur.load.id);
      for (const x of ["accept", "rolling", "end"] as const) await act(cur.legs[0].id, x, asA);
      assert.equal((await currentTripFor(a.id))?.trip.id, cur.legs[0].id, "delivered, waiting for dispatch: still on the card");
      // Dispatch completes it: the card is empty — the old delivered load does not come back
      await act(cur.legs[0].id, "complete", dispatcher);
      assert.equal(await currentTripFor(a.id), null, "completed: only in history");
    });

    await test("same driver, two loads: tomorrow's is lined up after tonight's; Delivered → tomorrow's is the main load at once", async () => {
      const tonight = `${NO}N1`;
      const tomorrow = `${NO}N2`;
      const t1 = await addLoad(
        { loadNo: tonight, driverProfileId: a.id, trailerNumbers: ["ZZ18365"], temperature: "REFER BILLS", loadedTrailer: true, stops: [{ type: "drop", name: "ZZ PFG", city: "SHAFTER", state: "CA", appointment: "2026-11-11T22:00" }] },
        dispatcher,
        { send: true, endDriverCurrent: true }
      );
      loadIds.add(t1.load.id);
      const tonightLeg = t1.legs[0].id;
      const input = {
        loadNo: tomorrow,
        driverProfileId: a.id,
        stops: [
          { type: "pickup" as const, name: "ZZ ROBINSON PHARMA", city: "COSTA MESA", state: "CA", appointment: "2026-11-12T08:00" },
          { type: "drop" as const, name: "ZZ BAUSCH LOMB", city: "WOODRUFF", state: "SC", appointment: "2026-11-17T09:00" },
        ],
      };
      await asks(addLoad(input, dispatcher, { send: true }), "driverBusy");
      const t2 = await addLoad(input, dispatcher, { send: true, lineUp: true });
      loadIds.add(t2.load.id);
      const nextLeg = (await ChatTrip.findByPk(t2.legs[0].id))!;
      assert.equal(nextLeg.status, "scheduled", "lined up");
      assert.equal(nextLeg.auto_send, true);
      assert.equal((await currentTripFor(a.id))?.trip.id, tonightLeg, "tonight's is the main load");
      // Driver delivers tonight's: tomorrow's goes out at once — no Mark completed needed
      for (const x of ["accept", "rolling", "end"] as const) await act(tonightLeg, x, asA);
      assert.equal((await ChatTrip.findByPk(nextLeg.id))?.status, "planned", "sent by itself");
      assert.equal((await currentTripFor(a.id))?.trip.id, nextLeg.id, "tomorrow's is the main load now");
      const hist = await tripsForDriver(a.id);
      assert(hist.trips.some((t) => t.id === tonightLeg && t.status === "ended"), "tonight's in history");
      assert.match((await msgs(a.id)).join("\n"), new RegExp(`TRIP #${tomorrow}[\\s\\S]*ZZ ROBINSON PHARMA`), "full load message");
    });

    await test("a load only saved for later still waits for dispatch to confirm", async () => {
      const no = `${NO}S1`;
      const s1 = await addLoad({ loadNo: no, driverProfileId: a.id, stops: CHD_AMB }, dispatcher, { send: false });
      loadIds.add(s1.load.id);
      const cur = (await currentTripFor(a.id))!.trip.id;
      for (const x of ["accept", "rolling", "end"] as const) await act(cur, x, asA);
      const leg = (await ChatTrip.findByPk(s1.legs[0].id))!;
      assert.equal(leg.status, "offered", "offered — dispatch confirms");
    });

    await test("a load typed in chat = Send now: same Load # asks first, then leg 2 goes out with the standard message; no Load # → nothing", async () => {
      const no = `${NO}T`;
      const r = await addLoad({ loadNo: no, driverProfileId: a.id, stops: CHD_AMB }, dispatcher, { send: true, endDriverCurrent: true });
      loadIds.add(r.load.id);
      // Typed to driver B with the same Load # while A's leg is open → a question for dispatch, nothing created
      const q = await loadFromChat({ loadNo: no, driverProfileId: b.id, truckNumber: "ZZ303", stops: AMB_DEL }, dispatcher);
      assert.equal(q.kind, "question");
      assert.equal((q as any).needs, "endPrevious");
      assert.equal(await ChatTrip.count({ where: { load_id: r.load.id } }), 1);
      // "End leg 1 & send" (B may be busy too → answer that as well)
      let ans = await answerTypedLoad((q as any).id, { endPrevious: true }, dispatcher);
      if (ans.kind === "question") ans = await answerTypedLoad((q as any).id, { endDriverCurrent: true }, dispatcher);
      assert.equal(ans.kind, "sent");
      assert.equal((ans as any).tripNo, `${no}-2`);
      const leg2 = (await ChatTrip.findOne({ where: { load_id: r.load.id, leg_no: 2 } }))!;
      assert.equal(leg2.status, "planned", "sent to B");
      assert.equal(leg2.source, "typed");
      assert.equal((await ChatTrip.findOne({ where: { load_id: r.load.id, leg_no: 1 } }))?.status, "ended");
      assert.match((await msgs(b.id)).join("\n"), new RegExp(`TRIP #${no}-2[\\s\\S]*ZZ DELIVERY DELHI`), "standard load message");

      // Through the chat itself: a new Load # typed to A → sent like the form
      const fresh = `${NO}U`;
      const text = `LOAD # ${fresh}\nTRUCK # ZZ404\nPICK\nZZ YARD FRESNO\n1 MAIN ST\nFRESNO, CA 93701\nDROP\nZZ DELIVERY FREMONT\n2 MAIN ST\nFREMONT, CA 94538`;
      await Message.create({ channelId: channel[0].id, userProfileId: a.id, senderId: staff!.id, body: text, messageDirection: "S", deliveryStatus: "sent", status: "sent", messageTimestampUtc: new Date() } as any);
      await wait(2500);
      const typed = await ChatLoad.findOne({ where: { invoice_no: fresh } });
      assert(typed, "load made from the chat message");
      loadIds.add(typed!.id);
      const tl = (await ChatTrip.findOne({ where: { load_id: typed!.id } }))!;
      assert(["planned", "scheduled"].includes(tl.status), `sent or lined up (A may be busy): ${tl.status}`);

      // No Load # → no load
      const before = await ChatTrip.count();
      await Message.create({
        channelId: channel[0].id,
        userProfileId: a.id,
        senderId: staff!.id,
        body: "PICK\nZZ NO NUMBER\n1 MAIN ST\nFRESNO, CA 93701\nDROP\nZZ SOMEWHERE\n2 MAIN ST\nFREMONT, CA 94538",
        messageDirection: "S",
        deliveryStatus: "sent",
        status: "sent",
        messageTimestampUtc: new Date(),
      } as any);
      await wait(2000);
      assert.equal(await ChatTrip.count(), before, "nothing created without a Load #");
      assert.equal((await loadFromChat({ driverProfileId: a.id, stops: CHD_AMB }, dispatcher)).kind, "noLoadNo");
    });
  } finally {
    const trips = await ChatTrip.findAll({ where: { [Op.or]: [{ load_id: [...loadIds] }, { driver_profile_id: people.map((p) => p.id) }] } });
    const ids = trips.map((t) => t.id);
    const routeIds = trips.map((t) => t.driver_pay_details_id).filter(Boolean);
    if (routeIds.length) {
      await secondarySequelize.query(`DELETE FROM driver_pay_mileages WHERE driver_pay_details_id IN (:ids)`, { replacements: { ids: routeIds } });
      await secondarySequelize.query(`DELETE FROM driver_expenses WHERE driver_pay_details_id IN (:ids)`, { replacements: { ids: routeIds } });
      await secondarySequelize.query(`DELETE FROM driver_pay_details WHERE id IN (:ids)`, { replacements: { ids: routeIds } });
    }
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
