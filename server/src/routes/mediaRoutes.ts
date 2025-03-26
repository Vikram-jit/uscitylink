import { Router } from 'express';
import {  fileUploadByQueue, getMedia, uploadLocal } from '../controllers/messageController';
import { authMiddleware } from '../middleware/authMiddleware';
import { convertImageAndDownload, convertImageToPDFAndDownload } from '../controllers/fileController';



const router = Router();

router.get('/convertAndDownload/:fileName',authMiddleware,  convertImageAndDownload)
router.get('/convertAndDownloadPdf/:fileName',authMiddleware,  convertImageToPDFAndDownload)
router.post('/uploadFileQueue',uploadLocal.array('files'), authMiddleware, fileUploadByQueue)



router.get('/:channelId',authMiddleware,  getMedia)

export default router;
