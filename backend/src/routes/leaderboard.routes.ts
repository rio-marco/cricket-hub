import { Router } from 'express';

import { getLeaderboard } from '../controllers/statistics.controller';
import { validate } from '../middlewares/validate.middleware';
import {
  leaderboardQuerySchema,
  leaderboardTypeParamSchema,
} from '../validators/statistics.validator';

const router = Router();

router.get('/', validate(leaderboardQuerySchema, 'query'), getLeaderboard);
router.get(
  '/:type',
  validate(leaderboardTypeParamSchema, 'params'),
  validate(leaderboardQuerySchema, 'query'),
  getLeaderboard
);

export default router;
