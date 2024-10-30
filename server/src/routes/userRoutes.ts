import { Router } from 'express';
import { getChannelList, getUsers, updateUserActiveChannel } from '../controllers/userController';

const router = Router();

router.get('/', getUsers);
router.get('/channels/:id', getChannelList);
router.put('/updateActiveChannel/:id', updateUserActiveChannel);

export default router;
