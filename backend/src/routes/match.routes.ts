import { Router } from 'express';
import {
  createMatch,
  getMatches,
  getLiveMatches,
  getUpcomingMatches,
  getCompletedMatches,
  getMatchById,
  updateMatch,
  deleteMatch,
  performToss,
  setPlayingXI,
  assignScorer,
  startMatch,
  getMatchScorecard,
} from '../controllers/match.controller';
import { protect } from '../middlewares/auth.middleware';
import { validate } from '../middlewares/validate.middleware';
import {
  createMatchSchema,
  updateMatchSchema,
  tossSchema,
  playingXISchema,
  scorerSchema,
  matchQuerySchema,
} from '../validators/match.validator';

const router = Router();

// Public match query routes - literal routes declared before parameterized :id route
router.get('/', validate(matchQuerySchema, 'query'), getMatches);
router.get('/live', getLiveMatches);
router.get('/upcoming', getUpcomingMatches);
router.get('/completed', getCompletedMatches);
router.get('/:id', getMatchById);
router.get('/:id/scorecard', getMatchScorecard);

// Protected match management routes
router.post('/', protect, validate(createMatchSchema, 'body'), createMatch);
router.put('/:id', protect, validate(updateMatchSchema, 'body'), updateMatch);
router.delete('/:id', protect, deleteMatch);

// Match lifecycle & scoring setup actions
router.post('/:id/toss', protect, validate(tossSchema, 'body'), performToss);
router.post('/:id/playing-xi', protect, validate(playingXISchema, 'body'), setPlayingXI);
router.post('/:id/scorer', protect, validate(scorerSchema, 'body'), assignScorer);
router.post('/:id/start', protect, startMatch);

export default router;
