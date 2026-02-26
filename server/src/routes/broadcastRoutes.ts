import { Router } from 'express';
import { processBroadcastJobs } from '../controllers/broadcastController';

const router = Router();


router.get('/', processBroadcastJobs);

export default router;
