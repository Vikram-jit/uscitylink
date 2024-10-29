import { Router } from 'express';
import { create, get } from '../controllers/channelController';

const router = Router();

router.post('/', create);
router.get('/', get);

export default router;
