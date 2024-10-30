import { Model, DataTypes } from "sequelize";
import { primarySequelize } from "../sequelize";

class GroupChannel extends Model {
  public id!: string;
  public groupId!: string;
  public channelId!: string;

  static associate(models: any) {
       GroupChannel.belongsTo(models.Group, { foreignKey: 'groupId' });
       GroupChannel.belongsTo(models.Channel, { foreignKey: 'channelId' });
  }
}

GroupChannel.init(
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
    channelId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'channels', // Adjust based on your table name
        key: 'id',
      },
    },
  },
  {
    sequelize: primarySequelize,
    modelName: "GroupChannel",
    tableName: "group_channels",
  }
);

export default GroupChannel;
