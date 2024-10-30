import { Router } from 'express';
import { createMessage, getMessages } from '../controllers/messageController';

const router = Router();

router.post('/', createMessage);
 router.get('/:channelId/:userProfileId', getMessages);



export default router;
