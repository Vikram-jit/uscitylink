import { Model, DataTypes, Optional } from "sequelize";
import { primarySequelize } from "../sequelize";
import UserChannel from "./UserChannel";
import User from "./User";

// Define attributes for the Role model
export interface ChannelAttributes {
  id?: string; // Assuming you have an auto-incremented primary key
  name: string;
  description?: string;
  createdAt?: Date;
  updatedAt?: Date;
}

// Define optional attributes for creation
interface ChannelCreationAttributes
  extends Optional<ChannelAttributes, "id" | "createdAt" | "updatedAt"> {}

class Channel
  extends Model<ChannelAttributes, ChannelCreationAttributes>
  implements ChannelAttributes
{
  public id!: string; // Assuming you have an auto-incremented primary key
  public name!: string;
  public createdAt!: Date;
  public updatedAt!: Date;
  public description?: string | undefined;
  static associate(models: any) {
    //Channel.belongsToMany(models.UserProfile, { through: models.UserChannel, foreignKey: 'channelId' });
    Channel.hasMany(models.UserChannel, { foreignKey: 'channelId', as: 'user_channels' });
    Channel.hasMany(models.GroupChannel, { foreignKey: 'channelId', as: 'group_channels' });
  }
}

Channel.init(
  {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4, // Correct usage
        primaryKey: true,
      },
    name: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true, 
    },
    description: {
        type: DataTypes.STRING,
        allowNull: false,
        unique: true, 
      },
  },
  {
    sequelize: primarySequelize,
    modelName: "Channel", // Use a singular model name
    tableName: "channels", // Specify the table name in the database
    timestamps: true, // Automatically manage createdAt and updatedAt fields
  }
);

export default Channel;
