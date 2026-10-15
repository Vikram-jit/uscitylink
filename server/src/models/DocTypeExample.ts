import { Model, DataTypes } from "sequelize";
import { primarySequelize } from "../sequelize";
import { jsonGetter } from "./jsonColumn";
import { DocType } from "./DocType";

export class DocTypeExample extends Model {
  public id!: string;
  public doc_type_id!: string;
  public s3_key!: string;
  public expected_fields!: Record<string, any>;
  public source!: "upload" | "correction";
  public active!: boolean;
  public created_by?: string | null;

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;
}

DocTypeExample.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    doc_type_id: {
      type: DataTypes.UUID,
      allowNull: false,
    },
    s3_key: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    expected_fields: {
      type: DataTypes.JSON,
      get: jsonGetter("expected_fields"),
      allowNull: false,
      defaultValue: {},
    },
    source: {
      type: DataTypes.STRING(16),
      allowNull: false,
      defaultValue: "upload",
    },
    active: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
    },
    created_by: {
      type: DataTypes.UUID,
      allowNull: true,
    },
  },
  {
    sequelize: primarySequelize,
    modelName: "DocTypeExample",
    tableName: "doc_type_examples",
    timestamps: true,
  }
);

DocType.hasMany(DocTypeExample, { foreignKey: "doc_type_id", as: "examples" });
DocTypeExample.belongsTo(DocType, { foreignKey: "doc_type_id", as: "docType" });
