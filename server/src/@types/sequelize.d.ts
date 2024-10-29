import { User as SequelizeUser } from '../models/User';
import { Role } from '../models/Role'; // Adjust the path as necessary

declare module '../models/User' {
    interface User extends SequelizeUser {
        addRole(role: Role | Role[]): Promise<void>;
        setRoles(roles: Role[]): Promise<void>;
        removeRole(role: Role | Role[]): Promise<void>;
        getRoles(): Promise<Role[]>;
    }
}
