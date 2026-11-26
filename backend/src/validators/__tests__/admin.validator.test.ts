import {
  adminAuditQuerySchema,
  adminLoginSchema,
  adminMatchCorrectionSchema,
  adminUserQuerySchema,
  legacyBlockUserSchema,
  legacyUpdateUserSchema,
} from '../admin.validator';

describe('admin validator schemas', () => {
  it('requires exactly one admin login identifier and a password', () => {
    expect(adminLoginSchema.validate({ email: 'admin@example.com', password: 'Secret123!' }).error).toBeUndefined();
    expect(adminLoginSchema.validate({ phone: '+12345678901', password: 'Secret123!' }).error).toBeUndefined();
    expect(adminLoginSchema.validate({ password: 'Secret123!' }).error).toBeDefined();
    expect(
      adminLoginSchema.validate({ email: 'admin@example.com', phone: '+12345678901', password: 'Secret123!' }).error
    ).toBeDefined();
  });

  it('applies safe defaults and strict sort fields to admin list queries', () => {
    const { error, value } = adminUserQuerySchema.validate({});
    expect(error).toBeUndefined();
    expect(value.page).toBe(1);
    expect(value.limit).toBe(20);

    expect(adminUserQuerySchema.validate({ sort: 'password' }).error).toBeDefined();
    expect(adminAuditQuerySchema.validate({ sort: 'action' }).error).toBeUndefined();
  });

  it('requires a reason for scoring corrections', () => {
    const id = '507f1f77bcf86cd799439011';
    expect(adminMatchCorrectionSchema.validate({ deliveryId: id, reason: 'Wrong runs recorded' }).error).toBeUndefined();
    expect(adminMatchCorrectionSchema.validate({ deliveryId: id }).error).toBeDefined();
    expect(adminMatchCorrectionSchema.validate({ deliveryId: 'not-an-id', reason: 'Wrong runs recorded' }).error).toBeDefined();
  });

  it('accepts legacy admin user updates and blocks without breaking old payloads', () => {
    expect(legacyUpdateUserSchema.validate({ isBlocked: true }).error).toBeUndefined();
    const blocked = legacyBlockUserSchema.validate({});
    expect(blocked.error).toBeUndefined();
    expect(blocked.value.reason).toBe('Legacy administrative status update');
  });
});
