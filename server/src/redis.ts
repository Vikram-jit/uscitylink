import { createClient } from 'redis';
import dotenv from 'dotenv';
dotenv.config();
export const redisHost =
  process.env.DB_SERVER === 'local' ? '127.0.0.1' : (process.env.REDIS_HOST || '127.0.0.1');
export const redisPort = Number(process.env.REDIS_PORT) || 6379;
export const redisPassword = process.env.REDIS_PASSWORD;

const redisUrl = redisPassword
    ? `redis://:${redisPassword}@${redisHost}:${redisPort}`
    : `redis://${redisHost}:${redisPort}`;

const redisClient = createClient({
    url: redisUrl,
});

redisClient.on('error', (err) => {
    console.error('Redis Client Error', err);
});

const connectRedis = async () => {
    await redisClient.connect();
    console.log('Connected to Redis');
};

export { redisClient, connectRedis };