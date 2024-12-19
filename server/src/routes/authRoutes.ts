import { Router } from 'express';
import { register, login, loginWithPassword, loginWithWeb, sendOtp, validateOtp, resendOtp, logout } from '../controllers/authController';
import { syncDriver, syncUser } from '../controllers/userController';
import { authMiddleware } from '../middleware/authMiddleware';

const router = Router();

router.post('/register', register);
router.post('/sendOtp', sendOtp);
router.post('/re-sendOtp', resendOtp);
router.post('/validateOtp', validateOtp);
router.post('/login', login);
router.post('/loginWithPassword', loginWithPassword);
router.post('/loginWithWeb', loginWithWeb);
router.post('/syncUser', syncUser);
router.post('/syncDriver', syncDriver);
router.post('/logout',authMiddleware, logout);

export default router;
