import moment from "moment-timezone";
import { Message } from "../../models/Message";
import { MessageDocument } from "../../models/MessageDocument";
import { UserProfile } from "../../models/UserProfile";
import User from "../../models/User";
import GroupUser from "../../models/GroupUser";
import Group from "../../models/Group";

const TIMEZONE = process.env.AUTOMATION_TIMEZONE || "America/Los_Angeles";

export interface FlowContext {
  doc: {
    type: string | null;
    confidence: number | null;
    quality: string | null;
    is_document: boolean;
    notes: string | null;
    fields: Record<string, any>;
  };
  driver: {
    id: string;
    name: string | null;
    number: string | null;
    phone: string | null;
    truck: string | null;
    yard_id: number | null;
  };
  message: {
    id: string;
    channel_id: string;
    caption: string | null;
    url: string | null;
  };
  time: {
    hour: number;
    weekday: string;
    date: string;
  };
  // Filled per flow just before its actions run (see flowEngine/reasons)
  flow?: { reasons: string; checks: string };
}

export const buildDocContext = (doc: Partial<MessageDocument> | null): FlowContext["doc"] => {
  // A staff correction always wins over what the model read
  const type = doc?.corrected_doc_type || doc?.doc_type_key || null;
  return {
    type,
    confidence: doc?.corrected_doc_type ? 1 : doc?.confidence ?? null,
    quality: doc?.image_quality ?? null,
    is_document: type !== null && type !== "other",
    notes: doc?.notes ?? null,
    fields: { ...(doc?.fields || {}), ...(doc?.corrected_fields || {}) },
  };
};

export const buildFlowContext = async (
  message: Message,
  doc: Partial<MessageDocument> | null,
): Promise<FlowContext> => {
  const driverId = message.userProfileId;
  const profile = await UserProfile.findByPk(driverId);
  const user = profile ? await User.findByPk(profile.userId) : null;

  const groupLinks = await GroupUser.findAll({ where: { userProfileId: driverId } });
  const truckGroup = groupLinks.length
    ? await Group.findOne({ where: { id: groupLinks.map((g: any) => g.groupId), type: "truck" } })
    : null;

  const now = moment().tz(TIMEZONE);
  return {
    doc: buildDocContext(doc),
    driver: {
      id: driverId,
      name: profile?.username || null,
      number: user?.driver_number || null,
      phone: user?.phone_number || null,
      truck: (truckGroup as any)?.name || null,
      yard_id: user?.yard_id ?? null,
    },
    message: {
      id: message.id,
      channel_id: message.channelId,
      caption: message.body || null,
      url: message.url || null,
    },
    time: {
      hour: now.hour(),
      weekday: now.format("dddd").toLowerCase(),
      date: now.format("YYYY-MM-DD"),
    },
  };
};
