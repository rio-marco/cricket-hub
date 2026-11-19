/**
 * Custom application error class representing an operational HTTP error
 */
export class ApiError extends Error {
  public readonly statusCode: number;
  public readonly errors: any[];
  public readonly isOperational: boolean;

  constructor(
    statusCode: number,
    message: string,
    errors: any[] = [],
    isOperational: boolean = true
  ) {
    super(message);
    this.statusCode = statusCode;
    this.errors = errors;
    this.isOperational = isOperational;

    // Restore prototype chain
    Object.setPrototypeOf(this, new.target.prototype);
    Error.captureStackTrace(this, this.constructor);
  }

  /**
   * 400 Bad Request
   */
  public static badRequest(message: string = 'Bad Request', errors: any[] = []): ApiError {
    return new ApiError(400, message, errors);
  }

  /**
   * 401 Unauthorized
   */
  public static unauthorized(message: string = 'Unauthorized access', errors: any[] = []): ApiError {
    return new ApiError(401, message, errors);
  }

  /**
   * 403 Forbidden
   */
  public static forbidden(message: string = 'Access forbidden', errors: any[] = []): ApiError {
    return new ApiError(403, message, errors);
  }

  /**
   * 404 Not Found
   */
  public static notFound(message: string = 'Resource not found', errors: any[] = []): ApiError {
    return new ApiError(404, message, errors);
  }

  /**
   * 409 Conflict
   */
  public static conflict(message: string = 'Resource conflict', errors: any[] = []): ApiError {
    return new ApiError(409, message, errors);
  }

  public static tooManyRequests(message: string = 'Too many requests', errors: any[] = []): ApiError {
    return new ApiError(429, message, errors);
  }

  /**
   * 500 Internal Server Error
   */
  public static internal(message: string = 'Internal server error', errors: any[] = []): ApiError {
    return new ApiError(500, message, errors, false);
  }
}

export default ApiError;
