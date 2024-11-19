import { Router } from 'express';
import {  getMedia } from '../controllers/messageController';
import { authMiddleware } from '../middleware/authMiddleware';



const router = Router();


router.get('/:channelId',authMiddleware,  getMedia)



export default router;
