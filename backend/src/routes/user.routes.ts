import { Router } from 'express';
import {
  getAllUsers,
  getUserById,
  updateUser,
  blockUser,
  deleteUser,
  getDashboardStats,
} from '../controllers/user.controller';
import { protect } from '../middlewares/auth.middleware';
import { authorize } from '../middlewares/authorize.middleware';
import { UserRole } from '../constants/roles';

const router = Router();

// Protect all user management routes and restrict to ADMIN role
router.use(protect);
router.use(authorize(UserRole.ADMIN));

// Admin dashboard summary statistics (Placed before /:id parameter)
router.get('/dashboard/stats', getDashboardStats);

// User CRUD & Management
router.get('/', getAllUsers);
router.get('/:id', getUserById);
router.put('/:id', updateUser);
router.put('/:id/block', blockUser);
router.delete('/:id', deleteUser);

export default router;
