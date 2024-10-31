import { Router } from 'express';
import {   getMembers, userAddToChannel } from '../controllers/channelController';
import { authMiddleware } from '../middleware/authMiddleware';

const router = Router();


router.get('/',authMiddleware, getMembers);
router.post('/addToChannel',userAddToChannel)

export default router;
