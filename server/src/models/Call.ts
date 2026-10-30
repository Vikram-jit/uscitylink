import { Model, DataTypes } from "sequelize";
import { primarySequelize } from "../sequelize";

export type CallStatus = "ringing" | "ongoing" | "completed" | "missed" | "declined" | "cancelled" | "busy" | "failed";
export type CallType = "audio" | "video";

/** One call attempt between staff and a driver (see migrations/20261030000001-create-calls.js). */
export class Call extends Model {
  public id!: string;
  public channel_id!: string;
  public driver_id!: string;
  public initiator_id!: string;
  public answered_by?: string | null;
  public type!: CallType;
  public status!: CallStatus;
  public end_reason?: string | null;
  public started_at!: Date;
  public answered_at?: Date | null;
  public ended_at?: Date | null;
  public duration_sec!: number;
  public quality?: Record<string, any> | null;
  public message_id?: string | null;
  public queued_sec!: number; // waited in line (all dispatchers busy)
  public wait_sec?: number | null; // dialling → answered
  public kind!: "direct" | "dispatch"; // dispatch = driver called the dispatch line

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;
}

Call.init(
  {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    channel_id: { type: DataTypes.UUID, allowNull: false },
    driver_id: { type: DataTypes.UUID, allowNull: false },
    initiator_id: { type: DataTypes.UUID, allowNull: false },
    answered_by: { type: DataTypes.UUID, allowNull: true },
    type: { type: DataTypes.STRING(16), allowNull: false, defaultValue: "audio" },
    status: { type: DataTypes.STRING(16), allowNull: false, defaultValue: "ringing" },
    end_reason: { type: DataTypes.STRING(64), allowNull: true },
    started_at: { type: DataTypes.DATE, allowNull: false },
    answered_at: { type: DataTypes.DATE, allowNull: true },
    ended_at: { type: DataTypes.DATE, allowNull: true },
    duration_sec: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 },
    quality: { type: DataTypes.JSON, allowNull: true },
    message_id: { type: DataTypes.UUID, allowNull: true },
    queued_sec: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 },
    wait_sec: { type: DataTypes.INTEGER, allowNull: true },
    kind: { type: DataTypes.STRING(16), allowNull: false, defaultValue: "direct" },
  },
  { sequelize: primarySequelize, modelName: "Call", tableName: "calls", timestamps: true }
);

export class CallParticipant extends Model {
  public id!: string;
  public call_id!: string;
  public user_profile_id!: string;
  public role!: "caller" | "callee";
  public state!: "invited" | "joined" | "declined" | "missed" | "left";
  public device?: string | null;
  public invited_at!: Date;
  public joined_at?: Date | null;
  public left_at?: Date | null;
}

CallParticipant.init(
  {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    call_id: { type: DataTypes.UUID, allowNull: false },
    user_profile_id: { type: DataTypes.UUID, allowNull: false },
    role: { type: DataTypes.STRING(16), allowNull: false },
    state: { type: DataTypes.STRING(16), allowNull: false, defaultValue: "invited" },
    device: { type: DataTypes.STRING(32), allowNull: true },
    invited_at: { type: DataTypes.DATE, allowNull: false },
    joined_at: { type: DataTypes.DATE, allowNull: true },
    left_at: { type: DataTypes.DATE, allowNull: true },
  },
  { sequelize: primarySequelize, modelName: "CallParticipant", tableName: "call_participants", timestamps: true }
);
