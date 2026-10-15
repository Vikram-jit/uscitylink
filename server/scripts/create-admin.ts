// Run: npx ts-node scripts/create-admin.ts [email] [password] [name]
// Creates (or upgrades) an admin web login. Safe to run repeatedly.
import { primarySequelize } from "../src/sequelize";
import User from "../src/models/User";
import { UserProfile } from "../src/models/UserProfile";
import Role from "../src/models/Role";
import { randomUUID } from "crypto";
import { hashPassword } from "../src/utils/passwordCrypto";

const main = async () => {
  const email = process.argv[2] || "admin@uscitylink.local";
  const password = process.argv[3] || "Admin@12345";
  const name = process.argv[4] || "Admin";

  // The seed migration normally creates this; create it here if running without it
  // (roles.id is a UUID with no database default, so supply one)
  const [role] = await Role.findOrCreate({
    where: { name: "admin" },
    defaults: { id: randomUUID(), name: "admin" } as any,
  });

  const [user] = await User.findOrCreate({
    where: { email },
    defaults: { email, user_type: "staff", status: "active" } as any,
  });
  await user.update({ status: "active", user_type: user.user_type || "staff" });

  const hashed = await hashPassword(password);
  const existing = await UserProfile.findOne({ where: { userId: user.id, role_id: role.id } });
  if (existing) {
    await existing.update({ password: hashed, status: "active" });
  } else {
    await UserProfile.create({
      userId: user.id,
      username: name,
      password: hashed,
      role_id: String(role.id),
      isOnline: false,
      status: "active",
    } as any);
  }

  console.log(`✅ Admin ready\n   email:    ${email}\n   password: ${password}`);
  await primarySequelize.close();
};

main().catch((err) => {
  console.error("❌", err.message || err);
  process.exit(1);
});
