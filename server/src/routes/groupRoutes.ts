import { Router } from 'express';
import { create, get } from '../controllers/groupController';
import { authMiddleware } from '../middleware/authMiddleware';

const router = Router();

router.post('/',authMiddleware, create);
router.get('/',authMiddleware, get);


export default router;
