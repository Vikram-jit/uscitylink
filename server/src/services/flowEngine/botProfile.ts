import { UserProfile } from "../../models/UserProfile";
import User from "../../models/User";

let cachedBotProfileId: string | null = process.env.AUTOMATION_BOT_PROFILE_ID || null;

// The "Dispatch Assistant" profile seeded by the document-automation migration
export const getBotProfileId = async (): Promise<string> => {
  if (cachedBotProfileId) return cachedBotProfileId;
  const user = await User.findOne({ where: { driver_number: "bot001" } });
  const profile = user ? await UserProfile.findOne({ where: { userId: user.id } }) : null;
  if (!profile) {
    throw new Error("Dispatch Assistant profile not found — run the document automation migration");
  }
  cachedBotProfileId = profile.id;
  return profile.id;
};
