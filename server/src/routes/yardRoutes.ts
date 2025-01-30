import { Router } from 'express';

import { authMiddleware } from '../middleware/authMiddleware';
import { getById, getTruckList, getTrucks } from '../controllers/truckController';
import pdfGernate from '../controllers/yardController';

const router = Router();


router.get('/trucks',authMiddleware, getTrucks);
router.get('/truckList',authMiddleware, getTruckList);
router.get("/pdfGernate/:id",pdfGernate)
router.get('/:id',authMiddleware, getById);




export default router;
