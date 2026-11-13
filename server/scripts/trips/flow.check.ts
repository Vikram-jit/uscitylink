// Run: npx ts-node -T scripts/trips/flow.check.ts
// A whole trip against the LOCAL databases (refuses anything else): add → offer → send → driver taps
// → undo → end → complete → priced, a typed load read from chat, cancel. Trips are in USCityLink's
// database; the yard only gets each trip's Route List row.
// Uses a throwaway test driver with no phone token (nothing is pushed to a real phone) and removes
// everything it created at the end.
import "dotenv/config";
process.env.TRIP_ETA_SNAPSHOT = "off"; // no Google / Samsara calls from tests
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
import { ChatLoad, ChatTrip, ChatTripEvent } from "../../src/models/ChatTrip";
import { answerTypedLoad, loadFromChat } from "../../src/services/trips/loadService";
import { parseLoad } from "../../src/services/trips/parseLoad";
import { act, addProblem, createTrip, getTrip, loadNo, tripsForDriver, offerNextLoad, onDocumentRead, resolveProblem, sendLoad, syncPriced, undo } from "../../src/services/trips/tripService";
import { MessageDocument } from "../../src/models/MessageDocument";
import { isPriced, syncRouteRow } from "../../src/services/trips/routeListSync";
import { registerTripHooks } from "../../src/services/trips/tripAssistant";

const local = (h?: string) => !h || /^(localhost|127\.0\.0\.1)$/.test(h);
if (!local(process.env.DB_PRIMARY_HOST) || !local(process.env.DB_SECONDARY_HOST)) {
  console.error("Refusing to run: the databases in .env are not local");
  process.exit(2);
}

const results: string[] = [];
const test = async (name: string, fn: () => Promise<void>) => {
  try {
    await fn();
    results.push(`ok   ${name}`);
  } catch (e: any) {
    results.push(`FAIL ${name}: ${e.message}`);
  }
};
const yard = <T extends object = any>(sql: string, replacements: Record<string, any> = {}) =>
  secondarySequelize.query<T>(sql, { replacements, type: QueryTypes.SELECT });
const wait = (ms: number) => new Promise((r) => setTimeout(r, ms));

const STOPS = [
  { type: "pickup" as const, name: "ZZ TEST COLD STORAGE", street: "110 PLUGS DRIVE", city: "DECATUR", state: "AL", zip: "35601", appointment: "2026-10-19T09:00" },
  { type: "drop" as const, name: "ZZ TEST SYSCO", street: "5900 STEWART AVE", city: "FREMONT", state: "CA", zip: "94538", appointment: "2026-10-23T09:00" },
];

// Same model relations the server sets up at start (src/index.ts)
User.associate({ UserProfile });
UserProfile.associate({ User, Role, UserChannel, Channel, GroupUser, MessageStaff });
Role.associate({ UserProfile });
Channel.associate({ UserChannel, GroupChannel });
UserChannel.associate({ UserProfile, Channel });
Group.associate({ GroupChannel, GroupUser });
GroupUser.associate({ UserProfile, Group });
GroupChannel.associate({ Group, Channel });
MessageStaff.associate({ UserProfile });

const laDate = (d: Date) => new Intl.DateTimeFormat("en-CA", { timeZone: "America/Los_Angeles", year: "numeric", month: "2-digit", day: "2-digit" }).format(d);
/** The Route List form's numbering: the latest route's trip id + 1 (not the row id). */
const nextYardTripNo = async () => {
  const rows = await secondarySequelize.query<{ trip_id: string }>(`SELECT trip_id FROM driver_pay_details ORDER BY created_at DESC, id DESC LIMIT 1`, { type: QueryTypes.SELECT });
  return `00${(parseInt(String(rows[0]?.trip_id || "0").replace(/\D/g, ""), 10) || 0) + 1}`;
};
/** A load through to dispatch's Mark completed (the moment its Route List entry is created). */
const runToCompleted = async (id: number, driverActor: any, dispatcherActor: any) => {
  for (const a of ["accept", "rolling", "end"] as const) await act(id, a, driverActor);
  await act(id, "complete", dispatcherActor, { invoiceNo: `ZZTEST-INV-${id}` });
  return (await ChatTrip.findByPk(id))!;
};

