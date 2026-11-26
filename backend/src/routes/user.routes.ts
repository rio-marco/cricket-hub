import { Router } from 'express';
import * as adminController from '../controllers/admin.controller';
import { protect } from '../middlewares/auth.middleware';
import { authorize } from '../middlewares/authorize.middleware';
import { validate } from '../middlewares/validate.middleware';
import { UserRole } from '../constants/roles';
import {
  adminIdParamSchema,
  legacyBlockUserSchema,
  legacyUpdateUserSchema,
} from '../validators/admin.validator';

const router = Router();

router.use(protect);
router.use(authorize(UserRole.ADMIN));

router.get('/dashboard/stats', adminController.legacyGetDashboardStats);

router.get('/', adminController.legacyGetAllUsers);
router.get('/:id', validate(adminIdParamSchema, 'params'), adminController.legacyGetUserById);
router.put('/:id', validate(adminIdParamSchema, 'params'), validate(legacyUpdateUserSchema), adminController.legacyUpdateUser);
router.put('/:id/block', validate(adminIdParamSchema, 'params'), validate(legacyBlockUserSchema), adminController.legacyBlockUser);
router.delete('/:id', validate(adminIdParamSchema, 'params'), adminController.legacyDeleteUser);

export default router;
