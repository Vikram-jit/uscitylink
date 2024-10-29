import { Router } from 'express';
import { register, login, loginWithPassword, loginWithWeb } from '../controllers/authController';

const router = Router();

router.post('/register', register);
router.post('/login', login);
router.post('/loginWithPassword', loginWithPassword);
router.post('/loginWithWeb', loginWithWeb);

export default router;
