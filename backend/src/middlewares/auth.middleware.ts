import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { ApiError } from '../utils/apiError';
import { asyncHandler } from '../utils/asyncHandler';
import { MESSAGES } from '../constants/messages';
import User from '../models/User';

export interface IJwtPayload {
  id?: string;
  userId?: string;
  sub?: string;
  role?: string;
  iat?: number;
  exp?: number;
}

/**
 * Protect middleware:
 * Validates JWT Bearer token from Authorization header,
 * extracts user information, verifies active state, and attaches user to req.user.
 */
export const protect = asyncHandler(
  async (req: Request, _res: Response, next: NextFunction): Promise<void> => {
    let token: string | undefined;

    // Check Authorization header for Bearer scheme
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      token = authHeader.split(' ')[1];
    } else if (req.cookies && req.cookies.token) {
      token = req.cookies.token;
    }

    if (!token) {
      throw ApiError.unauthorized(MESSAGES.AUTH.UNAUTHORIZED || 'Authentication required. No token provided.');
    }

    // Verify token using JWT_SECRET
    let decoded: IJwtPayload;
    try {
      decoded = jwt.verify(token, env.JWT_SECRET) as IJwtPayload;
    } catch (err: any) {
      if (err.name === 'TokenExpiredError') {
        throw new ApiError(401, MESSAGES.AUTH.TOKEN_EXPIRED || 'Token has expired. Please log in again.');
      }
      throw new ApiError(401, MESSAGES.AUTH.INVALID_TOKEN || 'Invalid token. Authorization denied.');
    }

    const userId = decoded.id || decoded.userId || decoded.sub;
    if (!userId) {
      throw ApiError.unauthorized('Invalid token payload. User ID missing.');
    }

    // Query user from database
    const user = await User.findById(userId);
    if (!user) {
      throw ApiError.unauthorized(MESSAGES.AUTH.USER_NOT_FOUND || 'User belonging to this token no longer exists.');
    }

    // Check if account is suspended or blocked
    if (user.isBlocked) {
      throw ApiError.forbidden(MESSAGES.AUTH.ACCOUNT_BLOCKED || 'Your account has been suspended. Please contact support.');
    }

    // Attach user to Express Request
    req.user = user as any;
    next();
  }
);

export default protect;
