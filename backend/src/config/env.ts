import dotenv from 'dotenv';
import path from 'path';

// Load environment variables from .env file
dotenv.config({ path: path.resolve(process.cwd(), '.env') });

export interface IConfig {
  PORT: number;
  MONGODB_URI: string;
  MONGODB_URI_TEST: string;
  JWT_SECRET: string;
  JWT_EXPIRE: string;
  JWT_REFRESH_SECRET: string;
  JWT_REFRESH_EXPIRE: string;
  OTP_EXPIRY: number; // in minutes
  OTP_LENGTH: number;
  OTP_MAX_ATTEMPTS: number;
  OTP_MAX_RESENDS: number;
  OTP_RESEND_COOLDOWN_SECONDS: number;
  AUTH_LOGIN_MAX_ATTEMPTS: number;
  AUTH_LOGIN_LOCK_MINUTES: number;
  NODE_ENV: 'development' | 'production' | 'test';
  SMS_PROVIDER: string;
  UPLOAD_DIR: string;
  MAX_FILE_SIZE: number; // in bytes
  RATE_LIMIT_WINDOW_MS: number;
  RATE_LIMIT_MAX_REQUESTS: number;
  CORS_ORIGIN: string;
  TRUST_PROXY: number | boolean;
  ENABLE_API_DOCS: boolean;
  LOG_LEVEL: string;
  FIREBASE_PROJECT_ID: string;
  FIREBASE_CLIENT_EMAIL: string;
  FIREBASE_PRIVATE_KEY: string;
  FIREBASE_PUSH_RETRY_BATCH_SIZE: number;
  FIREBASE_PUSH_RETRY_INTERVAL_MS: number;
  ALLOW_NON_TRANSACTIONAL_WRITES: boolean;
  isProduction: boolean;
  isDevelopment: boolean;
  isTest: boolean;
}

const nodeEnv = (process.env.NODE_ENV || 'development') as 'development' | 'production' | 'test';

export const config: IConfig = {
  PORT: parseInt(process.env.PORT || '5000', 10),
  MONGODB_URI: process.env.MONGODB_URI || 'mongodb://localhost:27017/cricket_hub',
  MONGODB_URI_TEST:
    process.env.MONGODB_URI_TEST || 'mongodb://127.0.0.1:27019/cricket_hub_integration_test',
  JWT_SECRET: process.env.JWT_SECRET || 'cricket_hub_jwt_secret_key_change_in_production',
  JWT_EXPIRE: process.env.JWT_EXPIRE || '24h',
  JWT_REFRESH_SECRET: process.env.JWT_REFRESH_SECRET || 'cricket_hub_refresh_secret_key_change_in_production',
  JWT_REFRESH_EXPIRE: process.env.JWT_REFRESH_EXPIRE || '7d',
  OTP_EXPIRY: parseInt(process.env.OTP_EXPIRY || '5', 10),
  OTP_LENGTH: parseInt(process.env.OTP_LENGTH || '6', 10),
  OTP_MAX_ATTEMPTS: parseInt(process.env.OTP_MAX_ATTEMPTS || '5', 10),
  OTP_MAX_RESENDS: parseInt(process.env.OTP_MAX_RESENDS || '3', 10),
  OTP_RESEND_COOLDOWN_SECONDS: parseInt(process.env.OTP_RESEND_COOLDOWN_SECONDS || '60', 10),
  AUTH_LOGIN_MAX_ATTEMPTS: parseInt(process.env.AUTH_LOGIN_MAX_ATTEMPTS || '10', 10),
  AUTH_LOGIN_LOCK_MINUTES: parseInt(process.env.AUTH_LOGIN_LOCK_MINUTES || '15', 10),
  NODE_ENV: nodeEnv,
  SMS_PROVIDER: process.env.SMS_PROVIDER || 'mock',
  UPLOAD_DIR: process.env.UPLOAD_DIR || 'uploads',
  MAX_FILE_SIZE: parseInt(process.env.MAX_FILE_SIZE || '5242880', 10), // 5MB default
  RATE_LIMIT_WINDOW_MS: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000', 10), // 15 mins default
  RATE_LIMIT_MAX_REQUESTS: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100', 10),
  CORS_ORIGIN: process.env.CORS_ORIGIN || '*',
  TRUST_PROXY:
    process.env.TRUST_PROXY === 'true'
      ? true
      : Number.isFinite(Number(process.env.TRUST_PROXY))
        ? Number(process.env.TRUST_PROXY)
        : nodeEnv === 'production',
  ENABLE_API_DOCS:
    process.env.ENABLE_API_DOCS === 'true' ||
    (process.env.ENABLE_API_DOCS !== 'false' && nodeEnv !== 'production'),
  LOG_LEVEL: process.env.LOG_LEVEL || (nodeEnv === 'production' ? 'info' : 'debug'),
  FIREBASE_PROJECT_ID: process.env.FIREBASE_PROJECT_ID || '',
  FIREBASE_CLIENT_EMAIL: process.env.FIREBASE_CLIENT_EMAIL || '',
  FIREBASE_PRIVATE_KEY: process.env.FIREBASE_PRIVATE_KEY || '',
  FIREBASE_PUSH_RETRY_BATCH_SIZE: parseInt(process.env.FIREBASE_PUSH_RETRY_BATCH_SIZE || '50', 10),
  FIREBASE_PUSH_RETRY_INTERVAL_MS: parseInt(process.env.FIREBASE_PUSH_RETRY_INTERVAL_MS || '60000', 10),
  ALLOW_NON_TRANSACTIONAL_WRITES: process.env.ALLOW_NON_TRANSACTIONAL_WRITES === 'true',
  isProduction: nodeEnv === 'production',
  isDevelopment: nodeEnv === 'development',
  isTest: nodeEnv === 'test',
};

if (config.isProduction) {
  const insecureSecrets = [
    'cricket_hub_jwt_secret_key_change_in_production',
    'cricket_hub_refresh_secret_key_change_in_production',
  ];
  if (
    insecureSecrets.includes(config.JWT_SECRET) ||
    insecureSecrets.includes(config.JWT_REFRESH_SECRET) ||
    config.JWT_SECRET.length < 32 ||
    config.JWT_REFRESH_SECRET.length < 32 ||
    config.JWT_SECRET === config.JWT_REFRESH_SECRET
  ) {
    throw new Error('Production requires strong, distinct JWT_SECRET and JWT_REFRESH_SECRET values.');
  }
  if (config.CORS_ORIGIN === '*') {
    throw new Error('Production requires an explicit CORS_ORIGIN; wildcard origins are not allowed.');
  }
}

export const env = config;
export default config;
