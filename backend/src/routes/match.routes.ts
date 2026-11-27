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
import { apiLimiter } from '../middlewares/rateLimiter.middleware';
import { validate } from '../middlewares/validate.middleware';
import { idParamSchema } from '../validators/params.validator';
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
router.get('/', apiLimiter, validate(matchQuerySchema, 'query'), getMatches);
router.get('/live', apiLimiter, getLiveMatches);
router.get('/upcoming', apiLimiter, getUpcomingMatches);
router.get('/completed', apiLimiter, getCompletedMatches);
router.get('/:id', apiLimiter, validate(idParamSchema, 'params'), getMatchById);
router.get('/:id/scorecard', apiLimiter, validate(idParamSchema, 'params'), getMatchScorecard);

// Protected match management routes
router.post('/', protect, validate(createMatchSchema, 'body'), createMatch);
router.put('/:id', protect, validate(idParamSchema, 'params'), validate(updateMatchSchema, 'body'), updateMatch);
router.delete('/:id', protect, validate(idParamSchema, 'params'), deleteMatch);

// Match lifecycle & scoring setup actions
router.post('/:id/toss', protect, validate(idParamSchema, 'params'), validate(tossSchema, 'body'), performToss);
router.post('/:id/playing-xi', protect, validate(idParamSchema, 'params'), validate(playingXISchema, 'body'), setPlayingXI);
router.post('/:id/scorer', protect, validate(idParamSchema, 'params'), validate(scorerSchema, 'body'), assignScorer);
router.post('/:id/start', protect, validate(idParamSchema, 'params'), startMatch);

export default router;
