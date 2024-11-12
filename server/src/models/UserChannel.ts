import { Model, DataTypes } from "sequelize";
import { primarySequelize } from "../sequelize";

class UserChannel extends Model {
  public id!: string;
  public userProfileId!: string;
  public channelId!: string;
  public readonly userChannels?: UserChannel[]; // Add this line
  
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
        model: 'user_profiles', // Adjust based on your table name
        key: 'id',
      },
    },
    channelId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'channels', // Adjust based on your table name
        key: 'id',
      },
    },
    last_message_id: {
      type: DataTypes.UUID,
      allowNull: true,
      references: {
        model: 'messages', // Adjust based on your table name
        key: 'id',
      },
    },
  },
  {
    sequelize: primarySequelize,
    modelName: "UserChannel",
    tableName: "user_channels",
  }
);

export default UserChannel;
