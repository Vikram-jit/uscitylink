import { DataTypes, Model } from "sequelize";
import { primarySequelize } from "../sequelize";

class OTP extends Model {
  public id!: number;
  public user_email?: string;
  public phone_number?: string;
  public otp!: string;
  public expires_at!: Date;
  public createdAt!: Date;
  public updatedAt!: Date;
}

OTP.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    user_email: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    phone_number: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    otp: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    expires_at: {
      type: DataTypes.DATE,
      allowNull: false,
    },
  },
  {
    sequelize: primarySequelize,
    modelName: "OTP",
    tableName: "otps",
    timestamps: true,
  }
);

export default OTP;
