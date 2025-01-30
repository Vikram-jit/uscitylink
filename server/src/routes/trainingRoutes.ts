import { Router } from 'express';
import { authMiddleware } from '../middleware/authMiddleware';
import {  uploadAwsMiddleware } from '../controllers/fileController';
import { createTraining, getTrainingById } from '../controllers/trainingController';



const router = Router();


router.post('/',authMiddleware, uploadAwsMiddleware, createTraining)
router.get('/:id',authMiddleware, getTrainingById)



export default router;