import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { MESSAGES } from '../constants/messages';
import { ApiError } from '../utils/apiError';
import {
  generateOTP,
  hashOTP,
  hashRefreshToken,
  isOTPExpired,
  verifyOTPHash,
} from '../utils/otp';
import User, { IUser } from '../models/User';
import RefreshToken from '../models/RefreshToken';

export interface IRegisterData {
  name: string;
  email?: string;
  phone?: string;
  password: string;
  role?: string;
}

export interface ILoginData {
  email?: string;
  phone?: string;
  password: string;
}

export interface IAuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: string;
}

export interface IAuthResult {
  user: Partial<IUser> & { _id: string };
  userId?: string;
  tokens?: IAuthTokens;
  message?: string;
  otp?: string;
}

export class AuthService {
  /**
   * Helper to strip sensitive fields (password, otp) from user object
   */
  public sanitizeUser(user: any): Partial<IUser> & { _id: string } {
    const userObj = user.toObject ? user.toObject() : { ...user };
    delete userObj.password;
    delete userObj.otp;
    delete userObj.__v;
    return userObj;
  }

  /**
   * Calculate future expiration Date from a duration string or number of days
   */
  private calculateExpiryDate(expireString: string = '7d'): Date {
    const match = expireString.match(/^(\d+)([dhms])$/);
    if (!match) {
      // Default to 7 days
      return new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    }
    const val = parseInt(match[1], 10);
    const unit = match[2];
    let multiplier = 24 * 60 * 60 * 1000;
    if (unit === 'h') multiplier = 60 * 60 * 1000;
    else if (unit === 'm') multiplier = 60 * 1000;
    else if (unit === 's') multiplier = 1000;
    return new Date(Date.now() + val * multiplier);
  }

  /**
   * Generate JWT Access and Refresh tokens, persist RefreshToken in MongoDB
   */
  public async generateTokens(user: any): Promise<IAuthTokens> {
    const userId = user._id ? user._id.toString() : user.id;

    const accessPayload = {
      id: userId,
      userId,
      role: user.role,
      email: user.email,
    };

    const accessToken = jwt.sign(accessPayload, env.JWT_SECRET, {
      expiresIn: (env.JWT_EXPIRE || '24h') as any,
    });

    const refreshPayload = {
      id: userId,
      tokenType: 'refresh',
    };

    const refreshToken = jwt.sign(refreshPayload, env.JWT_REFRESH_SECRET, {
      expiresIn: (env.JWT_REFRESH_EXPIRE || '7d') as any,
    });

    const expiresAt = this.calculateExpiryDate(env.JWT_REFRESH_EXPIRE || '7d');

    await RefreshToken.create({
      user: userId,
      token: hashRefreshToken(refreshToken),
      expiresAt,
      isRevoked: false,
    });

    return {
      accessToken,
      refreshToken,
      expiresIn: env.JWT_EXPIRE || '24h',
    };
  }

  public async register(data: IRegisterData): Promise<IAuthResult> {
    if (data.email) {
      const existingEmail = await User.findOne({ email: data.email.toLowerCase() });
      if (existingEmail) {
        throw ApiError.conflict(MESSAGES.AUTH.EMAIL_ALREADY_EXISTS || 'Email is already registered.');
      }
    }

    if (data.phone) {
      const existingPhone = await User.findOne({ phone: data.phone });
      if (existingPhone) {
        throw ApiError.conflict(MESSAGES.AUTH.PHONE_ALREADY_EXISTS || 'Phone number is already registered.');
      }
    }

    const otpCode = generateOTP(env.OTP_LENGTH || 6);
    const otpHash = await hashOTP(otpCode);
    const expiresAt = new Date(Date.now() + (env.OTP_EXPIRY || 5) * 60 * 1000);

    const newUser = await User.create({
      name: data.name.trim(),
      email: data.email ? data.email.toLowerCase().trim() : undefined,
      phone: data.phone ? data.phone.trim() : undefined,
      password: data.password,
      role: 'NORMAL_USER',
      isVerified: false,
      isBlocked: false,
      otp: {
        code: otpHash,
        expiresAt,
        purpose: 'VERIFICATION',
        attempts: 0,
        resendCount: 0,
        lastSentAt: new Date(),
      },
    });

    return {
      user: this.sanitizeUser(newUser),
      userId: newUser._id.toString(),
      message: MESSAGES.AUTH.REGISTER_SUCCESS,
      otp: env.isDevelopment ? otpCode : undefined,
    };
  }

