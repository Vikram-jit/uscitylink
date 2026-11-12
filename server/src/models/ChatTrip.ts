import { randomBytes } from "crypto";
import { DataTypes, Model } from "sequelize";
import { primarySequelize } from "../sequelize";
import { jsonGetter } from "./jsonColumn";
import type { TripStatus } from "../services/trips/lifecycle";

// Trips (loads) sent to drivers (migrations/20261106000001-create-chat-trips.js). trip_no is the load's
// own number (L0047). When dispatch marks the trip completed, its yard Route List entry is created:
// driver_pay_details_id / route_trip_no (services/trips/routeListSync). Times are UTC.

export type LoadType = "direct" | "via_yard" | "relay" | "trailer_move";
export type LoadStatus = "scheduled" | "waiting" | "active" | "transfer" | "delivered" | "completed" | "cancelled";

/**
 * A load, tracked by its invoice # (migrations/20261112000001-create-chat-loads.js). Moved by one or
 * more legs: each leg is a ChatTrip run by one driver with their own truck / trailer / stops.
 * status is worked out from the legs (services/trips/loadService.loadStatusOf).
 */
export class ChatLoad extends Model {
  public id!: number;
  public load_no!: string | null;
  public invoice_no!: string | null;
  /** Public tracking link /track/<token> for shippers (works until the load is completed) */
  public track_token!: string | null;
  /** Short code for the app's "Track a load" (e.g. K7M2QX) */
  public track_code!: string | null;
  public type!: LoadType;
  public status!: LoadStatus;
  public notes!: string | null;
  public created_by!: string | null;
  public created_by_name!: string | null;
  public created_at!: Date;
  public updated_at!: Date;
  public legs?: ChatTrip[];
}

export class ChatTrip extends Model {
  public id!: number;
  /** The load this leg moves (every trip has one; a plain load has a single leg) */
  public load_id!: number | null;
  public leg_no!: number;
  /** Place in the driver's lineup of lined-up loads (lower goes first) */
  public queue_pos!: number | null;
  /** Lined up by dispatch "after the current load": sent by itself when the driver ends that load */
  public auto_send!: boolean;
  /** The leg drops the trailer at our yard for the next leg */
  public ends_at_yard!: boolean;
  /** ETA when the leg went Rolling — compared with the real delivery */
  public planned_eta_at!: Date | null;
  public trip_no!: string | null;
  /** Required before Mark completed */
  public invoice_no!: string | null;
  public status!: TripStatus;
  public status_before_hold!: TripStatus | null;
  public source!: "form" | "typed";
  public needs_review!: boolean;
  public review_notes!: string | null;
  public driver_profile_id!: string | null;
  public channel_id!: string | null;
  public message_id!: string | null;
  public driver_id_1!: number | null;
  public driver_id_2!: number | null;
  public truck_id!: number | null;
  public trailer_ids!: string | null;
  public truck_number!: string | null;
  public trailer_numbers!: string | null;
  public temperature!: string | null;
  public loaded_trailer!: boolean;
  public notes!: string | null;
  public planned_start_at!: Date | null;
  public sent_at!: Date | null;
  public started_at!: Date | null;
  public ended_at!: Date | null;
  public completed_at!: Date | null;
  public completed_by_name!: string | null;
  public total_mileage!: string | null;
  /** samsara (odometer) | manual (typed by dispatch — Samsara won't overwrite it) */
  public miles_source!: "samsara" | "manual" | null;
  public miles_note!: string | null;
  /** Why this leg was cut and handed to another driver / truck (breakdown, out_of_hours …) */
  public handover_reason!: string | null;
  public driver_pay_details_id!: number | null;
  public route_trip_no!: string | null;
  public created_by!: string | null;
  public created_by_name!: string | null;
  public raw_text!: string | null;
  public created_at!: Date;
  public updated_at!: Date;
  public stops?: ChatTripStop[];
  public events?: ChatTripEvent[];
  public problems?: ChatTripProblem[];
}

