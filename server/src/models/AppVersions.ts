import { Model, DataTypes, BelongsToGetAssociationMixin } from "sequelize";
import { primarySequelize } from "../sequelize";
import { UserProfile } from "./UserProfile";

export class AppVersions extends Model {
  public id!: string; // Primary key
  public version?: string;
  public buildNumber?: string;
  public status?: string | null;
  public platform?: string;
  public releaseNotes?: string | null;
  public force_update?: boolean;

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
    releaseNotes: {
      type: DataTypes.TEXT,
    },
    force_update: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    },
   
  },
  {
    sequelize: primarySequelize,
    modelName: "AppVersions",
    tableName: "app_versions",
    timestamps: true,
  }
);