  /**
   * Authenticate user with credentials, issue new token pair
   */
  public async login(data: ILoginData): Promise<{ user: Partial<IUser> & { _id: string }; tokens: IAuthTokens }> {
    const query: any = {};
    if (data.email) {
      query.email = data.email.toLowerCase().trim();
    } else if (data.phone) {
      query.phone = data.phone.trim();
    } else {
      throw ApiError.badRequest('Please provide either an email or a phone number to log in.');
    }

    // Password is select: false by default in Mongoose schema
    const user = await User.findOne(query).select('+password');
    if (!user) {
      throw ApiError.unauthorized(MESSAGES.AUTH.INVALID_CREDENTIALS || 'Invalid credentials.');
    }

    if (user.isBlocked) {
      throw ApiError.forbidden(MESSAGES.AUTH.ACCOUNT_BLOCKED || 'Your account has been suspended.');
    }

    const isPasswordValid = await user.comparePassword(data.password);
    if (!isPasswordValid) {
      throw ApiError.unauthorized(MESSAGES.AUTH.INVALID_CREDENTIALS || 'Invalid credentials.');
    }

    const tokens = await this.generateTokens(user);

    return {
      user: this.sanitizeUser(user),
      tokens,
    };
  }

  /**
   * Verify OTP submitted by user
   */
  public async verifyOTP(
    userId: string,
    otp: string
  ): Promise<{ user: Partial<IUser> & { _id: string }; tokens: IAuthTokens; message: string }> {
    const user = await User.findById(userId);
    if (!user) {
      throw ApiError.notFound(MESSAGES.AUTH.USER_NOT_FOUND || 'User not found.');
    }

    if (user.isVerified) {
      throw ApiError.badRequest(MESSAGES.AUTH.ACCOUNT_ALREADY_VERIFIED || 'This account is already verified.');
    }

    if (!user.otp || !user.otp.code) {
      throw ApiError.badRequest(MESSAGES.AUTH.INVALID_OTP || 'Invalid or incorrect OTP.');
    }

    if (user.otp.purpose && user.otp.purpose !== 'VERIFICATION') {
      throw ApiError.badRequest(MESSAGES.AUTH.OTP_PURPOSE_INVALID || 'This verification code cannot be used for this action.');
    }

    if (user.otp.expiresAt && isOTPExpired(user.otp.expiresAt)) {
      throw ApiError.badRequest(MESSAGES.AUTH.OTP_EXPIRED || 'OTP has expired. Please request a new one.');
    }

    if ((user.otp.attempts ?? 0) >= env.OTP_MAX_ATTEMPTS) {
      throw ApiError.tooManyRequests(MESSAGES.AUTH.OTP_ATTEMPTS_EXCEEDED || 'Too many incorrect OTP attempts.');
    }

    const isOtpValid = await verifyOTPHash(otp.trim(), user.otp.code);
    if (!isOtpValid) {
      user.otp.attempts = (user.otp.attempts ?? 0) + 1;
      await user.save();
      throw ApiError.badRequest(MESSAGES.AUTH.INVALID_OTP || 'Invalid or incorrect OTP.');
    }

    user.isVerified = true;
    user.otp = undefined;
    await user.save();

    return {
      user: this.sanitizeUser(user),
      tokens: await this.generateTokens(user),
      message: MESSAGES.AUTH.OTP_VERIFIED || 'OTP verified successfully.',
    };
  }

  public async resendOTP(data: {
    userId?: string;
    email?: string;
    phone?: string;
  }): Promise<{ userId: string; message: string; otp?: string }> {
    const query: any = {};
    if (data.userId) {
      query._id = data.userId;
    } else if (data.email) {
      query.email = data.email.toLowerCase().trim();
    } else if (data.phone) {
      query.phone = data.phone.trim();
    } else {
      throw ApiError.badRequest('A user ID, email, or phone number is required.');
    }

    const user = await User.findOne(query);
    if (!user) {
      throw ApiError.notFound(MESSAGES.AUTH.USER_NOT_FOUND || 'User not found.');
    }

    if (user.isVerified) {
      throw ApiError.badRequest(MESSAGES.AUTH.ACCOUNT_ALREADY_VERIFIED || 'This account is already verified.');
    }

    const cooldownMs = env.OTP_RESEND_COOLDOWN_SECONDS * 1000;
    if (user.otp?.lastSentAt && Date.now() - new Date(user.otp.lastSentAt).getTime() < cooldownMs) {
      throw ApiError.tooManyRequests(
        MESSAGES.AUTH.OTP_RESEND_COOLDOWN || 'Please wait before requesting another verification code.'
      );
    }

    if ((user.otp?.resendCount ?? 0) >= env.OTP_MAX_RESENDS) {
      throw ApiError.tooManyRequests(
        MESSAGES.AUTH.OTP_RESEND_LIMIT || 'The maximum number of OTP resends has been reached.'
      );
    }

    const otpCode = generateOTP(env.OTP_LENGTH || 6);
    const otpHash = await hashOTP(otpCode);
    user.otp = {
      code: otpHash,
      expiresAt: new Date(Date.now() + (env.OTP_EXPIRY || 5) * 60 * 1000),
      purpose: 'VERIFICATION',
      attempts: 0,
      resendCount: (user.otp?.resendCount ?? 0) + 1,
      lastSentAt: new Date(),
    };
    await user.save();

    return {
      userId: user._id.toString(),
      message: MESSAGES.AUTH.OTP_SENT || 'A new verification code has been sent.',
      otp: env.isDevelopment ? otpCode : undefined,
    };
  }

