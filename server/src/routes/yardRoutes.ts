import { Router } from 'express';

import { authMiddleware } from '../middleware/authMiddleware';
import { getById, getTruckList, getTrucks } from '../controllers/truckController';
import pdfGernate, { getInspectionView, getPays, insertInspection, queueData, sendInvoiceEmail } from '../controllers/yardController';

const router = Router();


router.get('/trucks',authMiddleware, getTrucks);
router.get('/truckList',authMiddleware, getTruckList);
router.get('/inspection',authMiddleware, getInspectionView);
router.post('/inspection',authMiddleware, insertInspection);
router.get('/pays',authMiddleware, getPays);
router.get("/pdfGernate/:id",pdfGernate)
router.get("/send-invoice/:id",sendInvoiceEmail)
router.get('/queue-data', queueData);
router.get('/:id',authMiddleware, getById);




export default router;
