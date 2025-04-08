import { Model, DataTypes, BelongsToGetAssociationMixin } from "sequelize";
import { primarySequelize } from "../sequelize";
import { UserProfile } from "./UserProfile";

export class Media extends Model {
  public id!: string; // Primary key
  public channelId?: string;
  public user_profile_id!: string;
  public groupId?: string | null;
  public file_name?: string;
  public file_type?: string;
  public mime_type?: string;
  public file_size?: string;
  public thumbnail?: string;
  public upload_type?: string;
  public upload_source?: string;
  public private_chat_id?:string;
  public key?: string;

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;

  public getSender!: BelongsToGetAssociationMixin<UserProfile>;
}

Media.init(
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
    private_chat_id: {
      type: DataTypes.UUID,
      allowNull: true,
    },
    upload_source: {
      type: DataTypes.STRING,
      allowNull: false,
      defaultValue:"message"
    },
    user_profile_id: {
      type: DataTypes.UUID,
      allowNull: false,
    },
    groupId: {
      type: DataTypes.UUID,
      allowNull: true,
    },
    file_name: {
      type: DataTypes.TEXT,
    },
    file_type: {
      type: DataTypes.TEXT,
    },
    thumbnail:{
      type: DataTypes.TEXT,
    },
    file_size: {
      type: DataTypes.TEXT,
    },
    mime_type: {
      type: DataTypes.TEXT,
    },
    key: {
      type: DataTypes.TEXT,
    },
    upload_type: {
      type: DataTypes.STRING,
    },
  },
  {
    sequelize: primarySequelize,
    modelName: "Media",
    tableName: "media",
    timestamps: true,
  }
);
