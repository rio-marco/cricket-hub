import { AdminAction } from '../../constants/admin';
import { redactSensitive } from '../../models/AdminAudit';
import {
  AdminAuditService,
  resolveSort,
  serializeAdminAudit,
} from '../adminAudit.service';

describe('admin audit helpers', () => {
  it('redacts nested sensitive fields recursively', () => {
    const redacted = redactSensitive({
      name: 'Admin',
      password: 'Secret123!',
      refreshToken: 'token',
      nested: [
        {
          refresh_token: 'key',
          safe: 'visible',
        },
      ],
    });

    expect(redacted.name).toBe('Admin');
    expect(redacted.password).toBeUndefined();
    expect(redacted.refreshToken).toBeUndefined();
    expect((redacted.nested as any[])[0].refresh_token).toBeUndefined();
    expect((redacted.nested as any[])[0].safe).toBe('visible');
  });

  it('resolves sort fields against an allow-list', () => {
    expect(resolveSort({ sort: 'action', order: 'asc' })).toEqual({ action: 1 });
    expect(resolveSort({ sort: '-password' })).toEqual({ createdAt: -1 });
  });

  it('serializes audits through redaction', () => {
    const audit = serializeAdminAudit({
      _id: '507f1f77bcf86cd799439011',
      action: AdminAction.USER_STATUS_CHANGED,
      before: { password: 'Secret123!', isBlocked: false },
      after: { password: 'Secret456!', isBlocked: true },
    });

    expect(audit.id).toBe('507f1f77bcf86cd799439011');
    expect((audit.before as any).password).toBeUndefined();
    expect((audit.after as any).password).toBeUndefined();
    expect((audit.after as any).isBlocked).toBe(true);
  });

  it('requires a reason for sensitive administrative actions', async () => {
    const service = new AdminAuditService();
    await expect(
      service.recordAdminAction({}, AdminAction.USER_STATUS_CHANGED, 'User')
    ).rejects.toMatchObject({ statusCode: 400 });
  });
});
