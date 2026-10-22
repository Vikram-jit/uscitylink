import { Request, Response } from "express";
import { Op, fn, col, literal, WhereOptions } from "sequelize";
import { AppVersions } from "../models/AppVersions";
import { UserProfile } from "../models/UserProfile";
import User from "../models/User";
import Role from "../models/Role";

// The app reports its version + build + platform (auth/updateAppVersion and the UPDATE_APP_VERSION
// socket event). Only an exact match with an "active" row counts as up to date, so several rows can
// be active at once while a new build rolls out.
export const PLATFORMS = ["android", "ios"];
export const STATUSES = ["pending", "active", "deprecated"];

type Body = { version?: string; buildNumber?: string | number; platform?: string; status?: string; releaseNotes?: string | null };

function validate(body: Body): { version: string; buildNumber: number; platform: string; status: string; releaseNotes: string | null } {
  const version = String(body.version ?? "").trim();
  const buildNumber = Number(body.buildNumber);
  const platform = String(body.platform ?? "").trim().toLowerCase();
  const status = String(body.status ?? "pending").trim().toLowerCase();
  if (!/^\d+(\.\d+){1,3}$/.test(version)) throw new Error("Version must look like 1.3.21");
  if (!Number.isInteger(buildNumber) || buildNumber < 1) throw new Error("Build number must be a whole number (the part after + in 1.3.21+24)");
  if (!PLATFORMS.includes(platform)) throw new Error("Platform must be android or ios");
  if (!STATUSES.includes(status)) throw new Error("Status must be pending, active or deprecated");
  const releaseNotes = body.releaseNotes ? String(body.releaseNotes).trim() : null;
  return { version, buildNumber, platform, status, releaseNotes };
}

async function ensureUnique(v: { version: string; buildNumber: number; platform: string }, exceptId?: string) {
  const clash = await AppVersions.findOne({
    where: {
      version: v.version,
      buildNumber: v.buildNumber,
      platform: v.platform,
      ...(exceptId ? { id: { [Op.ne]: exceptId } } : {}),
    },
  });
  if (clash) throw new Error(`${v.platform} ${v.version}+${v.buildNumber} already exists`);
}

export async function listAppVersions(req: Request, res: Response): Promise<any> {
  try {
    const rows = await AppVersions.findAll({ order: [["createdAt", "DESC"]] });

    // How many logins last reported each version (profiles don't store the platform)
    const counts = (await UserProfile.findAll({
      attributes: ["version", "buildNumber", "platform", [fn("COUNT", col("id")), "users"]],
      where: { version: { [Op.ne]: null } },
      group: ["version", "buildNumber", "platform"],
      raw: true,
    })) as unknown as { version: string; buildNumber: string; platform: string | null; users: number }[];
    // Same version + build on the same platform, or where the login's platform isn't known
    const usersFor = (v: string, b: string | number, p?: string) =>
      counts
        .filter((c) => c.version === v && String(c.buildNumber) === String(b) && (!c.platform || c.platform === p))
        .reduce((sum, c) => sum + Number(c.users), 0);

    const updatePending = await UserProfile.count({ where: { appUpdate: "0" } });

    return res.status(200).json({
      status: true,
      message: "App versions",
      data: {
        versions: rows.map((r) => ({ ...r.toJSON(), users: usersFor(r.version!, r.buildNumber!, r.platform) })),
        updatePending,
      },
    });
  } catch (err: any) {
    return res.status(500).json({ status: false, message: err.message || "Internal Server Error" });
  }
}

export async function createAppVersion(req: Request, res: Response): Promise<any> {
  try {
    const data = validate(req.body);
    await ensureUnique(data);
    const row = await AppVersions.create(data);
    return res.status(201).json({ status: true, message: "Version added", data: row });
  } catch (err: any) {
    return res.status(400).json({ status: false, message: err.message || "Could not add version" });
  }
}

export async function updateAppVersionRow(req: Request, res: Response): Promise<any> {
  try {
    const row = await AppVersions.findByPk(req.params.id);
    if (!row) return res.status(404).json({ status: false, message: "Version not found" });
    const data = validate({ ...row.toJSON(), ...req.body });
    await ensureUnique(data, row.id);
    await row.update(data);
    return res.status(200).json({ status: true, message: "Version updated", data: row });
  } catch (err: any) {
    return res.status(400).json({ status: false, message: err.message || "Could not update version" });
  }
}

export async function deleteAppVersion(req: Request, res: Response): Promise<any> {
  try {
    const row = await AppVersions.findByPk(req.params.id);
    if (!row) return res.status(404).json({ status: false, message: "Version not found" });
    // Deleting a live version would quietly mark everyone on it as out of date
    if (row.status === "active") throw new Error("Deprecate this version before deleting it");
    await row.destroy();
    return res.status(200).json({ status: true, message: "Version deleted", data: null });
  } catch (err: any) {
    return res.status(400).json({ status: false, message: err.message || "Could not delete version" });
  }
}

