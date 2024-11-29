import { Model, DataTypes } from "sequelize";
import { primarySequelize } from "../sequelize";

class GroupUser extends Model {
  public id!: string;
  public groupId!: string;
  public userProfileId!: string;
  public status?: string;
  public last_message_id?: string;
  public message_count?: number;
  public last_message_utc?:Date

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
    last_message_id: {
      type: DataTypes.UUID,
      allowNull: true,
      references: {
        model: 'messages', 
        key: 'id',
      },
    },
    message_count: {
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
    modelName: "GroupUser",
    tableName: "group_users",
  }
);

export default GroupUser;
