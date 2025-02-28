import { Router } from 'express';
import { changePassword, dashboard, dashboardWeb, gernateNewPassword, getChannelList,  getGroupList,  getProfile,  getUserProfile,  getUserProfileById,  getUsers, getUserWithoutChannel, updateDeviceToken, updateProfile, updateProfileByWeb, updateUserActiveChannel } from '../controllers/userController';
import { authMiddleware } from '../middleware/authMiddleware';

const router = Router();

router.get('/', getUsers);
router.get('/driver-profile',authMiddleware,getProfile)
router.get('/profile/:id',authMiddleware, getUserProfileById);
router.post('/genrate-password/:id',authMiddleware, gernateNewPassword);
router.put('/update-profile/:id/:role', updateProfile);
router.put('/update-profile-web/:id',authMiddleware, updateProfileByWeb);
router.get('/dashboard',authMiddleware, dashboard);
router.get('/dashboard-web',authMiddleware, dashboardWeb);
router.get('/profile',authMiddleware, getUserProfile);
router.put('/updateDeviceToken',authMiddleware, updateDeviceToken);
router.get('/drivers',authMiddleware, getUserWithoutChannel);

router.get('/channels', authMiddleware,getChannelList);
router.get('/groups', authMiddleware,getGroupList);
router.put('/updateActiveChannel',authMiddleware, updateUserActiveChannel);
router.post('/change-password',authMiddleware, changePassword);


export default router;
