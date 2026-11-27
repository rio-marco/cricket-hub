import { Router } from 'express';
import {
  addTeam,
  bringPlayerForward,
  completeAuction,
  createAuction,
  decideBid,
  deleteAuction,
  getAuction,
  getAuctionPlayers,
  getAuctionResults,
  getAuctionState,
  getBidHistory,
  getTeamPurse,
  listAuctions,
  listAuctionsByStatus,
  markSold,
  markUnsold,
  nextPlayer,
  pauseAuction,
  placeBid,
  registerPlayers,
  removePlayer,
  removeTeam,
  resumeAuction,
  setPlayerAvailability,
  startAuction,
  updateAuction,
} from '../controllers/auction.controller';
import { scoringLimiter } from '../middlewares/rateLimiter.middleware';
import { protect } from '../middlewares/auth.middleware';
import { validate } from '../middlewares/validate.middleware';
import {
  auctionActionSchema,
  auctionHistoryQuerySchema,
  auctionPlayersQuerySchema,
  auctionQuerySchema,
  auctionTeamSchema,
  availabilitySchema,
  bidDecisionSchema,
  createAuctionSchema,
  placeBidSchema,
  registerPlayersSchema,
  updateAuctionSchema,
} from '../validators/auction.validator';
import { idParamSchema, idAuctionPlayerIdParamSchema, idBidIdParamSchema, idTeamIdParamSchema } from '../validators/params.validator';

const router = Router();

router.get('/', protect, validate(auctionQuerySchema, 'query'), listAuctions);
router.get('/upcoming', protect, validate(auctionQuerySchema, 'query'), listAuctionsByStatus('UPCOMING'));
router.get('/live', protect, validate(auctionQuerySchema, 'query'), listAuctionsByStatus('LIVE'));
router.get('/completed', protect, validate(auctionQuerySchema, 'query'), listAuctionsByStatus('COMPLETED'));
router.get('/:id', protect, validate(idParamSchema, 'params'), getAuction);
router.get('/:id/state', protect, validate(idParamSchema, 'params'), validate(auctionHistoryQuerySchema, 'query'), getAuctionState);
router.get('/:id/players', protect, validate(idParamSchema, 'params'), validate(auctionPlayersQuerySchema, 'query'), getAuctionPlayers);
router.get('/:id/history', protect, validate(idParamSchema, 'params'), validate(auctionHistoryQuerySchema, 'query'), getBidHistory);
router.get('/:id/results', protect, validate(idParamSchema, 'params'), getAuctionResults);
router.get('/:id/teams/:teamId/purse', protect, validate(idTeamIdParamSchema, 'params'), getTeamPurse);

router.post('/', scoringLimiter, protect, validate(createAuctionSchema, 'body'), createAuction);
router.put('/:id', protect, validate(idParamSchema, 'params'), validate(updateAuctionSchema, 'body'), updateAuction);
router.delete('/:id', protect, validate(idParamSchema, 'params'), deleteAuction);

router.post('/:id/players', protect, validate(idParamSchema, 'params'), validate(registerPlayersSchema, 'body'), registerPlayers);
router.delete('/:id/players/:auctionPlayerId', protect, validate(idAuctionPlayerIdParamSchema, 'params'), validate(auctionActionSchema, 'body'), removePlayer);
router.patch('/:id/players/:auctionPlayerId/availability', protect, validate(idAuctionPlayerIdParamSchema, 'params'), validate(availabilitySchema, 'body'), setPlayerAvailability);
router.post('/:id/players/:auctionPlayerId/forward', protect, validate(idAuctionPlayerIdParamSchema, 'params'), validate(auctionActionSchema, 'body'), bringPlayerForward);

router.post('/:id/teams', protect, validate(idParamSchema, 'params'), validate(auctionTeamSchema, 'body'), addTeam);
router.delete('/:id/teams/:teamId', protect, validate(idTeamIdParamSchema, 'params'), validate(auctionActionSchema, 'body'), removeTeam);

router.post('/:id/start', scoringLimiter, protect, validate(idParamSchema, 'params'), validate(auctionActionSchema, 'body'), startAuction);
router.post('/:id/pause', scoringLimiter, protect, validate(idParamSchema, 'params'), validate(auctionActionSchema, 'body'), pauseAuction);
router.post('/:id/resume', scoringLimiter, protect, validate(idParamSchema, 'params'), validate(auctionActionSchema, 'body'), resumeAuction);
router.post('/:id/complete', scoringLimiter, protect, validate(idParamSchema, 'params'), validate(auctionActionSchema, 'body'), completeAuction);

router.post('/:id/bid', scoringLimiter, protect, validate(idParamSchema, 'params'), validate(placeBidSchema, 'body'), placeBid);
router.post('/:id/bids/:bidId/decision', scoringLimiter, protect, validate(idBidIdParamSchema, 'params'), validate(bidDecisionSchema, 'body'), decideBid);
router.post('/:id/sold', scoringLimiter, protect, validate(idParamSchema, 'params'), validate(auctionActionSchema, 'body'), markSold);
router.post('/:id/unsold', scoringLimiter, protect, validate(idParamSchema, 'params'), validate(auctionActionSchema, 'body'), markUnsold);
router.post('/:id/next', scoringLimiter, protect, validate(idParamSchema, 'params'), validate(auctionActionSchema, 'body'), nextPlayer);

export default router;
