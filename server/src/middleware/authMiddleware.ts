import { Request, Response, NextFunction } from 'express';
import { verifyToken } from '../utils/jwt';

export const authMiddleware = (req: Request, res: Response, next: NextFunction): any => {
    const token = req.headers.authorization?.split(' ')[1];

    if (!token) {
        return res.status(403).json({ message: 'No token provided' });
    }

    try {
        const decoded = verifyToken(token);
        req.userId = (decoded as any).id; // Attach user ID to the request
        next();
    } catch (error) {
        return res.status(401).json({ message: 'Unauthorized' });
    }
};
