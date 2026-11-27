import { Router } from 'express';
import {
  completeMatch,
  correctBall,
  endInnings,
  getScoringCommentary,
  getScoringInnings,
  getScoringState,
  recordBall,
  startInnings,
  undoBall,
} from '../controllers/scoring.controller';
import { protect } from '../middlewares/auth.middleware';
import { apiLimiter, scoringLimiter } from '../middlewares/rateLimiter.middleware';
import { validate } from '../middlewares/validate.middleware';
import { idParamSchema, matchIdParamSchema, idDeliveryIdParamSchema } from '../validators/params.validator';
import {
  completeMatchSchema,
  correctBallSchema,
  inningsEndSchema,
  recordBallSchema,
  scoringQuerySchema,
  startInningsSchema,
  undoBallSchema,
} from '../validators/scoring.validator';

const router = Router();

router.get('/:matchId', apiLimiter, validate(matchIdParamSchema, 'params'), validate(scoringQuerySchema, 'query'), getScoringState);
router.get('/:matchId/state', apiLimiter, validate(matchIdParamSchema, 'params'), validate(scoringQuerySchema, 'query'), getScoringState);
router.get('/:matchId/innings/:inningsNumber', apiLimiter, validate(matchIdParamSchema, 'params'), getScoringInnings);
router.get('/:matchId/commentary', apiLimiter, validate(matchIdParamSchema, 'params'), validate(scoringQuerySchema, 'query'), getScoringCommentary);

router.post('/:matchId/start-innings', scoringLimiter, protect, validate(matchIdParamSchema, 'params'), validate(startInningsSchema, 'body'), startInnings);
router.post('/:matchId/ball', scoringLimiter, protect, validate(matchIdParamSchema, 'params'), validate(recordBallSchema, 'body'), recordBall);
router.post('/:matchId/undo', scoringLimiter, protect, validate(matchIdParamSchema, 'params'), validate(undoBallSchema, 'body'), undoBall);
router.post(
  '/:matchId/ball/:deliveryId/correct',
  scoringLimiter,
  protect,
  validate(idDeliveryIdParamSchema, 'params'),
  validate(correctBallSchema, 'body'),
  correctBall
);
router.post('/:matchId/innings-end', scoringLimiter, protect, validate(matchIdParamSchema, 'params'), validate(inningsEndSchema, 'body'), endInnings);
router.post('/:matchId/complete', scoringLimiter, protect, validate(matchIdParamSchema, 'params'), validate(completeMatchSchema, 'body'), completeMatch);

export default router;
