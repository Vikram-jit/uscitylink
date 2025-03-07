import { Router } from 'express';
import { authMiddleware } from '../../middleware/authMiddleware';
import { deletedByUserId, getChatMessageUser, getMessagesByUserId, messageToGroup } from '../../controllers/staff/chatController';

const router = Router(); 

router.get('/message/:id/:channelId',authMiddleware, getMessagesByUserId);
router.post('/messageToGroup', messageToGroup);
router.delete('/message/:id',authMiddleware, deletedByUserId);

export default router