import jwt from 'jsonwebtoken';
import dotEnv from 'dotenv'

dotEnv?.config()

export const generateToken = (userId: string): string => {
    return jwt.sign({ id: userId }, process.env.JWT_SECRET!, { expiresIn: '2y' });
};

export const verifyToken = (token: string) => {
    return jwt.verify(token, process.env.JWT_SECRET!);
};
