import { registerSchema, resendOTPSchema } from '../../validators/auth.validator';

describe('auth validators', () => {
  it('defaults public registration to NORMAL_USER', () => {
    const { error, value } = registerSchema.validate({
      name: 'Test User',
      email: 'test@example.com',
      password: 'Password1',
    });

    expect(error).toBeUndefined();
    expect(value.role).toBe('NORMAL_USER');
  });

  it('rejects privileged roles on public registration', () => {
    const { error } = registerSchema.validate({
      name: 'Test User',
      email: 'test@example.com',
      password: 'Password1',
      role: 'ADMIN',
    });

    expect(error?.message).toMatch(/NORMAL_USER/);
  });

  it('requires an identifier when resending an OTP', () => {
    expect(resendOTPSchema.validate({}).error?.message).toMatch(/userId/);
    expect(resendOTPSchema.validate({ userId: 'u1' }).value).toEqual({ userId: 'u1' });
  });
});
