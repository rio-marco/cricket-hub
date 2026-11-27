import { checkSocketRateLimit, _resetSocketRateLimitForTests } from '../rateLimit';

describe('socket rate limit', () => {
  beforeEach(() => _resetSocketRateLimitForTests());

  it('blocks after max requests in window', () => {
    const opts = { keyPrefix: 'test', windowMs: 60_000, max: 2 };
    expect(checkSocketRateLimit('s1', opts).allowed).toBe(true);
    expect(checkSocketRateLimit('s1', opts).allowed).toBe(true);
    const third = checkSocketRateLimit('s1', opts);
    expect(third.allowed).toBe(false);
    expect(third.retryAfterMs).toBeGreaterThan(0);
  });
});
