import { Router } from 'express';
import { authMiddleware } from '../../middleware/authMiddleware';
import { getChatMessageUser, getMessagesByUserId } from '../../controllers/staff/chatController';

const router = Router(); 

router.get('/message/:id',authMiddleware, getMessagesByUserId);

export default router