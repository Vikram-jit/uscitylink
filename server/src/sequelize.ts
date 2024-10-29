import { Sequelize } from 'sequelize';
import dotConfig from 'dotenv'

dotConfig.config()

// Primary database
const primarySequelize = new Sequelize(
    process.env.DB_PRIMARY_NAME || 'default_primary_db', // Database name
    process.env.DB_PRIMARY_USER || 'root',          // Username
    process.env.DB_PRIMARY_PASSWORD || '',      // Password
    {
        host: process.env.DB_PRIMARY_HOST || '', // Host
        dialect: 'mysql',
    }
);

// Secondary database
const secondarySequelize = new Sequelize(
    process.env.DB_SECONDARY_NAME || 'default_secondary_db', // Database name
    process.env.DB_SECONDARY_USER || 'root',             // Username
    process.env.DB_SECONDARY_PASSWORD || '',         // Password
    {
        host: process.env.DB_SECONDARY_HOST || 'localhost', // Host
        dialect: 'mysql',
    }
);

export { primarySequelize, secondarySequelize };