  /**
   * Generate OTP for password recovery
   */
  public async forgotPassword(
    data: { email?: string; phone?: string }
  ): Promise<{ userId: string; message: string; otp?: string }> {
    const query: any = {};
    if (data.email) {
      query.email = data.email.toLowerCase().trim();
    } else if (data.phone) {
      query.phone = data.phone.trim();
    } else {
      throw ApiError.badRequest('Please provide either email or phone number.');
    }

    const user = await User.findOne(query);
    if (!user) {
      throw ApiError.notFound(MESSAGES.AUTH.USER_NOT_FOUND || 'No user account found with this identifier.');
    }

    const otpCode = generateOTP(env.OTP_LENGTH || 6);
    const otpHash = await hashOTP(otpCode);
    const expiresAt = new Date(Date.now() + (env.OTP_EXPIRY || 5) * 60 * 1000);

    user.otp = {
      code: otpHash,
      expiresAt,
      purpose: 'PASSWORD_RESET',
      attempts: 0,
      resendCount: (user.otp?.resendCount ?? 0) + 1,
      lastSentAt: new Date(),
    };
    await user.save();

    return {
      userId: user._id.toString(),
      message: MESSAGES.AUTH.OTP_SENT || 'Password reset OTP sent successfully.',
      otp: env.isDevelopment ? otpCode : undefined,
    };
  }

  /**
   * Reset user password using verified OTP
   */
  public async resetPassword(
    userId: string,
    otp: string,
    newPassword: string
  ): Promise<{ message: string }> {
    const user = await User.findById(userId).select('+password');
    if (!user) {
      throw ApiError.notFound(MESSAGES.AUTH.USER_NOT_FOUND || 'User not found.');
    }

    if (!user.otp || !user.otp.code) {
      throw ApiError.badRequest(MESSAGES.AUTH.INVALID_OTP || 'Invalid or incorrect OTP.');
    }

    if (user.otp.purpose && user.otp.purpose !== 'PASSWORD_RESET') {
      throw ApiError.badRequest(
        MESSAGES.AUTH.OTP_PURPOSE_INVALID || 'This verification code cannot be used for this action.'
      );
    }

    if (user.otp.expiresAt && isOTPExpired(user.otp.expiresAt)) {
      throw ApiError.badRequest(MESSAGES.AUTH.OTP_EXPIRED || 'OTP has expired. Please request a new one.');
    }

    if ((user.otp.attempts ?? 0) >= env.OTP_MAX_ATTEMPTS) {
      throw ApiError.tooManyRequests(
        MESSAGES.AUTH.OTP_ATTEMPTS_EXCEEDED || 'Too many incorrect OTP attempts. Please request a new code.'
      );
    }

    const isOtpValid = await verifyOTPHash(otp.trim(), user.otp.code);
    if (!isOtpValid) {
      user.otp.attempts = (user.otp.attempts ?? 0) + 1;
      await user.save();
      throw ApiError.badRequest(MESSAGES.AUTH.INVALID_OTP || 'Invalid or incorrect OTP.');
    }

    // Set new password (pre-save hook hashes it automatically)
    user.password = newPassword;
    user.otp = undefined;
    await user.save();

    // Invalidate all existing refresh tokens for security
    await RefreshToken.updateMany({ user: user._id }, { isRevoked: true });

    return {
      message: MESSAGES.AUTH.PASSWORD_RESET_SUCCESS || 'Password has been reset successfully.',
    };
  }

  /**
   * Change password for authenticated user
   */
  public async changePassword(
    userId: string,
    currentPassword: string,
    newPassword: string
  ): Promise<{ message: string }> {
    const user = await User.findById(userId).select('+password');
    if (!user) {
      throw ApiError.notFound(MESSAGES.AUTH.USER_NOT_FOUND || 'User not found.');
    }

    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) {
      throw ApiError.badRequest('Current password does not match.');
    }

