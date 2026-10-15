import { Model, DataTypes } from "sequelize";
import { primarySequelize } from "../sequelize";
import { jsonGetter } from "./jsonColumn";
import { Flow } from "./Flow";

export class FlowRun extends Model {
  public id!: string;
  public flow_id!: string;
  public message_id!: string;
  public driver_id?: string | null;
  public doc_type_key?: string | null;
  public matched!: boolean;
  public shadow!: boolean;
  public skipped_reason?: string | null;
  public context_snapshot?: Record<string, any> | null;
  public condition_trace?: any;
  public action_results?: any[] | null;
  public error?: string | null;

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;
}

FlowRun.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    flow_id: {
      type: DataTypes.UUID,
      allowNull: false,
    },
    message_id: {
      type: DataTypes.UUID,
      allowNull: false,
    },
    driver_id: {
      type: DataTypes.UUID,
      allowNull: true,
    },
    doc_type_key: {
      type: DataTypes.STRING(64),
      allowNull: true,
    },
    matched: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    },
    shadow: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    },
    skipped_reason: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    context_snapshot: {
      type: DataTypes.JSON,
      get: jsonGetter("context_snapshot"),
      allowNull: true,
    },
    condition_trace: {
      type: DataTypes.JSON,
      get: jsonGetter("condition_trace"),
      allowNull: true,
    },
    action_results: {
      type: DataTypes.JSON,
      get: jsonGetter("action_results"),
      allowNull: true,
    },
    error: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
  },
  {
    sequelize: primarySequelize,
    modelName: "FlowRun",
    tableName: "flow_runs",
    timestamps: true,
  }
);

Flow.hasMany(FlowRun, { foreignKey: "flow_id", as: "runs" });
FlowRun.belongsTo(Flow, { foreignKey: "flow_id", as: "flow" });
