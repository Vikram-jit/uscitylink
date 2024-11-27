import { Router } from 'express';

import { authMiddleware } from '../middleware/authMiddleware';
import { getTrucks } from '../controllers/truckController';

const router = Router();


router.get('/trucks',authMiddleware, getTrucks);


export default router;
