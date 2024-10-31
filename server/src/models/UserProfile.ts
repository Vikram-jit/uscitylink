import { Model, DataTypes, Optional, Sequelize } from "sequelize";
import { primarySequelize } from "../sequelize";
import UserChannel from "./UserChannel";

// Define the attributes of the model
interface UserProfileAttributes {
  id?: string;
  userId: string;
  username?: string;
  profile_pic?: string;
  password?: string;
  status?: string;
  role_id: number;
  last_message_id?: number;
  isOnline: boolean;
  device_id?: string;
  device_token?: string;
  platform?: string;
  last_login?: Date;
  channelId?:string;
}

// Define the creation attributes (optional attributes for creating a new instance)
interface UserProfileCreationAttributes
  extends Optional<UserProfileAttributes, "userId"> {}

export class UserProfile
  extends Model<UserProfileAttributes, UserProfileCreationAttributes>
  implements UserProfileAttributes
{
  public id!: string;
  public userId!: string;
  public username?: string;
  public profile_pic?: string;
  public password?: string;
  public status?: string;
  public role_id!: number;
  public last_message_id?: number;
  public isOnline!: boolean;
  public device_id?: string;
  public device_token?: string;
  public platform?: string;
  public last_login?: Date;
  public channelId?: string;

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;

  // Define associations here (if needed)
  public static associate(models: any) {
    UserProfile.belongsTo(models.User, { foreignKey: "userId", as: "user" });
    UserProfile.belongsTo(models.Role, { foreignKey: "role_id", as: "role" });
    UserProfile.hasMany(UserChannel, { foreignKey: 'userProfileId', as: 'userChannels' });

  }
}

UserProfile.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4, // Correct usage
      primaryKey: true,
    },

    userId: {
      type: DataTypes.UUID,
      allowNull: false,
      primaryKey: true,
    },
    username: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    profile_pic: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    password: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    status: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    role_id: {
      type: DataTypes.UUID,
      allowNull: false,
    },
    last_message_id: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },
    isOnline: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    },
    device_id: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    device_token: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    platform: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    last_login: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    channelId: {
      type: DataTypes.UUID,
      allowNull: true,
      references: {
        model: 'channels', // Adjust based on your table name
        key: 'id',
      },
    },
  },
  {
    sequelize: primarySequelize,
    modelName: "UserProfile",
    tableName: "user_profiles",
    timestamps: true,
  }
);
