import { NextFunction, Request, Response } from 'express';
import { AdminPermission } from '../../constants/admin';
import { UserRole } from '../../constants/roles';
import { authorizeAdmin } from '../admin.middleware';

const createRequest = (user?: any): Request =>
  ({ user } as unknown as Request);

const invoke = (handler: any, req: Request): { next: NextFunction; error: any } => {
  const next = jest.fn() as unknown as NextFunction;
  handler(req, {} as Response, next);
  const error = (next as jest.Mock).mock.calls[0]?.[0];
  return { next, error };
};

describe('authorizeAdmin', () => {
  it('allows admins with the requested permission', () => {
    const { next, error } = invoke(
      authorizeAdmin(AdminPermission.USERS_MANAGE),
      createRequest({ role: UserRole.ADMIN })
    );
    expect(error).toBeUndefined();
    expect(next).toHaveBeenCalledWith();
  });

  it('rejects non-admin users', () => {
    const { error } = invoke(
      authorizeAdmin(AdminPermission.USERS_MANAGE),
      createRequest({ role: UserRole.PLAYER })
    );
    expect(error).toBeInstanceOf(Error);
    expect(error.statusCode).toBe(403);
  });

  it('rejects unauthenticated requests', () => {
    const { error } = invoke(authorizeAdmin(), createRequest());
    expect(error).toBeInstanceOf(Error);
    expect(error.statusCode).toBe(403);
  });
});
