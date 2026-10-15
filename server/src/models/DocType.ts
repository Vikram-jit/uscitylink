import { Model, DataTypes } from "sequelize";
import { primarySequelize } from "../sequelize";
import { jsonGetter } from "./jsonColumn";

export type DocFieldType = "string" | "number" | "date" | "boolean";

export interface DocField {
  key: string;
  label: string;
  type: DocFieldType;
  description?: string;
  required?: boolean;
}

export class DocType extends Model {
  public id!: string;
  public key!: string;
  public name!: string;
  public description?: string | null;
  public identify_hints?: string | null;
  public fields!: DocField[];
  public keywords?: string[] | null;
  public active!: boolean;
  public version!: number;

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;
}

DocType.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    key: {
      type: DataTypes.STRING(64),
      allowNull: false,
      unique: true,
    },
    name: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    identify_hints: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    fields: {
      type: DataTypes.JSON,
      get: jsonGetter("fields"),
      allowNull: false,
      defaultValue: [],
    },
    keywords: {
      type: DataTypes.JSON,
      get: jsonGetter("keywords"),
      allowNull: true,
    },
    active: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
    },
    version: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 1,
    },
  },
  {
    sequelize: primarySequelize,
    modelName: "DocType",
    tableName: "doc_types",
    timestamps: true,
  }
);
