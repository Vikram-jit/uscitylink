import { Router } from 'express';
import { authMiddleware } from '../../middleware/authMiddleware';
import { addOrRemoveDriverFromGrop, driverGroupList, get,getTruckList } from '../../controllers/staff/groupController';
import { create } from '../../controllers/groupController';

const router = Router();
router.get('/:groupId/drivers',authMiddleware, driverGroupList);

router.get('/',authMiddleware, get);
router.get('/truckList',authMiddleware, getTruckList);
router.post('/',authMiddleware, create);
router.put('/addMember',authMiddleware, addOrRemoveDriverFromGrop);



export default router;
