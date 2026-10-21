import { Model, DataTypes } from "sequelize";
import { primarySequelize } from "../sequelize";
import { jsonGetter } from "./jsonColumn";

export type ScaleStatus =
  | "PASS_PRELIMINARY"
  | "OVER_GROSS"
  | "ADJUST_AND_REWEIGH"
  | "OCR_UNCERTAIN";

export type ApprovalStatus = "pending" | "approved" | "rejected" | "not_required" | "superseded";

// One row per scale ticket: what was read, the rules it was judged against, the result, what the
// driver was told, the reweigh chain and the dispatcher's decision (spec §9 output contract + audit).
export class ScaleCheck extends Model {
  public id!: string;
  public message_id!: string;
  public message_document_id?: string | null;
  public driver_id?: string | null;
  public channel_id?: string | null;
  public truck?: string | null;
  public ticket_number?: string | null;
  public measured_weights?: Record<string, number | null> | null;
  public confidence?: number | null;
  public image_quality?: string | null;
  public rule_set_id?: string | null;
  public rule_set_version?: string | null;
  public model?: string | null;
  public status!: ScaleStatus;
  public flags?: string[] | null;
  public group_overages_lb?: Record<string, number> | null;
  public headroom_lb?: Record<string, number> | null;
  public feasible_adjustments?: any[] | null;
  public assumptions?: string[] | null;
  public required_actions?: string[] | null;
  public driver_message?: string | null;
  public previous_check_id?: string | null;
  public reweigh_check_id?: string | null;
  public approval_status!: ApprovalStatus;
  public approved_by?: string | null;
  public approved_at?: Date | null;
  public approval_note?: string | null;
  public trip_id?: string | null;
  public tractor_unit?: string | null;
  public trailer_unit?: string | null;
  public controlling_rules?: any | null;
  public bridge_results?: any[] | null;
  public kpra?: any | null;
  // Recorded by dispatch: what the driver moved, and confirmation they were parked and secured
  public adjustment_made?: { action: string; holes?: number | null; parked_confirmed: boolean; by?: string; at?: string } | null;
  // On a reweigh: predicted vs actual weight shift from the adjustment
  public prediction?: any | null;

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;
}

const json = (name: string) => ({ type: DataTypes.JSON, allowNull: true, get: jsonGetter(name) });

ScaleCheck.init(
  {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    message_id: { type: DataTypes.UUID, allowNull: false, unique: true },
    message_document_id: { type: DataTypes.UUID, allowNull: true },
    driver_id: { type: DataTypes.UUID, allowNull: true },
    channel_id: { type: DataTypes.UUID, allowNull: true },
    truck: { type: DataTypes.STRING(64), allowNull: true },
    ticket_number: { type: DataTypes.STRING(64), allowNull: true },
    measured_weights: json("measured_weights"),
    confidence: { type: DataTypes.FLOAT, allowNull: true },
    image_quality: { type: DataTypes.STRING(16), allowNull: true },
    rule_set_id: { type: DataTypes.UUID, allowNull: true },
    rule_set_version: { type: DataTypes.STRING(64), allowNull: true },
    model: { type: DataTypes.STRING(64), allowNull: true },
    status: { type: DataTypes.STRING(32), allowNull: false },
    flags: json("flags"),
    group_overages_lb: json("group_overages_lb"),
    headroom_lb: json("headroom_lb"),
    feasible_adjustments: json("feasible_adjustments"),
    assumptions: json("assumptions"),
    required_actions: json("required_actions"),
    driver_message: { type: DataTypes.TEXT, allowNull: true },
    previous_check_id: { type: DataTypes.UUID, allowNull: true },
    reweigh_check_id: { type: DataTypes.UUID, allowNull: true },
    approval_status: { type: DataTypes.STRING(16), allowNull: false, defaultValue: "not_required" },
    approved_by: { type: DataTypes.UUID, allowNull: true },
    approved_at: { type: DataTypes.DATE, allowNull: true },
    approval_note: { type: DataTypes.TEXT, allowNull: true },
    trip_id: { type: DataTypes.UUID, allowNull: true },
    tractor_unit: { type: DataTypes.STRING(64), allowNull: true },
    trailer_unit: { type: DataTypes.STRING(64), allowNull: true },
    controlling_rules: json("controlling_rules"),
    bridge_results: json("bridge_results"),
    kpra: json("kpra"),
    adjustment_made: json("adjustment_made"),
    prediction: json("prediction"),
  },
  { sequelize: primarySequelize, modelName: "ScaleCheck", tableName: "scale_checks", timestamps: true },
);
