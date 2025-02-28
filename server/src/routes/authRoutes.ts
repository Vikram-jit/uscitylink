import { Router } from 'express';
import { register, login, loginWithPassword, loginWithWeb, sendOtp, validateOtp, resendOtp, logout, loginWithToken, updateAppVersion } from '../controllers/authController';
import { syncDriver, syncUser } from '../controllers/userController';
import { authMiddleware } from '../middleware/authMiddleware';

const router = Router();

router.post('/register', register);
router.post('/sendOtp', sendOtp);
router.post('/re-sendOtp', resendOtp);
router.post('/validateOtp', validateOtp);
router.post('/login', login);
router.get('/loginWithToken/:token', loginWithToken);
router.post('/loginWithPassword', loginWithPassword);
router.post('/loginWithWeb', loginWithWeb);
router.post('/syncUser', syncUser);
router.post('/syncDriver', syncDriver);
router.post('/logout',authMiddleware, logout);
router.put('/updateAppVersion',authMiddleware, updateAppVersion);

export default router;
