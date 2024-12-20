import { Router } from 'express';
import { changePassword, dashboard, getChannelList,  getGroupList,  getUserProfile,  getUsers, getUserWithoutChannel, updateDeviceToken, updateProfile, updateUserActiveChannel } from '../controllers/userController';
import { authMiddleware } from '../middleware/authMiddleware';

const router = Router();

router.get('/', getUsers);
router.put('/',authMiddleware, updateProfile);
router.get('/dashboard',authMiddleware, dashboard);
router.get('/profile',authMiddleware, getUserProfile);
router.put('/updateDeviceToken',authMiddleware, updateDeviceToken);
router.get('/drivers',authMiddleware, getUserWithoutChannel);

router.get('/channels', authMiddleware,getChannelList);
router.get('/groups', authMiddleware,getGroupList);
router.put('/updateActiveChannel',authMiddleware, updateUserActiveChannel);
router.post('/change-password',authMiddleware, changePassword);


export default router;
