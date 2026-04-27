import { Router } from 'express';
import { authMiddleware } from '../middleware/authMiddleware';
import { getMessagesV2, quickMessage } from '../controllers/messageV2Controller';



const router = Router();


router.get('/:channelId',authMiddleware, getMessagesV2);
router.post('/send-message', quickMessage);

export default router;
