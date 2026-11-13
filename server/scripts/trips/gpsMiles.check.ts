// Run: npx ts-node -T scripts/trips/gpsMiles.check.ts
// Miles per leg from the truck's GPS when the driver didn't tap or dispatch ended late — against the
// LOCAL databases (refuses anything else). Samsara and Google are faked here: each test truck drives a
// made-up trail on a straight line (1 mile = 1/69° of latitude), and the odometer follows the trail.
// Throwaway drivers / trucks, everything it created is removed at the end.
import "dotenv/config";
process.env.TRIP_ETA_SNAPSHOT = "off";
process.env.SAMSARA_API_KEY = "test-key";
process.env.GOOGLE_PLACES_API_KEY = "test-key";
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
import { act, addMileage, NO_GPS_NOTE } from "../../src/services/trips/tripService";
import { addLoad, getLoad } from "../../src/services/trips/loadService";
import { endLegNow, setMiles } from "../../src/services/trips/loadControl";
import { milesReport } from "../../src/services/trips/milesReport";
import { dwellsOf, matchStops, meetPoint } from "../../src/services/trips/gpsTimes";

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

// ---------- the fake world ----------
const DAY = new Date(Date.UTC(new Date().getUTCFullYear(), new Date().getUTCMonth(), new Date().getUTCDate() - 2));
const at = (h: number, m = 0) => new Date(DAY.getTime() + (h * 60 + m) * 60_000);
const pos = (x: number) => ({ lat: 30 + x / 69, lng: -97 });
/** [start "hh:mm", end "hh:mm", from mile, to mile] — the truck moves straight, or stands still */
type Seg = [string, string, number, number];
const mins = (s: string) => Number(s.split(":")[0]) * 60 + Number(s.split(":")[1]);
function trailOf(segs: Seg[]) {
  const pts: { t: number; x: number; mph: number }[] = [];
  for (const [a, b, x0, x1] of segs) {
    const m0 = mins(a);
    const m1 = mins(b);
    const mph = Math.abs(x1 - x0) / ((m1 - m0) / 60);
    for (let m = m0; m < m1; m++) pts.push({ t: at(0, m).getTime(), x: x0 + ((x1 - x0) * (m - m0)) / (m1 - m0), mph });
  }
  const [a, b, x0, x1] = segs[segs.length - 1];
  pts.push({ t: at(0, mins(b)).getTime(), x: x1, mph: 0 });
  void a;
  void x0;
  let odo = 5_000_000; // meters
  return pts.map((p, i) => {
    if (i) odo += Math.abs(p.x - pts[i - 1].x) * 1609.344;
    return { ...p, odo };
  });
}
const TRAILS: Record<string, ReturnType<typeof trailOf>> = {};
// Addresses the fake Google knows (city → mile on the line); anything else: not found
const PLACES: Record<string, number> = { ZZGPICK: 0, ZZGDROP: 200, ZZG3PICK: 1000, ZZG3DROP: 1240, ZZG4PICK: 2000, ZZG4MEET: 2100, ZZG4DROP: 2250 };

const realFetch = globalThis.fetch;
(globalThis as any).fetch = async (input: any) => {
  const url = new URL(String(input));
  const json = (body: any) => ({ ok: true, status: 200, json: async () => body }) as any;
  if (url.hostname === "api.samsara.com" && url.pathname.endsWith("/stats/history")) {
    const trail = TRAILS[url.searchParams.get("vehicleIds") || ""] || [];
    const from = new Date(url.searchParams.get("startTime")!).getTime();
    const to = new Date(url.searchParams.get("endTime")!).getTime();
    const inWin = trail.filter((p) => p.t >= from && p.t <= to);
    const type = url.searchParams.get("types");
    const list =
      type === "gps"
        ? inWin.map((p) => ({ time: new Date(p.t).toISOString(), ...{ latitude: pos(p.x).lat, longitude: pos(p.x).lng }, speedMilesPerHour: p.mph }))
        : inWin.map((p) => ({ time: new Date(p.t).toISOString(), value: Math.round(p.odo) }));
    return json({ data: [{ id: url.searchParams.get("vehicleIds"), [type!]: list }], pagination: { hasNextPage: false } });
  }
  if (url.hostname === "api.samsara.com") return json({ data: [] });
  if (url.hostname === "maps.googleapis.com" && url.pathname.endsWith("/geocode/json")) {
    const address = url.searchParams.get("address");
    if (address) {
      const hit = Object.keys(PLACES).find((k) => address.toUpperCase().includes(k));
      return json(hit ? { status: "OK", results: [{ geometry: { location: pos(PLACES[hit]) } }] } : { status: "ZERO_RESULTS", results: [] });
    }
    const lat = Number(url.searchParams.get("latlng")!.split(",")[0]);
    const mile = Math.round((lat - 30) * 69);
    return json({
      status: "OK",
      results: [
        {
          formatted_address: `Mile ${mile} Rd, ZZMILE${mile}, TX 75001`,
          address_components: [
            { long_name: `${mile}`, short_name: `${mile}`, types: ["street_number"] },
            { long_name: "Mile Rd", short_name: "Mile Rd", types: ["route"] },
            { long_name: `ZZMILE${mile}`, short_name: `ZZMILE${mile}`, types: ["locality"] },
            { long_name: "Texas", short_name: "TX", types: ["administrative_area_level_1"] },
            { long_name: "75001", short_name: "75001", types: ["postal_code"] },
          ],
        },
      ],
    });
  }
  return json({ status: "ZERO_RESULTS", results: [], data: [] });
};

