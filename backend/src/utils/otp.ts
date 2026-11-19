import crypto from 'crypto';
import config from '../config/env';

/**
 * Generate a cryptographically secure random numeric OTP string of specified length
 *
 * @param length Length of the OTP (defaults to config.OTP_LENGTH or 6)
 * @returns Numeric OTP string with leading zeroes if necessary
 */
export const generateOTP = (length: number = config.OTP_LENGTH || 6): string => {
  const safeLength = length > 0 ? length : 6;
  const max = Math.pow(10, safeLength);
  const min = Math.pow(10, safeLength - 1);
  const randomValue = crypto.randomInt(min, max);
  return randomValue.toString();
};

/**
 * Check if the given OTP expiration timestamp has passed
 *
 * @param expiresAt Date or ISO string or timestamp of OTP expiration
 * @returns True if expired, false otherwise
 */
export const isOTPExpired = (expiresAt: Date | string | number): boolean => {
  if (!expiresAt) {
    return true;
  }
  const expiryTime = new Date(expiresAt).getTime();
  return Date.now() > expiryTime;
};

/**
 * Calculate future expiration Date for an OTP based on minutes
 *
 * @param minutes Duration in minutes (defaults to config.OTP_EXPIRY or 5)
 * @returns Date instance in future
 */
export const getOTPExpiry = (minutes: number = config.OTP_EXPIRY || 5): Date => {
  const safeMinutes = minutes > 0 ? minutes : 5;
  return new Date(Date.now() + safeMinutes * 60 * 1000);
};

export default {
  generateOTP,
  isOTPExpired,
  getOTPExpiry,
};
