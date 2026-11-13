// Run: npx ts-node -T scripts/trips/repair.check.ts
// Add to loads / Repair against the LOCAL databases (refuses anything else): an old assistant "TRIP #…"
// message with a load whose single address was guessed as a pickup is previewed, then repaired (stop type
// in place, details, the assistant message replaced — in a truck chat for every copy), dispatch's own text
// is never rewritten, closed legs are refused, and the Missed loads list finds skipped / fixable ones.
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
import { addLoad } from "../../src/services/trips/loadService";
import { forgetMissed, missedLoads, repairApply, repairPreview } from "../../src/services/trips/messageRepair";

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
const NO = `ZZ${TAG}R`;
/** One address, no PICK / DROP labels, with truck / team / trailer / temp */
const TEXT = (no: string) => `YOUR LONG FOR TOMORROW MORNING.\n\nTRUCK # ZZTRUCK${TAG}\n\nTEAM # ZZ TruckGrp Driver A + ZZ TruckGrp Driver B\n\nTRAILER # ZZ107065\n\nTEMP # 34 CONT.\n\nORDER # ${no}\n\nZZ FreshPoint Atlanta\n1200 Oakley Industrial Blvd B\nFAIRBURN, GA 30213\n11/16/2026 06:00AM`;
/** The assistant message as the old code wrote it */
const OLD_ASSISTANT = (no: string) => `TRIP #${no}\nTRUCK # ZZTRUCK${TAG}\nTRAILER # WILL ADVISE\n\nPICKUP\nZZ FreshPoint Atlanta\n1200 Oakley Industrial Blvd B\nFAIRBURN, GA 30213 11/16/2026 06:00AM`;

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
      replacements: { n: `ZZ TruckGrp Driver ${n}` },
      type: QueryTypes.INSERT,
    });
    yardIds.push(Number(yardId));
    const user = await User.create({ driver_number: `zzrp${n}${TAG}`, status: "active", yard_id: Number(yardId) } as any);
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
  const dispatcher = { role: "dispatcher" as const, id: staff!.id, name: staff!.username };
  const loadIds = new Set<number>();
  /** A chat line from dispatch (or the assistant when automated). Created automated so the load hook leaves it alone — a message that was never turned into a load. */
  const say = async (body: string, automated = false) => {
    const m = await Message.create({ channelId, userProfileId: a.id, senderId: staff!.id, body, messageDirection: "S", deliveryStatus: "sent", status: "sent", messageTimestampUtc: new Date(), is_automated: true } as any);
    if (!automated) await m.update({ is_automated: false });
    return m;
  };

  /** The old world: a load whose single address was guessed as a pickup + the assistant's old message */
  const oldLoad = async (no: string, extra: { groupCopies?: boolean } = {}) => {
    const typed = await say(TEXT(no)); // dispatch's own text (hook skipped: is_automated)
    const res = await addLoad(
      { loadNo: no, driverProfileId: a.id, channelId, truckNumber: `ZZTRUCK${TAG}`, trailerNumbers: ["WILL ADVISE"], temperature: null, stops: [{ type: "pickup", name: "ZZ FreshPoint Atlanta", street: "1200 Oakley Industrial Blvd B", city: "FAIRBURN", state: "GA", zip: "30213", appointment: "2026-11-16T06:00" }], rawText: TEXT(no), needsReview: true, reviewNotes: ["Only one address — check whether it is the pickup or the delivery"] },
      dispatcher,
      { send: false, fromChat: true }
    );
    loadIds.add(res.load.id);
    const legRow = res.legs[0];
    // sent the old way: the assistant's message, linked
    let assistant: Message;
    if (extra.groupCopies) {
      const at = new Date();
      assistant = await Message.create({ channelId, groupId: group.id, userProfileId: staff!.id, senderId: staff!.id, body: OLD_ASSISTANT(no), messageDirection: "S", deliveryStatus: "sent", status: "sent", messageTimestampUtc: at, type: "default", is_automated: true } as any);
      for (const p of people) await Message.create({ channelId, groupId: group.id, userProfileId: p.id, senderId: staff!.id, body: OLD_ASSISTANT(no), messageDirection: "S", deliveryStatus: "sent", status: "sent", messageTimestampUtc: at, type: "truck_group", is_automated: true } as any);
      await GroupMessage.create({ groupId: group.id, body: OLD_ASSISTANT(no), senderId: staff!.id, deliveryStatus: "sent", messageTimestampUtc: at, url_upload_type: "server" } as any);
    } else {
      assistant = await say(OLD_ASSISTANT(no), true);
    }
    await ChatTrip.update({ status: "planned", sent_at: new Date(), message_id: assistant.id }, { where: { id: legRow.id } });
    return { typed, assistant, legId: legRow.id, loadId: res.load.id };
  };

  try {
    await test("preview: an old 'TRIP #…' message + a load with the one address guessed as a pickup → what would change, and the replacement text", async () => {
      const o = await oldLoad(NO);
      const pv = await repairPreview(o.assistant.id);
      assert.equal(pv.mode, "repair");
      assert(pv.canApply);
      const labels = pv.changes.map((c) => `${c.label}|${c.before}→${c.after}`).join("\n");
      assert(/Pickup→Drop/.test(labels), `stop type: ${labels}`);
      assert(/Temperature\|—→34 CONT\./.test(labels), "temperature");
      assert(/Trailer\|WILL ADVISE→ZZ107065/.test(labels), "trailer");
      assert(pv.message, "the assistant's message would be replaced");
      assert.equal(pv.message!.before, OLD_ASSISTANT(NO));
      assert(/^LOAD # /.test(pv.message!.after) && /^DROP$/m.test(pv.message!.after) && !/PICKUP/.test(pv.message!.after), pv.message!.after);
      assert(/TEMP # 34 CONT\./.test(pv.message!.after));
      // nothing changed by previewing
      assert.equal((await Message.findByPk(o.assistant.id))!.body, OLD_ASSISTANT(NO));
      assert.equal((await ChatTripStop.findOne({ where: { chat_trip_id: o.legId } }))!.type, "pickup");
      // asking from dispatch's own message gives the same load
      assert.equal((await repairPreview(o.typed.id)).load?.legId, o.legId);
    });

    await test("apply: stop type changed in place (arrival time kept), details fixed, the assistant message replaced, dispatch's own text untouched, event recorded; again → nothing to repair", async () => {
      const o = await oldLoad(`${NO}2`);
      const arrived = new Date("2026-11-16T10:00:00Z");
      await ChatTripStop.update({ arrived_at: arrived }, { where: { chat_trip_id: o.legId } });
      const out = await repairApply(o.assistant.id, dispatcher);
      assert.equal(out.replaced, true);
      const stop = (await ChatTripStop.findOne({ where: { chat_trip_id: o.legId } }))!;
      assert.equal(stop.type, "drop");
      assert.equal(new Date(stop.arrived_at!).getTime(), arrived.getTime(), "arrival time survived");
      const trip = (await ChatTrip.findByPk(o.legId))!;
      assert.equal(trip.temperature, "34 CONT.");
      assert.equal(trip.trailer_numbers, "ZZ107065");
      assert.equal(trip.needs_review, false, "nothing left to check");
      const asst = (await Message.findByPk(o.assistant.id))!;
      assert(/^LOAD # /.test(asst.body) && /^DROP$/m.test(asst.body), "message replaced");
      assert.equal((await Message.findByPk(o.typed.id))!.body, TEXT(`${NO}2`), "dispatch's own text is never rewritten");
      const ev = await ChatTripEvent.findOne({ where: { chat_trip_id: o.legId, type: "repair" } });
      assert(ev && /Pickup → Drop/.test(String(ev.note)), "recorded in History");
      assert.equal((await repairPreview(o.assistant.id)).mode, "ok", "nothing more to repair");
    });

    await test("a closed load can't be repaired from the chat", async () => {
      const o = await oldLoad(`${NO}3`);
      await ChatTrip.update({ status: "completed" }, { where: { id: o.legId } });
      const pv = await repairPreview(o.assistant.id);
      assert.equal(pv.canApply, false);
      assert(pv.why);
      await assert.rejects(repairApply(o.assistant.id, dispatcher), /completed|closed/);
      assert.equal((await ChatTripStop.findOne({ where: { chat_trip_id: o.legId } }))!.type, "pickup", "untouched");
    });

    await test("in a truck chat the replacement reaches the staff copy, every member's copy and the group message", async () => {
      const o = await oldLoad(`${NO}4`, { groupCopies: true });
      await repairApply(o.assistant.id, dispatcher);
      const rows = await Message.findAll({ where: { groupId: group.id, body: { [Op.like]: `LOAD # ${NO}4%` } } });
      assert.equal(rows.filter((r) => r.type === "default").length, 1, "staff copy");
      assert.equal(rows.filter((r) => r.type === "truck_group").length, 2, "both members' copies");
      assert.equal(await Message.count({ where: { groupId: group.id, body: OLD_ASSISTANT(`${NO}4`) } }), 0, "no old copy left");
      assert.equal(await GroupMessage.count({ where: { groupId: group.id, body: { [Op.like]: `LOAD # ${NO}4%` } } }), 1, "group message too");
    });

    await test("a message with no load: preview says add; apply adds it (drop, nothing sent); a message with no address is a plan", async () => {
      const text = TEXT(`${NO}5`);
      const skipped = await say(text);
      const pv = await repairPreview(skipped.id);
      assert.equal(pv.mode, "add");
      assert.equal(pv.loadNo, `${NO}5`);
      assert.equal(pv.plan, false);
      const chatBefore = await Message.count({ where: { userProfileId: a.id } });
      const out = await repairApply(skipped.id, dispatcher);
      loadIds.add(out.data.load.id);
      const stops = out.data.legs[0].stops;
      assert.equal(stops.length, 1);
      assert.equal(stops[0].type, "drop", "the one address is the drop");
      assert.equal(out.data.legs[0].sent_at, null, "not sent");
      assert.equal(await Message.count({ where: { userProfileId: a.id } }), chatBefore, "nothing posted to the driver");
      const noAddr = await say(`ORDER # ${NO}6\nTRUCK # 1\nTEMP # 36`);
      const pv2 = await repairPreview(noAddr.id);
      assert.equal(pv2.mode, "add");
      assert.equal(pv2.plan, true);
    });

    await test("Missed loads: lists a skipped load text and a fixable load; not one already in Loads", async () => {
      const skippedNo = `${NO}7`;
      const skipped = await say(TEXT(skippedNo));
      const fixable = await oldLoad(`${NO}8`);
      const fine = await oldLoad(`${NO}9`);
      await repairApply(fine.assistant.id, dispatcher); // already repaired → ok
      forgetMissed();
      const list = await missedLoads(14);
      const mine = (id: string) => list.find((l) => l.messageId === id);
      assert.equal(mine(skipped.id)?.kind, "missing");
      assert.equal(mine(skipped.id)?.loadNo, skippedNo);
      assert.equal(mine(fixable.assistant.id)?.kind, "fixable", "fixable is listed by its assistant message");
      assert(mine(fixable.assistant.id)!.changes.some((c) => /Pickup → Drop/.test(c)));
      assert(!mine(fine.assistant.id) && !mine(fine.typed.id), "a repaired load is not listed");
      // once added, it leaves the list
      const out = await repairApply(skipped.id, dispatcher);
      loadIds.add(out.data.load.id);
      assert(!(await missedLoads(14)).some((l) => l.messageId === skipped.id), "added → gone from the list");
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
    await Group.update({ last_message_id: null as any }, { where: { id: group.id } });
    await Message.destroy({ where: { [Op.or]: [{ groupId: group.id }, { userProfileId: pids }, { body: { [Op.like]: `%${NO}%` } }] } });
    await GroupMessage.destroy({ where: { groupId: group.id } });
    await GroupUser.destroy({ where: { groupId: group.id } });
    await Group.destroy({ where: { id: group.id } });
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
