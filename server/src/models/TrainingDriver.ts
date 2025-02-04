import { Model, DataTypes, BelongsToGetAssociationMixin } from "sequelize";
import { primarySequelize } from "../sequelize";
import { UserProfile } from "./UserProfile";
import { Training } from "./Training";

export class TrainingDriver extends Model {
  public id!: string; // Primary key
  public tainingId?: string;
  public driverId?: string;
  public view_duration?: string;
  public isCompleteWatch?: boolean;
  public questionId?: string;
  public selectedOptionId?: string;

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;
}

TrainingDriver.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    tainingId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: "taining",
        key: "id",
      },
    },
    driverId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: "users",
        key: "id",
      },
    },

    view_duration: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    isCompleteWatch: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
  },
  {
    sequelize: primarySequelize,
    modelName: "TrainingDriver",
    tableName: "training_drivers",
    timestamps: true,
  }
);
Training.hasMany(TrainingDriver, {
  foreignKey: "tainingId", // This is the key in the Question model
  as: "assgin_drivers", // Alias to refer to the association
});

TrainingDriver.belongsTo(UserProfile, {
  foreignKey: "driverId", // This is the key in the Question model
  as: "user_profiles", // Alias to refer to the association
});


