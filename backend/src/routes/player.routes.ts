import { Router } from 'express';
import {
  createPlayer,
  getPlayers,
  searchPlayers,
  getPlayerById,
  updatePlayer,
  deletePlayer,
  getPlayerStats,
  getPlayerTeams,
  getPlayerMatches,
} from '../controllers/player.controller';
import { protect } from '../middlewares/auth.middleware';
import { apiLimiter } from '../middlewares/rateLimiter.middleware';
import { validate } from '../middlewares/validate.middleware';
import {
  createPlayerSchema,
  updatePlayerSchema,
  searchPlayerSchema,
} from '../validators/player.validator';
import { playerStatisticsQuerySchema } from '../validators/statistics.validator';
import { idParamSchema } from '../validators/params.validator';

const router = Router();

// Base player routes
router.post('/', protect, validate(createPlayerSchema, 'body'), createPlayer);
router.get('/', apiLimiter, validate(searchPlayerSchema, 'query'), getPlayers);

// Search endpoint placed before dynamic :id route to prevent collision
router.get('/search', apiLimiter, validate(searchPlayerSchema, 'query'), searchPlayers);

// Dynamic player routes by ID
router.get('/:id', validate(idParamSchema, 'params'), getPlayerById);
router.put('/:id', protect, validate(idParamSchema, 'params'), validate(updatePlayerSchema, 'body'), updatePlayer);
router.delete('/:id', protect, validate(idParamSchema, 'params'), deletePlayer);

// Player details: statistics, teams, and matches
router.get('/:id/stats', validate(idParamSchema, 'params'), validate(playerStatisticsQuerySchema, 'query'), getPlayerStats);
router.get('/:id/teams', validate(idParamSchema, 'params'), getPlayerTeams);
router.get('/:id/matches', validate(idParamSchema, 'params'), getPlayerMatches);

export default router;
