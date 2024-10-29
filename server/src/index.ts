import express from 'express';
import http from 'http';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import { initSocket } from './sockets/socket';
import authRoutes from './routes/authRoutes';
import { primarySequelize, secondarySequelize } from './sequelize';
import { connectRedis } from './redis';
import User from './models/User';
import { UserProfile } from './models/UserProfile';
import Role from './models/Role';
import userRoutes from './routes/userRoutes';
import channelRoutes from './routes/channelRoutes';

dotenv.config();

const app = express();
const server = http.createServer(app);
initSocket(server);

app.use(cors());
app.use(helmet());
app.use(express.json());

// Basic route
app.get('/', (req, res) => {
    res.send('Hello World!');
});

// Use authentication routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/user', userRoutes );
app.use('/api/v1/channel', channelRoutes );
// app.use('/api', socketRoutes);

// Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, async() => {

    await primarySequelize.authenticate();
    console.log('Connected to primary database.');

    await secondarySequelize.authenticate();
    console.log('Connected to secondary database.');

    await connectRedis();

    // Sync both databases
    await primarySequelize.sync(); // Use { force: false } to avoid dropping tables
    console.log('Primary database & tables synced!');

    await secondarySequelize.sync(); // Use { force: false } to avoid dropping tables

    User.associate({ UserProfile });
    UserProfile.associate({ User, Role });
    Role.associate({ UserProfile });
    
    console.log('Secondary database & tables synced!');
    console.log(`Server is running on port ${PORT}`);
});
