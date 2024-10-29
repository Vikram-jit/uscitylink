import { createClient } from 'redis';

const redisClient = createClient({
    url: 'redis://localhost:6379', // Adjust if your Redis server runs on a different host or port
});

redisClient.on('error', (err) => {
    console.error('Redis Client Error', err);
});

const connectRedis = async () => {
    await redisClient.connect();
    console.log('Connected to Redis');
};

export { redisClient, connectRedis };
