import { Message } from './Message';
import { Model, DataTypes } from "sequelize";
import { primarySequelize } from "../sequelize";

class StaffChannel extends Model {
  public id!: string;
  public userProfileId!: string;
  public channelId!: string;
  public last_message_id?: string;
  public sent_message_count?: number;
  public recieve_message_count?: number;
  public readonly StaffChannels?: StaffChannel[]; 
  
  static associate(models: any) {
    StaffChannel.belongsTo(models.UserProfile, { foreignKey: 'userProfileId' });
    StaffChannel.belongsTo(models.Channel, { foreignKey: 'channelId' });
    
  }
}

StaffChannel.init(
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
    modelName: "StaffChannel",
    tableName: "user_channels",
  }
);

export default StaffChannel;
