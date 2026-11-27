import { Router } from 'express';
import { apiLimiter } from '../middlewares/rateLimiter.middleware';

import {
  getPlayerBattingStats,
  getPlayerBowlingStats,
  getPlayerFieldingStats,
  getPlayerFormatWiseStats,
  getPlayerOverallStats,
  getPlayerRecentForm,
  getPlayerSeasonWiseStats,
  getPlayerTournamentWiseStats,
  getStatisticsOverview,
  getTopBatsmen,
  getTopBowlers,
  getTournamentStatistics,
} from '../controllers/statistics.controller';
import { validate } from '../middlewares/validate.middleware';
import { playerIdParamSchema, teamIdParamSchema, tournamentIdParamSchema, matchIdParamSchema } from '../validators/params.validator';
import {
  playerStatisticsIdParamSchema,
  playerStatisticsQuerySchema,
  tournamentParamSchema,
} from '../validators/statistics.validator';

const router = Router();

router.get('/', apiLimiter, validate(playerStatisticsQuerySchema, 'query'), getStatisticsOverview);
router.get('/top-batsmen', apiLimiter, validate(playerStatisticsQuerySchema, 'query'), getTopBatsmen);
router.get('/top-bowlers', apiLimiter, validate(playerStatisticsQuerySchema, 'query'), getTopBowlers);
router.get(
  '/tournament/:id',
  apiLimiter,
  validate(tournamentParamSchema, 'params'),
  validate(playerStatisticsQuerySchema, 'query'),
  getTournamentStatistics
);

router.get(
  '/players/:id/overall',
  apiLimiter,
  validate(playerStatisticsIdParamSchema, 'params'),
  validate(playerStatisticsQuerySchema, 'query'),
  getPlayerOverallStats
);
router.get(
  '/players/:id/batting',
  apiLimiter,
  validate(playerStatisticsIdParamSchema, 'params'),
  validate(playerStatisticsQuerySchema, 'query'),
  getPlayerBattingStats
);
router.get(
  '/players/:id/bowling',
  apiLimiter,
  validate(playerStatisticsIdParamSchema, 'params'),
  validate(playerStatisticsQuerySchema, 'query'),
  getPlayerBowlingStats
);
router.get(
  '/players/:id/fielding',
  apiLimiter,
  validate(playerStatisticsIdParamSchema, 'params'),
  validate(playerStatisticsQuerySchema, 'query'),
  getPlayerFieldingStats
);
router.get(
  '/players/:id/recent',
  apiLimiter,
  validate(playerStatisticsIdParamSchema, 'params'),
  validate(playerStatisticsQuerySchema, 'query'),
  getPlayerRecentForm
);
router.get(
  '/players/:id/tournaments',
  apiLimiter,
  validate(playerStatisticsIdParamSchema, 'params'),
  validate(playerStatisticsQuerySchema, 'query'),
  getPlayerTournamentWiseStats
);
router.get(
  '/players/:id/seasons',
  apiLimiter,
  validate(playerStatisticsIdParamSchema, 'params'),
  validate(playerStatisticsQuerySchema, 'query'),
  getPlayerSeasonWiseStats
);
router.get(
  '/players/:id/formats',
  apiLimiter,
  validate(playerStatisticsIdParamSchema, 'params'),
  validate(playerStatisticsQuerySchema, 'query'),
  getPlayerFormatWiseStats
);

export default router;
