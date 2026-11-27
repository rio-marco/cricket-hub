import jwt from 'jsonwebtoken';
import { env } from '../../config/env';

jest.mock('../../utils/otp', () => ({
  generateOTP: jest.fn(() => '123456'),
  hashOTP: jest.fn(async () => 'hashed-otp'),
  verifyOTPHash: jest.fn(async (otp: string) => otp === '123456'),
  hashRefreshToken: jest.fn((token: string) => `hashed:${token}`),
  isOTPExpired: jest.fn(() => false),
}));

jest.mock('../../models/User', () => ({
  __esModule: true,
  default: {
    findOne: jest.fn(),
    create: jest.fn(),
    findById: jest.fn(),
  },
}));

jest.mock('../../models/RefreshToken', () => ({
  __esModule: true,
  default: {
    create: jest.fn(),
    findOneAndUpdate: jest.fn(),
    updateOne: jest.fn(),
    updateMany: jest.fn(),
  },
}));

import User from '../../models/User';
import RefreshToken from '../../models/RefreshToken';
import { verifyOTPHash } from '../../utils/otp';
import { AuthService } from '../auth.service';

const makeUser = (overrides: Record<string, any> = {}): any => {
  const user = {
    _id: 'u1',
    name: 'Test User',
    email: 'test@example.com',
    phone: undefined,
    role: 'NORMAL_USER',
    isVerified: false,
    isBlocked: false,
    otp: {
      code: 'hashed-otp',
      expiresAt: new Date(Date.now() + 60_000),
      purpose: 'VERIFICATION',
      attempts: 0,
      resendCount: 0,
      lastSentAt: new Date(),
    },
    save: jest.fn().mockResolvedValue(undefined),
    ...overrides,
  };

  return {
    ...user,
    toObject: () => {
      const { save, ...plain } = user;
      return { ...plain };
    },
  };
};

describe('AuthService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    (verifyOTPHash as jest.Mock).mockImplementation(async (otp: string) => otp === '123456');
  });

  it('registers public users as NORMAL_USER without issuing tokens', async () => {
    (User.findOne as jest.Mock).mockResolvedValue(null);
    (User.create as jest.Mock).mockImplementation(async (payload: any) => makeUser(payload));

    const result = await new AuthService().register({
      name: 'Test User',
      email: 'test@example.com',
      password: 'Password1',
      role: 'ADMIN',
    });

    expect(User.create).toHaveBeenCalledWith(
      expect.objectContaining({ role: 'NORMAL_USER', isVerified: false })
    );
    expect(result.userId).toBe('u1');
    expect(result.tokens).toBeUndefined();
    expect(result.user).not.toHaveProperty('password');
    expect(result.user).not.toHaveProperty('otp');
  });

  it('issues tokens when verification succeeds', async () => {
    const user = makeUser();
    (User.findById as jest.Mock).mockResolvedValue(user);
    (RefreshToken.create as jest.Mock).mockResolvedValue({});

    const result = await new AuthService().verifyOTP('u1', '123456');

    expect(result.tokens.accessToken).toEqual(expect.any(String));
    expect(result.tokens.refreshToken).toEqual(expect.any(String));
    expect(user.isVerified).toBe(true);
    expect(user.otp).toBeUndefined();
  });

  it('increments OTP attempts on an incorrect code', async () => {
    const user = makeUser();
    (User.findById as jest.Mock).mockResolvedValue(user);
    (verifyOTPHash as jest.Mock).mockResolvedValueOnce(false);

    await expect(new AuthService().verifyOTP('u1', '000000')).rejects.toMatchObject({
      statusCode: 400,
    });
    expect(user.otp.attempts).toBe(1);
  });

  it('stores hashed refresh tokens and atomically rotates them', async () => {
    const rawToken = jwt.sign(
      { id: 'u1', tokenType: 'refresh' },
      env.JWT_REFRESH_SECRET,
      { expiresIn: '7d' }
    );
    (RefreshToken.findOneAndUpdate as jest.Mock).mockResolvedValue({
      user: 'u1',
      expiresAt: new Date(Date.now() + 60_000),
    });
    (User.findById as jest.Mock).mockResolvedValue(makeUser({ isVerified: true }));
    (RefreshToken.create as jest.Mock).mockResolvedValue({});

    const result = await new AuthService().refreshToken(rawToken);

    expect(RefreshToken.findOneAndUpdate).toHaveBeenCalledWith(
      expect.objectContaining({ token: `hashed:${rawToken}`, isRevoked: false }),
      expect.anything(),
      expect.anything()
    );
    expect(RefreshToken.create).toHaveBeenCalledWith(
      expect.objectContaining({ token: expect.stringMatching(/^hashed:/) })
    );
    expect(result.accessToken).toEqual(expect.any(String));
  });

  it('hashes the supplied refresh token on logout', async () => {
    await new AuthService().logout('u1', 'raw-refresh-token');

    expect(RefreshToken.updateOne).toHaveBeenCalledWith(
      expect.objectContaining({ token: 'hashed:raw-refresh-token' }),
      { isRevoked: true }
    );
  });

  it('locks account after configured failed login attempts', async () => {
    const user = makeUser({ isVerified: true, isBlocked: false, comparePassword: jest.fn().mockResolvedValue(false), save: jest.fn().mockResolvedValue(undefined) });
    (User.findOne as jest.Mock).mockReturnValue({ select: jest.fn().mockResolvedValue(user) });
    (env as any).AUTH_LOGIN_MAX_ATTEMPTS = 2;
    (env as any).AUTH_LOGIN_LOCK_MINUTES = 15;

    await expect(new AuthService().login({ email: 'test@example.com', password: 'bad' })).rejects.toMatchObject({ statusCode: 401 });
    expect(user.authLockout.failedAttempts).toBe(1);

    await expect(new AuthService().login({ email: 'test@example.com', password: 'bad' })).rejects.toMatchObject({ statusCode: 401 });
    expect(user.authLockout.lockUntil).toBeInstanceOf(Date);
    expect(user.authLockout.failedAttempts).toBe(0);
  });

  it('rejects login while lockout is active and clears lockout on success', async () => {
    const locked = makeUser({ isVerified: true, isBlocked: false, authLockout: { failedAttempts: 0, lockUntil: new Date(Date.now() + 60000) }, comparePassword: jest.fn().mockResolvedValue(true), save: jest.fn().mockResolvedValue(undefined) });
    (User.findOne as jest.Mock).mockReturnValue({ select: jest.fn().mockResolvedValue(locked) });
    await expect(new AuthService().login({ email: 'test@example.com', password: 'Password1' })).rejects.toMatchObject({ statusCode: 429 });

    const recover = makeUser({ isVerified: true, isBlocked: false, authLockout: { failedAttempts: 2, lockUntil: undefined }, comparePassword: jest.fn().mockResolvedValue(true), save: jest.fn().mockResolvedValue(undefined) });
    (User.findOne as jest.Mock).mockReturnValue({ select: jest.fn().mockResolvedValue(recover) });
    (RefreshToken.create as jest.Mock).mockResolvedValue({});
    const result = await new AuthService().login({ email: 'test@example.com', password: 'Password1' });
    expect(result.tokens.accessToken).toEqual(expect.any(String));
    expect(recover.authLockout.failedAttempts).toBe(0);
  });
});