ChatTrip.init(
  {
    id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
    load_id: DataTypes.BIGINT.UNSIGNED,
    leg_no: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 1 },
    queue_pos: DataTypes.INTEGER,
    auto_send: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false },
    ends_at_yard: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false },
    planned_eta_at: DataTypes.DATE,
    trip_no: DataTypes.STRING,
    invoice_no: DataTypes.STRING(64),
    status: { type: DataTypes.STRING(20), allowNull: false, defaultValue: "scheduled" },
    status_before_hold: DataTypes.STRING(20),
    source: { type: DataTypes.STRING(10), allowNull: false, defaultValue: "form" },
    needs_review: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false },
    review_notes: DataTypes.TEXT,
    driver_profile_id: DataTypes.STRING(64),
    channel_id: DataTypes.STRING(64),
    message_id: DataTypes.STRING(64),
    driver_id_1: DataTypes.BIGINT.UNSIGNED,
    driver_id_2: DataTypes.BIGINT.UNSIGNED,
    truck_id: DataTypes.BIGINT.UNSIGNED,
    trailer_ids: DataTypes.STRING,
    truck_number: DataTypes.STRING,
    trailer_numbers: DataTypes.STRING,
    temperature: DataTypes.STRING,
    loaded_trailer: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: false },
    notes: DataTypes.TEXT,
    planned_start_at: DataTypes.DATE,
    sent_at: DataTypes.DATE,
    started_at: DataTypes.DATE,
    ended_at: DataTypes.DATE,
    completed_at: DataTypes.DATE,
    completed_by_name: DataTypes.STRING,
    total_mileage: DataTypes.DECIMAL(10, 2),
    miles_source: DataTypes.STRING(10),
    miles_note: DataTypes.STRING(255),
    handover_reason: DataTypes.STRING(32),
    driver_pay_details_id: DataTypes.BIGINT.UNSIGNED,
    route_trip_no: DataTypes.STRING,
    created_by: DataTypes.STRING(64),
    created_by_name: DataTypes.STRING,
    raw_text: DataTypes.TEXT,
  },
  { sequelize: primarySequelize, tableName: "chat_trips", modelName: "ChatTrip", underscored: true, timestamps: true }
);

export class ChatTripStop extends Model {
  public id!: number;
  public chat_trip_id!: number;
  public seq!: number;
  /** yard: our yard, where a leg drops the trailer for the next one */
  public type!: "pickup" | "drop" | "switch" | "yard";
  public name!: string | null;
  public street!: string | null;
  public city!: string | null;
  public state!: string | null;
  public zip!: string | null;
  public appointment_local!: string | null;
  public appointment_at!: Date | null;
  public timezone!: string | null;
  public arrived_at!: Date | null;
  public departed_at!: Date | null;
  public ref!: string | null;
  public mileage!: string | null;
}

ChatTripStop.init(
  {
    id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
    chat_trip_id: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false },
    seq: { type: DataTypes.SMALLINT.UNSIGNED, allowNull: false },
    type: { type: DataTypes.STRING(10), allowNull: false },
    name: DataTypes.STRING,
    street: DataTypes.STRING,
    city: DataTypes.STRING,
    state: DataTypes.STRING(2),
    zip: DataTypes.STRING(10),
    appointment_local: DataTypes.STRING(16),
    appointment_at: DataTypes.DATE,
    timezone: DataTypes.STRING(40),
    arrived_at: DataTypes.DATE,
    departed_at: DataTypes.DATE,
    ref: DataTypes.STRING,
    mileage: DataTypes.DECIMAL(10, 2),
  },
  { sequelize: primarySequelize, tableName: "chat_trip_stops", modelName: "ChatTripStop", underscored: true, timestamps: true }
);

export class ChatTripEvent extends Model {
  public id!: number;
  public chat_trip_id!: number;
  public type!: string;
  public from_status!: string | null;
  public to_status!: string | null;
  public stop_id!: number | null;
  public actor_role!: string;
  public actor_id!: string | null;
  public actor_name!: string | null;
  public note!: string | null;
  public data!: Record<string, any> | null;
  public lat!: string | null;
  public lng!: string | null;
  public message_id!: string | null;
  public happened_at!: Date;
  public created_at!: Date;
}

