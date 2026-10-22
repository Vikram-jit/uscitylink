import { UserProfile } from "../models/UserProfile";

// Remember the build each login last reported, so Admin → App versions can show who has what
// installed. The update check itself only saved it for builds marked active, which left everyone on
// an older build showing the version they had before. Never throws: this is bookkeeping only.
export async function recordInstalledVersion(profileId: string | undefined, version: unknown, buildNumber: unknown): Promise<void> {
  try {
    const v = typeof version === "string" ? version.trim() : "";
    const b = buildNumber === null || buildNumber === undefined ? "" : String(buildNumber).trim();
    if (!profileId || !v || !b) return;
    await UserProfile.update({ version: v, buildNumber: b }, { where: { id: profileId } });
  } catch (err) {
    console.log("recordInstalledVersion", err);
  }
}
