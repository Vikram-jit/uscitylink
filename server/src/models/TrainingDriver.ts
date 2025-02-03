import { Model, DataTypes, BelongsToGetAssociationMixin } from "sequelize";
import { primarySequelize } from "../sequelize";
import { UserProfile } from "./UserProfile";

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
    questionId: {
      type: DataTypes.UUID,
      allowNull: true,
      references: {
        model: "questions",
        key: "id",
      },
    },
    selectedOptionId: {
        type: DataTypes.UUID,
        allowNull: true,
        references: {
          model: "question_options",
          key: "id",
        },
      },
  },
  {
    sequelize: primarySequelize,
    modelName: "TrainingDriver",
    tableName: "training_drivers",
    timestamps: true,
  }
);
