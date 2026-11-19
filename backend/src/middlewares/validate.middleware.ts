import { Request, Response, NextFunction, RequestHandler } from 'express';
import Joi from 'joi';
import { ApiError } from '../utils/apiError';

export type ValidationProperty = 'body' | 'query' | 'params';

/**
 * Joi Request Validation Middleware Factory
 *
 * @param schema Joi ObjectSchema to validate against
 * @param property Request property to validate ('body' | 'query' | 'params')
 */
export const validate = (
  schema: Joi.ObjectSchema,
  property: ValidationProperty = 'body'
): RequestHandler => {
  return (req: Request, _res: Response, next: NextFunction): void => {
    const { error, value } = schema.validate(req[property], {
      abortEarly: false,
      stripUnknown: true,
      errors: {
        wrap: {
          label: '',
        },
      },
    });

    if (error) {
      const formattedErrors = error.details.map((item) => ({
        field: item.path.join('.'),
        message: item.message,
      }));

      const errorMessage = formattedErrors.map((e) => e.message).join('; ');
      return next(new ApiError(400, `Validation Error: ${errorMessage}`, formattedErrors));
    }

    // Assign sanitized/typecast value back to request object
    req[property] = value;
    next();
  };
};

export default validate;