// ---- Installs: what each login last reported (user_profiles.version / buildNumber / platform) ----

// One row per installed version + build, newest first, with the platforms and the matching status
export async function listInstalls(req: Request, res: Response): Promise<any> {
  try {
    const groups = (await UserProfile.findAll({
      attributes: [
        "version",
        "buildNumber",
        "platform",
        [fn("COUNT", col("UserProfile.id")), "users"],
        [fn("SUM", literal("CASE WHEN isOnline = 1 THEN 1 ELSE 0 END")), "online"],
        [fn("MAX", col("last_login")), "lastSeen"],
      ],
      group: ["version", "buildNumber", "platform"],
      raw: true,
    })) as unknown as { version: string | null; buildNumber: string | null; platform: string | null; users: number; online: number; lastSeen: string | null }[];

    const versions = await AppVersions.findAll({ raw: true });
    const statusOf = (v: string, b: string, p: string | null) => {
      const same = versions.filter((x) => x.version === v && String(x.buildNumber) === String(b));
      const row = same.find((x) => x.platform === p) || (p ? undefined : same[0]);
      return row?.status || null; // null = this build was never added on the App versions page
    };

    const byVersion = new Map<string, any>();
    let notReported = 0;
    for (const g of groups) {
      if (!g.version || !g.buildNumber) {
        notReported += Number(g.users);
        continue;
      }
      const key = `${g.version}+${g.buildNumber}`;
      const item =
        byVersion.get(key) ||
        { version: g.version, buildNumber: g.buildNumber, users: 0, online: 0, lastSeen: null, platforms: [] as any[] };
      item.users += Number(g.users);
      item.online += Number(g.online || 0);
      if (g.lastSeen && (!item.lastSeen || g.lastSeen > item.lastSeen)) item.lastSeen = g.lastSeen;
      item.platforms.push({ platform: g.platform || null, users: Number(g.users), status: statusOf(g.version, g.buildNumber, g.platform) });
      byVersion.set(key, item);
    }

    const cmp = (a: any, b: any) => {
      const pa = a.version.split(".").map(Number);
      const pb = b.version.split(".").map(Number);
      for (let i = 0; i < Math.max(pa.length, pb.length); i++) if ((pb[i] || 0) !== (pa[i] || 0)) return (pb[i] || 0) - (pa[i] || 0);
      return Number(b.buildNumber) - Number(a.buildNumber);
    };

    return res.status(200).json({
      status: true,
      message: "Installed versions",
      data: { installs: [...byVersion.values()].sort(cmp), notReported },
    });
  } catch (err: any) {
    return res.status(500).json({ status: false, message: err.message || "Internal Server Error" });
  }
}

// Logins on one version + build (or with none reported), searchable and paged
export async function listInstallUsers(req: Request, res: Response): Promise<any> {
  try {
    const version = String(req.query.version || "");
    const buildNumber = String(req.query.buildNumber || "");
    const platform = String(req.query.platform || "");
    const search = String(req.query.search || "").trim();
    const page = Math.max(1, Number(req.query.page) || 1);
    const pageSize = Math.min(100, Math.max(1, Number(req.query.pageSize) || 25));

    const where: any = version ? { version, buildNumber } : { [Op.or]: [{ version: null }, { buildNumber: null }] };
    if (platform === "unknown") where.platform = null;
    // withUnknown: also logins with no platform recorded (matches the count on the versions table)
    else if (platform) where.platform = req.query.withUnknown ? { [Op.or]: [platform, null] } : platform;
    if (search) {
      const like = { [Op.like]: `%${search}%` };
      where[Op.and] = [
        {
          [Op.or]: [
            { username: like },
            { "$user.email$": like },
            { "$user.phone_number$": like },
            { "$user.driver_number$": like },
          ],
        },
      ];
    }

    const { rows, count } = await UserProfile.findAndCountAll({
      where: where as WhereOptions,
      attributes: ["id", "username", "platform", "version", "buildNumber", "appUpdate", "isOnline", "last_login", "status"],
      include: [
        { model: User, as: "user", attributes: ["email", "phone_number", "driver_number"] },
        { model: Role, as: "role", attributes: ["name"] },
      ],
      order: [["last_login", "DESC"]],
      limit: pageSize,
      offset: (page - 1) * pageSize,
      subQuery: false,
    });

    return res.status(200).json({
      status: true,
      message: "Users",
      data: { users: rows, total: count, page, pageSize },
    });
  } catch (err: any) {
    return res.status(500).json({ status: false, message: err.message || "Internal Server Error" });
  }
}
