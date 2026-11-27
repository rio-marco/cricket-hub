import { Request, Response } from 'express';
import { asyncHandler } from '../utils/asyncHandler';
import { ApiResponse } from '../utils/apiResponse';
import { ApiError } from '../utils/apiError';
import { MESSAGES } from '../constants/messages';
import auctionService from '../services/auction.service';
import { AuctionCommit } from '../sockets/types';
import { publishAuctionEvent } from '../sockets/publisher';

const currentUserId = (req: Request): string => {
  const userId = req.user?._id?.toString() || req.user?.id;
  if (!userId) throw ApiError.unauthorized('User is not authenticated.');
  return userId;
};

const actionInput = (req: Request): Record<string, unknown> => {
  const headerKey = req.header('Idempotency-Key');
  const ifMatch = req.header('If-Match')?.replace(/"/g, '');
  const body = (req.body || {}) as Record<string, unknown>;
  return {
    ...body,
    ...(headerKey && !body.idempotencyKey ? { idempotencyKey: headerKey } : {}),
    ...(ifMatch && body.expectedVersion === undefined ? { expectedVersion: Number(ifMatch) } : {}),
  };
};

const respondWithState = (
  res: Response,
  status: number,
  message: string,
  result: any
): void => {
  const { commit, ...state } = result || {};
  if ((commit as AuctionCommit | undefined)?.committed) {
    publishAuctionEvent(commit as AuctionCommit, state);
  }
  ApiResponse.success(res, status, message, state);
};

export const listAuctions = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await auctionService.listAuctions(req.query as Record<string, any>, currentUserId(req));
  res.status(200).json({
    success: true,
    message: MESSAGES.AUCTION.FETCHED,
    data: result.data,
    pagination: result.pagination,
  });
});

export const listAuctionsByStatus = (status: string) =>
  asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const result = await auctionService.listAuctions({ ...(req.query as Record<string, any>), status }, currentUserId(req));
    res.status(200).json({
      success: true,
      message: MESSAGES.AUCTION.FETCHED,
      data: result.data,
      pagination: result.pagination,
    });
  });

export const getAuction = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const auction = await auctionService.getAuctionById(req.params.id as string, currentUserId(req));
  ApiResponse.success(res, 200, MESSAGES.AUCTION.FETCHED, auction);
});

export const getAuctionState = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const state = await auctionService.getState(req.params.id as string, currentUserId(req), req.query as Record<string, any>);
  ApiResponse.success(res, 200, MESSAGES.AUCTION.FETCHED, state);
});

export const getAuctionPlayers = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await auctionService.getAuctionPlayers(req.params.id as string, req.query as Record<string, any>, currentUserId(req));
  res.status(200).json({
    success: true,
    message: MESSAGES.AUCTION.FETCHED,
    data: result.data,
    pagination: result.pagination,
  });
});

export const getBidHistory = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const bids = await auctionService.getBidHistory(req.params.id as string, req.query as Record<string, any>, currentUserId(req));
  ApiResponse.success(res, 200, MESSAGES.AUCTION.FETCHED, bids);
});

export const getAuctionResults = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const results = await auctionService.getResults(req.params.id as string, currentUserId(req));
  ApiResponse.success(res, 200, MESSAGES.AUCTION.FETCHED, results);
});

export const getTeamPurse = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const userId = currentUserId(req);
  const purse = await auctionService.getTeamPurse(req.params.id as string, req.params.teamId as string, userId);
  ApiResponse.success(res, 200, MESSAGES.AUCTION.FETCHED, purse);
});

export const createAuction = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await auctionService.createAuction(currentUserId(req), actionInput(req) as any);
  respondWithState(res, 201, MESSAGES.AUCTION.CREATED, result);
});

export const updateAuction = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await auctionService.updateAuction(req.params.id as string, currentUserId(req), actionInput(req));
  respondWithState(res, 200, MESSAGES.AUCTION.UPDATED, result);
});

export const deleteAuction = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await auctionService.deleteAuction(req.params.id as string, currentUserId(req));
  ApiResponse.success(res, 200, 'Auction deleted successfully.', result);
});

