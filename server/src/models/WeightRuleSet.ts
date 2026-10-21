import { Model, DataTypes } from "sequelize";
import { primarySequelize } from "../sequelize";

// Audited, versioned legal weight limits used by the scale agent. Rows are never edited in place:
// a change creates a new version and deactivates the old one, so every scale check can be traced
// to the exact rules it was judged against.
export class WeightRuleSet extends Model {
  public id!: string;
  public jurisdiction!: string;
  public road_class!: string;
  public version!: number;
  public name!: string;
  public single_axle_lb!: number;
  public tandem_lb!: number;
  public gross_lb!: number;
  // Company planning target, not a legal limit
  public steer_target_lb?: number | null;
  public sum_tolerance_lb!: number;
  public min_confidence!: number;
  public citation?: string | null;
  public source_url?: string | null;
  public effective_date?: string | null;
  public reviewed_by?: string | null;
  public notes?: string | null;
  public active!: boolean;
  // Kingpin-to-rearmost-axle limit (e.g. CA 40 ft); null = no KPRA rule
  public kpra_max_ft?: number | null;
  public bridge_formula!: boolean;
  // Sign-off: a rule set counts as verified only once reviewed, and again every review_months
  public review_months!: number;
  public reviewed_at?: Date | null;

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;
}

WeightRuleSet.init(
  {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    jurisdiction: { type: DataTypes.STRING(16), allowNull: false },
    road_class: { type: DataTypes.STRING(32), allowNull: false, defaultValue: "interstate" },
    version: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 1 },
    name: { type: DataTypes.STRING, allowNull: false },
    single_axle_lb: { type: DataTypes.INTEGER, allowNull: false },
    tandem_lb: { type: DataTypes.INTEGER, allowNull: false },
    gross_lb: { type: DataTypes.INTEGER, allowNull: false },
    steer_target_lb: { type: DataTypes.INTEGER, allowNull: true },
    sum_tolerance_lb: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 100 },
    min_confidence: { type: DataTypes.FLOAT, allowNull: false, defaultValue: 0.8 },
    citation: { type: DataTypes.TEXT, allowNull: true },
    source_url: { type: DataTypes.STRING(512), allowNull: true },
    effective_date: { type: DataTypes.DATEONLY, allowNull: true },
    reviewed_by: { type: DataTypes.UUID, allowNull: true },
    notes: { type: DataTypes.TEXT, allowNull: true },
    active: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true },
    kpra_max_ft: { type: DataTypes.FLOAT, allowNull: true },
    bridge_formula: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true },
    review_months: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 12 },
    reviewed_at: { type: DataTypes.DATE, allowNull: true },
  },
  { sequelize: primarySequelize, modelName: "WeightRuleSet", tableName: "weight_rule_sets", timestamps: true },
);
