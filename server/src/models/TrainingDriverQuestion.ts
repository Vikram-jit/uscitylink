import { Model, DataTypes, BelongsToGetAssociationMixin } from "sequelize";
import { primarySequelize } from "../sequelize";
import { UserProfile } from "./UserProfile";
import { Training } from "./Training";

export class TrainingDriverQuestions extends Model {
  public id!: string; 
  public tainingId?: string;
  public driverId?: string;
  public questionId?: string;
  public selectedOptionId?: string;
  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;
}

TrainingDriverQuestions.init(
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
    questionId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: "questions",
        key: "id",
      },
    },
    selectedOptionId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: "question_options",
        key: "id",
      },
    },
  },
  {
    sequelize: primarySequelize,
    modelName: "TrainingDriverQuestions",
    tableName: "training_driver_questions",
    timestamps: true,
  }
);
