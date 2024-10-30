import { Router } from 'express';
import { create, get, getById, userAddToChannel } from '../controllers/channelController';
import { authMiddleware } from '../middleware/authMiddleware';

const router = Router();

router.post('/', create);
router.get('/',authMiddleware, get);
router.get('/:id', getById);
router.post('/addToChannel',userAddToChannel)

export default router;
