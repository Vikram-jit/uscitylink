import { Router } from 'express';
import { create,deleteTemplate,get, getById,update,createOrUpdate } from '../controllers/templateController';
import { authMiddleware } from '../middleware/authMiddleware';
import { uploadMiddleware } from '../controllers/messageController';

const router = Router();

router.post('/', authMiddleware, create);
router.get('/', authMiddleware, get);
router.delete('/:id', authMiddleware, deleteTemplate);
router.get('/:id', authMiddleware, getById);
router.put('/:id', authMiddleware, update);
router.post("/createOrUpdate",authMiddleware,uploadMiddleware,createOrUpdate)
export default router;
