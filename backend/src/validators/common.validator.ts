import Joi from 'joi';

export const objectIdPattern = /^[0-9a-fA-F]{24}$/;

export const objectIdParam = (name = 'id') =>
  Joi.string().trim().pattern(objectIdPattern).required().messages({
    'string.pattern.base': `${name} must be a valid ObjectId`,
    'string.empty': `${name} is required`,
    'any.required': `${name} is required`,
  });

export const objectIdParamsSchema = (keys: string[]) =>
  Joi.object(keys.reduce<Record<string, Joi.StringSchema>>((acc, key) => {
    acc[key] = objectIdParam(key);
    return acc;
  }, {}));

export default { objectIdPattern, objectIdParam, objectIdParamsSchema };
