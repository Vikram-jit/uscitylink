import { Router } from 'express';
import { register, login, loginWithPassword, loginWithWeb } from '../controllers/authController';
import { syncDriver, syncUser } from '../controllers/userController';

const router = Router();

router.post('/register', register);
router.post('/login', login);
router.post('/loginWithPassword', loginWithPassword);
router.post('/loginWithWeb', loginWithWeb);
router.post('/syncUser', syncUser);
router.post('/syncDriver', syncDriver);

export default router;
