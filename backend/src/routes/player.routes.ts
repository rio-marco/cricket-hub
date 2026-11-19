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
import { validate } from '../middlewares/validate.middleware';
import {
  createPlayerSchema,
  updatePlayerSchema,
  searchPlayerSchema,
} from '../validators/player.validator';

const router = Router();

// Base player routes
router.post('/', protect, validate(createPlayerSchema, 'body'), createPlayer);
router.get('/', validate(searchPlayerSchema, 'query'), getPlayers);

// Search endpoint placed before dynamic :id route to prevent collision
router.get('/search', validate(searchPlayerSchema, 'query'), searchPlayers);

// Dynamic player routes by ID
router.get('/:id', getPlayerById);
router.put('/:id', protect, validate(updatePlayerSchema, 'body'), updatePlayer);
router.delete('/:id', protect, deletePlayer);

// Player details: statistics, teams, and matches
router.get('/:id/stats', getPlayerStats);
router.get('/:id/teams', getPlayerTeams);
router.get('/:id/matches', getPlayerMatches);

export default router;
