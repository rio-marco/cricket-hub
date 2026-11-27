import { Router } from 'express';
import { apiLimiter } from '../middlewares/rateLimiter.middleware';

import { getLeaderboard } from '../controllers/statistics.controller';
import { validate } from '../middlewares/validate.middleware';
import { tournamentIdParamSchema } from '../validators/params.validator';
import {
  leaderboardQuerySchema,
  leaderboardTypeParamSchema,
} from '../validators/statistics.validator';

const router = Router();

router.get('/', apiLimiter, validate(leaderboardQuerySchema, 'query'), getLeaderboard);
router.get(
  '/:type',
  apiLimiter,
  validate(leaderboardTypeParamSchema, 'params'),
  validate(leaderboardQuerySchema, 'query'),
  getLeaderboard
);

export default router;
