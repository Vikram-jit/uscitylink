import { Router } from 'express';
import { create, get,getById, getMessagesByGroupId, groupAddMember,groupUpdate, groupRemoveMember ,groupRemove, groupStatusMember} from '../controllers/groupController';
import { authMiddleware } from '../middleware/authMiddleware';
import { truckGroups } from '../controllers/truckChatController';

const router = Router();

router.post('/',authMiddleware, create);
router.get('/truck-groups',authMiddleware, truckGroups);
router.put('/:id',authMiddleware, groupUpdate);
router.delete('/:id',authMiddleware, groupRemove);
router.get('/messages/:id',authMiddleware, getMessagesByGroupId);

router.post('/member/:id',authMiddleware, groupAddMember);
router.put('/member/:id',authMiddleware, groupStatusMember);
router.delete('/member/:id',authMiddleware, groupRemoveMember);

router.get('/',authMiddleware, get);
router.get('/:id',authMiddleware, getById);
export default router;
