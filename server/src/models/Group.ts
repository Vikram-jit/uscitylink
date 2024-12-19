import { Model, DataTypes, Optional } from "sequelize";
import { primarySequelize } from "../sequelize";

// Define attributes for the Role model
export interface GroupAttributes {
  id?: string; // Assuming you have an auto-incremented primary key
  name: string;
  type?: string;
  description?: string;
  createdAt?: Date;
  updatedAt?: Date;
  last_message_id?: string;
  message_count?: number;
}

// Define optional attributes for creation
interface GroupCreationAttributes
  extends Optional<GroupAttributes, "id" | "createdAt" | "updatedAt"> {}

class Group
  extends Model<GroupAttributes, GroupCreationAttributes>
  implements GroupAttributes
{
  public id!: string; // Assuming you have an auto-incremented primary key
  public name!: string;
  public type?: string;
  public createdAt!: Date;
  public updatedAt!: Date;
  public description?: string | undefined;
  public last_message_id?: string;
  public message_count?: number;
  static associate(models: any) {
    Group.hasOne(models.GroupChannel, {
      foreignKey: "groupId",
      as: "group_channel",
    });
    Group.hasMany(models.GroupUser, {
      foreignKey: "groupId",
      as: "group_users",
    });
    
  }
}

Group.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
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
    type: {
      type: DataTypes.ENUM,
      values: ["group", "truck"], // Enum values
      defaultValue: "group",
    },

    last_message_id: {
      type: DataTypes.UUID,
      allowNull: true,
      references: {
        model: "messages",
        key: "id",
      },
    },
    message_count: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
    },
  },
  {
    sequelize: primarySequelize,
    modelName: "Group", // Use a singular model name
    tableName: "groups", // Specify the table name in the database
    timestamps: true, // Automatically manage createdAt and updatedAt fields
  }
);

export default Group;