    if (currentPassword === newPassword) {
      throw ApiError.badRequest('New password cannot be the same as your current password.');
    }

    user.password = newPassword;
    await user.save();

    // Revoke old refresh tokens to ensure re-authentication
    await RefreshToken.updateMany({ user: user._id }, { isRevoked: true });

    return {
      message: 'Password changed successfully. Please log in with your new password.',
    };
  }

  /**
   * Rotate refresh token and issue new token pair
   */
  public async refreshToken(token: string): Promise<IAuthTokens> {
    if (!token) {
      throw ApiError.badRequest(MESSAGES.AUTH.REFRESH_TOKEN_REQUIRED || 'Refresh token is required.');
    }

    let decoded: any;
    try {
      decoded = jwt.verify(token, env.JWT_REFRESH_SECRET);
    } catch (err: any) {
      throw ApiError.unauthorized(MESSAGES.AUTH.REFRESH_TOKEN_INVALID || 'Invalid or expired refresh token.');
    }

    const tokenHash = hashRefreshToken(token);
    const storedToken = await RefreshToken.findOneAndUpdate(
      {
        token: tokenHash,
        isRevoked: false,
        expiresAt: { $gt: new Date() },
      },
      { $set: { isRevoked: true } },
      { new: true }
    );
    if (!storedToken) {
      throw ApiError.unauthorized(MESSAGES.AUTH.REFRESH_TOKEN_INVALID || 'Refresh token revoked or expired.');
    }

    const user = await User.findById(storedToken.user);
    if (!user) {
      throw ApiError.unauthorized(MESSAGES.AUTH.USER_NOT_FOUND || 'User belonging to this token no longer exists.');
    }

    if (user.isBlocked) {
      throw ApiError.forbidden(MESSAGES.AUTH.ACCOUNT_BLOCKED || 'Your account is suspended.');
    }

    return this.generateTokens(user);
  }

  /**
   * Revoke refresh token(s) on user logout
   */
  public async logout(userId: string, refreshTokenString?: string): Promise<{ message: string }> {
    if (refreshTokenString) {
      await RefreshToken.updateOne(
        { token: hashRefreshToken(refreshTokenString), user: userId },
        { isRevoked: true }
      );
    } else {
      await RefreshToken.updateMany({ user: userId }, { isRevoked: true });
    }

    return {
      message: MESSAGES.AUTH.LOGOUT_SUCCESS || 'Logged out successfully.',
    };
  }

  /**
   * Get user profile by ID
   */
  public async getProfile(userId: string): Promise<Partial<IUser> & { _id: string }> {
    const user = await User.findById(userId);
    if (!user) {
      throw ApiError.notFound(MESSAGES.AUTH.USER_NOT_FOUND || 'User not found.');
    }
    return this.sanitizeUser(user);
  }

  /**
   * Update profile details for a user
   */
  public async updateProfile(
    userId: string,
    data: { name?: string; email?: string; phone?: string; avatar?: string; fcmToken?: string }
  ): Promise<Partial<IUser> & { _id: string }> {
    const user = await User.findById(userId);
    if (!user) {
      throw ApiError.notFound(MESSAGES.AUTH.USER_NOT_FOUND || 'User not found.');
    }

    // Validate email conflict
    if (data.email && data.email.toLowerCase() !== user.email) {
      const existingEmail = await User.findOne({
        email: data.email.toLowerCase(),
        _id: { $ne: userId },
      });
      if (existingEmail) {
        throw ApiError.conflict(MESSAGES.AUTH.EMAIL_ALREADY_EXISTS || 'Email is already in use by another account.');
      }
      user.email = data.email.toLowerCase().trim();
    }

    // Validate phone conflict
    if (data.phone && data.phone !== user.phone) {
      const existingPhone = await User.findOne({
        phone: data.phone,
        _id: { $ne: userId },
      });
      if (existingPhone) {
        throw ApiError.conflict(MESSAGES.AUTH.PHONE_ALREADY_EXISTS || 'Phone number is already in use by another account.');
      }
      user.phone = data.phone.trim();
    }

    if (data.name !== undefined) user.name = data.name.trim();
    if (data.avatar !== undefined) user.avatar = data.avatar;
    if (data.fcmToken !== undefined) user.fcmToken = data.fcmToken;

    await user.save();

    return this.sanitizeUser(user);
  }
}

export const authService = new AuthService();
export default authService;
