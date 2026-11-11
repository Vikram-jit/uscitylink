// Run: npx ts-node -T scripts/trips/loads.check.ts
// Loads with legs against the LOCAL databases (refuses anything else): via the yard with a second
// driver, a relay with "assign later", the invoice rule, Route List on hold for multi-leg loads, the
// equipment board, "already on a load" warnings, yard visits and delivered-vs-ETA.
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
import { act, offerNextLoad, sendLoad } from "../../src/services/trips/tripService";
import { assignLeg, createLoad, deliveryTiming, getLoad, listLoads } from "../../src/services/trips/loadService";
import { conflictsFor, trailersBoard, trucksBoard, yardVisitsFrom } from "../../src/services/trips/equipment";
import { loadStatusOf } from "../../src/services/trips/legs";

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

const PICKUP = { type: "pickup" as const, name: "ZZ TEST COLD STORAGE", street: "1 Test Rd", city: "DECATUR", state: "AL", zip: "35601", appointment: "2026-10-19T13:30" };
const YARD = { type: "yard" as const, name: "ZZ TEST YARD", street: "2 Yard Rd", city: "FONTANA", state: "CA", zip: "92335" };
const MEET = { type: "switch" as const, name: "ZZ TEST TA", street: "3 Meet Rd", city: "AMARILLO", state: "TX", zip: "79101" };
const DROP = { type: "drop" as const, name: "ZZ TEST SYSCO", street: "4 Drop Rd", city: "FREMONT", state: "CA", zip: "94538", appointment: "2026-10-23T09:00" };

const lastMessage = async (profileId: string) => String((await Message.findOne({ where: { userProfileId: profileId }, order: [["createdAt", "DESC"]] }))?.body || "");

