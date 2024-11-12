import { Model, DataTypes,BelongsToGetAssociationMixin } from 'sequelize';
import { primarySequelize } from '../sequelize';
import { UserProfile } from './UserProfile';

export class Message extends Model {
  public id!: string; // Primary key
  public channelId!: string;
  public userProfileId!: string;
  public groupId!: string | null; // Make optional if not always present
  public body!: string;
  public messageDirection!: 'S' | 'R'; // Assuming S for sent, R for received
  public deliveryStatus!: string;
  public messageTimestampUtc!: Date;
  public senderId!: string;
  public isRead!: boolean;
  public status!: string;

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;

  public getSender!: BelongsToGetAssociationMixin<UserProfile>;
}

Message.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    channelId: {
      type: DataTypes.UUID,
      allowNull: false,
    },
    userProfileId: {
      type: DataTypes.UUID,
      allowNull: false,
    },
    groupId: {
      type: DataTypes.UUID,
      allowNull: true,
    },
    body: {
      type: DataTypes.TEXT,
      allowNull: false,
    },
    messageDirection: {
      type: DataTypes.ENUM('S', 'R'),
      allowNull: false,
    },
    deliveryStatus: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    messageTimestampUtc: {
      type: DataTypes.DATE,
      allowNull: false,
    },
    senderId: {
      type: DataTypes.UUID,
      allowNull: false,
    },
    isRead: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    status: {
      type: DataTypes.STRING,
      allowNull: false,
    },
  },
  {
    sequelize:primarySequelize,
    modelName: 'Message',
    tableName: 'messages',
    timestamps: true,
  }
);
Message.belongsTo(UserProfile, { foreignKey: 'senderId', as: 'sender' });
UserProfile.hasMany(Message, { foreignKey: 'senderId', as: 'messages' });
