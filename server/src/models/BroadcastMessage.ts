import { Model, DataTypes, Optional } from "sequelize";
import { primarySequelize } from "../sequelize";
import { UserProfile } from "./UserProfile";

interface BroadcastMessageAttributes {
  id: number;
  broadcast_message_log_id: string;
  sender_id:string;
  user_id: string;
  body: string;
  url: string | null;
  status: "pending" | "processing" | "sent" | "failed";
  createdAt?: Date;
  updatedAt?: Date;
}

interface BroadcastMessageCreationAttributes
  extends Optional<BroadcastMessageAttributes, "id" | "status"> {}

class BroadcastMessage
  extends Model<
    BroadcastMessageAttributes,
    BroadcastMessageCreationAttributes
  >
  implements BroadcastMessageAttributes
{
  public id!: number;
    public sender_id!: string;
    public broadcast_message_log_id!: string;
  public user_id!: string;
  public body!: string;
  public url!: string | null;
  public status!: "pending" | "processing" | "sent" | "failed";

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;
}

BroadcastMessage.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    broadcast_message_log_id: {
      type: DataTypes.UUID,
      allowNull: false,
    },
    sender_id: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    user_id: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    body: {
      type: DataTypes.TEXT,
      allowNull: false,
    },
    url: {
      type: DataTypes.TEXT,
      allowNull: true, // better allow null
    },
    status: {
      type: DataTypes.ENUM("pending", "processing", "sent", "failed"),
      defaultValue: "pending",
    },
  },
  {
    sequelize:primarySequelize,
    tableName: "broadcast_messages",
    modelName: "BroadcastMessage",
  }
);

export default BroadcastMessage;


BroadcastMessage.belongsTo(UserProfile, {
  foreignKey: "user_id",
  as: "userProfile",
});

UserProfile.hasMany(BroadcastMessage, {
  foreignKey: "user_id",
  as: "broadcastMessages",
});

