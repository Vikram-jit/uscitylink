import { Router } from 'express';
import { create,deleteTemplate,get, getById,update } from '../controllers/templateController';
import { authMiddleware } from '../middleware/authMiddleware';

const router = Router();

router.post('/', authMiddleware, create);
router.get('/', authMiddleware, get);
router.delete('/:id', authMiddleware, deleteTemplate);
router.get('/:id', authMiddleware, getById);
router.put('/:id', authMiddleware, update);

export default router;
