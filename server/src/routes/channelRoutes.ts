import { Router } from 'express';
import { channelRemoveMember, channelStatusMember, countMessageAndGroup, create, get, getActiveChannel, getById, getMembers, userAddToChannel } from '../controllers/channelController';
import { authMiddleware } from '../middleware/authMiddleware';

const router = Router();

router.post('/', create);
router.get('/',authMiddleware, get);
router.get('/countMessageAndGroup',authMiddleware, countMessageAndGroup);
router.get('/activeChannel',authMiddleware, getActiveChannel);
router.get('/members',authMiddleware, getMembers);
router.post('/addToChannel',authMiddleware,userAddToChannel)
router.put('/member/:id',authMiddleware, channelStatusMember);
router.delete('/member/:id',authMiddleware, channelRemoveMember);

export default router;
