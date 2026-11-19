import { Request, Response } from 'express';
import { asyncHandler } from '../utils/asyncHandler';
import { ApiResponse } from '../utils/apiResponse';
import { ApiError } from '../utils/apiError';
import { MESSAGES } from '../constants/messages';
import authService from '../services/auth.service';

/**
 * Register a new user
 * POST /api/v1/auth/register
 */
export const register = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await authService.register(req.body);
  ApiResponse.success(
    res,
    201,
    MESSAGES.AUTH.REGISTER_SUCCESS || 'User registered successfully. Verification OTP has been sent.',
    result
  );
});

/**
 * Authenticate user & issue tokens
 * POST /api/v1/auth/login
 */
export const login = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await authService.login(req.body);
  ApiResponse.success(
    res,
    200,
    MESSAGES.AUTH.LOGIN_SUCCESS || 'Logged in successfully.',
    result
  );
});

/**
 * Verify OTP
 * POST /api/v1/auth/verify-otp
 */
export const verifyOTP = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const { userId, otp } = req.body;
  if (!userId || !otp) {
    throw ApiError.badRequest('Both userId and otp are required.');
  }
  const result = await authService.verifyOTP(userId, otp);
  ApiResponse.success(
    res,
    200,
    result.message,
    result
  );
});

export const resendOTP = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await authService.resendOTP(req.body);
  ApiResponse.success(
    res,
    200,
    result.message,
    result
  );
});

/**
 * Request password reset OTP
 * POST /api/v1/auth/forgot-password
 */
export const forgotPassword = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await authService.forgotPassword(req.body);
  ApiResponse.success(
    res,
    200,
    result.message,
    result
  );
});

/**
 * Reset password with OTP
 * POST /api/v1/auth/reset-password
 */
export const resetPassword = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const { userId, otp, newPassword } = req.body;
  if (!userId || !otp || !newPassword) {
    throw ApiError.badRequest('userId, otp, and newPassword are required.');
  }
  const result = await authService.resetPassword(userId, otp, newPassword);
  ApiResponse.success(
    res,
    200,
    result.message
  );
});

/**
 * Change password (authenticated)
 * PUT /api/v1/auth/change-password
 */
export const changePassword = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const userId = req.user?._id?.toString() || req.user?.id;
  if (!userId) {
    throw ApiError.unauthorized('User not authenticated.');
  }
  const { currentPassword, newPassword } = req.body;
  const result = await authService.changePassword(userId, currentPassword, newPassword);
  ApiResponse.success(
    res,
    200,
    result.message
  );
});

/**
 * Refresh access token
 * POST /api/v1/auth/refresh-token
 */
export const refreshToken = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const { refreshToken: token } = req.body;
  if (!token) {
    throw ApiError.badRequest(MESSAGES.AUTH.REFRESH_TOKEN_REQUIRED || 'Refresh token is required.');
  }
  const result = await authService.refreshToken(token);
  ApiResponse.success(
    res,
    200,
    MESSAGES.AUTH.TOKEN_REFRESH_SUCCESS || 'Access token refreshed successfully.',
    result
  );
});

/**
 * Logout and revoke refresh tokens
 * POST /api/v1/auth/logout
 */
export const logout = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const userId = req.user?._id?.toString() || req.user?.id;
  if (!userId) {
    throw ApiError.unauthorized('User not authenticated.');
  }
  const { refreshToken: token } = req.body;
  const result = await authService.logout(userId, token);
  ApiResponse.success(
    res,
    200,
    result.message
  );
});

/**
 * Get current user profile
 * GET /api/v1/auth/me or GET /api/v1/auth/profile
 */
export const getProfile = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const userId = req.user?._id?.toString() || req.user?.id;
  if (!userId) {
    throw ApiError.unauthorized('User not authenticated.');
  }
  const user = await authService.getProfile(userId);
  ApiResponse.success(
    res,
    200,
    'Profile retrieved successfully.',
    user
  );
});

/**
 * Update current user profile
 * PUT /api/v1/auth/profile
 */
export const updateProfile = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const userId = req.user?._id?.toString() || req.user?.id;
  if (!userId) {
    throw ApiError.unauthorized('User not authenticated.');
  }
  const updatedUser = await authService.updateProfile(userId, req.body);
  ApiResponse.success(
    res,
    200,
    MESSAGES.AUTH.PROFILE_UPDATED || 'Profile updated successfully.',
    updatedUser
  );
});

/**
 * Upload avatar image
 * PUT /api/v1/auth/avatar
 */
export const uploadAvatar = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const userId = req.user?._id?.toString() || req.user?.id;
  if (!userId) {
    throw ApiError.unauthorized('User not authenticated.');
  }
  if (!req.file) {
    throw ApiError.badRequest('Please upload an image file using the "avatar" field.');
  }

  const avatarUrl = `/uploads/${req.file.filename}`;
  const updatedUser = await authService.updateProfile(userId, { avatar: avatarUrl });

  ApiResponse.success(
    res,
    200,
    'Avatar uploaded successfully.',
    { avatar: avatarUrl, user: updatedUser }
  );
});

export default {
  register,
  login,
  verifyOTP,
  resendOTP,
  forgotPassword,
  resetPassword,
  changePassword,
  refreshToken,
  logout,
  getProfile,
  updateProfile,
  uploadAvatar,
};
