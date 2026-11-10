// Run: npx ts-node -T scripts/trips/assignments.check.ts
// The truck pickers' lookups against the LOCAL database (read-only): trucks with their assigned
// drivers, and a driver's truck with their team mate.
import "dotenv/config";
import assert from "assert";
import User from "../../src/models/User";
import { UserProfile } from "../../src/models/UserProfile";
import Role from "../../src/models/Role";
import UserChannel from "../../src/models/UserChannel";
import Channel from "../../src/models/Channel";
import Group from "../../src/models/Group";
import GroupUser from "../../src/models/GroupUser";
import GroupChannel from "../../src/models/GroupChannel";
import { MessageStaff } from "../../src/models/MessageStaff";
import { assignmentOfDriver, truckAssignments } from "../../src/services/trips/tripService";

const local = (h?: string) => !h || /^(localhost|127\.0\.0\.1)$/.test(h);
if (!local(process.env.DB_PRIMARY_HOST)) {
  console.error("Refusing to run: the database in .env is not local");
  process.exit(2);
}
User.associate({ UserProfile });
UserProfile.associate({ User, Role, UserChannel, Channel, GroupUser, MessageStaff });
Role.associate({ UserProfile });
Group.associate({ GroupChannel, GroupUser });
GroupUser.associate({ UserProfile, Group });

(async () => {
  const all = await truckAssignments("");
  assert(all.length > 0, "no truck groups");
  const team = all.find((t) => t.drivers.length >= 2);
  assert(team, "no truck with two drivers");
  const one = await truckAssignments(team.truck);
  assert(one.some((t) => t.truck === team.truck), "search by number");
  const back = await assignmentOfDriver(team.drivers[0].id);
  assert.equal(back?.truck, team.truck);
  assert(back?.drivers.some((d) => d.id === team.drivers[1].id), "team mate included");
  console.log(`ok   ${all.length} trucks; truck ${team.truck} → ${team.drivers.length} drivers; driver → truck ${back?.truck}`);
  process.exit(0);
})().catch((e) => {
  console.log(`FAIL ${e.message}`);
  process.exit(1);
});
