import { Router } from 'express';
import { create, get,getById, getMessagesByGroupId, groupAddMember,groupUpdate, groupRemoveMember ,groupRemove, groupStatusMember} from '../controllers/groupController';
import { authMiddleware } from '../middleware/authMiddleware';

const router = Router();

router.post('/',authMiddleware, create);
router.get('/',authMiddleware, get);
router.get('/:id',authMiddleware, getById);
router.put('/:id',authMiddleware, groupUpdate);
router.delete('/:id',authMiddleware, groupRemove);
router.get('/messages/:id',authMiddleware, getMessagesByGroupId);
router.post('/member/:id',authMiddleware, groupAddMember);
router.put('/member/:id',authMiddleware, groupStatusMember);
router.delete('/member/:id',authMiddleware, groupRemoveMember);


export default router;
