import { Model, DataTypes } from "sequelize";
import { primarySequelize } from "../sequelize";
import { jsonGetter } from "./jsonColumn";

export type RoadClass = "interstate" | "state_highway" | "local";

export interface TripSegment {
  state: string; // two-letter code
  road_class: RoadClass;
  note?: string;
}

export interface TripPermit {
  state: string;
  number: string;
  expires_at: string; // YYYY-MM-DD
  gross_lb?: number | null;
  tandem_lb?: number | null;
  single_axle_lb?: number | null;
}

// The route a driver is on, entered by dispatch: every state and road class in order, plus permits.
// The scale agent judges a ticket against the rules of every segment (lowest limit wins).
export class DriverTrip extends Model {
  public id!: string;
  public driver_id!: string;
  public truck?: string | null;
  public trailer?: string | null;
  public origin?: string | null;
  public destination?: string | null;
  public segments?: TripSegment[] | null;
  public permits?: TripPermit[] | null;
  public cargo?: string | null;
  public status!: "active" | "closed";
  public notes?: string | null;
  public created_by?: string | null;
  public closed_at?: Date | null;

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;
}

DriverTrip.init(
  {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    driver_id: { type: DataTypes.UUID, allowNull: false },
    truck: { type: DataTypes.STRING(64), allowNull: true },
    trailer: { type: DataTypes.STRING(64), allowNull: true },
    origin: { type: DataTypes.STRING, allowNull: true },
    destination: { type: DataTypes.STRING, allowNull: true },
    segments: { type: DataTypes.JSON, allowNull: true, get: jsonGetter("segments") },
    permits: { type: DataTypes.JSON, allowNull: true, get: jsonGetter("permits") },
    cargo: { type: DataTypes.STRING, allowNull: true },
    status: { type: DataTypes.STRING(16), allowNull: false, defaultValue: "active" },
    notes: { type: DataTypes.TEXT, allowNull: true },
    created_by: { type: DataTypes.UUID, allowNull: true },
    closed_at: { type: DataTypes.DATE, allowNull: true },
  },
  { sequelize: primarySequelize, modelName: "DriverTrip", tableName: "driver_trips", timestamps: true },
);
