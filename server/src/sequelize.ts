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
        // daily_vehicle_entries.created_at is a TIMESTAMP column, which MySQL
        // converts based on the session time_zone. Sequelize defaults to
        // '+00:00' and would otherwise shift every read away from the
        // server's own SYSTEM timezone that the yard system writes in.
        keepDefaultTimezone: true,
    } as any
);

export { primarySequelize, secondarySequelize };
