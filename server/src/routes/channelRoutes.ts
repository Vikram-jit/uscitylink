import { Router } from 'express';
import { create, get, getActiveChannel, getById, getMembers, userAddToChannel } from '../controllers/channelController';
import { authMiddleware } from '../middleware/authMiddleware';

const router = Router();

router.post('/', create);
router.get('/',authMiddleware, get);
router.get('/activeChannel',authMiddleware, getActiveChannel);
router.get('/members',authMiddleware, getMembers);
router.post('/addToChannel',authMiddleware,userAddToChannel)

export default router;
