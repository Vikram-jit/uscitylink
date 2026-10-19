import { Model, DataTypes } from "sequelize";
import { primarySequelize } from "../sequelize";

export type UsageSource = "message" | "precheck" | "reread" | "sample" | "test" | "demo";

export class AiUsageLog extends Model {
  public id!: string;
  public source!: UsageSource;
  public message_id?: string | null;
  public doc_type_key?: string | null;
  public model!: string;
  public input_tokens!: number;
  public cache_read_tokens!: number;
  public cache_write_tokens!: number;
  public output_tokens!: number;
  public cost_usd!: number | string;
  public latency_ms?: number | null;
  public created_by?: string | null;

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;
}

AiUsageLog.init(
  {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    source: { type: DataTypes.STRING(16), allowNull: false },
    message_id: { type: DataTypes.UUID, allowNull: true },
    doc_type_key: { type: DataTypes.STRING(64), allowNull: true },
    model: { type: DataTypes.STRING(64), allowNull: false },
    input_tokens: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 },
    cache_read_tokens: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 },
    cache_write_tokens: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 },
    output_tokens: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 },
    cost_usd: { type: DataTypes.DECIMAL(12, 6), allowNull: false, defaultValue: 0 },
    latency_ms: { type: DataTypes.INTEGER, allowNull: true },
    created_by: { type: DataTypes.UUID, allowNull: true },
  },
  {
    sequelize: primarySequelize,
    modelName: "AiUsageLog",
    tableName: "ai_usage_log",
    timestamps: true,
  }
);
