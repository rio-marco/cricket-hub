import Joi from 'joi';
import { DismissalType, ExtraType, ResultType } from '../constants/enums';

const objectIdPattern = /^[0-9a-fA-F]{24}$/;
const objectIdMessage = 'Invalid identifier format. Must be a valid 24-character hexadecimal ObjectId';

const objectId = (field: string, required = false) => {
  const schema = Joi.string().trim().pattern(objectIdPattern).messages({
    'string.pattern.base': `${field}: ${objectIdMessage}`,
    'string.empty': `${field} is required`,
    'any.required': `${field} is required`,
  });
  return required ? schema.required() : schema.optional();
};

const commonDeliveryFields = {
  batter: objectId('batter').optional(),
  nonStriker: objectId('nonStriker').optional(),
  bowler: objectId('bowler').optional(),
  expectedVersion: Joi.number().integer().min(0).optional(),
  idempotencyKey: Joi.string().trim().min(3).max(120).optional(),
};

export const startInningsSchema = Joi.object({
  striker: objectId('striker', true),
  nonStriker: objectId('nonStriker', true),
  bowler: objectId('bowler', true),
  inningsNumber: Joi.number().integer().valid(1, 2).optional(),
  expectedVersion: Joi.number().integer().min(0).optional(),
  idempotencyKey: Joi.string().trim().min(3).max(120).optional(),
});

export const recordBallSchema = Joi.object({
  ...commonDeliveryFields,
  runs: Joi.number().integer().min(0).max(6).default(0),
  extraType: Joi.string()
    .valid(...Object.values(ExtraType))
    .default(ExtraType.NONE),
  extraRuns: Joi.number().integer().min(0).max(12).default(0),
  wicket: Joi.object({
    type: Joi.string()
      .valid(...Object.values(DismissalType))
      .required(),
    batter: objectId('wicket batter').optional(),
    fielder: objectId('wicket fielder').optional(),
    description: Joi.string().trim().max(200).optional().allow(''),
  }).optional(),
  commentary: Joi.string().trim().max(300).optional().allow(''),
});

export const correctBallSchema = recordBallSchema.keys({
  expectedVersion: Joi.number().integer().min(0).optional(),
});

export const undoBallSchema = Joi.object({
  expectedVersion: Joi.number().integer().min(0).optional(),
  idempotencyKey: Joi.string().trim().min(3).max(120).optional(),
});

export const inningsEndSchema = Joi.object({
  inningsNumber: Joi.number().integer().valid(1, 2).optional(),
  status: Joi.string().valid('COMPLETED', 'DECLARED').default('COMPLETED'),
  expectedVersion: Joi.number().integer().min(0).optional(),
  idempotencyKey: Joi.string().trim().min(3).max(120).optional(),
});

export const completeMatchSchema = Joi.object({
  resultType: Joi.string().valid(...Object.values(ResultType)).optional(),
  winner: objectId('winner').optional(),
  margin: Joi.number().integer().min(0).optional(),
  description: Joi.string().trim().max(300).optional().allow(''),
  playerOfMatch: objectId('playerOfMatch').optional(),
  idempotencyKey: Joi.string().trim().min(3).max(120).optional(),
});

export const scoringQuerySchema = Joi.object({
  inningsNumber: Joi.number().integer().valid(1, 2).optional(),
  limit: Joi.number().integer().min(1).max(100).default(30),
  order: Joi.string().valid('asc', 'desc').default('desc'),
});

export default {
  startInningsSchema,
  recordBallSchema,
  correctBallSchema,
  undoBallSchema,
  inningsEndSchema,
  completeMatchSchema,
  scoringQuerySchema,
};
