import { Router } from 'express';

import { authMiddleware } from '../middleware/authMiddleware';
import { getById, getTruckList, getTrucks } from '../controllers/truckController';
import pdfGernate, { getPays, sendInvoiceEmail } from '../controllers/yardController';

const router = Router();


router.get('/trucks',authMiddleware, getTrucks);
router.get('/truckList',authMiddleware, getTruckList);
router.get('/pays',authMiddleware, getPays);
router.get("/pdfGernate/:id",pdfGernate)
router.get("/send-invoice/:id",sendInvoiceEmail)
router.get('/:id',authMiddleware, getById);




export default router;
