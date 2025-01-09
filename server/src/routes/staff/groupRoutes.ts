import { Router } from 'express';
import { authMiddleware } from '../../middleware/authMiddleware';
import { get,getTruckList } from '../../controllers/staff/groupController';
import { create } from '../../controllers/groupController';

const router = Router();

router.get('/',authMiddleware, get);
router.get('/truckList',authMiddleware, getTruckList);
router.post('/',authMiddleware, create);



export default router;