const near = (actual: Date | null | undefined, expected: Date, minutes = 3, what = "time") => {
  assert(actual, `${what} is empty`);
  const off = Math.abs(new Date(actual).getTime() - expected.getTime()) / 60_000;
  assert(off <= minutes, `${what} ${new Date(actual).toISOString()} is ${Math.round(off)} min from ${expected.toISOString()}`);
};
const about = (actual: any, expected: number, tol = 2.5, what = "miles") => {
  assert(actual !== null && actual !== undefined, `${what} empty`);
  assert(Math.abs(Number(actual) - expected) <= tol, `${what} ${actual} ≠ ~${expected}`);
};
const settle = () => new Promise((r) => setTimeout(r, 1500));

(async () => {
  initSocket(http.createServer());
  const driverRole = await Role.findOne({ where: { name: "driver" } });
  const staffRole = await Role.findOne({ where: { name: "staff" } });
  const yardDrivers: number[] = [];
  const yardTrucks: number[] = [];
  const users: User[] = [];
  const people: UserProfile[] = [];
  for (const n of ["A", "B"]) {
    const [yardId] = await secondarySequelize.query(`INSERT INTO drivers (name, created_at, updated_at) VALUES (:n, NOW(), NOW())`, {
      replacements: { n: `ZZ TEST GPS ${n}` },
      type: QueryTypes.INSERT,
    });
    yardDrivers.push(Number(yardId));
    const user = await User.create({ driver_number: `zzgps${n}`, status: "active", yard_id: Number(yardId) } as any);
    users.push(user);
    people.push(await UserProfile.create({ userId: user.id, role_id: driverRole!.id, username: `ZZ GPS Driver ${n}`, device_token: null } as any));
  }
  for (const [num, vid] of [
    ["ZZGPS1", "zzv1"],
    ["ZZGPS2", "zzv2"],
    ["ZZGPS3A", "zzv3a"],
    ["ZZGPS3B", "zzv3b"],
    ["ZZGPS4", "zzv4"],
  ]) {
    const [id] = await secondarySequelize.query(`INSERT INTO trucks (number, samsara_vehicle_id, status, created_at, updated_at) VALUES (:num, :vid, '1', NOW(), NOW())`, {
      replacements: { num, vid },
      type: QueryTypes.INSERT,
    });
    yardTrucks.push(Number(id));
  }
  const [a, b] = people;
  const staff = await UserProfile.findOne({ where: { role_id: staffRole!.id } });
  const channel = await primarySequelize.query<{ id: string }>(`SELECT id FROM channels WHERE name = 'demo' LIMIT 1`, { type: QueryTypes.SELECT });
  for (const p of people) await UserChannel.create({ userProfileId: p.id, channelId: channel[0].id } as any);
  const dispatcher = { role: "dispatcher" as const, id: staff!.id, name: staff!.username };
  const asA = { role: "driver" as const, id: a.id, name: a.username };
  const loadIds: number[] = [];
  const stop = (type: "pickup" | "drop" | "switch", city: string, name = city) => ({ type, name: `${name} CO`, street: "1 Main St", city, state: "TX" });
  /** Send a load, then pretend it was sent at [sentAt] (the trail is two days ago) */
  const sendAt = async (input: any, sentAt: Date, opts: any = {}) => {
    const res: any = await addLoad(input, dispatcher, { send: true, ...opts });
    const legId = Number(res?.legId || res?.trip?.id || res?.id);
    const leg = legId ? await ChatTrip.findByPk(legId) : await ChatTrip.findOne({ where: { driver_profile_id: input.driverProfileId }, order: [["id", "DESC"]] });
    if (leg?.load_id) loadIds.push(leg.load_id);
    await ChatTrip.update({ sent_at: sentAt }, { where: { id: leg!.id }, silent: true });
    return (await ChatTrip.findByPk(leg!.id))!;
  };
  const legOf = (id: number) => ChatTrip.findByPk(id, { include: [{ model: ChatTripStop, as: "stops" }] }) as Promise<ChatTrip>;
  const sorted = (l: ChatTrip) => [...(l.stops || [])].sort((x, y) => x.seq - y.seq);

  try {
    await test("matcher: arrival / departure at each stop, dwells, where two trucks met", () => {
      const t = trailOf([
        ["06:00", "08:00", -60, 0],
        ["08:00", "09:00", 0, 0],
        ["09:00", "15:40", 0, 200],
        ["15:40", "16:30", 200, 200],
        ["16:30", "19:10", 200, 280],
      ]).map((p) => ({ t: p.t, mph: p.mph, ...pos(p.x) }));
      const [p, d] = matchStops(t, [pos(0), pos(200)]);
      near(p!.departedAt, at(9, 0), 2, "left pickup");
      near(d!.arrivedAt, at(15, 40), 2, "arrived delivery");
      assert.equal(dwellsOf(t).length, 2);
      // delivery not on the map: the truck's last stop before dispatch ended (19:10) — the 15:40 dwell
      const [, d2] = matchStops(t, [pos(0), null], { endBy: at(19, 10) });
      near(d2!.arrivedAt, at(15, 40), 2, "delivery from the dwell");
      const other = trailOf([
        ["11:00", "15:00", 120, 120],
        ["15:00", "16:00", 120, 150],
      ]).map((q) => ({ t: q.t, mph: q.mph, ...pos(q.x) }));
      const m = meetPoint(t, other);
      assert(m, "met");
      assert(Math.abs((m!.lat - 30) * 69 - 120) < 0.5, "met at mile 120");
    });

    let leg1 = 0;
    await test("never tapped, dispatch ends late (19:10): Rolling 9:00 and Delivered 15:40 from GPS; miles only pickup → delivery", async () => {
      TRAILS.zzv1 = trailOf([
        ["06:00", "08:00", -60, 0],
        ["08:00", "09:00", 0, 0],
        ["09:00", "15:40", 0, 200],
        ["15:40", "16:30", 200, 200],
        ["16:30", "19:10", 200, 280],
        ["19:10", "20:10", 280, 280],
      ]);
      const leg = await sendAt({ loadNo: "ZZGPS-1", driverProfileId: a.id, truckNumber: "ZZGPS1", stops: [stop("pickup", "ZZGPICK"), stop("drop", "ZZGDROP")] }, at(7, 30));
      leg1 = leg.id;
      await endLegNow(leg.id, dispatcher, { at: at(19, 10), sendNext: false });
      await settle();
      const l = await legOf(leg.id);
      near(l.started_at, at(9, 0), 3, "Rolling");
      near(l.ended_at, at(15, 40), 3, "Delivered");
      near(sorted(l)[1].arrived_at, at(15, 40), 3, "delivery arrived");
      near(sorted(l)[0].arrived_at, at(8, 0), 3, "pickup arrived");
      about(l.total_mileage, 200);
      assert.equal(l.miles_source, "gps");
      const ev = await ChatTripEvent.findOne({ where: { chat_trip_id: leg.id, type: "time_correction", actor_role: "system" } });
      assert.match(String(ev?.note), /Times from the truck's GPS: .*Rolling .*Delivered .*dispatch ended at/);
      const detail = await getLoad(l.load_id!);
      assert(detail.history.some((h) => h.type === "time_correction" && /GPS/.test(String(h.note))), "in the load's History");
    });

    await test("Rolling tapped 9:05, dispatch ends late: Rolling kept, Delivered from GPS", async () => {
      TRAILS.zzv2 = TRAILS.zzv1;
      const leg = await sendAt({ loadNo: "ZZGPS-2", driverProfileId: b.id, truckNumber: "ZZGPS2", stops: [stop("pickup", "ZZGPICK"), stop("drop", "ZZGDROP")] }, at(7, 30));
      await act(leg.id, "accept", { role: "driver", id: b.id, name: b.username }, { at: at(7, 40).toISOString() } as any);
      await act(leg.id, "rolling", { role: "driver", id: b.id, name: b.username }, { at: at(9, 5).toISOString() } as any);
      const tapped = (await legOf(leg.id)).started_at;
      await endLegNow(leg.id, dispatcher, { at: at(19, 10), sendNext: false });
      await settle();
      const l = await legOf(leg.id);
      assert.equal(new Date(l.started_at!).getTime(), new Date(tapped!).getTime(), "driver's Rolling not changed");
      near(l.ended_at, at(15, 40), 3, "Delivered");
      about(l.total_mileage, (new Date(tapped!).getTime() - at(9, 0).getTime()) / 60_000 > 2 ? 200 - (new Date(tapped!).getTime() - at(9, 0).getTime()) / 120_000 : 200, 3);
    });

    await test("handover between two trucks, nobody tapped: leg 1 ends where truck A reached the meet point, leg 2 starts when truck B left it", async () => {
      TRAILS.zzv3a = trailOf([
        ["07:00", "08:00", 970, 1000],
        ["08:00", "09:00", 1000, 1000],
        ["09:00", "12:00", 1000, 1090],
        ["12:00", "13:30", 1090, 1090],
        ["13:30", "15:10", 1090, 1040],
        ["15:10", "16:00", 1040, 1040],
      ]);
      TRAILS.zzv3b = trailOf([
        ["10:00", "11:50", 1005, 1060],
        ["11:50", "12:50", 1060, 1090],
        ["12:50", "13:20", 1090, 1090],
        ["13:20", "18:20", 1090, 1240],
        ["18:20", "19:30", 1240, 1240],
      ]);
      // The meet point was typed as a place Google doesn't know
      const one = await sendAt({ loadNo: "ZZGPS-3", driverProfileId: a.id, truckNumber: "ZZGPS3A", stops: [stop("pickup", "ZZG3PICK"), stop("switch", "ZZG3NOWHERE", "ZZ MEET")] }, at(7, 30));
      await endLegNow(one.id, dispatcher, { at: at(14, 0), sendNext: false });
      const two = await sendAt({ loadNo: "ZZGPS-3", driverProfileId: b.id, truckNumber: "ZZGPS3B", stops: [stop("switch", "ZZG3NOWHERE", "ZZ MEET"), stop("drop", "ZZG3DROP")] }, at(11, 0), { endPrevious: true });
      assert.equal(two.load_id, one.load_id, "same Load # → leg 2");
      await endLegNow(two.id, dispatcher, { at: at(19, 25), sendNext: false });
      await settle();
      await addMileage(one.id, { forceGps: true }); // again now that leg 2 is there: where the trucks met
      const l1 = await legOf(one.id);
      const l2 = await legOf(two.id);
      near(l1.started_at, at(9, 0), 3, "leg 1 Rolling");
      near(l1.ended_at, at(12, 0), 3, "leg 1 ended at the meet point");
      near(l2.started_at, at(13, 20), 3, "leg 2 Rolling");
      near(l2.ended_at, at(18, 20), 3, "leg 2 delivered");
      about(l1.total_mileage, 90);
      about(l2.total_mileage, 150);
      const report = await milesReport({ by: "driver", from: at(0), to: at(23, 59), q: "ZZ TEST GPS" });
      const rowA = report.rows.find((r) => r.name === "ZZ TEST GPS A");
      const rowB = report.rows.find((r) => r.name === "ZZ TEST GPS B");
      assert(rowA && rowB, "both drivers in the Miles report");
      assert(rowA!.items.some((i) => i.loadId === one.load_id && Math.abs(Number(i.miles) - 90) <= 2.5), "A: 90 mi on this load");
      assert(rowB!.items.some((i) => i.loadId === one.load_id && Math.abs(Number(i.miles) - 150) <= 2.5), "B: 150 mi on this load");
      const byTruck = await milesReport({ by: "truck", from: at(0), to: at(23, 59), q: "ZZGPS3" });
      assert.deepEqual(byTruck.rows.map((r) => [r.name, Math.round(r.miles)]).sort(), [
        ["Truck ZZGPS3A", 90],
        ["Truck ZZGPS3B", 150],
      ]);
    });

    await test("same truck, driver swap, no meet address: leg 1 ends at the swap stop arrival, leg 2 starts when it leaves — no mile twice", async () => {
      TRAILS.zzv4 = trailOf([
        ["07:00", "08:00", 1970, 2000],
        ["08:00", "09:00", 2000, 2000],
        ["09:00", "12:20", 2000, 2100],
        ["12:20", "13:10", 2100, 2100],
        ["13:10", "18:10", 2100, 2250],
        ["18:10", "19:00", 2250, 2250],
      ]);
      const one = await sendAt({ loadNo: "ZZGPS-4", driverProfileId: a.id, truckNumber: "ZZGPS4", stops: [stop("pickup", "ZZG4PICK"), stop("switch", "ZZG4MEET", "ZZ SWAP")] }, at(7, 30));
      await endLegNow(one.id, dispatcher, { at: at(15, 0), sendNext: false });
      const two = await sendAt({ loadNo: "ZZGPS-4", driverProfileId: b.id, truckNumber: "ZZGPS4", stops: [stop("switch", "ZZG4MEET", "ZZ SWAP"), stop("drop", "ZZG4DROP")] }, at(12, 30), { endPrevious: true });
      await endLegNow(two.id, dispatcher, { at: at(18, 55), sendNext: false });
      await settle();
      const l1 = await legOf(one.id);
      const l2 = await legOf(two.id);
      near(l1.ended_at, at(12, 20), 3, "leg 1 ended");
      near(l2.started_at, at(13, 10), 3, "leg 2 Rolling");
      about(Number(l1.total_mileage) + Number(l2.total_mileage), 250, 3, "load total");
    });

    await test("no GPS (tracker offline): nothing guessed, the leg says so and counts as missing miles", async () => {
      const leg = await sendAt({ loadNo: "ZZGPS-5", driverProfileId: a.id, truckNumber: "ZZGPS1", stops: [stop("pickup", "ZZGPICK"), stop("drop", "ZZGDROP")] }, new Date(Date.now() - 3 * 3600_000));
      await endLegNow(leg.id, dispatcher, { sendNext: false });
      await settle();
      const l = await legOf(leg.id);
      assert.equal(l.started_at, null);
      assert.equal(l.total_mileage, null);
      assert.equal(l.miles_note, NO_GPS_NOTE);
      const detail = await getLoad(l.load_id!);
      assert.equal(detail.milesTotals.missing, 1);
    });

    await test("typed miles are never overwritten by GPS", async () => {
      await setMiles(leg1, 123, "odometer photo", dispatcher);
      await addMileage(leg1, { forceGps: true });
      const l = await legOf(leg1);
      assert.equal(Number(l.total_mileage), 123);
      assert.equal(l.miles_source, "manual");
    });
  } finally {
    const trips = await ChatTrip.findAll({ where: { driver_profile_id: people.map((p) => p.id) } });
    const ids = trips.map((t) => t.id);
    const loads = [...new Set([...loadIds, ...(trips.map((t) => t.load_id).filter(Boolean) as number[])])];
    if (ids.length) {
      await ChatTripEvent.destroy({ where: { chat_trip_id: ids } });
      await ChatTripStop.destroy({ where: { chat_trip_id: ids } });
      await ChatTrip.destroy({ where: { id: ids } });
    }
    if (loads.length) await ChatLoad.destroy({ where: { id: loads } });
    await Message.destroy({ where: { userProfileId: people.map((p) => p.id) } });
    await UserChannel.destroy({ where: { userProfileId: people.map((p) => p.id) } });
    for (const p of people) await p.destroy();
    for (const u of users) await u.destroy();
    for (const id of yardDrivers) await secondarySequelize.query(`DELETE FROM drivers WHERE id = :id`, { replacements: { id } });
    for (const id of yardTrucks) await secondarySequelize.query(`DELETE FROM trucks WHERE id = :id`, { replacements: { id } });
    (globalThis as any).fetch = realFetch;
  }
  console.log(results.join("\n"));
  process.exit(results.some((r) => r.startsWith("FAIL")) ? 1 : 0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
