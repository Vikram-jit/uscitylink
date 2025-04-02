import { Model, DataTypes, BelongsToGetAssociationMixin } from "sequelize";
import { primarySequelize } from "../sequelize";
import { UserProfile } from "./UserProfile";
import UserChannel from "./UserChannel";
import GroupUser from "./GroupUser";
import Group from "./Group";
import Channel from "./Channel";

export class Message extends Model {
  public id!: string; // Primary key
  public channelId!: string;
  public userProfileId!: string;
  public groupId!: string | null; // Make optional if not always present
  public body!: string;
  public messageDirection!: "S" | "R"; // Assuming S for sent, R for received
  public deliveryStatus!: string;
  public messageTimestampUtc!: Date;
  public senderId!: string;
  public isRead!: boolean;
  public status!: string;
  public url?: string;
  public type?: string;
  public thumbnail?: string;
  public reply_message_id?: string;
  public driverPin?: string;
  public staffPin?: string;
  public url_upload_type?: string;
  public private_chat_id?: string;
  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;

  public getSender!: BelongsToGetAssociationMixin<UserProfile>;
}

Message.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    channelId: {
      type: DataTypes.UUID,
      allowNull: false,
    },
    userProfileId: {
      type: DataTypes.UUID,
      allowNull: false,
    },
    private_chat_id: {
      type: DataTypes.UUID,
      allowNull: true,
    },
    groupId: {
      type: DataTypes.UUID,
      allowNull: true,
    },
    body: {
      type: DataTypes.TEXT,
      allowNull: false,
    },
    messageDirection: {
      type: DataTypes.ENUM("S", "R"),
      allowNull: false,
    },
    deliveryStatus: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    messageTimestampUtc: {
      type: DataTypes.DATE,
      allowNull: false,
    },
    senderId: {
      type: DataTypes.UUID,
      allowNull: false,
    },
    url: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    thumbnail: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    isRead: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    status: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    type: {
      type: DataTypes.ENUM,
      values: ["default", "truck_group", "group"], // Enum values
      defaultValue: "default",
    },
    driverPin: {
      type: DataTypes.ENUM,
      values: ["0", "1"], // Enum values
      defaultValue: "0",
    },
    staffPin: {
      type: DataTypes.ENUM,
      values: ["0", "1"], // Enum values
      defaultValue: "0",
    },
    url_upload_type: {
      type: DataTypes.STRING,
      defaultValue: "not-upload",
    },
    reply_message_id: {
      type: DataTypes.UUID,
      allowNull: true,
      references: {
        model: "messages",
        key: "id",
      },
    },
  },
  {
    sequelize: primarySequelize,
    modelName: "Message",
    tableName: "messages",
    timestamps: true,
  }
);

Message.belongsTo(UserProfile, { foreignKey: "senderId", as: "sender" });
Message.belongsTo(Channel, { foreignKey: "channelId", as: "channel" });
Message.belongsTo(Message, { foreignKey: "reply_message_id", as: "r_message" });

UserProfile.hasMany(Message, { foreignKey: "senderId", as: "messages" });
UserChannel.belongsTo(Message, {
  foreignKey: "last_message_id",
  as: "last_message",
});
GroupUser.belongsTo(Message, {
  foreignKey: "last_message_id",
  as: "last_message",
});
Group.belongsTo(Message, { foreignKey: "last_message_id", as: "last_message" });
