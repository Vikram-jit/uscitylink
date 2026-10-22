import { Request, Response } from "express";
import { AppVersions } from "../models/AppVersions";
import { UserProfile } from "../models/UserProfile";
import { recordInstalledVersion } from "./appInstalls";

export type UpdateStatus = "UpToDate" | "UpdateAvailable" | "ForceUpdate";

type Build = { version: string; buildNumber: number | string };

// 1.3.22+1 vs 1.3.21+24: version first (part by part), then the build number. iOS restarts the
// build number for every version, so the build only matters between equal versions.
export function compareBuilds(a: Build, b: Build): number {
  const pa = String(a.version).split(".").map((n) => Number(n) || 0);
  const pb = String(b.version).split(".").map((n) => Number(n) || 0);
  for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
    const d = (pa[i] || 0) - (pb[i] || 0);
    if (d) return d;
  }
  return (Number(a.buildNumber) || 0) - (Number(b.buildNumber) || 0);
}

export type UpdatePolicy = {
  status: UpdateStatus;
  latest: { version: string; buildNumber: number; releaseNotes: string | null } | null;
  required: { version: string; buildNumber: number } | null; // the newest forced build, if any
};

// Only Active rows of the platform count. A forced Active row makes every older build update.
export function evaluateUpdate(rows: AppVersions[], installed: Build): UpdatePolicy {
  const active = rows.filter((r) => r.status === "active" && r.version && r.buildNumber != null);
  const newestFirst = [...active].sort((a, b) => compareBuilds(b as Build, a as Build));
  const latest = newestFirst[0];
  const required = newestFirst.find((r) => r.force_update);

  let status: UpdateStatus = "UpToDate";
  if (required && compareBuilds(installed, required as Build) < 0) status = "ForceUpdate";
  else if (latest && compareBuilds(installed, latest as Build) < 0) status = "UpdateAvailable";

  return {
    status,
    latest: latest ? { version: latest.version!, buildNumber: Number(latest.buildNumber), releaseNotes: latest.releaseNotes || null } : null,
    required: required ? { version: required.version!, buildNumber: Number(required.buildNumber) } : null,
  };
}

// PUT /api/v2/auth/updateAppVersion — the new app's version check. v1 keeps the old answer
// ("NewVersion"/"UpToDate"/...) for the builds already in the stores.
export async function updateAppVersionV2(req: Request, res: Response): Promise<any> {
  try {
    const { version, buildNumber, platform } = req.body || {};
    if (!version || buildNumber === undefined || buildNumber === null || !platform) {
      throw new Error("version, buildNumber and platform are required");
    }
    const rows = await AppVersions.findAll({ where: { platform: String(platform).toLowerCase() } });
    const policy = evaluateUpdate(rows, { version: String(version), buildNumber });

    await recordInstalledVersion(req.user?.id, version, buildNumber);
    // Keeps Admin → App versions "Logins needing an update" meaningful
    await UserProfile.update(
      { appUpdate: policy.status === "UpToDate" ? "1" : "0" },
      { where: { id: req.user?.id } }
    );

    return res.status(200).json({ status: true, message: "Version checked", data: policy });
  } catch (err: any) {
    return res.status(400).json({ status: false, message: err.message || "Version check failed" });
  }
}
