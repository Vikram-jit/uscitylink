import { Router } from 'express';
import {  getMedia } from '../controllers/messageController';
import { authMiddleware } from '../middleware/authMiddleware';
import { convertImageAndDownload, convertImageToPDFAndDownload } from '../controllers/fileController';



const router = Router();

router.get('/convertAndDownload/:fileName',authMiddleware,  convertImageAndDownload)
router.get('/convertAndDownloadPdf/:fileName',authMiddleware,  convertImageToPDFAndDownload)



router.get('/:channelId',authMiddleware,  getMedia)

export default router;
