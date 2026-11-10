import { DataTypes, Model } from "sequelize";
import { primarySequelize } from "../sequelize";
import { jsonGetter } from "./jsonColumn";
import type { TripStatus } from "../services/trips/lifecycle";

// Trips (loads) sent to drivers (migrations/20261106000001-create-chat-trips.js). trip_no is the load's
// own number (L0047). When dispatch marks the trip completed, its yard Route List entry is created:
// driver_pay_details_id / route_trip_no (services/trips/routeListSync). Times are UTC.

export class ChatTrip extends Model {
  public id!: number;
  public trip_no!: string | null;
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
    trip_no: DataTypes.STRING,
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
  public type!: "pickup" | "drop" | "switch";
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

ChatTrip.hasMany(ChatTripStop, { foreignKey: "chat_trip_id", as: "stops" });
ChatTrip.hasMany(ChatTripEvent, { foreignKey: "chat_trip_id", as: "events" });
ChatTrip.hasMany(ChatTripProblem, { foreignKey: "chat_trip_id", as: "problems" });
ChatTripStop.belongsTo(ChatTrip, { foreignKey: "chat_trip_id" });
