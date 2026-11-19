import { Request, Response, NextFunction, ErrorRequestHandler } from 'express';
import { ApiResponse } from '../utils/apiResponse';
import { ApiError } from '../utils/apiError';
import { logger } from '../utils/logger';
import { env } from '../config/env';

/**
 * Global Error Handling Middleware
 * Catches all errors forwarded from async handlers and Express pipeline,
 * sanitizes and formats the error, and returns a uniform JSON response.
 */
export const errorHandler: ErrorRequestHandler = (
  err: any,
  req: Request,
  res: Response,
  _next: NextFunction
): void => {
  let statusCode = 500;
  let message = 'Internal server error';
  let errorDetails: any = undefined;

  // Handle custom ApiError instances
  if (err instanceof ApiError) {
    statusCode = err.statusCode;
    message = err.message;
    errorDetails = err.errors && err.errors.length > 0 ? err.errors : undefined;
  }
  // Handle Mongoose Validation Errors
  else if (err.name === 'ValidationError') {
    statusCode = 400;
    message = 'Validation failed';
    if (err.errors) {
      errorDetails = Object.values(err.errors).map((val: any) => ({
        field: val.path,
        message: val.message,
      }));
    }
  }
  // Handle Mongoose CastError (e.g. invalid ObjectId format)
  else if (err.name === 'CastError') {
    statusCode = 400;
    message = `Invalid ${err.path || 'identifier'}: ${err.value}`;
    errorDetails = [{ field: err.path, message: `Resource not found or invalid format: ${err.value}` }];
  }
  // Handle Mongoose Duplicate Key Error (E11000)
  else if (err.code === 11000) {
    statusCode = 409;
    const duplicateFields = Object.keys(err.keyPattern || err.keyValue || {});
    const fieldName = duplicateFields.length > 0 ? duplicateFields[0] : 'field';
    message = `Duplicate value entered for ${fieldName}. Please use another value.`;
    errorDetails = [{ field: fieldName, message: `${fieldName} already exists.` }];
  }
  // Handle JWT Malformed / Signature Errors
  else if (err.name === 'JsonWebTokenError') {
    statusCode = 401;
    message = 'Invalid authentication token';
    errorDetails = [{ message: err.message }];
  }
  // Handle JWT Token Expiration
  else if (err.name === 'TokenExpiredError') {
    statusCode = 401;
    message = 'Authentication token has expired. Please log in again.';
    errorDetails = [{ expiredAt: err.expiredAt }];
  }
  // Handle Multer upload errors
  else if (err.name === 'MulterError') {
    statusCode = 400;
    message = err.message || 'File upload error';
    errorDetails = [{ code: err.code, field: err.field }];
  }
  // Generic / standard Error
  else if (err instanceof Error) {
    statusCode = (err as any).statusCode || 500;
    message = err.message || 'Internal server error';
    if (env.isDevelopment) {
      errorDetails = {
        name: err.name,
        stack: err.stack,
      };
    }
  }

  // Log error using application logger
  if (statusCode >= 500) {
    logger.error(`[Server Error ${statusCode}] ${req.method} ${req.originalUrl}: ${message}`, err.stack || err);
  } else {
    logger.warn(`[Client Error ${statusCode}] ${req.method} ${req.originalUrl}: ${message}`);
  }

  // In development, include stack trace for non-operational / 500 errors if not already included
  if (env.isDevelopment && statusCode === 500 && !errorDetails) {
    errorDetails = {
      stack: err.stack,
    };
  }

  ApiResponse.error(res, statusCode, message, errorDetails);
};

/**
 * 404 Route Not Found Middleware
 */
export const notFoundHandler = (req: Request, res: Response, _next: NextFunction): void => {
  const message = `Route not found: ${req.method} ${req.originalUrl}`;
  logger.warn(`[404 Not Found] ${req.method} ${req.originalUrl}`);
  ApiResponse.error(res, 404, message);
};

export default errorHandler;
