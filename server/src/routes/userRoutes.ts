import { Router } from 'express';
import { getChannelList,  getUsers, getUserWithoutChannel, updateUserActiveChannel } from '../controllers/userController';
import { authMiddleware } from '../middleware/authMiddleware';

const router = Router();

router.get('/', getUsers);
router.get('/drivers',authMiddleware, getUserWithoutChannel);

router.get('/channels', authMiddleware,getChannelList);
router.put('/updateActiveChannel/:id', updateUserActiveChannel);

export default router;
