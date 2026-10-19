import { Model, DataTypes } from "sequelize";
import { primarySequelize } from "../sequelize";
import { jsonGetter } from "./jsonColumn";

export type FlowTrigger = "document_analyzed" | "attachment_received";

export interface FlowBranch {
  name?: string;
  conditions: any;
  actions: any[];
}

export class Flow extends Model {
  public id!: string;
  public name!: string;
  public description?: string | null;
  public trigger!: FlowTrigger;
  public priority!: number;
  public active!: boolean;
  public shadow_mode!: boolean;
  public conditions!: any;
  public actions!: any[];
  public else_actions?: any[] | null;
  // ELSE IF branches, checked in order when IF does not match: [{ name, conditions, actions }]
  public else_if?: FlowBranch[] | null;
  public cooldown_minutes!: number;
  public stop_on_match!: boolean;
  public created_by?: string | null;
  public updated_by?: string | null;

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;
}

Flow.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    name: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    trigger: {
      type: DataTypes.STRING(32),
      allowNull: false,
      defaultValue: "document_analyzed",
    },
    priority: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 100,
    },
    active: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    },
    shadow_mode: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: true,
    },
    conditions: {
      type: DataTypes.JSON,
      get: jsonGetter("conditions"),
      allowNull: false,
    },
    actions: {
      type: DataTypes.JSON,
      get: jsonGetter("actions"),
      allowNull: false,
      defaultValue: [],
    },
    else_actions: {
      type: DataTypes.JSON,
      get: jsonGetter("else_actions"),
      allowNull: true,
    },
    else_if: {
      type: DataTypes.JSON,
      get: jsonGetter("else_if"),
      allowNull: true,
    },
    cooldown_minutes: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 0,
    },
    stop_on_match: {
      type: DataTypes.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    },
    created_by: {
      type: DataTypes.UUID,
      allowNull: true,
    },
    updated_by: {
      type: DataTypes.UUID,
      allowNull: true,
    },
  },
  {
    sequelize: primarySequelize,
    modelName: "Flow",
    tableName: "flows",
    timestamps: true,
  }
);
