import { NextFunction, Request, Response } from 'express';

const hasUnsafeKey = (key: string): boolean => key.startsWith('$') || key.includes('.');

const sanitizeValue = (value: unknown): unknown => {
  if (Array.isArray(value)) {
    return value.map(sanitizeValue);
  }

  if (value && typeof value === 'object') {
    const sanitized: Record<string, unknown> = {};
    for (const [key, nested] of Object.entries(value as Record<string, unknown>)) {
      if (hasUnsafeKey(key)) {
        continue;
      }
      sanitized[key] = sanitizeValue(nested);
    }
    return sanitized;
  }

  return value;
};

const sanitizeInPlace = (target: unknown): void => {
  if (!target || typeof target !== 'object') return;

  if (Array.isArray(target)) {
    for (let i = 0; i < target.length; i += 1) {
      target[i] = sanitizeValue(target[i]);
    }
    return;
  }

  const record = target as Record<string, unknown>;
  for (const key of Object.keys(record)) {
    if (hasUnsafeKey(key)) {
      delete record[key];
      continue;
    }
    const value = record[key];
    if (value && typeof value === 'object') {
      sanitizeInPlace(value);
    }
  }
};

export const sanitizeRequest = (req: Request, _res: Response, next: NextFunction): void => {
  sanitizeInPlace(req.body);
  sanitizeInPlace(req.params);

  // req.query may be a getter-only object in Express 5.
  const query = req.query as unknown;
  if (query && typeof query === 'object') {
    const sanitized = sanitizeValue(query) as Record<string, unknown>;
    try {
      req.query = sanitized as any;
    } catch {
      sanitizeInPlace(req.query);
    }
  }

  next();
};

export default sanitizeRequest;
