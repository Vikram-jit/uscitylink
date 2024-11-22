import { Router } from 'express';
import { getChannelList,  getUserProfile,  getUsers, getUserWithoutChannel, updateDeviceToken, updateUserActiveChannel } from '../controllers/userController';
import { authMiddleware } from '../middleware/authMiddleware';

const router = Router();

router.get('/', getUsers);
router.get('/profile',authMiddleware, getUserProfile);
router.put('/updateDeviceToken',authMiddleware, updateDeviceToken);
router.get('/drivers',authMiddleware, getUserWithoutChannel);

router.get('/channels', authMiddleware,getChannelList);
router.put('/updateActiveChannel',authMiddleware, updateUserActiveChannel);

export default router;
