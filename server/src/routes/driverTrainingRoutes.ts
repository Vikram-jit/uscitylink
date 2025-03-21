import { Router } from 'express';
import { authMiddleware } from '../middleware/authMiddleware';
import {  uploadAwsMiddleware } from '../controllers/fileController';
import certificateGenate, { getAssginVideos, getTrainingQuestions, quizAnswerSubmit, updateVideoStatusWithDuration } from '../controllers/trainingController';



const router = Router();

router.get('/',authMiddleware, getAssginVideos)
router.get('/training-questions/:id',authMiddleware, getTrainingQuestions)
router.get('/training-certificate/:id', certificateGenate)
router.post('/quiz-submit/:id',authMiddleware, quizAnswerSubmit)
router.put('/update-duration/:id',authMiddleware, updateVideoStatusWithDuration)


export default router;