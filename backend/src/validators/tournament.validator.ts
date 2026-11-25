import Joi from 'joi';
import {
  TournamentFormat,
  BallType,
  MatchFormat,
  TournamentStatus,
} from '../constants/enums';

const objectIdPattern = /^[0-9a-fA-F]{24}$/;
const objectIdMessage = 'Invalid identifier format. Must be a valid 24-character hexadecimal ObjectId';

/**
 * Validation schema for creating a new tournament
 */
export const createTournamentSchema = Joi.object({
  name: Joi.string().trim().min(3).max(150).required().messages({
    'string.base': 'Tournament name must be a string',
    'string.empty': 'Tournament name cannot be empty',
    'string.min': 'Tournament name must be at least 3 characters long',
    'string.max': 'Tournament name cannot exceed 150 characters',
    'any.required': 'Tournament name is required',
  }),
  description: Joi.string().trim().max(2000).optional().allow('').messages({
    'string.max': 'Description cannot exceed 2000 characters',
  }),
  logo: Joi.string().trim().optional().allow('').messages({
    'string.base': 'Logo must be a valid string or URL',
  }),
  banner: Joi.string().trim().optional().allow('').messages({
    'string.base': 'Banner must be a valid string or URL',
  }),
  format: Joi.string()
    .valid(...Object.values(TournamentFormat))
    .required()
    .messages({
      'any.only': `Format must be one of: ${Object.values(TournamentFormat).join(', ')}`,
      'any.required': 'Tournament format is required',
    }),
  ballType: Joi.string()
    .valid(...Object.values(BallType))
    .required()
    .messages({
      'any.only': `Ball type must be one of: ${Object.values(BallType).join(', ')}`,
      'any.required': 'Ball type is required',
    }),
  matchFormat: Joi.string()
    .valid(...Object.values(MatchFormat))
    .required()
    .messages({
      'any.only': `Match format must be one of: ${Object.values(MatchFormat).join(', ')}`,
      'any.required': 'Match format is required',
    }),
  customOvers: Joi.number().integer().min(1).max(100).optional().messages({
    'number.min': 'Custom overs must be at least 1',
    'number.max': 'Custom overs cannot exceed 100',
  }),
  venues: Joi.array().items(Joi.string().trim().min(1)).optional().default([]).messages({
    'array.base': 'Venues must be an array of venue names',
  }),
  city: Joi.string().trim().max(100).optional().allow('').messages({
    'string.max': 'City name cannot exceed 100 characters',
  }),
  startDate: Joi.date().iso().required().messages({
    'date.base': 'Start date must be a valid ISO date',
    'any.required': 'Start date is required',
  }),
  endDate: Joi.date().iso().min(Joi.ref('startDate')).required().messages({
    'date.base': 'End date must be a valid ISO date',
    'date.min': 'End date must be on or after start date',
    'any.required': 'End date is required',
  }),
  registrationStartDate: Joi.date().iso().optional().messages({
    'date.base': 'Registration start date must be a valid ISO date',
  }),
  registrationEndDate: Joi.date().iso().optional().messages({
    'date.base': 'Registration end date must be a valid ISO date',
  }),
  maxTeams: Joi.number().integer().min(2).max(128).required().messages({
    'number.min': 'A tournament must have at least 2 teams',
    'number.max': 'Maximum teams limit cannot exceed 128',
    'any.required': 'Maximum teams limit is required',
  }),
  maxPlayersPerTeam: Joi.number().integer().min(7).max(30).optional().default(15).messages({
    'number.min': 'Minimum players per team must be at least 7',
    'number.max': 'Maximum players per team cannot exceed 30',
  }),
  rules: Joi.string().trim().max(5000).optional().allow('').messages({
    'string.max': 'Rules cannot exceed 5000 characters',
  }),
  registrationFee: Joi.number().min(0).optional().default(0).messages({
    'number.min': 'Registration fee cannot be negative',
  }),
});

/**
 * Validation schema for updating tournament details
 */
export const updateTournamentSchema = Joi.object({
  name: Joi.string().trim().min(3).max(150).optional().messages({
    'string.min': 'Tournament name must be at least 3 characters long',
    'string.max': 'Tournament name cannot exceed 150 characters',
  }),
  description: Joi.string().trim().max(2000).optional().allow(''),
  logo: Joi.string().trim().optional().allow(''),
  banner: Joi.string().trim().optional().allow(''),
  format: Joi.string()
    .valid(...Object.values(TournamentFormat))
    .optional()
    .messages({
      'any.only': `Format must be one of: ${Object.values(TournamentFormat).join(', ')}`,
    }),
  ballType: Joi.string()
    .valid(...Object.values(BallType))
    .optional()
    .messages({
      'any.only': `Ball type must be one of: ${Object.values(BallType).join(', ')}`,
    }),
  matchFormat: Joi.string()
    .valid(...Object.values(MatchFormat))
    .optional()
    .messages({
      'any.only': `Match format must be one of: ${Object.values(MatchFormat).join(', ')}`,
    }),
  customOvers: Joi.number().integer().min(1).max(100).optional(),
  venues: Joi.array().items(Joi.string().trim().min(1)).optional(),
  city: Joi.string().trim().max(100).optional().allow(''),
  startDate: Joi.date().iso().optional(),
  endDate: Joi.date().iso().optional(),
  registrationStartDate: Joi.date().iso().optional().allow(null),
  registrationEndDate: Joi.date().iso().optional().allow(null),
  maxTeams: Joi.number().integer().min(2).max(128).optional(),
  maxPlayersPerTeam: Joi.number().integer().min(7).max(30).optional(),
  rules: Joi.string().trim().max(5000).optional().allow(''),
  registrationFee: Joi.number().min(0).optional(),
}).min(1).messages({
  'object.min': 'At least one field must be provided to update',
});

/**
 * Validation schema for registering a team to a tournament
 */
export const registerTeamSchema = Joi.object({
  teamId: Joi.string().trim().pattern(objectIdPattern).required().messages({
    'string.pattern.base': `teamId: ${objectIdMessage}`,
    'string.empty': 'Team ID is required',
    'any.required': 'Team ID is required',
  }),
});

/**
 * Validation schema for updating tournament lifecycle status
 */
export const updateTournamentStatusSchema = Joi.object({
  status: Joi.string()
    .valid(...Object.values(TournamentStatus))
    .required()
    .messages({
      'any.only': `Status must be one of: ${Object.values(TournamentStatus).join(', ')}`,
      'any.required': 'Status is required',
    }),
});

export const tournamentQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).default(1),
  limit: Joi.number().integer().min(1).max(100).default(10),
  sort: Joi.string().trim().max(100),
  order: Joi.string().trim().valid('asc', 'desc'),
  status: Joi.string().valid(...Object.values(TournamentStatus)),
  city: Joi.string().trim().max(100),
  format: Joi.string().valid(...Object.values(TournamentFormat)),
  organizer: Joi.string().pattern(objectIdPattern),
  search: Joi.string().trim().max(100).allow(''),
});

export default {
  createTournamentSchema,
  updateTournamentSchema,
  registerTeamSchema,
  updateTournamentStatusSchema,
  tournamentQuerySchema,
};
