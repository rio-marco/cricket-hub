type Bucket = { count: number; resetAt: number };

const buckets = new Map<string, Bucket>();
const MAX_BUCKETS = 5000;

export interface SocketRateLimitOptions {
  windowMs: number;
  max: number;
  keyPrefix: string;
}

export const checkSocketRateLimit = (
  socketId: string,
  options: SocketRateLimitOptions
): { allowed: boolean; retryAfterMs: number } => {
  const now = Date.now();
  if (buckets.size > MAX_BUCKETS) {
    for (const [key, bucket] of buckets) {
      if (bucket.resetAt <= now || buckets.size > MAX_BUCKETS) buckets.delete(key);
      else break;
    }
  }
  const key = `${options.keyPrefix}:${socketId}`;
  const existing = buckets.get(key);
  if (!existing || existing.resetAt <= now) {
    buckets.set(key, { count: 1, resetAt: now + options.windowMs });
    return { allowed: true, retryAfterMs: 0 };
  }
  if (existing.count >= options.max) {
    return { allowed: false, retryAfterMs: Math.max(existing.resetAt - now, 0) };
  }
  existing.count += 1;
  return { allowed: true, retryAfterMs: 0 };
};

export const clearSocketRateLimit = (socketId: string): void => {
  for (const key of buckets.keys()) {
    if (key.endsWith(`:${socketId}`) || key.includes(`:${socketId}:`)) buckets.delete(key);
  }
};

export const _resetSocketRateLimitForTests = (): void => {
  buckets.clear();
};
