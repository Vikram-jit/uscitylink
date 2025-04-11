import { Router } from 'express';
import { authMiddleware } from '../middleware/authMiddleware';
import { getMessagesV2 } from '../controllers/messageV2Controller';



const router = Router();


router.get('/:channelId',authMiddleware, getMessagesV2);

export default router;
