import { Response } from 'express';

export interface IPaginationMeta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
  hasNextPage: boolean;
  hasPrevPage: boolean;
}

export interface IStandardResponse<T = any> {
  success: boolean;
  message: string;
  data?: T;
  error?: any;
  pagination?: IPaginationMeta;
}

/**
 * Standardized API Response formatter
 */
export class ApiResponse {
  /**
   * Send a successful JSON response
   */
  public static success<T = any>(
    res: Response,
    statusCode: number = 200,
    message: string = 'Operation successful',
    data?: T
  ): Response {
    const responsePayload: IStandardResponse<T> = {
      success: true,
      message,
      ...(data !== undefined && { data }),
    };
    return res.status(statusCode).json(responsePayload);
  }

  /**
   * Send an error JSON response
   */
  public static error(
    res: Response,
    statusCode: number = 500,
    message: string = 'An unexpected error occurred',
    error?: any
  ): Response {
    const responsePayload: IStandardResponse = {
      success: false,
      message,
      ...(error !== undefined && { error }),
    };
    return res.status(statusCode).json(responsePayload);
  }

  /**
   * Send a paginated JSON response
   */
  public static paginated<T = any>(
    res: Response,
    data: T[],
    page: number,
    limit: number,
    total: number,
    message: string = 'Records retrieved successfully'
  ): Response {
    const safeLimit = limit > 0 ? limit : 10;
    const safePage = page > 0 ? page : 1;
    const totalPages = Math.ceil(total / safeLimit) || 1;

    const responsePayload: IStandardResponse<T[]> = {
      success: true,
      message,
      data,
      pagination: {
        page: safePage,
        limit: safeLimit,
        total,
        totalPages,
        hasNextPage: safePage < totalPages,
        hasPrevPage: safePage > 1,
      },
    };
    return res.status(200).json(responsePayload);
  }
}

export default ApiResponse;