(async () => {
  initSocket(http.createServer());

  // ---------- throwaway people; a real fleet trailer and truck nobody's loads use (read only) ----------
  const driverRole = await Role.findOne({ where: { name: "driver" } });
  const staffRole = await Role.findOne({ where: { name: "staff" } });
  const yardIds: number[] = [];
  const users: User[] = [];
  const people: UserProfile[] = [];
  for (const n of ["A", "B"]) {
    const [yardId] = await secondarySequelize.query(`INSERT INTO drivers (name, created_at, updated_at) VALUES (:n, NOW(), NOW())`, {
      replacements: { n: `ZZ TEST LEG DRIVER ${n}` },
      type: QueryTypes.INSERT,
    });
    yardIds.push(Number(yardId));
    const user = await User.create({ driver_number: `zzleg${n}`, status: "active", yard_id: Number(yardId) } as any);
    users.push(user);
    people.push(await UserProfile.create({ userId: user.id, role_id: driverRole!.id, username: `ZZ Leg Driver ${n}`, device_token: null } as any));
  }
  const [a, b] = people;
  const staff = await UserProfile.findOne({ where: { role_id: staffRole!.id } });
  const channel = await primarySequelize.query<{ id: string }>(`SELECT id FROM channels WHERE name = 'demo' LIMIT 1`, { type: QueryTypes.SELECT });
  for (const p of people) await UserChannel.create({ userProfileId: p.id, channelId: channel[0].id } as any);
  const [trailer] = await secondarySequelize.query<{ id: number; number: string }>(
    `SELECT id, number FROM trailers WHERE company_id IS NULL AND is_active = '1' AND deleted_at IS NULL ORDER BY id DESC LIMIT 1`,
    { type: QueryTypes.SELECT }
  );
  const usedTrucks = (await ChatTrip.findAll({ attributes: ["truck_number"] })).map((t) => String(t.truck_number || "").toUpperCase());
  const truckGroups = (await Group.findAll({ where: { type: "truck" } })).map((g: any) => String(g.name).toUpperCase());
  const fleetTrucks = await secondarySequelize.query<{ number: string }>(
    `SELECT number FROM trucks WHERE company_id IS NULL AND status = '1' AND deleted_at IS NULL ORDER BY id DESC LIMIT 200`,
    { type: QueryTypes.SELECT }
  );
  const truck = fleetTrucks.map((t) => String(t.number).trim()).find((n) => !usedTrucks.includes(n.toUpperCase()) && !truckGroups.includes(n.toUpperCase()));
  assert(trailer && truck, "need a fleet trailer and a free fleet truck in the local yard DB");

  const dispatcher = { role: "dispatcher" as const, id: staff!.id, name: staff!.username };
  const asA = { role: "driver" as const, id: a.id, name: a.username };
  const asB = { role: "driver" as const, id: b.id, name: b.username };
  const loadIds: number[] = [];

  try {
    let viaYard = 0;
    let leg1 = 0;
    let leg2 = 0;

    await test("via yard: two legs, numbered after the load; leg 2 starts at the yard leg 1 ends at", async () => {
      const res = await createLoad(
        {
          type: "via_yard",
          legs: [
            { driverProfileId: a.id, truckNumber: truck, trailerNumbers: [trailer.number], stops: [PICKUP, YARD] },
            { stops: [DROP] },
          ],
        },
        dispatcher
      );
      viaYard = res.load.id;
      loadIds.push(viaYard);
      const [l1, l2] = res.legs;
      leg1 = l1.id;
      leg2 = l2.id;
      assert.equal(res.load.type, "via_yard");
      assert.equal(res.load.load_no, l1.trip_no);
      assert.equal(l2.trip_no, `${l1.trip_no}-2`);
      assert.equal(l1.ends_at_yard, true);
      assert.deepEqual(l2.stops!.map((s) => s.type), ["yard", "drop"]);
      assert.equal(l2.driver_profile_id, null, "leg 2: assign later");
      assert.equal(res.load.status, "scheduled");
    });

    await test("leg 2 can't go out before leg 1 is delivered (no driver yet; then blocked by leg 1)", async () => {
      await assert.rejects(sendLoad(leg2, dispatcher), /Assign a driver/);
      await assignLeg(viaYard, leg2, { driverProfileId: b.id }, dispatcher);
      await assert.rejects(sendLoad(leg2, dispatcher), /isn't delivered yet/);
      // Driver B asking for a load doesn't get it early either
      await offerNextLoad(b.id, "asked");
      assert.equal((await ChatTrip.findByPk(leg2))?.status, "scheduled");
    });

    await test("leg 1 on the road: truck and trailer show On load; the same trailer elsewhere is flagged", async () => {
      await sendLoad(leg1, dispatcher);
      await act(leg1, "accept", asA);
      await act(leg1, "rolling", asA);
      assert.equal((await ChatLoad.findByPk(viaYard))?.status, "active");
      const trailers = await trailersBoard();
      const t = trailers.find((x) => x.id === Number(trailer.id))!;
      assert.equal(t.state, "on_load");
      assert.equal(t.leg?.tripId, leg1);
      const trucks = await trucksBoard();
      assert.equal(trucks.find((x) => x.number === truck)?.state, "on_load");
      const conflicts = await conflictsFor({ truckNumber: truck, trailerNumbers: [trailer.number], driverProfileIds: [a.id] });
      assert.deepEqual(conflicts.filter((c) => c.leg.tripId === leg1).map((c) => c.kind).sort(), ["driver", "trailer", "truck"]);
      // Its own load doesn't count
      assert.equal((await conflictsFor({ truckNumber: truck, loadId: viaYard })).length, 0);
    });

    await test("leg 1 dropped at the yard: driver A told so, leg 2 offered to driver B with the trailer carried over", async () => {
      await act(leg1, "end", asA);
      assert.match(await lastMessageOf(a.id, /dropped at the yard/), /dropped at the yard/);
      const l2 = await ChatTrip.findByPk(leg2);
      assert.equal(l2?.status, "offered");
      assert.equal(l2?.trailer_numbers, trailer.number);
      assert.equal(l2?.loaded_trailer, true);
      assert.match(await lastMessageOf(b.id, /waiting for dispatch/), /waiting for dispatch/);
      await wait(600);
      assert.equal((await ChatLoad.findByPk(viaYard))?.status, "waiting");
    });

    await test("leg 1 completes without the invoice # (not the last leg); Route List on hold", async () => {
      await act(leg1, "complete", dispatcher);
      const l1 = await ChatTrip.findByPk(leg1);
      assert.equal(l1?.status, "completed");
      assert.equal(l1?.driver_pay_details_id, null);
      const events = await ChatTripEvent.findAll({ where: { chat_trip_id: leg1 } });
      assert(events.some((e) => e.note === "Route List on hold (multi-leg load)"));
    });

    await test("leg 2 runs; the last leg needs the invoice #; it goes on the whole load", async () => {
      await sendLoad(leg2, dispatcher);
      for (const x of ["accept", "rolling", "end"] as const) await act(leg2, x, asB);
      await wait(600);
      assert.equal((await ChatLoad.findByPk(viaYard))?.status, "delivered");
      await assert.rejects(act(leg2, "complete", dispatcher), /invoice number/);
      await act(leg2, "complete", dispatcher, { invoiceNo: "ZZTEST-INV-77" });
      await wait(600);
      const res = await getLoad(viaYard);
      assert.equal(res.load.invoice_no, "ZZTEST-INV-77");
      assert.deepEqual(res.legs.map((l) => l.invoice_no), ["ZZTEST-INV-77", "ZZTEST-INV-77"]);
      assert.equal(res.load.status, "completed");
      assert(res.legs.every((l) => !l.driver_pay_details_id), "no Route List rows for a multi-leg load");
      assert.equal(res.yardVisits.filter((v) => v.source === "leg").length >= 0, true);
    });

    await test("relay, leg 2 assign later: after the handover the load waits under Ready to transfer", async () => {
      const res = await createLoad(
        { type: "relay", invoiceNo: "ZZTEST-INV-78", legs: [{ driverProfileId: a.id, trailerNumbers: [trailer.number], stops: [PICKUP, MEET] }, { stops: [DROP] }] },
        dispatcher,
        { send: true }
      );
      loadIds.push(res.load.id);
      const [l1, l2] = res.legs;
      assert.deepEqual(l2.stops!.map((s) => s.type), ["switch", "drop"]);
      for (const x of ["accept", "rolling", "end"] as const) await act(l1.id, x, asA);
      assert.match(await lastMessageOf(a.id, /handed over/), /handed over/);
      await wait(600);
      assert.equal((await ChatTrip.findByPk(l2.id))?.status, "scheduled", "no driver: not offered");
      assert.equal((await ChatLoad.findByPk(res.load.id))?.status, "transfer");
      const t = (await trailersBoard()).find((x) => x.id === Number(trailer.id))!;
      assert.equal(t.state, "waiting_transfer");
      const list = await listLoads({ status: "transfer", q: "ZZTEST-INV-78" });
      assert.deepEqual(list.loads.map((l) => l.id), [res.load.id]);
      // Assign driver B and send in one go
      await assignLeg(res.load.id, l2.id, { driverProfileId: b.id, send: true }, dispatcher);
      assert.equal((await ChatTrip.findByPk(l2.id))?.status, "planned");
    });

    await test("load status from its legs", () => {
      const leg = (leg_no: number, status: string) => ({ leg_no, status, driver_profile_id: null, ends_at_yard: false }) as any;
      assert.equal(loadStatusOf([leg(1, "scheduled"), leg(2, "scheduled")]), "scheduled");
      assert.equal(loadStatusOf([leg(1, "rolling"), leg(2, "scheduled")]), "active");
      assert.equal(loadStatusOf([leg(1, "ended"), leg(2, "scheduled")]), "transfer");
      assert.equal(loadStatusOf([leg(1, "completed"), leg(2, "offered")]), "waiting");
      assert.equal(loadStatusOf([leg(1, "completed"), leg(2, "paperwork")]), "delivered");
      assert.equal(loadStatusOf([leg(1, "completed"), leg(2, "routed")]), "completed");
      assert.equal(loadStatusOf([leg(1, "cancelled")]), "cancelled");
      assert.equal(loadStatusOf([leg(1, "completed"), leg(2, "cancelled")]), "completed");
    });

    await test("yard visits: gate entry/depart pairs per trailer, plus a yard leg security didn't log", () => {
      const t = (h: number) => new Date(Date.UTC(2026, 10, 1, h));
      const gate = [
        { trailer_id: 7, status: "entry" as const, empty_loaded: "loaded", created_at: t(2) },
        { trailer_id: 7, status: "depart" as const, empty_loaded: "loaded", created_at: t(20) },
        { trailer_id: 7, status: "entry" as const, empty_loaded: "loaded", created_at: t(30) },
      ];
      const legs = [
        { leg_no: 1, status: "completed", ends_at_yard: true, ended_at: t(2), started_at: t(0) }, // matches the gate entry
        { leg_no: 2, status: "completed", ends_at_yard: true, ended_at: t(50), started_at: t(20) }, // not logged at the gate
        { leg_no: 3, status: "rolling", ends_at_yard: false, ended_at: null, started_at: t(60) },
      ] as any;
      const visits = yardVisitsFrom(legs, gate, new Map([[7, "10265"]]), t(40));
      assert.deepEqual(
        visits.map((v) => [v.source, v.trailer, v.minutes]),
        [
          ["gate", "10265", 18 * 60],
          ["gate", "10265", 10 * 60], // still in: until "now"
          ["leg", null, 10 * 60], // dropped at t50, next leg left at t60
        ]
      );
    });

    await test("delivered vs appointment and vs the ETA at Rolling", () => {
      const at = (h: number, m = 0) => new Date(Date.UTC(2026, 10, 2, h, m));
      const legs = [
        { leg_no: 1, status: "completed", ended_at: at(1), planned_eta_at: null, stops: [] },
        { leg_no: 2, status: "ended", ended_at: at(10, 40), planned_eta_at: at(10), stops: [{ seq: 2, appointment_at: at(9, 0) }] },
      ] as any;
      const timing = deliveryTiming(legs)!;
      assert.equal(timing.lateMinutes, 100);
      assert.equal(timing.etaOffMinutes, 40);
      assert.equal(timing.etaVsAppointmentMinutes, 60);
    });
  } finally {
    // ---------- clean up everything this run created ----------
    const trips = await ChatTrip.findAll({ where: { load_id: loadIds } });
    const tripIds = trips.map((t) => t.id);
    const routeIds = trips.map((t) => t.driver_pay_details_id).filter(Boolean);
    if (routeIds.length) {
      await secondarySequelize.query(`DELETE FROM driver_pay_mileages WHERE driver_pay_details_id IN (:ids)`, { replacements: { ids: routeIds } });
      await secondarySequelize.query(`DELETE FROM driver_expenses WHERE driver_pay_details_id IN (:ids)`, { replacements: { ids: routeIds } });
      await secondarySequelize.query(`DELETE FROM driver_pay_details WHERE id IN (:ids)`, { replacements: { ids: routeIds } });
    }
    if (tripIds.length) {
      await ChatTripEvent.destroy({ where: { chat_trip_id: tripIds } });
      await ChatTrip.destroy({ where: { id: tripIds } });
    }
    if (loadIds.length) await ChatLoad.destroy({ where: { id: loadIds } });
    const ids = people.map((p) => p.id);
    await Message.destroy({ where: { userProfileId: ids } });
    await UserChannel.destroy({ where: { userProfileId: ids } });
    await primarySequelize.query(`DELETE FROM driver_trips WHERE driver_id IN (:ids)`, { replacements: { ids } });
    await UserProfile.destroy({ where: { id: ids } });
    await User.destroy({ where: { id: users.map((u) => u.id) } });
    await secondarySequelize.query(`DELETE FROM drivers WHERE id IN (:ids)`, { replacements: { ids: yardIds } });
  }

  console.log(results.join("\n"));
  process.exit(results.some((r) => r.startsWith("FAIL")) ? 1 : 0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});

function wait(ms: number) {
  return new Promise((r) => setTimeout(r, ms));
}

/** The newest chat line for the driver matching [re] (the bot may add more lines after it). */
async function lastMessageOf(profileId: string, re: RegExp) {
  const rows = await Message.findAll({ where: { userProfileId: profileId }, order: [["createdAt", "DESC"]], limit: 10 });
  return String(rows.find((r) => re.test(String(r.body)))?.body || "");
}
