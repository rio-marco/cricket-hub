export interface SanitizeUserOptions {
  includeContact?: boolean;
  includeRole?: boolean;
  includeStatus?: boolean;
  includeTimestamps?: boolean;
}

const SENSITIVE_KEYS = new Set([
  'password',
  'otp',
  'fcmToken',
  'authLockout',
  'refreshToken',
  'refreshTokens',
  '__v',
]);

export const sanitizeUser = (user: any, options: SanitizeUserOptions = {}): any => {
  if (!user) return user;
  const source = typeof user.toObject === 'function' ? user.toObject() : { ...user };
  const {
    includeContact = true,
    includeRole = true,
    includeStatus = true,
    includeTimestamps = true,
  } = options;

  const allowed = new Set<string>(['_id', 'id', 'name', 'avatar']);
  if (includeContact) {
    allowed.add('email');
    allowed.add('phone');
  }
  if (includeRole) allowed.add('role');
  if (includeStatus) {
    allowed.add('isVerified');
    allowed.add('isBlocked');
  }
  if (includeTimestamps) {
    allowed.add('createdAt');
    allowed.add('updatedAt');
  }

  const out: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(source)) {
    if (SENSITIVE_KEYS.has(key)) continue;
    if (allowed.has(key)) out[key] = value;
  }
  return out;
};

export default sanitizeUser;
