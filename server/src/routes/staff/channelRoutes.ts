import { Router } from 'express';
import { authMiddleware } from '../../middleware/authMiddleware';
import { getChannelListWithActive,selectedChannelMembers,updateStaffActiceChannel,addOrRemoveDriverFromChannel ,driverList} from '../../controllers/staff/channelController';
import { getChatMessageUser } from '../../controllers/staff/chatController';

const router = Router();

router.get('/channels',authMiddleware, getChannelListWithActive);
router.get('/members',authMiddleware, selectedChannelMembers);
router.get('/chatUsers',authMiddleware, getChatMessageUser);
router.get('/drivers',authMiddleware, driverList);
router.put('/addOrRemoveDriverFromChannel',authMiddleware, addOrRemoveDriverFromChannel);
router.put('/updateStaffActiceChannel',authMiddleware, updateStaffActiceChannel);

export default router