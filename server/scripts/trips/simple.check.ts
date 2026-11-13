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
import { addLoad, answerTypedLoad, getLoad, loadFromChat, loadFromText, lookupLoad, NeedsAnswer } from "../../src/services/trips/loadService";
import { endLegNow, setMiles } from "../../src/services/trips/loadControl";
import { milesReport } from "../../src/services/trips/milesReport";
import { parseLoad } from "../../src/services/trips/parseLoad";
import { driverPayload } from "../../src/services/trips/driverView";
import { registerTripHooks } from "../../src/services/trips/tripAssistant";
import { deleteLegOfMessage, forgetMessage, loadsOfMessage } from "../../src/services/trips/messageLoads";
import { randomUUID } from "crypto";

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
const msgs = async (id: string) => (await Message.findAll({ where: { userProfileId: id }, order: [["createdAt", "DESC"]], limit: 60 })).map((m) => String(m.body));
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

    await test("the load number is kept exactly as staff typed it (zeros and all) and matched exactly", async () => {
      const digits = String(Date.now() % 1000000).padStart(6, "7");
      const res = await addLoad({ loadNo: `00${digits}`, driverProfileId: a.id, stops: CHD_AMB }, dispatcher, { send: false });
      loadIds.add(res.load.id);
      assert.equal(res.load.invoice_no, `00${digits}`, "saved as typed");
      assert.equal(res.legs[0].trip_no, `00${digits}`);
      assert.equal((await lookupLoad(`00${digits}`)).load?.id, res.load.id, "the same number finds it");
      assert.equal((await lookupLoad(digits)).load, null, "a different number (no zeros) is a different load");
      // Don't leave a lined-up load on driver A for the tests that follow
      await ChatTrip.update({ status: "cancelled", queue_pos: null }, { where: { load_id: res.load.id } });
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
      // …and dispatch is told in System Messages (unread), not just by a pop-up
      const sys = await UserProfile.findOne({ include: [{ model: User, as: "user", where: { driver_number: "system001" }, required: true }] });
      if (sys) {
        const note = await Message.findOne({ where: { userProfileId: sys.id, body: { [Op.like]: "%Load NOT created%ZZ Simple Driver A%" } }, order: [["createdAt", "DESC"]] });
        assert(note, "a System Message says the load was not created");
        assert((await MessageStaff.count({ where: { messageId: note!.id, status: "un-read" } })) > 0, "unread for staff");
        await MessageStaff.destroy({ where: { messageId: note!.id } });
        await Message.destroy({ where: { id: note!.id } });
      }
      assert.equal((await loadFromChat({ driverProfileId: a.id, stops: CHD_AMB }, dispatcher)).kind, "noLoadNo");
    });

    await test("same Load # already lined up: asked to replace it; Replace & send / End current & send / Replace & line up — the driver never sees the lined-up copy", async () => {
      const no = `${NO}R`;
      // Saved for later on driver A: lined up, nothing in A's chat
      const before = (await msgs(a.id)).length;
      const saved = await addLoad({ loadNo: no, driverProfileId: a.id, stops: CHD_AMB, temperature: "34" }, dispatcher, { send: false });
      loadIds.add(saved.load.id);
      const old = saved.legs[0];
      assert.equal(old.status, "scheduled");
      assert.equal((await msgs(a.id)).length, before, "the driver is told nothing about a lined-up load");
      // The form's note says so
      const look = await lookupLoad(no, a.id);
      assert.equal(look.linedUp?.tripId, old.id);
      assert.equal(look.nextLegNo, 1, "replacing it keeps leg 1");
      // Same Load # again → asked (send or save)
      const q = await asks(addLoad({ loadNo: no, driverProfileId: a.id, stops: CHD_AMB }, dispatcher, { send: true }), "replaceLinedUp");
      assert.equal(q.info.linedUp.tripId, old.id);
      await asks(addLoad({ loadNo: no, driverProfileId: a.id, stops: CHD_AMB }, dispatcher, { send: false }), "replaceLinedUp");
      // Replace & send: the old copy is cancelled, the new one is leg 1 with the same number, sent
      const done = await addLoad({ loadNo: no, driverProfileId: a.id, stops: CHD_AMB, temperature: "36" }, dispatcher, { send: true, replace: true, endDriverCurrent: true });
      assert.equal(done.load.id, saved.load.id, "same load");
      const live = done.legs.filter((l: any) => l.status !== "cancelled");
      assert.equal(live.length, 1, "one leg, not two");
      assert.equal(live[0].leg_no, 1);
      assert.equal(live[0].trip_no, old.trip_no, "same number");
      assert.equal(live[0].temperature, "36", "the new copy's details");
      assert.equal(live[0].status, "planned", "sent");
      assert.equal((await ChatTrip.findByPk(old.id))?.status, "cancelled");
      const ev = await ChatTripEvent.findOne({ where: { chat_trip_id: old.id, to_status: "cancelled" } });
      assert.match(String(ev?.note), new RegExp(`Replaced — Load ${no} sent again`));
      assert.equal((await currentTripFor(a.id))?.trip.id, live[0].id, "A's app: the new copy");

      // Driver busy: the replace question carries the current load; Replace & line up → after it
      const no2 = `${NO}R2`;
      const s2 = await addLoad({ loadNo: no2, driverProfileId: a.id, stops: AMB_DEL }, dispatcher, { send: false });
      loadIds.add(s2.load.id);
      const q2 = await asks(addLoad({ loadNo: no2, driverProfileId: a.id, stops: AMB_DEL }, dispatcher, { send: true }), "replaceLinedUp");
      assert.equal(q2.info.current?.tripId, live[0].id, "the driver's current load is in the question");
      const lined = await addLoad({ loadNo: no2, driverProfileId: a.id, stops: AMB_DEL }, dispatcher, { send: true, replace: true, lineUp: true });
      const l2 = lined.legs.filter((l: any) => l.status !== "cancelled");
      assert.equal(l2.length, 1);
      assert.equal(l2[0].status, "scheduled", "lined up after the current load");
      assert.equal(l2[0].auto_send, true, "goes out when the current one is delivered");
      assert.equal((await ChatTrip.findByPk(live[0].id))?.status, "planned", "current load untouched");
      // Again, this time End current & send
      const ended = await addLoad({ loadNo: no2, driverProfileId: a.id, stops: AMB_DEL }, dispatcher, { send: true, replace: true, endDriverCurrent: true });
      const l3 = ended.legs.filter((l: any) => l.status !== "cancelled");
      assert.equal(l3.length, 1);
      assert.equal(l3[0].status, "planned", "sent");
      assert.equal((await ChatTrip.findByPk(live[0].id))?.status, "ended", "A's current load ended");
      assert.equal((await currentTripFor(a.id))?.trip.id, l3[0].id);
      assert(!(await msgs(a.id)).some((m) => /lined up/i.test(m)), "nothing about lined-up loads in A's chat");
    });

    await test("a load pasted in the chat box: nothing reaches the driver until it's sent; Line up → nothing; End & send → the standard load message", async () => {
      const no = `${NO}P`;
      const text = `Load #: ${no}\n\nPickup#\nWayne Farms - Albertville\n700 McDonald Ave.\nALBERTVILLE, AL 35950\n\nPickup#\nSANDERSON FARMS\n320 SANDERSONS FARMS PARKWAY\nPALESTINE, TX 75801\n11/12/2026 08:00PM\n\nDrop#\nROMA SOUTHERN CALIFORNIA\n16639 East Gale Ave\nCITY OF INDUSTRY, CA 91745\n11/15/2026 07:00AM`;
      // A is on another load
      const cur = await addLoad({ loadNo: `${NO}P0`, driverProfileId: a.id, stops: CHD_AMB }, dispatcher, { send: true, endDriverCurrent: true });
      loadIds.add(cur.load.id);
      const before = (await msgs(a.id)).length;
      const q = await asks(loadFromText(text, a.id, dispatcher), "driverBusy");
      assert.equal(q.info.current.tripId, cur.legs[0].id);
      assert.equal((await msgs(a.id)).length, before, "asked first: nothing in the driver's chat");
      // Line up → saved, nothing to the driver
      const lined = await loadFromText(text, a.id, dispatcher, { lineUp: true });
      loadIds.add(lined.data.load.id);
      assert.equal(lined.loadNo, no);
      const leg = lined.data.legs.find((l: any) => l.status !== "cancelled")!;
      assert.equal(leg.status, "scheduled");
      assert.equal(leg.stops.length, 3, "two pickups and the drop");
      assert.equal((await msgs(a.id)).length, before, "lined up: still nothing in the driver's chat");
      // Pasted again: already lined up → replace; End current & send → the standard load message
      await asks(loadFromText(text, a.id, dispatcher), "replaceLinedUp");
      const sent = await loadFromText(text, a.id, dispatcher, { replace: true, endDriverCurrent: true });
      const live = sent.data.legs.filter((l: any) => l.status !== "cancelled");
      assert.equal(live.length, 1);
      assert.equal(live[0].status, "planned");
      const chat = await msgs(a.id);
      assert(chat.some((m) => /PICKUP\nWayne Farms - Albertville/.test(m)), "the standard load message");
      assert(!chat.some((m) => m.startsWith("Load #:")), "the pasted text itself never went to the driver");
      // No Load # / no address: refused, nothing sent
      await assert.rejects(loadFromText("Pickup#\nX\n1 Main St\nRENO, NV 89501", a.id, dispatcher), /LOAD # 1234/);
      await assert.rejects(loadFromText("LOAD # 1\nhello", a.id, dispatcher), /Couldn't read a pickup/);
    });

    await test("the driver's app gets only the driver's part: no dispatch notes / raw text / pay ids; miles once delivered", async () => {
      const no = `${NO}V`;
      const r = await addLoad({ loadNo: no, driverProfileId: b.id, stops: CHD_AMB, notes: "Call receiver 30 min out", reviewNotes: ["check appt"], rawText: "RAW PASTED TEXT" }, dispatcher, { send: true, endDriverCurrent: true });
      loadIds.add(r.load.id);
      const legId = r.legs[0].id;
      await ChatTrip.update({ needs_review: true, review_notes: "check appt", miles_note: "internal" } as any, { where: { id: legId } });
      const forbidden = ["needs_review", "review_notes", "raw_text", "created_by", "created_by_name", "miles_source", "miles_note", "route_trip_no", "driver_pay_details_id", "queue_pos", "auto_send", "events", "message_id"];
      const live = driverPayload(await currentTripFor(b.id));
      assert.equal(live.trip.id, legId);
      assert(live.next, "the next button is kept");
      for (const k of forbidden) assert(!(k in live.trip), `${k} hidden`);
      assert.equal(live.trip.notes, "Call receiver 30 min out", "driver notes kept");
      assert.equal(live.trip.invoice_no, no, "the Load # is kept");
      assert(!("total_mileage" in live.trip), "no miles while running");
      // Delivered with miles: the driver sees them
      const asB = { role: "driver" as const, id: b.id, name: b.username };
      for (const x of ["accept", "rolling", "end"] as const) await act(legId, x, asB);
      await setMiles(legId, 212.4, "test", dispatcher);
      const mine = driverPayload(await tripsForDriver(b.id));
      const done = mine.trips.find((t: any) => t.id === legId);
      assert.equal(done.total_mileage, 212.4);
      for (const k of forbidden) assert(!(k in done), `${k} hidden in history`);
      assert(done.stops.every((st: any) => !("ref" in st)), "stops cleaned");
    });

    await test("chat words: a later \"TAKE TRAILER # …\" fills the load's trailer; the driver's plain \"rolling / arrived / delivered\" moves the load", async () => {
      const no = `${NO}W`;
      const r = await addLoad({ loadNo: no, driverProfileId: b.id, stops: CHD_AMB }, dispatcher, { send: true, endDriverCurrent: true });
      loadIds.add(r.load.id);
      const legId = r.legs[0].id;
      const leg = async () => (await ChatTrip.findByPk(legId, { include: [{ model: ChatTripStop, as: "stops" }] }))!;
      const say = async (body: string, fromStaff = false) => {
        await Message.create({ channelId: channel[0].id, userProfileId: b.id, senderId: fromStaff ? staff!.id : b.id, body, messageDirection: fromStaff ? "S" : "R", deliveryStatus: "sent", status: "sent", messageTimestampUtc: new Date() } as any);
        await wait(1800);
      };
      assert.equal((await leg()).trailer_numbers, null);
      await say("TAKE TRAILER # 16465", true);
      assert.equal((await leg()).trailer_numbers, "16465", "trailer filled from the follow-up");
      await say("trailer 16465 is broken", true);
      assert.equal((await leg()).trailer_numbers, "16465", "a sentence about a trailer changes nothing");

      await say("not loaded yet");
      assert.equal((await leg()).status, "planned", "not done → nothing moves");
      await say("rolling ");
      let t = await leg();
      assert.equal(t.status, "rolling", "Got it → Rolling from the word");
      assert(t.started_at, "started");
      const ev = await ChatTripEvent.findOne({ where: { chat_trip_id: legId, to_status: "rolling" } as any }).catch(() => null);
      if (ev) assert.match(String(ev.note), /From the driver's chat/);
      await say("arrived ");
      t = await leg();
      const stops = [...(t.stops || [])].sort((x, y) => x.seq - y.seq);
      assert(stops[stops.length - 1].arrived_at, "arrived at the delivery (loaded at the pickup already)");
      assert.equal(t.status, "rolling");
      await say("delivered");
      assert.equal((await leg()).status, "ended", "Delivered from the word");

      // The BOL / POD photo sent straight in the chat goes on the load → Paperwork check
      await Message.create({ channelId: channel[0].id, userProfileId: b.id, senderId: b.id, body: "pod", url: "uscitylink/zz-test-pod.jpg", thumbnail: "uscitylink/zz-test-pod-thumb.jpg", url_upload_type: "server", messageDirection: "R", deliveryStatus: "sent", status: "sent", messageTimestampUtc: new Date() } as any);
      await wait(2000);
      assert.equal((await leg()).status, "paperwork", "delivered load → Paperwork check");
      const full = await getLoad(r.load.id);
      assert.equal(full.documents.length, 1, "the photo is on the load");
      assert.equal(full.documents[0].url, "uscitylink/zz-test-pod.jpg");
      assert.equal(full.documents[0].caption, "pod");
      assert(full.history.some((h: any) => h.type === "document"), "in History");
      assert(!("events" in driverPayload(await currentTripFor(b.id)).trip), "the driver's app still gets no events");
    });

    await test("deleting a load message: the app is told which load it made; confirmed → the load is deleted; a deleted photo leaves the Paperwork", async () => {
      const no = `${NO}X`;
      // A load typed in the chat (the staff's own message)
      const src = await Message.create({ channelId: channel[0].id, userProfileId: b.id, senderId: staff!.id, body: "(test) typed load", messageDirection: "S", deliveryStatus: "sent", status: "sent", messageTimestampUtc: new Date(), is_automated: true } as any);
      let out = await loadFromChat({ loadNo: no, driverProfileId: b.id, stops: CHD_AMB, sourceMessageId: src.id }, dispatcher);
      while (out.kind === "question") out = await answerTypedLoad(out.id, out.needs === "endPrevious" ? { endPrevious: true } : out.needs === "replaceLinedUp" ? { replace: true } : { endDriverCurrent: true }, dispatcher);
      assert.equal(out.kind, "sent");
      const loadId = (out as any).loadId;
      loadIds.add(loadId);
      const leg = (await ChatTrip.findOne({ where: { load_id: loadId } }))!;

      const fromTyped = await loadsOfMessage(src.id);
      assert.equal(fromTyped.length, 1, "the typed message made the load");
      assert.equal(fromTyped[0].loadNo, no);
      assert(fromTyped[0].onlyLeg && fromTyped[0].canDelete);
      const fromStandard = await loadsOfMessage(leg.message_id!);
      assert.equal(fromStandard[0]?.legId, leg.id, "the standard load message is linked too");
      assert.equal((await loadsOfMessage(randomUUID())).length, 0, "any other message: nothing to ask");

      // A completed leg is never deleted from the chat
      await ChatTrip.update({ status: "completed" }, { where: { id: leg.id } });
      const done = await loadsOfMessage(src.id);
      assert.equal(done[0].canDelete, false);
      await assert.rejects(deleteLegOfMessage(src.id, leg.id, dispatcher), /completed/);
      await ChatTrip.update({ status: "planned" }, { where: { id: leg.id } });

      // A driver's photo on it, then the photo deleted → off the Paperwork
      // (B's delivered load from the test before would take the photo first: close it, long ago)
      await ChatTrip.update({ status: "completed", completed_at: new Date(Date.now() - 10 * 86400_000) }, { where: { driver_profile_id: b.id, status: ["ended", "paperwork"] } });
      const photo = await Message.create({ channelId: channel[0].id, userProfileId: b.id, senderId: b.id, body: "bol", url: "uscitylink/zz-del-bol.jpg", url_upload_type: "server", messageDirection: "R", deliveryStatus: "sent", status: "sent", messageTimestampUtc: new Date() } as any);
      await wait(1500);
      assert.equal((await getLoad(loadId)).documents.length, 1);
      await forgetMessage(photo.id);
      assert.equal((await getLoad(loadId)).documents.length, 0, "deleted photo left the Paperwork");

      // Confirmed: message + load go
      const res = await deleteLegOfMessage(src.id, leg.id, dispatcher);
      assert.equal(res.deletedLoad, true);
      assert.equal(await ChatLoad.count({ where: { id: loadId } }), 0, "load deleted");
      assert.equal(await ChatTrip.count({ where: { load_id: loadId } }), 0, "legs deleted");
      assert.equal(await ChatTripEvent.count({ where: { chat_trip_id: leg.id } }), 0, "its history deleted");
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
