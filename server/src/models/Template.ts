import { Model, DataTypes, BelongsToGetAssociationMixin } from "sequelize";
import { primarySequelize } from "../sequelize";
import { UserProfile } from "./UserProfile";
import UserChannel from "./UserChannel";
import GroupUser from "./GroupUser";
import Group from "./Group";

export class Template extends Model {
  public id!: string; // Primary key
  public channelId?: string;
  public userProfileId?: string;
  public body?: string;
  public name?: string;
  public url?: string;

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;

  public getSender!: BelongsToGetAssociationMixin<UserProfile>;
}

Template.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    channelId: {
      type: DataTypes.UUID,
      allowNull: true,
    },
    userProfileId: {
      type: DataTypes.UUID,
      allowNull: true,
    },

    body: {
      type: DataTypes.TEXT,
      allowNull: true,
    },

    name: {
      type: DataTypes.STRING,
      allowNull: true,
    },

    url: {
      type: DataTypes.STRING,
      allowNull: true,
    },
  },
  {
    sequelize: primarySequelize,
    modelName: "Template",
    tableName: "templates",
    timestamps: true,
  }
);
