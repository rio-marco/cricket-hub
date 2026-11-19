import rateLimit from 'express-rate-limit';
import { Request, Response, NextFunction } from 'express';
import { env } from '../config/env';
import { ApiResponse } from '../utils/apiResponse';

/**
 * Custom rate limit exceeded response handler
 */
const rateLimitHandler = (
  _req: Request,
  res: Response,
  _next: NextFunction,
  options: any
): void => {
  ApiResponse.error(
    res,
    options.statusCode || 429,
    options.message || 'Too many requests from this IP address, please try again later.'
  );
};

/**
 * General API Rate Limiter
 * Default: 100 requests per 15 minutes
 */
export const apiLimiter = rateLimit({
  windowMs: env.RATE_LIMIT_WINDOW_MS || 15 * 60 * 1000,
  max: env.RATE_LIMIT_MAX_REQUESTS || 100,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: 'Too many requests from this IP, please try again after 15 minutes.',
  handler: rateLimitHandler,
  skip: () => env.isTest,
});

/**
 * Authentication Endpoints Rate Limiter
 * More restrictive: 20 requests per 15 minutes to prevent brute-force attacks
 */
export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: 'Too many authentication attempts from this IP, please try again after 15 minutes.',
  handler: rateLimitHandler,
  skip: () => env.isTest,
});

export const otpLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: 'Too many verification code requests from this IP, please try again after 15 minutes.',
  handler: rateLimitHandler,
  skip: () => env.isTest,
});

/**
 * Live Cricket Scoring Rate Limiter
 * Permissive: 200 requests per 15 minutes to allow rapid ball-by-ball updates
 */
export const scoringLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: 'Too many scoring updates sent, please slow down and try again shortly.',
  handler: rateLimitHandler,
  skip: () => env.isTest,
});

export default {
  apiLimiter,
  authLimiter,
  otpLimiter,
  scoringLimiter,
};
