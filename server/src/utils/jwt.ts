import jwt from 'jsonwebtoken';

export const generateToken = (userId: string): string => {
    return jwt.sign({ id: userId }, process.env.JWT_SECRET!, { expiresIn: '1h' });
};

export const verifyToken = (token: string) => {
    return jwt.verify(token, process.env.JWT_SECRET!);
};
