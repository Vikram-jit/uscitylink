import { Router } from 'express';
import { authMiddleware } from '../../middleware/authMiddleware';
import { addStaffMember, getChatUsers, getStaffMembers, sendMessageToStaffMember } from '../../controllers/staff/StaffChatController';

const router = Router(); 

router.get('/getStaffList',authMiddleware, getStaffMembers);
router.post('/addStaffMember',authMiddleware, addStaffMember);
router.post('/sendMessage',authMiddleware, sendMessageToStaffMember);
router.get('/staffChatUsers',authMiddleware, getChatUsers);


export default router