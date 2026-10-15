import { Model, DataTypes } from "sequelize";
import { primarySequelize } from "../sequelize";
import { jsonGetter } from "./jsonColumn";
import { Message } from "./Message";

export type MessageDocumentStatus = "pending" | "done" | "failed" | "skipped";

export class MessageDocument extends Model {
  public id!: string;
  public message_id!: string;
  public media_key?: string | null;
  public status!: MessageDocumentStatus;
  public doc_type_key?: string | null;
  public confidence?: number | null;
  public image_quality?: "good" | "poor" | "unreadable" | null;
  public fields?: Record<string, any> | null;
  public notes?: string | null;
  public tags?: string[] | null;
  public text_found?: string[] | null;
  public classified_by?: string | null;
  public matched_keywords?: string[] | null;
  public error?: string | null;
  public model?: string | null;
  public input_tokens?: number | null;
  public output_tokens?: number | null;
  public latency_ms?: number | null;
  public corrected_by?: string | null;
  public corrected_doc_type?: string | null;
  public corrected_fields?: Record<string, any> | null;

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;
}

MessageDocument.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    message_id: {
      type: DataTypes.UUID,
      allowNull: false,
      unique: true,
    },
    media_key: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    status: {
      type: DataTypes.STRING(16),
      allowNull: false,
      defaultValue: "pending",
    },
    doc_type_key: {
      type: DataTypes.STRING(64),
      allowNull: true,
    },
    confidence: {
      type: DataTypes.FLOAT,
      allowNull: true,
    },
    image_quality: {
      type: DataTypes.STRING(16),
      allowNull: true,
    },
    fields: {
      type: DataTypes.JSON,
      get: jsonGetter("fields"),
      allowNull: true,
    },
    notes: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    tags: {
      type: DataTypes.JSON,
      get: jsonGetter("tags"),
      allowNull: true,
    },
    text_found: {
      type: DataTypes.JSON,
      get: jsonGetter("text_found"),
      allowNull: true,
    },
    classified_by: {
      type: DataTypes.STRING(16),
      allowNull: true,
    },
    matched_keywords: {
      type: DataTypes.JSON,
      get: jsonGetter("matched_keywords"),
      allowNull: true,
    },
    error: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    model: {
      type: DataTypes.STRING(64),
      allowNull: true,
    },
    input_tokens: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },
    output_tokens: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },
    latency_ms: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },
    corrected_by: {
      type: DataTypes.UUID,
      allowNull: true,
    },
    corrected_doc_type: {
      type: DataTypes.STRING(64),
      allowNull: true,
    },
    corrected_fields: {
      type: DataTypes.JSON,
      get: jsonGetter("corrected_fields"),
      allowNull: true,
    },
  },
  {
    sequelize: primarySequelize,
    modelName: "MessageDocument",
    tableName: "message_documents",
    timestamps: true,
  }
);

MessageDocument.belongsTo(Message, { foreignKey: "message_id", as: "message" });
Message.hasOne(MessageDocument, { foreignKey: "message_id", as: "document" });
