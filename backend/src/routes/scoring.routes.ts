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
import { validate } from '../middlewares/validate.middleware';
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

router.get('/:matchId', validate(scoringQuerySchema, 'query'), getScoringState);
router.get('/:matchId/state', validate(scoringQuerySchema, 'query'), getScoringState);
router.get('/:matchId/innings/:inningsNumber', getScoringInnings);
router.get('/:matchId/commentary', validate(scoringQuerySchema, 'query'), getScoringCommentary);

router.post('/:matchId/start-innings', protect, validate(startInningsSchema, 'body'), startInnings);
router.post('/:matchId/ball', protect, validate(recordBallSchema, 'body'), recordBall);
router.post('/:matchId/undo', protect, validate(undoBallSchema, 'body'), undoBall);
router.post(
  '/:matchId/ball/:deliveryId/correct',
  protect,
  validate(correctBallSchema, 'body'),
  correctBall
);
router.post('/:matchId/innings-end', protect, validate(inningsEndSchema, 'body'), endInnings);
router.post('/:matchId/complete', protect, validate(completeMatchSchema, 'body'), completeMatch);

export default router;
