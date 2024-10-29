import { Model, DataTypes, Optional } from 'sequelize';
import { primarySequelize } from '../sequelize';
import { UserProfile } from './UserProfile';


// Define attributes for the Role model
export interface RoleAttributes {
  id?: number; // Assuming you have an auto-incremented primary key
  name: string;
  createdAt?: Date;
  updatedAt?: Date;
}

// Define optional attributes for creation
interface RoleCreationAttributes extends Optional<RoleAttributes, 'id' | 'createdAt' | 'updatedAt'> {}

class Role extends Model<RoleAttributes, RoleCreationAttributes> implements RoleAttributes {
  public id!: number; // Assuming you have an auto-incremented primary key
  public name!: string;
  public createdAt!: Date;
  public updatedAt!: Date;

  static associate(models: any) {
    Role.hasMany(models.UserProfile, { foreignKey: 'role_id', as: 'profiles' });
  }
}

Role.init({
  name: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true, // Ensure unique role names
  },
}, { 
  sequelize: primarySequelize,
  modelName: 'Role', // Use a singular model name
  tableName: 'roles', // Specify the table name in the database
  timestamps: true, // Automatically manage createdAt and updatedAt fields
});

export default Role;
