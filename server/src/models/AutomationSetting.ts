import { Model, DataTypes } from "sequelize";
import { primarySequelize } from "../sequelize";

export class AutomationSetting extends Model {
  public key!: string;
  public value?: string | null;
  public updated_by?: string | null;

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;
}

AutomationSetting.init(
  {
    key: { type: DataTypes.STRING(64), primaryKey: true },
    value: { type: DataTypes.TEXT, allowNull: true },
    updated_by: { type: DataTypes.UUID, allowNull: true },
  },
  {
    sequelize: primarySequelize,
    modelName: "AutomationSetting",
    tableName: "automation_settings",
    timestamps: true,
  }
);
