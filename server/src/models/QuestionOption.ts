import { Model, DataTypes, BelongsToGetAssociationMixin } from "sequelize";
import { primarySequelize } from "../sequelize";
import { UserProfile } from "./UserProfile";

export class QuestionOption extends Model {
  public id!: string; // Primary key
  public questionId?: string;
  public options?: string;
  public isCorrect?: boolean;

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;
}

QuestionOption.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    questionId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: "questions",
        key: "id",
      },
    },

    option: {
      type: DataTypes.TEXT("long"),
      allowNull: false,
    },
    isCorrect: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
  },
  {
    sequelize: primarySequelize,
    modelName: "QuestionOption",
    tableName: "question_options",
    timestamps: true,
  }
);
