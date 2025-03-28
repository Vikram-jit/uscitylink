import { Model, DataTypes } from "sequelize";
import { primarySequelize } from "../sequelize";
import { UserProfile } from "./UserProfile";

class GroupMessage extends Model {
  public id!: string;
  public groupId!: string;
  public senderId!: string;
  public body!: string;
  public deliveryStatus!: string;
  public messageTimestampUtc!: Date;
   public thumbnail?:string
   public url_upload_type?:string
  static associate(models: any) {
    GroupMessage.belongsTo(models.Group, { foreignKey: "groupId" });
    GroupMessage.belongsTo(models.UserProfile, { foreignKey: "senderId" });
  }
  
}

GroupMessage.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      autoIncrement: true,
      primaryKey: true,
    },
    groupId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: "groups",
        key: "id",
      },
    },
    senderId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: "user_profiles",
        key: "id",
      },
    },
    body: {
      type: DataTypes.TEXT,
      allowNull: false,
    },
    url_upload_type: {
      type: DataTypes.TEXT,
      allowNull: false,
    },
    thumbnail:{
          type: DataTypes.STRING,
          allowNull:true
    },
    deliveryStatus: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    messageTimestampUtc: {
      type: DataTypes.DATE,
      allowNull: false,
    },
    url: {
      type: DataTypes.STRING,
      allowNull: true,
    },
  },
  {
    sequelize: primarySequelize,
    modelName: "GroupMessage",
    tableName: "group_messages",
  }
);

GroupMessage.belongsTo(UserProfile, { foreignKey: 'senderId', as: 'sender' });
UserProfile.hasMany(GroupMessage, { foreignKey: 'senderId', as: 'group_messages' });

export default GroupMessage;
