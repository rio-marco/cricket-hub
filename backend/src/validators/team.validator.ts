import Joi from 'joi';
import { TeamMemberRole, InvitationStatus } from '../constants/enums';

const objectIdPattern = /^[0-9a-fA-F]{24}$/;
const objectIdMessage = 'must be a valid 24-character hexadecimal ObjectId';

/**
 * Schema for creating a new team
 */
export const createTeamSchema = Joi.object({
  name: Joi.string().trim().min(2).max(50).required().messages({
    'string.base': 'Team name must be a string',
    'string.empty': 'Team name cannot be empty',
    'string.min': 'Team name must be at least 2 characters long',
    'string.max': 'Team name cannot exceed 50 characters',
    'any.required': 'Team name is required',
  }),
  description: Joi.string().trim().max(1000).optional().allow('').messages({
    'string.max': 'Description cannot exceed 1000 characters',
  }),
  location: Joi.string().trim().max(100).optional().allow('').messages({
    'string.max': 'Location cannot exceed 100 characters',
  }),
  logo: Joi.string().trim().uri().optional().allow('').messages({
    'string.uri': 'Logo must be a valid URL',
  }),
});

/**
 * Schema for updating an existing team
 */
export const updateTeamSchema = Joi.object({
  name: Joi.string().trim().min(2).max(50).optional().messages({
    'string.min': 'Team name must be at least 2 characters long',
    'string.max': 'Team name cannot exceed 50 characters',
  }),
  description: Joi.string().trim().max(1000).optional().allow('').messages({
    'string.max': 'Description cannot exceed 1000 characters',
  }),
  location: Joi.string().trim().max(100).optional().allow('').messages({
    'string.max': 'Location cannot exceed 100 characters',
  }),
  logo: Joi.string().trim().uri().optional().allow('').messages({
    'string.uri': 'Logo must be a valid URL',
  }),
  captain: Joi.string().pattern(objectIdPattern).optional().allow(null, '').messages({
    'string.pattern.base': `Captain ID ${objectIdMessage}`,
  }),
  viceCaptain: Joi.string().pattern(objectIdPattern).optional().allow(null, '').messages({
    'string.pattern.base': `Vice-captain ID ${objectIdMessage}`,
  }),
  wicketkeeper: Joi.string().pattern(objectIdPattern).optional().allow(null, '').messages({
    'string.pattern.base': `Wicketkeeper ID ${objectIdMessage}`,
  }),
  isActive: Joi.boolean().optional(),
}).min(1).messages({
  'object.min': 'At least one field must be provided for update',
});

/**
 * Schema for inviting a player to a team
 */
export const invitePlayerSchema = Joi.object({
  playerId: Joi.string().trim().pattern(objectIdPattern).required().messages({
    'string.empty': 'Player ID is required',
    'string.pattern.base': `Player ID ${objectIdMessage}`,
    'any.required': 'Player ID is required',
  }),
  message: Joi.string().trim().max(500).optional().allow('').messages({
    'string.max': 'Message cannot exceed 500 characters',
  }),
});

/**
 * Schema for adding a player directly to a team
 */
export const addPlayerSchema = Joi.object({
  playerId: Joi.string().trim().pattern(objectIdPattern).required().messages({
    'string.empty': 'Player ID is required',
    'string.pattern.base': `Player ID ${objectIdMessage}`,
    'any.required': 'Player ID is required',
  }),
  role: Joi.string()
    .valid(...Object.values(TeamMemberRole))
    .optional()
    .default(TeamMemberRole.PLAYER)
    .messages({
      'any.only': `Role must be one of: ${Object.values(TeamMemberRole).join(', ')}`,
    }),
});

/**
 * Schema for responding to an invitation or join request
 */
export const respondInvitationSchema = Joi.object({
  status: Joi.string()
    .valid(InvitationStatus.ACCEPTED, InvitationStatus.REJECTED)
    .required()
    .messages({
      'string.empty': 'Status is required',
      'any.only': `Status must be either '${InvitationStatus.ACCEPTED}' or '${InvitationStatus.REJECTED}'`,
      'any.required': 'Status is required',
    }),
});

/**
 * Schema for updating a team member's role
 */
export const updateMemberRoleSchema = Joi.object({
  role: Joi.string()
    .valid(...Object.values(TeamMemberRole))
    .required()
    .messages({
      'string.empty': 'Role is required',
      'any.only': `Role must be one of: ${Object.values(TeamMemberRole).join(', ')}`,
      'any.required': 'Role is required',
    }),
});

export default {
  createTeamSchema,
  updateTeamSchema,
  invitePlayerSchema,
  addPlayerSchema,
  respondInvitationSchema,
  updateMemberRoleSchema,
};
