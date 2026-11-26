import Joi from 'joi';
import { AuctionStatus, AuctionPlayerStatus, AuctionBidDecision } from '../constants/enums';

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

const mutationFields = {
  idempotencyKey: Joi.string().trim().min(3).max(120).optional(),
  expectedVersion: Joi.number().integer().min(0).optional(),
};

export const createAuctionSchema = Joi.object({
  name: Joi.string().trim().min(3).max(120).required(),
  tournament: objectId('tournament').optional(),
  teams: Joi.array().items(objectId('team')).min(2).max(100).required(),
  purseAmount: Joi.number().min(0).required(),
  basePrice: Joi.number().min(0).default(0),
  minBidIncrement: Joi.number().integer().min(1).default(100000),
  maxSquadSize: Joi.number().integer().min(1).max(100).default(25),
  minSquadSize: Joi.number().integer().min(1).max(100).default(11),
  playerCategories: Joi.array().items(Joi.string().trim().min(1).max(50)).max(50).default([]),
  rules: Joi.object().unknown(true).default({}),
  status: Joi.string().valid(AuctionStatus.DRAFT, AuctionStatus.UPCOMING).default(AuctionStatus.DRAFT),
  idempotencyKey: mutationFields.idempotencyKey,
});

export const updateAuctionSchema = Joi.object({
  name: Joi.string().trim().min(3).max(120).optional(),
  tournament: objectId('tournament').allow(null).optional(),
  teams: Joi.array().items(objectId('team')).min(2).max(100).optional(),
  purseAmount: Joi.number().min(0).optional(),
  basePrice: Joi.number().min(0).optional(),
  minBidIncrement: Joi.number().integer().min(1).optional(),
  maxSquadSize: Joi.number().integer().min(1).max(100).optional(),
  minSquadSize: Joi.number().integer().min(1).max(100).optional(),
  playerCategories: Joi.array().items(Joi.string().trim().min(1).max(50)).max(50).optional(),
  rules: Joi.object().unknown(true).optional(),
  status: Joi.string().valid(AuctionStatus.DRAFT, AuctionStatus.UPCOMING, AuctionStatus.CANCELLED).optional(),
  ...mutationFields,
}).min(1);

export const registerPlayersSchema = Joi.object({
  players: Joi.array()
    .items(
      Joi.object({
        playerId: objectId('player ID', true),
        basePrice: Joi.number().min(0).optional(),
        category: Joi.string().trim().min(1).max(50).optional(),
        set: Joi.number().integer().min(1).max(1000).optional(),
        order: Joi.number().integer().min(1).max(10000).optional(),
      })
    )
    .min(1)
    .max(200)
    .required(),
  idempotencyKey: mutationFields.idempotencyKey,
});

export const placeBidSchema = Joi.object({
  team: objectId('team', true),
  amount: Joi.number().min(1).optional(),
  ...mutationFields,
});

export const bidDecisionSchema = Joi.object({
  accept: Joi.boolean().required(),
  reason: Joi.string().trim().max(300).optional().allow(''),
  ...mutationFields,
});

export const auctionActionSchema = Joi.object({
  ...mutationFields,
  reason: Joi.string().trim().max(300).optional().allow(''),
});

export const auctionTeamSchema = Joi.object({
  teamId: objectId('team ID', true),
});

export const availabilitySchema = Joi.object({
  available: Joi.boolean().required(),
  ...mutationFields,
});

export const auctionQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(100).optional(),
  sort: Joi.string().trim().max(60).optional(),
  order: Joi.string().valid('asc', 'desc').optional(),
  status: Joi.string().trim().max(200).optional(),
  search: Joi.string().trim().max(100).optional().allow(''),
  tournament: objectId('tournament').optional(),
  team: objectId('team').optional(),
  createdBy: objectId('createdBy').optional(),
});

export const auctionPlayersQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(100).optional(),
  sort: Joi.string().trim().max(60).optional(),
  order: Joi.string().valid('asc', 'desc').optional(),
  status: Joi.string().valid(...Object.values(AuctionPlayerStatus)).optional(),
  category: Joi.string().trim().max(50).optional(),
  available: Joi.boolean().optional(),
  search: Joi.string().trim().max(100).optional().allow(''),
});

export const auctionHistoryQuerySchema = Joi.object({
  limit: Joi.number().integer().min(1).max(200).optional(),
  decision: Joi.string().valid(...Object.values(AuctionBidDecision)).optional(),
});

export default {
  createAuctionSchema,
  updateAuctionSchema,
  registerPlayersSchema,
  placeBidSchema,
  bidDecisionSchema,
  auctionActionSchema,
  auctionTeamSchema,
  availabilitySchema,
  auctionQuerySchema,
  auctionPlayersQuerySchema,
  auctionHistoryQuerySchema,
};
