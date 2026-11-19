import { Request, Response } from 'express';
import { asyncHandler } from '../utils/asyncHandler';
import { ApiResponse } from '../utils/apiResponse';
import { ApiError } from '../utils/apiError';
import { getPaginationParams } from '../utils/pagination';
import User from '../models/User';
import Team from '../models/Team';
import Player from '../models/Player';
import RefreshToken from '../models/RefreshToken';
import Tournament from '../models/Tournament';
import Match from '../models/Match';

/**
 * Get all users with pagination, role filter, and text search
 * GET /api/v1/users
 */
export const getAllUsers = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const { page, limit, skip, sort } = getPaginationParams(req.query, 10, 100, '-createdAt');

  const filter: any = {};

  // Search by keyword in name, email, or phone
  if (req.query.search) {
    const searchRegex = new RegExp(String(req.query.search).trim(), 'i');
    filter.$or = [
      { name: searchRegex },
      { email: searchRegex },
      { phone: searchRegex },
    ];
  }

  // Filter by role
  if (req.query.role) {
    filter.role = req.query.role;
  }

  // Filter by block status
  if (req.query.isBlocked !== undefined) {
    filter.isBlocked = req.query.isBlocked === 'true';
  }

  // Filter by verification status
  if (req.query.isVerified !== undefined) {
    filter.isVerified = req.query.isVerified === 'true';
  }

  const [users, total] = await Promise.all([
    User.find(filter)
      .sort(sort as any)
      .skip(skip)
      .limit(limit)
      .select('-password -otp')
      .lean(),
    User.countDocuments(filter),
  ]);

  ApiResponse.paginated(res, users, page, limit, total, 'Users retrieved successfully.');
});

/**
 * Get single user by ID
 * GET /api/v1/users/:id
 */
export const getUserById = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const user = await User.findById(req.params.id).select('-password -otp').lean();
  if (!user) {
    throw ApiError.notFound('User not found.');
  }

  ApiResponse.success(res, 200, 'User retrieved successfully.', user);
});

/**
 * Update user details (Admin)
 * PUT /api/v1/users/:id
 */
export const updateUser = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const user = await User.findById(req.params.id);
  if (!user) {
    throw ApiError.notFound('User not found.');
  }

  const { name, email, phone, role, isVerified, isBlocked } = req.body;

  if (email && email.toLowerCase() !== user.email) {
    const emailExists = await User.findOne({ email: email.toLowerCase(), _id: { $ne: user._id } });
    if (emailExists) {
      throw ApiError.conflict('Email address already in use by another user.');
    }
    user.email = email.toLowerCase().trim();
  }

  if (phone && phone !== user.phone) {
    const phoneExists = await User.findOne({ phone, _id: { $ne: user._id } });
    if (phoneExists) {
      throw ApiError.conflict('Phone number already in use by another user.');
    }
    user.phone = phone.trim();
  }

  if (name !== undefined) user.name = name.trim();
  if (role !== undefined) user.role = role;
  if (isVerified !== undefined) user.isVerified = Boolean(isVerified);
  if (isBlocked !== undefined) {
    user.isBlocked = Boolean(isBlocked);
    if (user.isBlocked) {
      // Invalidate active sessions
      await RefreshToken.updateMany({ user: user._id }, { isRevoked: true });
    }
  }

  await user.save();

  const sanitizedUser = user.toObject();
  delete (sanitizedUser as any).password;
  delete (sanitizedUser as any).otp;

  ApiResponse.success(res, 200, 'User updated successfully.', sanitizedUser);
});

/**
 * Block or unblock a user
 * PUT /api/v1/users/:id/block
 */
export const blockUser = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const user = await User.findById(req.params.id);
  if (!user) {
    throw ApiError.notFound('User not found.');
  }

  // Toggle or explicitly set block status
  const shouldBlock = req.body.isBlocked !== undefined ? Boolean(req.body.isBlocked) : !user.isBlocked;
  user.isBlocked = shouldBlock;
  await user.save();

  if (shouldBlock) {
    // Revoke all active refresh tokens for the blocked user
    await RefreshToken.updateMany({ user: user._id }, { isRevoked: true });
  }

  ApiResponse.success(
    res,
    200,
    shouldBlock ? 'User has been blocked successfully.' : 'User has been unblocked successfully.',
    { userId: user._id, isBlocked: user.isBlocked }
  );
});

/**
 * Soft delete user (blocks user and marks account inactive)
 * DELETE /api/v1/users/:id
 */
export const deleteUser = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const user = await User.findById(req.params.id);
  if (!user) {
    throw ApiError.notFound('User not found.');
  }

  // Soft delete: set isBlocked to true and revoke tokens
  user.isBlocked = true;
  await user.save();

  await RefreshToken.updateMany({ user: user._id }, { isRevoked: true });

  ApiResponse.success(res, 200, 'User soft-deleted and access revoked successfully.', {
    userId: user._id,
    deleted: true,
  });
});

/**
 * Admin dashboard statistics
 * GET /api/v1/users/dashboard/stats
 */
export const getDashboardStats = asyncHandler(async (_req: Request, res: Response): Promise<void> => {
  const [
    totalUsers,
    activeUsers,
    blockedUsers,
    verifiedUsers,
    usersByRole,
    totalTeams,
    totalPlayers,
    totalTournaments,
    totalMatches,
  ] = await Promise.all([
    User.countDocuments(),
    User.countDocuments({ isBlocked: false }),
    User.countDocuments({ isBlocked: true }),
    User.countDocuments({ isVerified: true }),
    User.aggregate([
      {
        $group: {
          _id: '$role',
          count: { $sum: 1 },
        },
      },
    ]),
    Team.countDocuments().catch(() => 0),
    Player.countDocuments().catch(() => 0),
    Tournament.countDocuments().catch(() => 0),
    Match.countDocuments().catch(() => 0),
  ]);

  const roleCounts: Record<string, number> = {};
  usersByRole.forEach((item) => {
    roleCounts[item._id] = item.count;
  });

  const stats = {
    users: {
      total: totalUsers,
      active: activeUsers,
      blocked: blockedUsers,
      verified: verifiedUsers,
      byRole: roleCounts,
    },
    platform: {
      teams: totalTeams,
      players: totalPlayers,
      tournaments: totalTournaments,
      matches: totalMatches,
    },
  };

  ApiResponse.success(res, 200, 'Dashboard statistics retrieved successfully.', stats);
});

export default {
  getAllUsers,
  getUserById,
  updateUser,
  blockUser,
  deleteUser,
  getDashboardStats,
};
