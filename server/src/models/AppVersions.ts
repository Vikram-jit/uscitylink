import { Model, DataTypes, BelongsToGetAssociationMixin } from "sequelize";
import { primarySequelize } from "../sequelize";
import { UserProfile } from "./UserProfile";

export class AppVersions extends Model {
  public id!: string; // Primary key
  public version?: string;
  public buildNumber?: string;
  public status?: string | null;
  public platform?: string;

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;

 
}

AppVersions.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    buildNumber: {
      type: DataTypes.STRING,
    },
    version: {
        type: DataTypes.STRING,
      },
   status: {
      type: DataTypes.STRING,
    },
    platform:{
      type: DataTypes.STRING,
    },
   
  },
  {
    sequelize: primarySequelize,
    modelName: "AppVersions",
    tableName: "app_versions",
    timestamps: true,
  }
);
