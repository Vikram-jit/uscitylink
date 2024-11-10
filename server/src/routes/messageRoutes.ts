import { getMessagesByUserId } from './../controllers/messageController';
import { Router } from 'express';
import { createMessage, getMessages } from '../controllers/messageController';
import { authMiddleware } from '../middleware/authMiddleware';

const router = Router();

router.post('/', createMessage);

router.get('/byUserId/:id',authMiddleware, getMessagesByUserId);
router.get('/:channelId',authMiddleware, getMessages);


export default router;
