import { Model, DataTypes, BelongsToGetAssociationMixin } from "sequelize";
import { primarySequelize } from "../sequelize";
import { UserProfile } from "./UserProfile";

export class MessageStaff extends Model {
  public id!: string; // Primary key
  public version?: string;
  public buildNumber?: string;
  public status?: string | null;
  public platform?: string;

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;

  static associate(models: any) {
    MessageStaff.belongsTo(models.UserProfile, { foreignKey: "driverId" });
  }
}

MessageStaff.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    messageId: {
      type: DataTypes.UUID,
    },
    staffId: {
      type: DataTypes.UUID,
    },
    driverId: {
      type: DataTypes.UUID,
    },
    status: {
      type: DataTypes.STRING,
    },
    type: {
      type: DataTypes.STRING,
    },
  },
  {
    sequelize: primarySequelize,
    modelName: "MessageStaff",
    tableName: "message_staff",
    timestamps: true,
  }
);
