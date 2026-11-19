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
  defaultSort: string = '-createdAt'
): IPaginationParams => {
  const rawPage = parseInt(query.page as string, 10);
  const rawLimit = parseInt(query.limit as string, 10);

  const page = !isNaN(rawPage) && rawPage > 0 ? rawPage : 1;
  let limit = !isNaN(rawLimit) && rawLimit > 0 ? rawLimit : defaultLimit;
  if (limit > maxLimit) {
    limit = maxLimit;
  }

  const skip = (page - 1) * limit;

  // Handle sort parsing (e.g. ?sort=-createdAt,name or ?sort=field&order=desc)
  let sort: Record<string, 1 | -1> | string = defaultSort;
  if (query.sort && typeof query.sort === 'string') {
    const sortField = query.sort.trim();
    if (query.order && typeof query.order === 'string') {
      const orderDirection = query.order.toLowerCase() === 'asc' ? 1 : -1;
      sort = { [sortField]: orderDirection };
    } else {
      sort = sortField;
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
