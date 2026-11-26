import Joi from 'joi';
import { MatchFormat } from '../constants/enums';
import { LEADERBOARD_METRICS } from '../utils/statistics';

const objectIdPattern = /^[0-9a-fA-F]{24}$/;

const filterFields = {
  tournament: Joi.string().pattern(objectIdPattern).optional(),
  season: Joi.number().integer().min(1900).max(2100).optional(),
  format: Joi.string().valid(...Object.values(MatchFormat)).optional(),
  from: Joi.date().iso().optional(),
  to: Joi.date().iso().optional(),
};

export const playerStatisticsQuerySchema = Joi.object(filterFields);

export const playerStatisticsIdParamSchema = Joi.object({
  id: Joi.string().pattern(objectIdPattern).required(),
});

export const leaderboardQuerySchema = Joi.object({
  ...filterFields,
  metric: Joi.string()
    .valid(
      ...LEADERBOARD_METRICS,
      ...LEADERBOARD_METRICS.map((metric) => metric.toLowerCase()),
      'batsmen',
      'bowlers',
      'batters'
    )
    .optional(),
  page: Joi.number().integer().min(1).max(100000).optional(),
  limit: Joi.number().integer().min(1).max(100).optional(),
  minInnings: Joi.number().integer().min(1).max(1000).optional(),
});

const leaderboardTypes = [
  ...LEADERBOARD_METRICS,
  ...LEADERBOARD_METRICS.map((metric) => metric.toLowerCase()),
  'batsmen',
  'bowlers',
  'batters',
];

export const leaderboardTypeParamSchema = Joi.object({
  type: Joi.string().valid(...leaderboardTypes).required(),
});

export const tournamentParamSchema = Joi.object({
  id: Joi.string().pattern(objectIdPattern).required(),
});

export default {
  playerStatisticsQuerySchema,
  playerStatisticsIdParamSchema,
  leaderboardQuerySchema,
  leaderboardTypeParamSchema,
  tournamentParamSchema,
};