(async () => {
  initSocket(http.createServer());
  registerTripHooks();

  // ---------- throwaway people ----------
  const [yardDriverId] = await secondarySequelize.query(`INSERT INTO drivers (name, created_at, updated_at) VALUES ('ZZ TEST DRIVER', NOW(), NOW())`, {
    type: QueryTypes.INSERT,
  });
  const driverRole = await Role.findOne({ where: { name: "driver" } });
  const staffRole = await Role.findOne({ where: { name: "staff" } });
  const user = await User.create({ driver_number: "zztest01", status: "active", yard_id: Number(yardDriverId) } as any);
  const driver = await UserProfile.create({ userId: user.id, role_id: driverRole!.id, username: "ZZ Test Driver", device_token: null } as any);
  const otherUser = await User.create({ driver_number: "zztest02", status: "active" } as any);
  const other = await UserProfile.create({ userId: otherUser.id, role_id: driverRole!.id, username: "ZZ Other Driver", device_token: null } as any);
  const staff = await UserProfile.findOne({ where: { role_id: staffRole!.id } });
  const channel = await primarySequelize.query<{ id: string }>(`SELECT id FROM channels WHERE name = 'demo' LIMIT 1`, { type: QueryTypes.SELECT });
  await UserChannel.create({ userProfileId: driver.id, channelId: channel[0].id } as any);

  const dispatcher = { role: "dispatcher" as const, id: staff!.id, name: staff!.username };
  const me = { role: "driver" as const, id: driver.id, name: driver.username };
  const tripIds: number[] = [];

  try {
    let tripId = 0;

    await test("add a load → scheduled with its own load number; nothing in the yard yet", async () => {
      const trip = await createTrip({ driverProfileId: driver.id, temperature: "34 CONT.", stops: STOPS }, dispatcher);
      assert(trip);
      tripId = trip.id;
      tripIds.push(tripId);
      assert.equal(trip.status, "scheduled");
      assert.equal(trip.trip_no, loadNo(trip.id));
      assert.match(String(trip.trip_no), /^L\d{4,}$/);
      assert.equal(trip.driver_pay_details_id, null, "no Route List entry before completion");
      assert.equal(trip.route_trip_no, null);
    });

    await test("driver asks for the next load → offered, told to wait for dispatch", async () => {
      await offerNextLoad(driver.id, "asked");
      const trip = await ChatTrip.findByPk(tripId);
      assert.equal(trip?.status, "offered");
      // Drivers never see lined-up loads: asking only gets "dispatch will send your next load"
      const said = await Message.findAll({ where: { userProfileId: driver.id }, order: [["createdAt", "DESC"]], limit: 5 });
      assert(said.some((m) => /dispatch will send your next load here/.test(String(m.body))), "told dispatch will send it");
      assert(!said.some((m) => /lined up/i.test(String(m.body))), "nothing about a lined-up load");
    });

    await test("only dispatch sends it: the load text goes to the driver's chat", async () => {
      await assert.rejects(act(tripId, "accept", me), /accept a trip that is waiting/i);
      const trip = await sendLoad(tripId, dispatcher);
      assert.equal(trip?.status, "planned");
      const msg = await Message.findByPk(trip!.message_id!);
      assert.match(String(msg?.body), /PICKUP\nZZ TEST COLD STORAGE[\s\S]*DROP\nZZ TEST SYSCO[\s\S]*10\/23\/2026 09:00AM/);
      // The load we sent ourselves is not read back as a second trip
      await wait(400);
      assert.equal(await ChatTrip.count({ where: { message_id: trip!.message_id! } }), 1);
    });

    await test("the driver runs the trip; another driver can't touch it", async () => {
      await assert.rejects(act(tripId, "accept", { role: "driver", id: other.id, name: "x" }), /isn't your trip/);
      // The driver's three taps: Got it → Rolling (→ Delivered below)
      for (const a of ["accept", "rolling"] as const) await act(tripId, a, me, { lat: 34.05, lng: -118.25 });
      const trip = await getTrip(tripId);
      assert.equal(trip?.status, "rolling");
      assert(trip?.started_at, "rolling starts the trip");
      const lines = await Message.findAll({ where: { userProfileId: driver.id, is_automated: true }, order: [["createdAt", "ASC"]] });
      assert(lines.some((l) => /accepted load/.test(String(l.body))) && lines.some((l) => /Loaded — rolling/.test(String(l.body))));
      // No scale ticket sent: asked once, right after Rolling (not at Got it)
      const asks = lines.filter((l) => /Please send the scale ticket/.test(String(l.body)));
      assert.equal(asks.length, 1, "asked once");
      const acceptedAt = lines.find((l) => /accepted load/.test(String(l.body)))!;
      const rollingAt = lines.find((l) => /Loaded — rolling/.test(String(l.body)))!;
      assert(new Date(asks[0].createdAt) >= new Date(rollingAt.createdAt) && asks[0].id !== acceptedAt.id, "asked after Rolling");
    });

    await test("end, undo by the same driver, end again; still nothing in the yard until dispatch completes", async () => {
      await act(tripId, "end", me);
      assert.equal((await ChatTrip.findByPk(tripId))?.status, "ended");
      await assert.rejects(undo(tripId, dispatcher), /Only the person/);
      await undo(tripId, me);
      const back = await ChatTrip.findByPk(tripId);
      assert.equal(back?.status, "rolling");
      assert.equal(back?.ended_at, null);
      await act(tripId, "end", me);
      const delivered = await ChatTrip.findByPk(tripId);
      assert.equal(delivered?.driver_pay_details_id, null, "delivered is not enough for the yard");
      await assert.rejects(act(tripId, "complete", me), /done by dispatcher/);
      const done = await getTrip(tripId);
      assert(done?.stops?.find((x) => x.seq === 2)?.arrived_at, "delivered marks the last stop arrived");
      const withGps = (done?.events || []).filter((e) => e.lat !== null);
      assert(withGps.length >= 2, "taps keep their location");
    });

    await test("Mark completed creates the Route List entry (next yard trip id, real dates, driver, stops, no pay record)", async () => {
      await assert.rejects(act(tripId, "complete", dispatcher), /invoice number/);
      await assert.rejects(act(tripId, "complete", dispatcher, { invoiceNo: "   " }), /invoice number/);
      const blocked = (await ChatTrip.findByPk(tripId))!;
      assert.equal(blocked.status, "ended", "no invoice, not completed");
      assert.equal(blocked.driver_pay_details_id, null, "no invoice, no Route List entry");
      const expected = await nextYardTripNo();
      await act(tripId, "complete", dispatcher, { invoiceNo: "  ZZTEST-INV-1 " });
      const trip = (await ChatTrip.findByPk(tripId))!;
      assert.equal(trip.status, "completed");
      assert.equal(trip.invoice_no, "ZZTEST-INV-1");
      assert(trip.driver_pay_details_id, "no Route List entry");
      assert.equal(trip.route_trip_no, expected);
      const [row] = await yard(`SELECT trip_id, trip_start_date, trip_end_date, driver_type, ready_status FROM driver_pay_details WHERE id = :id`, {
        id: trip.driver_pay_details_id,
      });
      assert.deepEqual(row, {
        trip_id: expected,
        trip_start_date: laDate(trip.started_at!),
        trip_end_date: laDate(trip.ended_at!),
        driver_type: "single",
        ready_status: "not-ready",
      });
      const expenses = await yard(`SELECT driver_id FROM driver_expenses WHERE driver_pay_details_id = :id`, { id: trip.driver_pay_details_id });
      assert.deepEqual(expenses.map((e: any) => e.driver_id), [String(yardDriverId)]);
      const legs = await yard(`SELECT pickup_location, delivery_location FROM driver_pay_mileages WHERE driver_pay_details_id = :id`, { id: trip.driver_pay_details_id });
      assert.deepEqual(legs, [{ pickup_location: "ZZ TEST COLD STORAGE - DECATUR, AL", delivery_location: "ZZ TEST SYSCO - FREMONT, CA" }]);
      const pays = await yard(`SELECT id FROM driver_pays WHERE driver_pay_details_id = :id`, { id: trip.driver_pay_details_id });
      assert.equal(pays.length, 0);
      const events = (await getTrip(tripId))?.events || [];
      assert(events.some((e) => e.note === `Route List entry ${expected} created`));
    });

    await test("dispatch undoing Mark completed takes the entry back out; completing again recreates it", async () => {
      const first = (await ChatTrip.findByPk(tripId))!;
      await undo(tripId, dispatcher);
      const back = (await ChatTrip.findByPk(tripId))!;
      assert.equal(back.status, "ended");
      assert.equal(back.driver_pay_details_id, null);
      assert.equal(back.invoice_no, "ZZTEST-INV-1", "undo keeps the invoice number");
      assert.equal((await yard(`SELECT id FROM driver_pay_details WHERE id = :id`, { id: first.driver_pay_details_id })).length, 0);
      await act(tripId, "complete", dispatcher);
      const again = (await ChatTrip.findByPk(tripId))!;
      assert.equal(again.status, "completed");
      assert(again.driver_pay_details_id);
    });

    await test("the accountant pricing the Route List row marks the trip priced", async () => {
      const trip = await ChatTrip.findByPk(tripId);
      await syncPriced([trip!]);
      assert.equal((await ChatTrip.findByPk(tripId))?.status, "completed", "not priced yet");
      await secondarySequelize.query(`UPDATE driver_pay_details SET load_rate_up = 1200 WHERE id = :id`, { replacements: { id: trip!.driver_pay_details_id } });
      await syncPriced([(await ChatTrip.findByPk(tripId))!]);
      assert.equal((await ChatTrip.findByPk(tripId))?.status, "routed");
    });

    await test("a scale ticket shared before Rolling is recorded, and the driver isn't asked", async () => {
      const t6 = await createTrip({ driverProfileId: driver.id, stops: STOPS }, dispatcher, { send: true });
      tripIds.push(t6!.id);
      await act(t6!.id, "accept", me);
      const photo = await Message.create({
        channelId: channel[0].id,
        userProfileId: driver.id,
        senderId: driver.id,
        body: "scale",
        messageDirection: "R",
        deliveryStatus: "sent",
        messageTimestampUtc: new Date(),
        isRead: false,
        status: "sent",
        url_upload_type: "with-out-media",
      } as any);
      await MessageDocument.create({ message_id: photo.id, status: "done", doc_type_key: "scale_ticket" } as any);
      await onDocumentRead(photo as any, "scale_ticket");
      await act(t6!.id, "rolling", me);
      const asks = await Message.count({ where: { userProfileId: driver.id, body: { [Op.like]: `%send the scale ticket for load ${t6!.trip_no}%` } } });
      assert.equal(asks, 0, "already shared: not asked");
      const trip = await getTrip(t6!.id);
      assert((trip?.events || []).some((e) => e.note === "Scale ticket received"));
      await MessageDocument.destroy({ where: { message_id: photo.id } });
    });

    await test("problems put a trip on hold and resolving resumes it", async () => {
      const t2 = await createTrip({ driverProfileId: driver.id, stops: STOPS }, dispatcher, { send: true });
      tripIds.push(t2!.id);
      await act(t2!.id, "start", me);
      const held = await addProblem(t2!.id, { kind: "breakdown", note: "flat tire", hold: true }, me);
      assert.equal(held?.status, "on_hold");
      const p = held?.problems?.[0];
      const resumed = await resolveProblem(t2!.id, p!.id, dispatcher);
      assert.equal(resumed?.status, "started");
    });

    await test("at completion: route rows add up to Total Mileage (trip start row included); lumper fills the form's Lumper", async () => {
      const t5 = await createTrip({ driverProfileId: driver.id, stops: STOPS }, dispatcher, { send: true });
      tripIds.push(t5!.id);
      await addProblem(t5!.id, { kind: "lumper", note: "paid at dock", amount: 150 }, me);
      // Samsara mileage as addMileage() writes it: start → pickup 12.5 mi, pickup → drop 2290 mi
      const stops = [...(t5!.stops || [])].sort((a, b) => a.seq - b.seq);
      await stops[0].update({ mileage: "12.5" });
      await stops[1].update({ mileage: "2290" });
      const done = await runToCompleted(t5!.id, me, dispatcher);
      const rows = await yard<any>(`SELECT pickup_location, delivery_location, mileage FROM driver_pay_mileages WHERE driver_pay_details_id = :id ORDER BY id`, {
        id: done.driver_pay_details_id,
      });
      assert.deepEqual(
        rows.map((r) => [r.pickup_location, r.delivery_location, Number(r.mileage)]),
        [
          ["Trip start", "ZZ TEST COLD STORAGE - DECATUR, AL", 12.5],
          ["ZZ TEST COLD STORAGE - DECATUR, AL", "ZZ TEST SYSCO - FREMONT, CA", 2290],
        ]
      );
      const [row] = await yard<any>(`SELECT total_mileage, lumper FROM driver_pay_details WHERE id = :id`, { id: done.driver_pay_details_id });
      assert.equal(Number(row.total_mileage), 2302.5);
      assert.equal(Number(row.lumper), 150);
    });

    await test("cancel needs a reason; a cancelled load never reaches the yard", async () => {
      const t3 = await createTrip({ driverProfileId: driver.id, stops: STOPS }, dispatcher, { send: true });
      tripIds.push(t3!.id);
      await assert.rejects(act(t3!.id, "cancel", dispatcher), /why/);
      await act(t3!.id, "cancel", dispatcher, { note: "Shipper closed" });
      const t = await ChatTrip.findByPk(t3!.id);
      assert.equal(t?.status, "cancelled");
      assert.equal(t?.driver_pay_details_id, null);
    });

    await test("a priced Route List row is never overwritten", async () => {
      const t4 = await createTrip({ driverProfileId: driver.id, stops: STOPS }, dispatcher, { send: true });
      tripIds.push(t4!.id);
      const done = await runToCompleted(t4!.id, me, dispatcher);
      await secondarySequelize.query(`UPDATE driver_pay_details SET load_rate_up = 1500, total_mileage = NULL WHERE id = :id`, { replacements: { id: done.driver_pay_details_id } });
      assert.equal(await isPriced(done.driver_pay_details_id!), true);
      const fresh = await ChatTrip.findByPk(t4!.id, { include: ["stops"] });
      await fresh!.update({ total_mileage: "999" });
      assert.equal(await syncRouteRow(fresh!, fresh!.stops || []), false);
      const [row] = await yard(`SELECT total_mileage FROM driver_pay_details WHERE id = :id`, { id: done.driver_pay_details_id });
      assert.equal((row as any).total_mileage, null);
    });

    await test("the driver's Loads list: their loads, newest first; not the ones dispatch hasn't sent", async () => {
      const lined = await createTrip({ driverProfileId: driver.id, stops: STOPS }, dispatcher); // scheduled, not sent
      tripIds.push(lined!.id);
      const mine = await tripsForDriver(driver.id);
      const ids = mine.trips.map((t) => t.id);
      assert(ids.includes(tripId), "a load the driver ran is listed");
      assert(!ids.includes(lined!.id), "a lined-up load isn't");
      assert(mine.trips.every((t) => !["scheduled", "offered"].includes(t.status)));
      const others = await tripsForDriver(other.id);
      assert(!others.trips.some((t) => ids.includes(t.id)), "another driver doesn't see them");
    });

    await test("a load typed by dispatch in chat becomes a trip like the form's Send now (flagged when unsure)", async () => {
      const no = `ZZF${Date.now() % 100000}`;
      await Message.create({
        channelId: channel[0].id,
        userProfileId: driver.id,
        senderId: staff!.id,
        body: `YOUR LONG LOAD FOR TOMORROW MORNING.\n\nLOAD # ${no}\nTEMP # 34 CONT.\n\nZZ TARGET - LAKE CITY\n309 NE TAMMY LANE\nLAKE CITY, FL 32055\n11/05/2026 02:00PM`,
        messageDirection: "S",
        deliveryStatus: "sent",
        messageTimestampUtc: new Date(),
        isRead: false,
        status: "sent",
        url_upload_type: "with-out-media",
      } as any);
      await wait(2500);
      // This driver may still be busy with an earlier load: then dispatch was asked — answer "Line up"
      if (!(await ChatLoad.findOne({ where: { invoice_no: no } }))) {
        const parsed = parseLoad(`YOUR LONG LOAD FOR TOMORROW MORNING.\n\nLOAD # ${no}\nTEMP # 34 CONT.\n\nZZ TARGET - LAKE CITY\n309 NE TAMMY LANE\nLAKE CITY, FL 32055\n11/05/2026 02:00PM`)!;
        const q = await loadFromChat({ loadNo: parsed.loadNo, driverProfileId: driver.id, stops: parsed.stops, temperature: parsed.temperature, needsReview: parsed.needsReview, reviewNotes: parsed.reasons }, dispatcher);
        assert.equal(q.kind, "question", "asked, not created");
        await answerTypedLoad((q as any).id, { lineUp: true, endPrevious: true }, dispatcher);
      }
      const load = await ChatLoad.findOne({ where: { invoice_no: no } });
      const trip = load ? await ChatTrip.findOne({ where: { load_id: load.id }, include: ["stops"] }) : null;
      assert(trip, "no trip from the typed load");
      tripIds.push(trip.id);
      assert(["planned", "scheduled"].includes(trip.status), trip.status);
      assert.equal(trip.source, "typed");
      assert.equal(trip.stops?.[0].type, "drop");
      assert(!/Only one address/.test(String(trip.review_notes || "")), "one address with no PICK/DROP labels is simply the drop — no 'check it' note");
    });
  } finally {
    // ---------- clean up everything this run created ----------
    const trips = await ChatTrip.findAll({ where: { id: tripIds } });
    const routeIds = trips.map((t) => t.driver_pay_details_id).filter(Boolean);
    if (routeIds.length) {
      await secondarySequelize.query(`DELETE FROM driver_pay_mileages WHERE driver_pay_details_id IN (:ids)`, { replacements: { ids: routeIds } });
      await secondarySequelize.query(`DELETE FROM driver_expenses WHERE driver_pay_details_id IN (:ids)`, { replacements: { ids: routeIds } });
      await secondarySequelize.query(`DELETE FROM driver_pay_details WHERE id IN (:ids)`, { replacements: { ids: routeIds } });
    }
    await ChatTripEvent.destroy({ where: { chat_trip_id: tripIds } });
    const loadIds = trips.map((t) => t.load_id).filter(Boolean) as number[];
    await ChatTrip.destroy({ where: { id: tripIds } });
    if (loadIds.length) await ChatLoad.destroy({ where: { id: loadIds } });
    const testMessages = await Message.findAll({ where: { userProfileId: [driver.id, other.id] }, attributes: ["id"] });
    await MessageDocument.destroy({ where: { message_id: testMessages.map((m) => m.id) } });
    await Message.destroy({ where: { userProfileId: [driver.id, other.id] } });
    await UserChannel.destroy({ where: { userProfileId: [driver.id, other.id] } });
    await primarySequelize.query(`DELETE FROM driver_trips WHERE driver_id IN (:ids)`, { replacements: { ids: [driver.id, other.id] } });
    await UserProfile.destroy({ where: { id: [driver.id, other.id] } });
    await User.destroy({ where: { id: [user.id, otherUser.id] } });
    await secondarySequelize.query(`DELETE FROM drivers WHERE id = :id`, { replacements: { id: yardDriverId } });
  }

  console.log(results.join("\n"));
  process.exit(results.some((r) => r.startsWith("FAIL")) ? 1 : 0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
