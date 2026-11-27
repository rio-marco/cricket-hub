import { sanitizeUser } from '../../utils/sanitizeUser';

describe('security DTO/sanitization regressions', () => {
  it('sanitizeUser strips sensitive auth/internal fields', () => {
    const user = {
      _id: 'u1',
      name: 'N',
      email: 'e@example.com',
      phone: '9999999999',
      role: 'NORMAL_USER',
      password: 'hash',
      otp: { code: '123456' },
      fcmToken: 'fcm',
      authLockout: { failedAttempts: 3 },
      refreshToken: 'rt',
      __v: 0,
    } as any;
    const safe = sanitizeUser(user);
    expect(safe.password).toBeUndefined();
    expect(safe.otp).toBeUndefined();
    expect(safe.fcmToken).toBeUndefined();
    expect(safe.authLockout).toBeUndefined();
    expect(safe.refreshToken).toBeUndefined();
    expect(safe.__v).toBeUndefined();
    expect(safe.email).toBe('e@example.com'); // allowed by default policy
  });

  it('sanitizeUser can exclude contact fields for public DTOs', () => {
    const safe = sanitizeUser({ _id: 'u1', name: 'N', email: 'e@example.com', phone: '9', role: 'PLAYER' } as any, { includeContact: false });
    expect(safe.email).toBeUndefined();
    expect(safe.phone).toBeUndefined();
    expect(safe.name).toBe('N');
  });
});
