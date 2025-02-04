import { Model, DataTypes, BelongsToGetAssociationMixin } from "sequelize";
import { primarySequelize } from "../sequelize";
import { UserProfile } from "./UserProfile";
import { Training } from "./Training";
import { QuestionOption } from "./QuestionOption";
import { TrainingDriver } from "./TrainingDriver";

export class Question extends Model {
  public id!: string; // Primary key
  public tainingId?: string;
  public question?: string;

  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;

  static associate(models: any) {
    Question.belongsTo(models.Training, {
      foreignKey: "tainingId", // This must match the foreign key in the Question model
      as: "training", // Alias for the association
    });
  }
}

Question.init(
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

    question: {
      type: DataTypes.TEXT("long"),
      allowNull: true,
    },
  },
  {
    sequelize: primarySequelize,
    modelName: "Question",
    tableName: "questions",
    timestamps: true,
  }
);
Training.hasMany(Question, {
  foreignKey: "tainingId", // This is the key in the Question model
  as: "questions", // Alias to refer to the association
});



TrainingDriver.belongsTo(Training, {
  foreignKey: "tainingId",
  as: "training",
});

Question.belongsTo(Training, {
  foreignKey: "tainingId",
  as: "training",
});

Question.hasMany(QuestionOption, {
  foreignKey: "questionId",
  as: "options",
});

//   QuestionOption.hasMany(Question, {
//     foreignKey: 'questionId',
//     as: 'question_options',
//   });
