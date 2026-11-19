import { Request, Response } from 'express';
import { asyncHandler } from '../utils/asyncHandler';
import { ApiResponse } from '../utils/apiResponse';
import { ApiError } from '../utils/apiError';
import { MESSAGES } from '../constants/messages';
import matchService from '../services/match.service';

/**
 * Create a new match
 * POST /api/v1/matches
 */
export const createMatch = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const userId = req.user?._id?.toString() || req.user?.id;
  if (!userId) {
    throw ApiError.unauthorized(MESSAGES.AUTH.UNAUTHORIZED || 'User is not authenticated.');
  }

  const match = await matchService.createMatch(userId, req.body);
  ApiResponse.success(
    res,
    201,
    MESSAGES.MATCH.CREATED || 'Match created and scheduled successfully.',
    match
  );
});

/**
 * List all matches with pagination and filters
 * GET /api/v1/matches
 */
export const getMatches = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await matchService.getMatches(req.query);
  ApiResponse.paginated(
    res,
    result.matches,
    result.pagination.page,
    result.pagination.limit,
    result.pagination.total,
    MESSAGES.MATCH.FETCHED || 'Matches retrieved successfully.'
  );
});

/**
 * Get all live matches
 * GET /api/v1/matches/live
 */
export const getLiveMatches = asyncHandler(async (_req: Request, res: Response): Promise<void> => {
  const matches = await matchService.getLiveMatches();
  ApiResponse.success(
    res,
    200,
    'Live matches retrieved successfully.',
    matches
  );
});

/**
 * Get upcoming matches
 * GET /api/v1/matches/upcoming
 */
export const getUpcomingMatches = asyncHandler(async (_req: Request, res: Response): Promise<void> => {
  const matches = await matchService.getUpcomingMatches();
  ApiResponse.success(
    res,
    200,
    'Upcoming matches retrieved successfully.',
    matches
  );
});

/**
 * Get completed matches
 * GET /api/v1/matches/completed
 */
export const getCompletedMatches = asyncHandler(async (_req: Request, res: Response): Promise<void> => {
  const matches = await matchService.getCompletedMatches();
  ApiResponse.success(
    res,
    200,
    'Completed matches retrieved successfully.',
    matches
  );
});

/**
 * Get match details by ID
 * GET /api/v1/matches/:id
 */
export const getMatchById = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  const match = await matchService.getMatchById(id);
  ApiResponse.success(
    res,
    200,
    MESSAGES.MATCH.FETCHED || 'Match details retrieved successfully.',
    match
  );
});

/**
 * Update match details
 * PUT /api/v1/matches/:id
 */
export const updateMatch = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const userId = req.user?._id?.toString() || req.user?.id;
  if (!userId) {
    throw ApiError.unauthorized(MESSAGES.AUTH.UNAUTHORIZED || 'User is not authenticated.');
  }

  const id = req.params.id as string;
  const updatedMatch = await matchService.updateMatch(id, userId, req.body);
  ApiResponse.success(
    res,
    200,
    MESSAGES.MATCH.UPDATED || 'Match details updated successfully.',
    updatedMatch
  );
});

/**
 * Delete a match (only UPCOMING)
 * DELETE /api/v1/matches/:id
 */
export const deleteMatch = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const userId = req.user?._id?.toString() || req.user?.id;
  if (!userId) {
    throw ApiError.unauthorized(MESSAGES.AUTH.UNAUTHORIZED || 'User is not authenticated.');
  }

  const id = req.params.id as string;
  const result = await matchService.deleteMatch(id, userId);
  ApiResponse.success(
    res,
    200,
    result.message
  );
});

/**
 * Record toss winner and decision
 * POST /api/v1/matches/:id/toss
 */
export const performToss = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const userId = req.user?._id?.toString() || req.user?.id;
  if (!userId) {
    throw ApiError.unauthorized(MESSAGES.AUTH.UNAUTHORIZED || 'User is not authenticated.');
  }

  const id = req.params.id as string;
  const { winner, decision } = req.body;
  const updatedMatch = await matchService.performToss(id, userId, winner, decision);
  ApiResponse.success(
    res,
    200,
    MESSAGES.MATCH.TOSS_RECORDED || 'Toss result recorded successfully.',
    updatedMatch
  );
});

/**
 * Set Playing XI and Substitutes for a team
 * POST /api/v1/matches/:id/playing-xi
 */
export const setPlayingXI = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const userId = req.user?._id?.toString() || req.user?.id;
  if (!userId) {
    throw ApiError.unauthorized(MESSAGES.AUTH.UNAUTHORIZED || 'User is not authenticated.');
  }

  const id = req.params.id as string;
  const { teamId, playingXI, substitutes } = req.body;
  const updatedMatch = await matchService.setPlayingXI(
    id,
    userId,
    teamId,
    playingXI,
    substitutes
  );
  ApiResponse.success(
    res,
    200,
    MESSAGES.MATCH.PLAYING_XI_SUBMITTED || 'Playing XI submitted successfully.',
    updatedMatch
  );
});

/**
 * Assign official scorer to match
 * POST /api/v1/matches/:id/scorer
 */
export const assignScorer = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const userId = req.user?._id?.toString() || req.user?.id;
  if (!userId) {
    throw ApiError.unauthorized(MESSAGES.AUTH.UNAUTHORIZED || 'User is not authenticated.');
  }

  const id = req.params.id as string;
  const { scorerId } = req.body;
  const updatedMatch = await matchService.assignScorer(id, userId, scorerId);
  ApiResponse.success(
    res,
    200,
    'Scorer assigned successfully.',
    updatedMatch
  );
});

/**
 * Start the match (creates 1st innings and sets status to LIVE)
 * POST /api/v1/matches/:id/start
 */
export const startMatch = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const userId = req.user?._id?.toString() || req.user?.id;
  if (!userId) {
    throw ApiError.unauthorized(MESSAGES.AUTH.UNAUTHORIZED || 'User is not authenticated.');
  }

  const id = req.params.id as string;
  const result = await matchService.startMatch(id, userId);
  ApiResponse.success(
    res,
    200,
    'Match started and is now LIVE.',
    result
  );
});

/**
 * Retrieve complete match scorecard
 * GET /api/v1/matches/:id/scorecard
 */
export const getMatchScorecard = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  const scorecard = await matchService.getMatchScorecard(id);
  ApiResponse.success(
    res,
    200,
    'Match scorecard retrieved successfully.',
    scorecard
  );
});

export default {
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
};
