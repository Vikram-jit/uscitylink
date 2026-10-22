import { Router } from 'express';
// api/v2 auth: the mobile app's auth. Same as v1 except validateOtp (honours the role the app
// sends: staff/driver) loginWithPassword (clean "Invalid credentials" for a missing profile) and updateAppVersion
// (answers UpToDate / UpdateAvailable / ForceUpdate with the latest build, for the update screen).
import { register, login, loginWithPasswordV2, loginWithWeb, sendOtp, validateOtpV2, resendOtp, logout, loginWithToken, verifyDriver } from '../controllers/authController';
import { syncDriver, syncUser } from '../controllers/userController';
import { authMiddleware } from '../middleware/authMiddleware';
import { updateAppVersionV2 } from '../services/appUpdatePolicy';

const router = Router();
router.post('/verifyDriver',verifyDriver);
router.post('/register', register);
router.post('/sendOtp', sendOtp);
router.post('/re-sendOtp', resendOtp);
router.post('/validateOtp', validateOtpV2);
router.post('/login', login);
router.get('/loginWithToken/:token', loginWithToken);
router.post('/loginWithPassword', loginWithPasswordV2);
router.post('/loginWithWeb', loginWithWeb);
router.post('/syncUser', syncUser);
router.post('/syncDriver', syncDriver);
router.post('/logout',authMiddleware, logout);
router.put('/updateAppVersion',authMiddleware, updateAppVersionV2);

export default router;
