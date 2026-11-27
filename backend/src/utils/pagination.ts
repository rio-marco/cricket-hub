export interface IPaginationParams {
  page: number;
  limit: number;
  skip: number;
  sort: Record<string, 1 | -1> | string;
}

export interface IPaginationMeta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
  hasNextPage: boolean;
  hasPrevPage: boolean;
}

/**
 * Extracts and sanitizes pagination parameters from an incoming request query object
 *
 * @param query Express request query object
 * @param defaultLimit Default items per page (default: 10)
 * @param maxLimit Maximum allowable limit (default: 100)
 * @param defaultSort Default sorting field/order (default: '-createdAt')
 */
export const getPaginationParams = (
  query: Record<string, any> = {},
  defaultLimit: number = 10,
  maxLimit: number = 100,
  defaultSort: string = '-createdAt',
  allowedSortFields: string[] = []
): IPaginationParams => {
  const rawPage = parseInt(query.page as string, 10);
  const rawLimit = parseInt(query.limit as string, 10);

  const page = !isNaN(rawPage) && rawPage > 0 ? rawPage : 1;
  let limit = !isNaN(rawLimit) && rawLimit > 0 ? rawLimit : defaultLimit;
  if (limit > maxLimit) {
    limit = maxLimit;
  }

  const skip = (page - 1) * limit;

  const normalizeSort = (value: string): Record<string, 1 | -1> | string => {
    const raw = String(value || '').trim();
    if (!raw) return defaultSort;
    const parts = raw.split(',').map((p) => p.trim()).filter(Boolean);
    if (!parts.length) return defaultSort;
    if (allowedSortFields.length > 0) {
      const sanitized: Record<string, 1 | -1> = {};
      for (const part of parts) {
        const desc = part.startsWith('-');
        const field = (desc ? part.slice(1) : part).trim();
        if (!field || !allowedSortFields.includes(field)) continue;
        sanitized[field] = desc ? -1 : 1;
      }
      return Object.keys(sanitized).length > 0 ? sanitized : defaultSort;
    }
    return raw;
  };

  let sort: Record<string, 1 | -1> | string = normalizeSort(defaultSort);
  if (query.sort && typeof query.sort === 'string') {
    const sortField = query.sort.trim();
    if (query.order && typeof query.order === 'string' && allowedSortFields.length > 0) {
      const field = sortField.replace(/^-/, '');
      if (allowedSortFields.includes(field)) {
        const orderDirection = query.order.toLowerCase() === 'asc' ? 1 : -1;
        sort = { [field]: orderDirection };
      }
    } else {
      sort = normalizeSort(sortField);
    }
  }

  return {
    page,
    limit,
    skip,
    sort,
  };
};

/**
 * Builds structured pagination metadata
 */
export const buildPaginationResponse = (
  total: number,
  page: number,
  limit: number
): IPaginationMeta => {
  const safeLimit = limit > 0 ? limit : 10;
  const safePage = page > 0 ? page : 1;
  const totalPages = Math.ceil(total / safeLimit) || 1;

  return {
    page: safePage,
    limit: safeLimit,
    total,
    totalPages,
    hasNextPage: safePage < totalPages,
    hasPrevPage: safePage > 1,
  };
};

export default {
  getPaginationParams,
  buildPaginationResponse,
};