ChatTripEvent.init(
  {
    id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
    chat_trip_id: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false },
    type: { type: DataTypes.STRING(30), allowNull: false },
    from_status: DataTypes.STRING(20),
    to_status: DataTypes.STRING(20),
    stop_id: DataTypes.BIGINT.UNSIGNED,
    actor_role: { type: DataTypes.STRING(20), allowNull: false },
    actor_id: DataTypes.STRING(64),
    actor_name: DataTypes.STRING,
    note: DataTypes.TEXT,
    data: { type: DataTypes.JSON, get: jsonGetter("data") },
    lat: DataTypes.DECIMAL(10, 7),
    lng: DataTypes.DECIMAL(10, 7),
    message_id: DataTypes.STRING(64),
    happened_at: { type: DataTypes.DATE, allowNull: false },
  },
  {
    sequelize: primarySequelize,
    tableName: "chat_trip_events",
    modelName: "ChatTripEvent",
    underscored: true,
    timestamps: true,
    updatedAt: false, // append-only
  }
);

export class ChatTripProblem extends Model {
  public id!: number;
  public chat_trip_id!: number;
  public kind!: string;
  public note!: string | null;
  public amount!: string | null;
  public opened_by!: string | null;
  public opened_by_name!: string | null;
  public resolved_at!: Date | null;
  public resolved_by_name!: string | null;
  public created_at!: Date;
}

ChatTripProblem.init(
  {
    id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
    chat_trip_id: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false },
    kind: { type: DataTypes.STRING(20), allowNull: false },
    note: DataTypes.TEXT,
    amount: DataTypes.DECIMAL(10, 2),
    opened_by: DataTypes.STRING(64),
    opened_by_name: DataTypes.STRING,
    resolved_at: DataTypes.DATE,
    resolved_by_name: DataTypes.STRING,
  },
  { sequelize: primarySequelize, tableName: "chat_trip_problems", modelName: "ChatTripProblem", underscored: true, timestamps: true }
);

ChatLoad.init(
  {
    id: { type: DataTypes.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
    load_no: DataTypes.STRING(32),
    invoice_no: DataTypes.STRING(64),
    track_token: DataTypes.STRING(40),
    track_code: DataTypes.STRING(8),
    type: { type: DataTypes.STRING(16), allowNull: false, defaultValue: "direct" },
    status: { type: DataTypes.STRING(16), allowNull: false, defaultValue: "scheduled" },
    notes: DataTypes.TEXT,
    created_by: DataTypes.STRING(64),
    created_by_name: DataTypes.STRING,
  },
  { sequelize: primarySequelize, tableName: "chat_loads", modelName: "ChatLoad", underscored: true, timestamps: true }
);

/** A fresh public tracking token (24 url-safe chars, not guessable) */
export const newTrackToken = () => randomBytes(18).toString("base64url");
// No 0/O, 1/I/L: easy to read out on the phone and type
const CODE_CHARS = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
export const newTrackCode = () => Array.from(randomBytes(6), (b) => CODE_CHARS[b % CODE_CHARS.length]).join("");
/** A code no other load has */
export async function uniqueTrackCode(): Promise<string> {
  for (let i = 0; i < 10; i++) {
    const code = newTrackCode();
    if (!(await ChatLoad.count({ where: { track_code: code } }))) return code;
  }
  return `${newTrackCode()}${newTrackCode().slice(0, 2)}`;
}
ChatLoad.beforeCreate(async (load) => {
  if (!load.track_token) load.track_token = newTrackToken();
  if (!load.track_code) load.track_code = await uniqueTrackCode();
});

ChatLoad.hasMany(ChatTrip, { foreignKey: "load_id", as: "legs" });
ChatTrip.belongsTo(ChatLoad, { foreignKey: "load_id", as: "load" });
ChatTrip.hasMany(ChatTripStop, { foreignKey: "chat_trip_id", as: "stops" });
ChatTrip.hasMany(ChatTripEvent, { foreignKey: "chat_trip_id", as: "events" });
ChatTrip.hasMany(ChatTripProblem, { foreignKey: "chat_trip_id", as: "problems" });
ChatTripStop.belongsTo(ChatTrip, { foreignKey: "chat_trip_id" });
