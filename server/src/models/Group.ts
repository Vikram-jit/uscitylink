import { Model, DataTypes, Optional } from "sequelize";
import { primarySequelize } from "../sequelize";

// Define attributes for the Role model
export interface GroupAttributes {
  id?: string; // Assuming you have an auto-incremented primary key
  name: string;
  description?: string;
  createdAt?: Date;
  updatedAt?: Date;
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
  public createdAt!: Date;
  public updatedAt!: Date;
  public description?: string | undefined;
  static associate(models: any) {
   
  
  }
}

Group.init(
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
    modelName: "Group", // Use a singular model name
    tableName: "groups", // Specify the table name in the database
    timestamps: true, // Automatically manage createdAt and updatedAt fields
  }
);

export default Group;
