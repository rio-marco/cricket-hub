import Joi from 'joi';
import { PlayingRole, BattingStyle, BowlingStyle } from '../constants/enums';

/**
 * Schema for creating a player profile
 */
export const createPlayerSchema = Joi.object({
  playingRole: Joi.string()
    .valid(...Object.values(PlayingRole))
    .required()
    .messages({
      'string.empty': 'Playing role is required',
      'any.only': `Playing role must be one of: ${Object.values(PlayingRole).join(', ')}`,
      'any.required': 'Playing role is required',
    }),
  battingStyle: Joi.string()
    .valid(...Object.values(BattingStyle))
    .required()
    .messages({
      'string.empty': 'Batting style is required',
      'any.only': `Batting style must be one of: ${Object.values(BattingStyle).join(', ')}`,
      'any.required': 'Batting style is required',
    }),
  bowlingStyle: Joi.string()
    .valid(...Object.values(BowlingStyle))
    .optional()
    .default(BowlingStyle.NONE)
    .messages({
      'any.only': `Bowling style must be one of: ${Object.values(BowlingStyle).join(', ')}`,
    }),
  jerseyNumber: Joi.number().integer().min(0).max(999).optional().messages({
    'number.base': 'Jersey number must be a number',
    'number.integer': 'Jersey number must be an integer',
    'number.min': 'Jersey number cannot be negative',
    'number.max': 'Jersey number cannot exceed 999',
  }),
  dateOfBirth: Joi.date().iso().max('now').optional().messages({
    'date.format': 'Date of birth must be a valid ISO date string',
    'date.max': 'Date of birth cannot be in the future',
  }),
  city: Joi.string().trim().max(100).optional().allow('').messages({
    'string.max': 'City cannot exceed 100 characters',
  }),
  bio: Joi.string().trim().max(500).optional().allow('').messages({
    'string.max': 'Bio cannot exceed 500 characters',
  }),
});

/**
 * Schema for updating an existing player profile
 */
export const updatePlayerSchema = Joi.object({
  playingRole: Joi.string()
    .valid(...Object.values(PlayingRole))
    .optional()
    .messages({
      'any.only': `Playing role must be one of: ${Object.values(PlayingRole).join(', ')}`,
    }),
  battingStyle: Joi.string()
    .valid(...Object.values(BattingStyle))
    .optional()
    .messages({
      'any.only': `Batting style must be one of: ${Object.values(BattingStyle).join(', ')}`,
    }),
  bowlingStyle: Joi.string()
    .valid(...Object.values(BowlingStyle))
    .optional()
    .messages({
      'any.only': `Bowling style must be one of: ${Object.values(BowlingStyle).join(', ')}`,
    }),
  jerseyNumber: Joi.number().integer().min(0).max(999).optional().allow(null).messages({
    'number.base': 'Jersey number must be a number',
    'number.integer': 'Jersey number must be an integer',
    'number.min': 'Jersey number cannot be negative',
    'number.max': 'Jersey number cannot exceed 999',
  }),
  dateOfBirth: Joi.date().iso().max('now').optional().allow(null).messages({
    'date.format': 'Date of birth must be a valid ISO date string',
    'date.max': 'Date of birth cannot be in the future',
  }),
  city: Joi.string().trim().max(100).optional().allow('').messages({
    'string.max': 'City cannot exceed 100 characters',
  }),
  bio: Joi.string().trim().max(500).optional().allow('').messages({
    'string.max': 'Bio cannot exceed 500 characters',
  }),
}).min(1).messages({
  'object.min': 'At least one field must be provided for update',
});

/**
 * Schema for player search and filtering query parameters
 */
export const searchPlayerSchema = Joi.object({
  search: Joi.string().trim().optional().allow(''),
  playingRole: Joi.string()
    .valid(...Object.values(PlayingRole))
    .optional()
    .messages({
      'any.only': `Playing role must be one of: ${Object.values(PlayingRole).join(', ')}`,
    }),
  battingStyle: Joi.string()
    .valid(...Object.values(BattingStyle))
    .optional()
    .messages({
      'any.only': `Batting style must be one of: ${Object.values(BattingStyle).join(', ')}`,
    }),
  bowlingStyle: Joi.string()
    .valid(...Object.values(BowlingStyle))
    .optional()
    .messages({
      'any.only': `Bowling style must be one of: ${Object.values(BowlingStyle).join(', ')}`,
    }),
  city: Joi.string().trim().optional().allow(''),
  page: Joi.number().integer().min(1).optional().default(1),
  limit: Joi.number().integer().min(1).max(100).optional().default(10),
  sort: Joi.string().trim().optional().default('-createdAt'),
  order: Joi.string().valid('asc', 'desc').optional(),
});

export default {
  createPlayerSchema,
  updatePlayerSchema,
  searchPlayerSchema,
};
