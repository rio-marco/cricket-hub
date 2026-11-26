import { NextFunction, Request, RequestHandler, Response } from 'express';
import { AdminPermission, hasAdminPermission, isAdminRole } from '../constants/admin';
import { MESSAGES } from '../constants/messages';
import { ApiError } from '../utils/apiError';

export const authorizeAdmin = (permission?: AdminPermission): RequestHandler => {
  return (req: Request, _res: Response, next: NextFunction): void => {
    const role = req.user?.role;

    if (!req.user || !isAdminRole(role) || !hasAdminPermission(role, permission)) {
      next(
        ApiError.forbidden(
          MESSAGES.AUTH.FORBIDDEN ||
            `Forbidden: administrative permission '${permission || 'ADMIN'}' is required.`
        )
      );
      return;
    }

    next();
  };
};

export default authorizeAdmin;
