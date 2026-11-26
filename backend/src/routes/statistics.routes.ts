import { Router } from 'express';

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
import {
  playerStatisticsIdParamSchema,
  playerStatisticsQuerySchema,
  tournamentParamSchema,
} from '../validators/statistics.validator';

const router = Router();

router.get('/', validate(playerStatisticsQuerySchema, 'query'), getStatisticsOverview);
router.get('/top-batsmen', validate(playerStatisticsQuerySchema, 'query'), getTopBatsmen);
router.get('/top-bowlers', validate(playerStatisticsQuerySchema, 'query'), getTopBowlers);
router.get(
  '/tournament/:id',
  validate(tournamentParamSchema, 'params'),
  validate(playerStatisticsQuerySchema, 'query'),
  getTournamentStatistics
);

router.get(
  '/players/:id/overall',
  validate(playerStatisticsIdParamSchema, 'params'),
  validate(playerStatisticsQuerySchema, 'query'),
  getPlayerOverallStats
);
router.get(
  '/players/:id/batting',
  validate(playerStatisticsIdParamSchema, 'params'),
  validate(playerStatisticsQuerySchema, 'query'),
  getPlayerBattingStats
);
router.get(
  '/players/:id/bowling',
  validate(playerStatisticsIdParamSchema, 'params'),
  validate(playerStatisticsQuerySchema, 'query'),
  getPlayerBowlingStats
);
router.get(
  '/players/:id/fielding',
  validate(playerStatisticsIdParamSchema, 'params'),
  validate(playerStatisticsQuerySchema, 'query'),
  getPlayerFieldingStats
);
router.get(
  '/players/:id/recent',
  validate(playerStatisticsIdParamSchema, 'params'),
  validate(playerStatisticsQuerySchema, 'query'),
  getPlayerRecentForm
);
router.get(
  '/players/:id/tournaments',
  validate(playerStatisticsIdParamSchema, 'params'),
  validate(playerStatisticsQuerySchema, 'query'),
  getPlayerTournamentWiseStats
);
router.get(
  '/players/:id/seasons',
  validate(playerStatisticsIdParamSchema, 'params'),
  validate(playerStatisticsQuerySchema, 'query'),
  getPlayerSeasonWiseStats
);
router.get(
  '/players/:id/formats',
  validate(playerStatisticsIdParamSchema, 'params'),
  validate(playerStatisticsQuerySchema, 'query'),
  getPlayerFormatWiseStats
);

export default router;
