import { Model, DataTypes } from "sequelize";
import { primarySequelize } from "../sequelize";

// Physical data for a tractor or trailer that a CAT ticket cannot show: axle layout (for the bridge
// formula), kingpin-to-rear-axle (KPRA), tandem holes, axle/tire ratings and the measured weight
// shift per tandem hole. unit_number matches the truck/trailer number on the ticket or in the yard.
export class EquipmentProfile extends Model {
  public id!: string;
  public kind!: "tractor" | "trailer";
  public unit_number!: string;
  public axle_count?: number | null;
  public steer_to_drive_center_ft?: number | null;
  public drive_spread_ft?: number | null;
  public kingpin_to_drive_center_ft?: number | null;
  public fifth_wheel_range_in?: number | null;
  public kpra_ft?: number | null;
  public trailer_spread_ft?: number | null;
  public length_ft?: number | null;
  public hole_spacing_in?: number | null;
  public holes_forward_available?: number | null;
  public holes_back_available?: number | null;
  public steer_rating_lb?: number | null;
  public drive_rating_lb?: number | null;
  public trailer_rating_lb?: number | null;
  public gvwr_lb?: number | null;
  public lb_per_hole?: number | null;
  public lb_per_hole_samples!: number;
  public notes?: string | null;
  public active!: boolean;
  public updated_by?: string | null;

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;
}

// A fresh object per column: Sequelize writes the column name into the definition it is given
const num = () => ({ type: DataTypes.FLOAT, allowNull: true });
const int = () => ({ type: DataTypes.INTEGER, allowNull: true });

EquipmentProfile.init(
  {
    id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
    kind: { type: DataTypes.STRING(16), allowNull: false },
    unit_number: { type: DataTypes.STRING(64), allowNull: false },
    axle_count: int(),
    steer_to_drive_center_ft: num(),
    drive_spread_ft: num(),
    kingpin_to_drive_center_ft: num(),
    fifth_wheel_range_in: num(),
    kpra_ft: num(),
    trailer_spread_ft: num(),
    length_ft: num(),
    hole_spacing_in: num(),
    holes_forward_available: int(),
    holes_back_available: int(),
    steer_rating_lb: int(),
    drive_rating_lb: int(),
    trailer_rating_lb: int(),
    gvwr_lb: int(),
    lb_per_hole: num(),
    lb_per_hole_samples: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 },
    notes: { type: DataTypes.TEXT, allowNull: true },
    active: { type: DataTypes.BOOLEAN, allowNull: false, defaultValue: true },
    updated_by: { type: DataTypes.UUID, allowNull: true },
  },
  { sequelize: primarySequelize, modelName: "EquipmentProfile", tableName: "equipment_profiles", timestamps: true },
);
