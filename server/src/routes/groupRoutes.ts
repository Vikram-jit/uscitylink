import { Router } from 'express';
import { create, get, getMessagesByGroupId, groupAddMember, groupRemoveMember } from '../controllers/groupController';
import { authMiddleware } from '../middleware/authMiddleware';

const router = Router();

router.post('/',authMiddleware, create);
router.get('/',authMiddleware, get);
router.get('/messages/:id',authMiddleware, getMessagesByGroupId);
router.post('/member/:id',authMiddleware, groupAddMember);
router.delete('/member/:id',authMiddleware, groupRemoveMember);


export default router;
