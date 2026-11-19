import { Request, Response, NextFunction, RequestHandler } from 'express';
import { ApiError } from '../utils/apiError';
import { MESSAGES } from '../constants/messages';
import { UserRole } from '../constants/roles';

/**
 * Role-Based Authorization Middleware Factory
 * Verifies that the authenticated user's role is within the allowed roles.
 *
 * @param roles List of authorized UserRole enum values or role strings
 */
export const authorize = (...roles: (UserRole | string)[]): RequestHandler => {
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (!req.user) {
      return next(ApiError.unauthorized(MESSAGES.AUTH.UNAUTHORIZED || 'User is not authenticated.'));
    }

    const userRole = req.user.role;

    if (!userRole || !roles.includes(userRole)) {
      return next(
        ApiError.forbidden(
          MESSAGES.AUTH.FORBIDDEN || `Forbidden: role '${userRole}' is not authorized to access this resource.`
        )
      );
    }

    next();
  };
};

export default authorize;
