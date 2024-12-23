import { Model, DataTypes, Optional } from 'sequelize';
import { primarySequelize } from '../sequelize';
import { UserProfile } from './UserProfile';

interface UserAttributes {
  id?: string; 
  email?: string;
  phone_number?: string;
  status?: 'active' | 'inactive' | 'block';
  createdAt?: Date;
  updatedAt?: Date;
  yard_id?:number;
  user_type?:string;
  profiles?: UserProfile[];
  driver_number?:string
}


interface UserCreationAttributes extends Optional<UserAttributes, 'id' | 'createdAt' | 'updatedAt'> {}

class User extends Model<UserAttributes, UserCreationAttributes> implements UserAttributes {
  
  public id!: string; // Assuming you have an auto-incremented primary key
  public email?: string;
  public phone_number?: string;
  public status?: 'active' | 'inactive' | 'block' = 'active';
  public createdAt!: Date;
  public updatedAt!: Date;
  public profiles?: UserProfile[]; // Add this line
  public user_type?: string | undefined;
  public yard_id?: number | undefined;
  public driver_number?: string | undefined;
  static associate(models: any) {
    User.hasMany(models.UserProfile, { foreignKey: 'userId', as: 'profiles' });
  

  }
}

User.init({
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4, // Correct usage
    primaryKey: true,
  },
  phone_number: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  user_type: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  driver_number: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  yard_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
  },
  email: {
    type: DataTypes.STRING,
    allowNull: true,
    unique: true,
    validate: {
      isEmail: true,
    },
  },
  status: {
    type: DataTypes.ENUM('active', 'inactive', 'block'),
    allowNull: false,
    defaultValue: 'active',
  },
}, { 
  sequelize: primarySequelize,
  modelName: 'User', // Use a singular model name
  tableName: 'users', // Specify the table name in the database
  timestamps: true,
});

export default User;