export const registerPlayers = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const body = actionInput(req);
  const result = await auctionService.registerPlayers(
    req.params.id as string,
    currentUserId(req),
    body.players as any,
    body.idempotencyKey as string | undefined
  );
  respondWithState(res, 201, MESSAGES.AUCTION.PLAYER_ADDED, result);
});

export const removePlayer = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await auctionService.removeAuctionPlayer(
    req.params.id as string,
    req.params.auctionPlayerId as string,
    currentUserId(req)
  );
  respondWithState(res, 200, MESSAGES.AUCTION.PLAYER_REMOVED, result);
});

export const setPlayerAvailability = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await auctionService.setPlayerAvailability(
    req.params.id as string,
    req.params.auctionPlayerId as string,
    currentUserId(req),
    Boolean((req.body as any).available)
  );
  respondWithState(res, 200, 'Player availability updated.', result);
});

export const bringPlayerForward = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await auctionService.bringPlayerForward(
    req.params.id as string,
    req.params.auctionPlayerId as string,
    currentUserId(req),
    actionInput(req)
  );
  respondWithState(res, 200, MESSAGES.AUCTION.PLAYER_BROUGHT_FORWARD, result);
});

export const addTeam = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await auctionService.addAuctionTeam(
    req.params.id as string,
    String((req.body as any).teamId),
    currentUserId(req)
  );
  respondWithState(res, 201, 'Team added to auction.', result);
});

export const removeTeam = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await auctionService.removeAuctionTeam(
    req.params.id as string,
    req.params.teamId as string,
    currentUserId(req)
  );
  respondWithState(res, 200, 'Team removed from auction.', result);
});

export const startAuction = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await auctionService.startAuction(req.params.id as string, currentUserId(req), actionInput(req));
  respondWithState(res, 200, MESSAGES.AUCTION.STARTED, result);
});

export const pauseAuction = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await auctionService.pauseAuction(req.params.id as string, currentUserId(req), actionInput(req));
  respondWithState(res, 200, MESSAGES.AUCTION.PAUSED, result);
});

export const resumeAuction = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await auctionService.resumeAuction(req.params.id as string, currentUserId(req), actionInput(req));
  respondWithState(res, 200, 'Auction resumed.', result);
});

export const completeAuction = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await auctionService.completeAuction(req.params.id as string, currentUserId(req), actionInput(req));
  respondWithState(res, 200, MESSAGES.AUCTION.COMPLETED, result);
});

export const placeBid = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await auctionService.placeBid(req.params.id as string, currentUserId(req), actionInput(req) as any);
  respondWithState(res, 201, MESSAGES.AUCTION.BID_PLACED, result);
});

export const decideBid = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await auctionService.decideBid(
    req.params.id as string,
    req.params.bidId as string,
    currentUserId(req),
    actionInput(req) as any
  );
  respondWithState(res, 200, result.commit?.decision === 'REJECTED' ? 'Bid rejected.' : MESSAGES.AUCTION.PLAYER_SOLD, result);
});

export const markSold = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await auctionService.markCurrentPlayerSold(req.params.id as string, currentUserId(req), actionInput(req));
  respondWithState(res, 200, MESSAGES.AUCTION.PLAYER_SOLD, result);
});

export const markUnsold = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await auctionService.markCurrentPlayerUnsold(req.params.id as string, currentUserId(req), actionInput(req));
  respondWithState(res, 200, MESSAGES.AUCTION.PLAYER_UNSOLD, result);
});

export const nextPlayer = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await auctionService.nextPlayer(req.params.id as string, currentUserId(req), actionInput(req));
  respondWithState(res, 200, MESSAGES.AUCTION.PLAYER_BROUGHT_FORWARD, result);
});

export default {
  listAuctions,
  listAuctionsByStatus,
  getAuction,
  getAuctionState,
  getAuctionPlayers,
  getBidHistory,
  getAuctionResults,
  getTeamPurse,
  createAuction,
  updateAuction,
  deleteAuction,
  registerPlayers,
  removePlayer,
  setPlayerAvailability,
  bringPlayerForward,
  addTeam,
  removeTeam,
  startAuction,
  pauseAuction,
  resumeAuction,
  completeAuction,
  placeBid,
  decideBid,
  markSold,
  markUnsold,
  nextPlayer,
};
