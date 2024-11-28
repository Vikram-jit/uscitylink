import { Model, DataTypes } from "sequelize";
import { primarySequelize } from "../sequelize";

class GroupUser extends Model {
  public id!: string;
  public groupId!: string;
  public userProfileId!: string;
  public status?: string;

  static associate(models: any) {
      GroupUser.belongsTo(models.Group, { foreignKey: 'groupId' });
      GroupUser.belongsTo(models.UserProfile, { foreignKey: 'userProfileId' });
  }
}

GroupUser.init(
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
        model: 'groups', // Adjust based on your table name
        key: 'id',
      },
    },
    userProfileId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'user_profiles', // Adjust based on your table name
        key: 'id',
      },
    },
    status: {
      type: DataTypes.ENUM,
      values: ['active', 'inactive'],  // Enum values
    defaultValue: 'active',  
    },
  },
  {
    sequelize: primarySequelize,
    modelName: "GroupUser",
    tableName: "group_users",
  }
);

export default GroupUser;
