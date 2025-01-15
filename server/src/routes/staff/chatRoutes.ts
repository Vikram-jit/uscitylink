import { Router } from 'express';
import { authMiddleware } from '../../middleware/authMiddleware';
import { deletedByUserId, getChatMessageUser, getMessagesByUserId } from '../../controllers/staff/chatController';

const router = Router(); 

router.get('/message/:id',authMiddleware, getMessagesByUserId);
router.delete('/message/:id',authMiddleware, deletedByUserId);

export default router