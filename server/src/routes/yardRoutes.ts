import { Router } from 'express';

import { authMiddleware } from '../middleware/authMiddleware';
import { getById, getTrucks } from '../controllers/truckController';

const router = Router();


router.get('/trucks',authMiddleware, getTrucks);
router.get('/:id',authMiddleware, getById);


export default router;
