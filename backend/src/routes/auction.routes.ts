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

const router = Router();

router.get('/', validate(auctionQuerySchema, 'query'), listAuctions);
router.get('/upcoming', validate(auctionQuerySchema, 'query'), listAuctionsByStatus('UPCOMING'));
router.get('/live', validate(auctionQuerySchema, 'query'), listAuctionsByStatus('LIVE'));
router.get('/completed', validate(auctionQuerySchema, 'query'), listAuctionsByStatus('COMPLETED'));
router.get('/:id', getAuction);
router.get('/:id/state', validate(auctionHistoryQuerySchema, 'query'), getAuctionState);
router.get('/:id/players', validate(auctionPlayersQuerySchema, 'query'), getAuctionPlayers);
router.get('/:id/history', validate(auctionHistoryQuerySchema, 'query'), getBidHistory);
router.get('/:id/results', getAuctionResults);
router.get('/:id/teams/:teamId/purse', getTeamPurse);

router.post('/', protect, validate(createAuctionSchema, 'body'), createAuction);
router.put('/:id', protect, validate(updateAuctionSchema, 'body'), updateAuction);
router.delete('/:id', protect, deleteAuction);

router.post('/:id/players', protect, validate(registerPlayersSchema, 'body'), registerPlayers);
router.delete('/:id/players/:auctionPlayerId', protect, validate(auctionActionSchema, 'body'), removePlayer);
router.patch('/:id/players/:auctionPlayerId/availability', protect, validate(availabilitySchema, 'body'), setPlayerAvailability);
router.post('/:id/players/:auctionPlayerId/forward', protect, validate(auctionActionSchema, 'body'), bringPlayerForward);

router.post('/:id/teams', protect, validate(auctionTeamSchema, 'body'), addTeam);
router.delete('/:id/teams/:teamId', protect, validate(auctionActionSchema, 'body'), removeTeam);

router.post('/:id/start', protect, validate(auctionActionSchema, 'body'), startAuction);
router.post('/:id/pause', protect, validate(auctionActionSchema, 'body'), pauseAuction);
router.post('/:id/resume', protect, validate(auctionActionSchema, 'body'), resumeAuction);
router.post('/:id/complete', protect, validate(auctionActionSchema, 'body'), completeAuction);

router.post('/:id/bid', protect, validate(placeBidSchema, 'body'), placeBid);
router.post('/:id/bids/:bidId/decision', protect, validate(bidDecisionSchema, 'body'), decideBid);
router.post('/:id/sold', protect, validate(auctionActionSchema, 'body'), markSold);
router.post('/:id/unsold', protect, validate(auctionActionSchema, 'body'), markUnsold);
router.post('/:id/next', protect, validate(auctionActionSchema, 'body'), nextPlayer);

export default router;
