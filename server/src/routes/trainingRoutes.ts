import { Router } from 'express';
import { authMiddleware } from '../middleware/authMiddleware';
import {  uploadAwsMiddleware } from '../controllers/fileController';
import certificateGenate, { addQutionsTrainingVideo, createTraining, getAllTrainings, getAssginDrivers, getTrainingById } from '../controllers/trainingController';



const router = Router();


router.post('/',authMiddleware, uploadAwsMiddleware, createTraining)
router.post('/add-questions/:id',authMiddleware, addQutionsTrainingVideo)
router.get('/',authMiddleware, getAllTrainings)
router.get('/assgin-drivers/:id',authMiddleware, getAssginDrivers)

router.get('/:id',authMiddleware, getTrainingById)



export default router;