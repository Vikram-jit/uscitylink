import {
  Model,
  DataTypes,
  Optional,
  Sequelize,
} from "sequelize";
import { primarySequelize } from "../sequelize";

export interface BroadcastMessageLogAttributes {
  id: string;
  body?: string | null;
  url?: string | null;
  totalMessages?: number;
    sentMessages?: number;
  createdAt?: Date;
  updatedAt?: Date;
}

export type BroadcastMessageLogCreationAttributes =
  Optional<
    BroadcastMessageLogAttributes,
    "id" | "createdAt" | "updatedAt"
  >;

export class BroadcastMessageLog
  extends Model<
    BroadcastMessageLogAttributes,
    BroadcastMessageLogCreationAttributes
  >
  implements BroadcastMessageLogAttributes
{
  public id!: string;
  public body!: string | null;
  public url!: string | null;
    public totalMessages!: number;
    public sentMessages!: number;

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;

  static initModel(sequelize: Sequelize): typeof BroadcastMessageLog {
    BroadcastMessageLog.init(
      {
        id: {
          type: DataTypes.UUID,
          defaultValue: DataTypes.UUIDV4,
          primaryKey: true,
        },
        body: {
          type: DataTypes.TEXT,
          allowNull: true,
        },
        url: {
          type: DataTypes.TEXT,
          allowNull: true,
        },
        totalMessages: {
          type: DataTypes.BIGINT,
          allowNull: false,
          defaultValue: 0,
        },
        sentMessages: {
          type: DataTypes.BIGINT,
          allowNull: false,
          defaultValue: 0,
        },  
      },
      {
        sequelize:primarySequelize,
        tableName: "broadcast_message_logs",
        modelName: "BroadcastMessageLog",
        timestamps: true,
      }
    );

    return BroadcastMessageLog;
  }
}

BroadcastMessageLog.initModel(primarySequelize);