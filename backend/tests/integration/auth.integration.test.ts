import bcrypt from 'bcrypt';

import RefreshToken from '../../src/models/RefreshToken';
import User from '../../src/models/User';
import { hashRefreshToken } from '../../src/utils/otp';
import {
  api,
  bearer,
  registerAndVerify,
  registerUser,
  uniqueValue,
  verifyRegisteredUser,
} from './helpers';

describe('MongoDB integration: authentication', () => {
  it('registers a user with hashed credentials and no tokens before OTP verification', async () => {
    const registration = await registerUser('auth-register');

    const user = await User.findById(registration.userId).select('+password');
    expect(user).not.toBeNull();
    expect(user!.email).toBe(registration.email);
    expect(user!.role).toBe('NORMAL_USER');
    expect(user!.isVerified).toBe(false);
    expect(user!.password).not.toBe(registration.password);
    expect(await bcrypt.compare(registration.password, user!.password!)).toBe(true);
    expect(user!.otp?.code).not.toBe(registration.otp);
    expect(await bcrypt.compare(registration.otp, user!.otp?.code || '')).toBe(true);
    expect(await RefreshToken.countDocuments({ user: registration.userId })).toBe(0);
  });

  it('rejects duplicate emails and privileged registration roles in the database-backed flow', async () => {
    const registration = await registerUser('auth-duplicate');

    const duplicate = await api()
      .post('/api/v1/auth/register')
      .send({
        name: 'Duplicate User',
        email: registration.email.toUpperCase(),
        password: 'StrongPass123!',
      })
      .expect(409);
    expect(duplicate.body.success).toBe(false);

    const privileged = await api()
      .post('/api/v1/auth/register')
      .send({
        name: 'Privileged User',
        email: `admin.${uniqueValue()}@example.com`,
        password: 'StrongPass123!',
        role: 'ADMIN',
      })
      .expect(400);
    expect(privileged.body.error).toEqual(
      expect.arrayContaining([expect.objectContaining({ field: 'role' })])
    );

    expect(
      await User.countDocuments({ email: registration.email })
    ).toBe(1);
  });

  it('records failed OTP attempts, verifies the real OTP, and issues hashed refresh tokens', async () => {
    const registration = await registerUser('auth-otp');

    await api()
      .post('/api/v1/auth/verify-otp')
      .send({ userId: registration.userId, otp: '000000' })
      .expect(400);
    expect((await User.findById(registration.userId))?.otp?.attempts).toBe(1);

    const verified = await verifyRegisteredUser(registration);
    const user = await User.findById(registration.userId);
    expect(user?.isVerified).toBe(true);
    expect(user?.otp?.code).toBeUndefined();

    const storedToken = await RefreshToken.findOne({
      user: registration.userId,
      token: hashRefreshToken(verified.refreshToken),
    });
    expect(storedToken).not.toBeNull();
    expect(storedToken!.isRevoked).toBe(false);
    expect(storedToken!.token).not.toBe(verified.refreshToken);
    expect(storedToken!.expiresAt.getTime()).toBeGreaterThan(Date.now());
  });

  it('enforces verification in the protect middleware for tokens issued by login', async () => {
    const registration = await registerUser('auth-unverified');
    const login = await api()
      .post('/api/v1/auth/login')
      .send({ email: registration.email, password: registration.password })
      .expect(200);
    expect(login.body.data.tokens.accessToken).toEqual(expect.any(String));

    await api()
      .get('/api/v1/auth/me')
      .set('Authorization', bearer(login.body.data.tokens.accessToken))
      .expect(403);
  });

  it('rotates refresh tokens atomically and rejects replay of an old token', async () => {
    const user = await registerAndVerify('auth-rotation');
    const oldRefreshToken = user.refreshToken;

    const rotated = await api()
      .post('/api/v1/auth/refresh-token')
      .send({ refreshToken: oldRefreshToken })
      .expect(200);
    const newRefreshToken = rotated.body.data.refreshToken;
    expect(newRefreshToken).not.toBe(oldRefreshToken);

    const [oldRecordAfterRotation, newRecordBeforeReuse] = await Promise.all([
      RefreshToken.findOne({ token: hashRefreshToken(oldRefreshToken) }),
      RefreshToken.findOne({ token: hashRefreshToken(newRefreshToken) }),
    ]);
    expect(oldRecordAfterRotation?.isRevoked).toBe(true);
    expect(newRecordBeforeReuse?.isRevoked).toBe(false);

    await api()
      .post('/api/v1/auth/refresh-token')
      .send({ refreshToken: oldRefreshToken })
      .expect(401);

    const reused = await api()
      .post('/api/v1/auth/refresh-token')
      .send({ refreshToken: newRefreshToken })
      .expect(200);
    expect(reused.body.data.accessToken).toEqual(expect.any(String));

    const newRecordAfterReuse = await RefreshToken.findOne({
      token: hashRefreshToken(newRefreshToken),
    });
    expect(newRecordAfterReuse?.isRevoked).toBe(true);
  });

  it('revokes the session on logout so the refresh token cannot be reused', async () => {
    const user = await registerAndVerify('auth-logout');

    await api()
      .post('/api/v1/auth/logout')
      .set('Authorization', bearer(user.accessToken))
      .send({ refreshToken: user.refreshToken })
      .expect(200);

    const stored = await RefreshToken.findOne({
      token: hashRefreshToken(user.refreshToken),
    });
    expect(stored?.isRevoked).toBe(true);

    await api()
      .post('/api/v1/auth/refresh-token')
      .send({ refreshToken: user.refreshToken })
      .expect(401);
  });
});
