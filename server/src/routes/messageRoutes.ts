import { getMessagesByUserId, uploadMiddleware, fileUpload, getMedia, fileUploadWeb, getGroupMessages } from './../controllers/messageController';
import { Router } from 'express';
import { createMessage, getMessages } from '../controllers/messageController';
import { authMiddleware } from '../middleware/authMiddleware';



const router = Router();

router.post('/', createMessage);
router.post('/fileUpload',authMiddleware, uploadMiddleware, fileUpload)
router.post('/fileUploadWeb',authMiddleware, uploadMiddleware, fileUploadWeb)
router.get('/media/:channelId',authMiddleware,  getMedia)
router.get('/byUserId/:id',authMiddleware, getMessagesByUserId);
router.get('/:channelId',authMiddleware, getMessages);
router.get('/:channelId/:groupId',authMiddleware, getGroupMessages);


export default router;
