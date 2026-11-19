import { Router } from 'express';
import {
  register,
  login,
  verifyOTP,
  forgotPassword,
  resetPassword,
  changePassword,
  refreshToken,
  logout,
  getProfile,
  updateProfile,
  uploadAvatar,
} from '../controllers/auth.controller';
import { protect } from '../middlewares/auth.middleware';
import { validate } from '../middlewares/validate.middleware';
import { authLimiter } from '../middlewares/rateLimiter.middleware';
import { uploadSingle } from '../middlewares/upload.middleware';
import {
  registerSchema,
  loginSchema,
  verifyOTPSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  changePasswordSchema,
  refreshTokenSchema,
  updateProfileSchema,
} from '../validators/auth.validator';

const router = Router();

// Public Authentication Endpoints (Rate limited)
router.post('/register', authLimiter, validate(registerSchema, 'body'), register);
router.post('/login', authLimiter, validate(loginSchema, 'body'), login);
router.post('/verify-otp', authLimiter, validate(verifyOTPSchema, 'body'), verifyOTP);
router.post('/forgot-password', authLimiter, validate(forgotPasswordSchema, 'body'), forgotPassword);
router.post('/reset-password', authLimiter, validate(resetPasswordSchema, 'body'), resetPassword);
router.post('/refresh-token', authLimiter, validate(refreshTokenSchema, 'body'), refreshToken);

// Protected Authentication Endpoints
router.post('/logout', protect, logout);
router.get('/me', protect, getProfile);
router.get('/profile', protect, getProfile);
router.put('/profile', protect, validate(updateProfileSchema, 'body'), updateProfile);
router.put('/change-password', protect, validate(changePasswordSchema, 'body'), changePassword);
router.put('/avatar', protect, uploadSingle('avatar'), uploadAvatar);

export default router;
