import { Router } from 'express';
import { sendMessage } from '../controllers/socketController';
import { authMiddleware } from '../middleware/authMiddleware';

const router = Router();

router.post('/send-message', authMiddleware, sendMessage);

export default router;
