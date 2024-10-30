import { Router } from 'express';
import { create, get } from '../controllers/groupController';

const router = Router();

router.post('/', create);
router.get('/', get);


export default router;
