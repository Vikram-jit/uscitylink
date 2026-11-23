// npm run migrate — runs the pending sequelize migrations against the SAME database the API uses
// (DB_PRIMARY_* in server/.env, see src/sequelize.ts), not config/config.json, whose entries can be stale.
// Extra arguments go to sequelize-cli, e.g. `npm run migrate -- db:migrate:status`.
require("dotenv").config();
const { spawnSync } = require("child_process");

const need = ["DB_PRIMARY_HOST", "DB_PRIMARY_NAME", "DB_PRIMARY_USER"];
const missing = need.filter((k) => !process.env[k]);
if (missing.length) {
  console.error(`migrate: missing ${missing.join(", ")} in server/.env`);
  process.exit(1);
}

const e = encodeURIComponent;
const port = process.env.DB_PRIMARY_PORT || "3306";
const url = `mysql://${e(process.env.DB_PRIMARY_USER)}:${e(process.env.DB_PRIMARY_PASSWORD || "")}@${process.env.DB_PRIMARY_HOST}:${port}/${e(process.env.DB_PRIMARY_NAME)}`;

const args = process.argv.slice(2);
const command = args.length ? args : ["db:migrate"];
console.log(`migrate: ${command.join(" ")} on ${process.env.DB_PRIMARY_HOST}/${process.env.DB_PRIMARY_NAME}`);

const r = spawnSync("npx", ["sequelize-cli", ...command, "--url", url], { stdio: "inherit" });
process.exit(r.status ?? 1);
