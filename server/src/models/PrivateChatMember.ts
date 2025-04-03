import { Model, DataTypes } from "sequelize";
import { primarySequelize } from "../sequelize";
import { UserProfile } from "./UserProfile";

class PrivateChatMember extends Model {
  public id?: string;
  public userProfileId?: string;
  public createdBy?: string;
  public senderCount?: number;
  public reciverCount?: number;
  public last_message_id?: string;
  public status?: string;

 
}

PrivateChatMember.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      autoIncrement: true,
      primaryKey: true,
    },

    userProfileId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: "user_profiles",
        key: "id",
      },
    },
    createdBy: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: "user_profiles",
        key: "id",
      },
    },
    senderCount: {
      type: DataTypes.NUMBER,
      allowNull: true,
    },
    reciverCount: {
      type: DataTypes.NUMBER,
      allowNull: true,
    },
    last_message_id: {
      type: DataTypes.UUID,
      allowNull: true,
      references: {
        model: "messages",
        key: "id",
      },
    },

    status: {
      type: DataTypes.STRING,
      allowNull: true,
    },
  },
  {
    sequelize: primarySequelize,
    modelName: "PrivateChatMember",
    tableName: "private_chat_members",
  }
);

export default PrivateChatMember;
