import { Router } from 'express';
import { authMiddleware } from '../../middleware/authMiddleware';
import { getChannelListWithActive,selectedChannelMembers ,driverList} from '../../controllers/staff/channelController';

const router = Router();

router.get('/channels',authMiddleware, getChannelListWithActive);
router.get('/members',authMiddleware, selectedChannelMembers);
router.get('/drivers',authMiddleware, driverList);

export default router