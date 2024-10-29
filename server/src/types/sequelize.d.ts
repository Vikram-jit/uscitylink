import { User as SequelizeUser } from '../src/models/User';
import { Role } from '../src/models/Role'; // Adjust the path as necessary

declare module '../src/models/User' {
    interface User extends SequelizeUser {
        addRole: (role: Role | Role[]) => Promise<void>;
        setRoles: (roles: Role[]) => Promise<void>;
        removeRole: (role: Role | Role[]) => Promise<void>;
        getRoles: () => Promise<Role[]>;
        // Add other methods you may use
    }
}
