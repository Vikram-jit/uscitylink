import { Message } from './Message';
import { Model, DataTypes } from "sequelize";
import { primarySequelize } from "../sequelize";

class UserChannel extends Model {
  public id!: string;
  public userProfileId!: string;
  public channelId!: string;
  public status?: string;
  public last_message_id?: string;
  public sent_message_count?: number;
  public recieve_message_count?: number;
 
  public last_message_utc?:Date
  public readonly userChannels?: UserChannel[]; 
  
  static associate(models: any) {
    UserChannel.belongsTo(models.UserProfile, { foreignKey: 'userProfileId' });
    UserChannel.belongsTo(models.Channel, { foreignKey: 'channelId' });
    
  }
}

UserChannel.init(
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
        model: 'user_profiles',
        key: 'id',
      },
    },
    channelId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'channels', 
        key: 'id',
      },
    },
    last_message_id: {
      type: DataTypes.UUID,
      allowNull: true,
      references: {
        model: 'messages', 
        key: 'id',
      },
    },
    recieve_message_count: {
      type: DataTypes.INTEGER,
      defaultValue:0
    },
    status: {
      type: DataTypes.STRING,
      defaultValue:"active"
    },
    sent_message_count: {
      type: DataTypes.INTEGER,
      defaultValue:0
    },
    last_message_utc: {
      type: DataTypes.DATE,
      defaultValue:0
    },
  },
  {
    sequelize: primarySequelize,
    modelName: "UserChannel",
    tableName: "user_channels",
  }
);

export default UserChannel;
