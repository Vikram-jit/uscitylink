// Run: npx ts-node -T scripts/calls/callAccess.check.ts
// Who may place calls, against the LOCAL databases (refuses anything else): calling is per driver (off by
// default; staff switch it on), staff can always call, the admin's global switch is the master, a driver
// without the flag is refused by call:invite, the toggle endpoint is staff-only / drivers-only and tells
// the driver's open app (calls:config). Throwaway drivers; removes everything it created and restores the
// global switch.
import "dotenv/config";
import assert from "assert";
import http from "http";
import { QueryTypes } from "sequelize";
import { primarySequelize, secondarySequelize } from "../../src/sequelize";
import { initSocket, getSocketInstance } from "../../src/sockets/socket";
import { UserProfile } from "../../src/models/UserProfile";
import User from "../../src/models/User";
import Role from "../../src/models/Role";
import Channel from "../../src/models/Channel";
import UserChannel from "../../src/models/UserChannel";
import GroupUser from "../../src/models/GroupUser";
import { isCallsEnabled, setCallsEnabled } from "../../src/services/documentAi/settings";
import { callingFor, inviteBlocked, setDriverCallingFlag } from "../../src/calls/callAccess";
import { callConfig, setDriverCalling } from "../../src/calls/callController";

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

/** A fake express response that keeps what the handler sent */
const fakeRes = () => {
  const r: any = { code: 200, body: null };
  r.status = (c: number) => ((r.code = c), r);
  r.json = (b: any) => ((r.body = b), r);
  return r;
};
const TAG = `${Date.now() % 100000}`;

(async () => {
  initSocket(http.createServer());
  const io: any = getSocketInstance();
  const driverRole = await Role.findOne({ where: { name: "driver" } });
  const staffRole = await Role.findOne({ where: { name: "staff" } });
  const yardIds: number[] = [];
  const users: User[] = [];
  const people: UserProfile[] = [];
  for (const n of ["A", "B"]) {
    const [yardId] = await secondarySequelize.query(`INSERT INTO drivers (name, created_at, updated_at) VALUES (:n, NOW(), NOW())`, { replacements: { n: `ZZ CALLFLAG ${n}` }, type: QueryTypes.INSERT });
    yardIds.push(Number(yardId));
    const user = await User.create({ driver_number: `zzcf${n}${TAG}`, status: "active", yard_id: Number(yardId) } as any);
    users.push(user);
    people.push(await UserProfile.create({ userId: user.id, role_id: driverRole!.id, username: `ZZ CallFlag Driver ${n}`, device_token: null } as any));
  }
  const [a, b] = people;
  const staff = await UserProfile.findOne({ where: { role_id: staffRole!.id } });
  const originalGlobal = await isCallsEnabled();

  // What the socket server was told
  const sent: { room: string; event: string; payload: any }[] = [];
  const realTo = io.to.bind(io);

  try {
    io.to = (room: string) => ({ emit: (event: string, payload: any) => void sent.push({ room, event, payload }) });
    await setCallsEnabled(true);

    await test("a new driver has calling OFF; staff turn it on for one driver only", async () => {
      assert.equal(!!(await User.findByPk(users[0].id))!.calls_enabled, false, "off by default");
      assert.equal((await callingFor(a.id)).enabled, false);
      const done = await setDriverCallingFlag(a.id, true);
      assert.equal(done.ok, true);
      assert.equal((await callingFor(a.id)).enabled, true, "A has it");
      assert.equal((await callingFor(b.id)).enabled, false, "B does not");
    });

    await test("staff can always call (no flag needed); only the global switch can stop them", async () => {
      const s = await callingFor(staff!.id);
      assert.equal(s.enabled, true);
      assert.equal(s.staff, true);
      assert.equal(await inviteBlocked(staff!.id), null, "staff may start a call");
    });

    await test("call:invite rule: a driver without the flag is refused, with it is allowed", async () => {
      assert.match(String(await inviteBlocked(b.id)), /isn't turned on for your account/);
      assert.equal(await inviteBlocked(a.id), null);
    });

    await test("the admin's global switch is the master: off = nobody can start a call, flag or not", async () => {
      await setCallsEnabled(false);
      assert.equal((await callingFor(a.id)).enabled, false, "flagged driver");
      assert.equal((await callingFor(staff!.id)).enabled, false, "staff");
      assert.equal(await inviteBlocked(a.id), "Calling is turned off");
      assert.equal(await inviteBlocked(staff!.id), "Calling is turned off");
      await setCallsEnabled(true);
    });

    await test("GET /calls/config answers per person: flagged driver true, unflagged false, staff true", async () => {
      const cfg = async (id: string) => {
        const res = fakeRes();
        await callConfig({ user: { id } } as any, res);
        return res.body.data.enabled;
      };
      assert.equal(await cfg(a.id), true);
      assert.equal(await cfg(b.id), false);
      assert.equal(await cfg(staff!.id), true);
    });

    await test("PUT /calls/drivers/:id switches the flag, tells that driver's open app (calls:config), refuses non-drivers", async () => {
      sent.length = 0;
      const res = fakeRes();
      await setDriverCalling({ user: { id: staff!.id }, params: { profileId: b.id }, body: { enabled: true } } as any, res);
      assert.equal(res.code, 200);
      assert.equal(res.body.data.enabled, true);
      assert.equal(!!(await User.findByPk(users[1].id))!.calls_enabled, true);
      assert.deepEqual(sent.find((e) => e.event === "calls:config"), { room: `user:${b.id}`, event: "calls:config", payload: { enabled: true } });
      // …and off again
      sent.length = 0;
      const off = fakeRes();
      await setDriverCalling({ user: { id: staff!.id }, params: { profileId: b.id }, body: { enabled: false } } as any, off);
      assert.equal(!!(await User.findByPk(users[1].id))!.calls_enabled, false);
      assert.equal(sent.find((e) => e.event === "calls:config")!.payload.enabled, false);
      // A staff profile / unknown id: refused
      const notDriver = fakeRes();
      await setDriverCalling({ user: { id: staff!.id }, params: { profileId: staff!.id }, body: { enabled: true } } as any, notDriver);
      assert.equal(notDriver.code, 400);
      const unknown = fakeRes();
      await setDriverCalling({ user: { id: staff!.id }, params: { profileId: "00000000-0000-0000-0000-000000000000" }, body: { enabled: true } } as any, unknown);
      assert.equal(unknown.code, 404);
    });

    await test("with the global switch off the driver is told enabled:false even though staff gave them the flag", async () => {
      await setCallsEnabled(false);
      sent.length = 0;
      const res = fakeRes();
      await setDriverCalling({ user: { id: staff!.id }, params: { profileId: a.id }, body: { enabled: true } } as any, res);
      assert.equal(res.body.data.effective, false);
      assert.equal(sent.find((e) => e.event === "calls:config")!.payload.enabled, false);
      await setCallsEnabled(true);
    });
  } finally {
    io.to = realTo;
    await setCallsEnabled(originalGlobal);
    const pids = people.map((p) => p.id);
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
