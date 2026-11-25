import Joi from 'joi';
import {
  MatchFormat,
  MatchStatus,
  BallType,
  TossDecision,
} from '../constants/enums';

const objectIdPattern = /^[0-9a-fA-F]{24}$/;
const objectIdMessage = 'Invalid identifier format. Must be a valid 24-character hexadecimal ObjectId';

/**
 * Validation schema for creating a cricket match (standalone or tournament)
 */
export const createMatchSchema = Joi.object({
  title: Joi.string().trim().max(150).optional().allow('').messages({
    'string.max': 'Match title cannot exceed 150 characters',
  }),
  tournamentId: Joi.string().trim().pattern(objectIdPattern).optional().allow(null, '').messages({
    'string.pattern.base': `tournamentId: ${objectIdMessage}`,
  }),
  teamA: Joi.string().trim().pattern(objectIdPattern).required().messages({
    'string.pattern.base': `teamA: ${objectIdMessage}`,
    'string.empty': 'Team A ID is required',
    'any.required': 'Team A ID is required',
  }),
  teamB: Joi.string()
    .trim()
    .pattern(objectIdPattern)
    .invalid(Joi.ref('teamA'))
    .required()
    .messages({
      'string.pattern.base': `teamB: ${objectIdMessage}`,
      'any.invalid': 'Team B cannot be the same as Team A',
      'string.empty': 'Team B ID is required',
      'any.required': 'Team B ID is required',
    }),
  format: Joi.string()
    .valid(...Object.values(MatchFormat))
    .required()
    .messages({
      'any.only': `Format must be one of: ${Object.values(MatchFormat).join(', ')}`,
      'any.required': 'Match format is required',
    }),
  totalOvers: Joi.number().integer().min(1).max(50).required().messages({
    'number.min': 'Match must have at least 1 over',
    'number.max': 'Total overs cannot exceed 50',
    'any.required': 'Total overs per innings is required',
  }),
  ballsPerOver: Joi.number().integer().min(1).max(8).default(6).messages({
    'number.min': 'An over must have at least 1 ball',
    'number.max': 'An over cannot exceed 8 balls',
  }),
  ballType: Joi.string()
    .valid(...Object.values(BallType))
    .optional()
    .messages({
      'any.only': `Ball type must be one of: ${Object.values(BallType).join(', ')}`,
    }),
  venue: Joi.string().trim().max(150).optional().allow('').messages({
    'string.max': 'Venue name cannot exceed 150 characters',
  }),
  city: Joi.string().trim().max(100).optional().allow('').messages({
    'string.max': 'City name cannot exceed 100 characters',
  }),
  matchDate: Joi.date().iso().optional().messages({
    'date.base': 'Match date must be a valid ISO date',
  }),
});

/**
 * Validation schema for updating match setup details
 */
export const updateMatchSchema = Joi.object({
  title: Joi.string().trim().max(150).optional().allow(''),
  format: Joi.string()
    .valid(...Object.values(MatchFormat))
    .optional()
    .messages({
      'any.only': `Format must be one of: ${Object.values(MatchFormat).join(', ')}`,
    }),
  totalOvers: Joi.number().integer().min(1).max(50).optional().messages({
    'number.min': 'Match must have at least 1 over',
    'number.max': 'Total overs cannot exceed 50',
  }),
  ballsPerOver: Joi.number().integer().min(1).max(8).optional().messages({
    'number.min': 'An over must have at least 1 ball',
    'number.max': 'An over cannot exceed 8 balls',
  }),
  ballType: Joi.string()
    .valid(...Object.values(BallType))
    .optional()
    .messages({
      'any.only': `Ball type must be one of: ${Object.values(BallType).join(', ')}`,
    }),
  venue: Joi.string().trim().max(150).optional().allow(''),
  city: Joi.string().trim().max(100).optional().allow(''),
  matchDate: Joi.date().iso().optional(),
}).min(1).messages({
  'object.min': 'At least one field must be provided to update',
});

/**
 * Validation schema for match toss result
 */
export const tossSchema = Joi.object({
  winner: Joi.string().trim().pattern(objectIdPattern).required().messages({
    'string.pattern.base': `winner: ${objectIdMessage}`,
    'string.empty': 'Toss winner team ID is required',
    'any.required': 'Toss winner team ID is required',
  }),
  decision: Joi.string()
    .valid(...Object.values(TossDecision))
    .required()
    .messages({
      'any.only': `Decision must be one of: ${Object.values(TossDecision).join(', ')}`,
      'any.required': 'Toss decision is required (BAT or BOWL)',
    }),
});

/**
 * Validation schema for setting Playing XI and Substitutes
 */
export const playingXISchema = Joi.object({
  teamId: Joi.string().trim().pattern(objectIdPattern).required().messages({
    'string.pattern.base': `teamId: ${objectIdMessage}`,
    'string.empty': 'Team ID is required',
    'any.required': 'Team ID is required',
  }),
  playingXI: Joi.array()
    .items(Joi.string().trim().pattern(objectIdPattern).messages({
      'string.pattern.base': `Player ID in playingXI: ${objectIdMessage}`,
    }))
    .length(11)
    .unique()
    .required()
    .messages({
      'array.base': 'playingXI must be an array of player IDs',
      'array.length': 'Playing XI must consist of exactly 11 unique players',
      'array.unique': 'Playing XI cannot contain duplicate players',
      'any.required': 'Playing XI is required',
    }),
  substitutes: Joi.array()
    .items(Joi.string().trim().pattern(objectIdPattern).messages({
      'string.pattern.base': `Player ID in substitutes: ${objectIdMessage}`,
    }))
    .unique()
    .optional()
    .default([])
    .messages({
      'array.base': 'Substitutes must be an array of player IDs',
      'array.unique': 'Substitutes cannot contain duplicate players',
    }),
});

/**
 * Validation schema for assigning a scorer
 */
export const scorerSchema = Joi.object({
  scorerId: Joi.string().trim().pattern(objectIdPattern).required().messages({
    'string.pattern.base': `scorerId: ${objectIdMessage}`,
    'string.empty': 'Scorer ID is required',
    'any.required': 'Scorer ID is required',
  }),
});

export const matchQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(10),
  sort: Joi.string().valid(
    'matchDate',
    'title',
    'status',
    'city',
    'format',
    'createdAt',
  ),
  order: Joi.string().trim().valid('asc', 'desc'),
  status: Joi.string().valid(...Object.values(MatchStatus)),
  format: Joi.string().valid(...Object.values(MatchFormat)),
  tournamentId: Joi.string().pattern(objectIdPattern),
  tournament: Joi.string().pattern(objectIdPattern),
  teamId: Joi.string().pattern(objectIdPattern),
  team: Joi.string().pattern(objectIdPattern),
  city: Joi.string().trim().max(100),
  search: Joi.string().trim().max(100).allow(''),
});

export default {
  createMatchSchema,
  updateMatchSchema,
  tossSchema,
  playingXISchema,
  scorerSchema,
  matchQuerySchema,
};
