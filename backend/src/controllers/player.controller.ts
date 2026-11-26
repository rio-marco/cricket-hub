import { Request, Response } from 'express';
import { asyncHandler } from '../utils/asyncHandler';
import { ApiResponse } from '../utils/apiResponse';
import { MESSAGES } from '../constants/messages';
import playerService from '../services/player.service';
import { normalizeStatisticsFilters } from '../services/playerStatistics.service';

/**
 * Create player profile for authenticated user
 * POST /api/v1/players
 */
export const createPlayer = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const player = await playerService.createPlayer(req.user!._id, req.body);
  ApiResponse.success(
    res,
    201,
    MESSAGES.PLAYER.CREATED || 'Player profile created successfully.',
    player
  );
});

/**
 * Get paginated list of players
 * GET /api/v1/players
 */
export const getPlayers = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await playerService.getPlayers(req.query);
  ApiResponse.paginated(
    res,
    result.data,
    result.pagination.page,
    result.pagination.limit,
    result.pagination.total,
    MESSAGES.PLAYER.LIST_FETCHED || 'Players retrieved successfully.'
  );
});

/**
 * Search players by keyword, playing role, style, or city
 * GET /api/v1/players/search
 */
export const searchPlayers = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await playerService.searchPlayers(req.query);
  ApiResponse.paginated(
    res,
    result.data,
    result.pagination.page,
    result.pagination.limit,
    result.pagination.total,
    MESSAGES.PLAYER.LIST_FETCHED || 'Players matching search retrieved successfully.'
  );
});

/**
 * Get single player profile by ID
 * GET /api/v1/players/:id
 */
export const getPlayerById = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const player = await playerService.getPlayerById(req.params.id as string);
  ApiResponse.success(
    res,
    200,
    MESSAGES.PLAYER.FETCHED || 'Player profile retrieved successfully.',
    player
  );
});

/**
 * Update player profile (Profile owner only)
 * PUT /api/v1/players/:id
 */
export const updatePlayer = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const player = await playerService.updatePlayer(req.params.id as string, req.user!._id, req.body);
  ApiResponse.success(
    res,
    200,
    MESSAGES.PLAYER.UPDATED || 'Player profile updated successfully.',
    player
  );
});

/**
 * Soft delete player profile (Profile owner only)
 * DELETE /api/v1/players/:id
 */
export const deletePlayer = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await playerService.deletePlayer(req.params.id as string, req.user!._id);
  ApiResponse.success(
    res,
    200,
    'Player profile deleted successfully.',
    result
  );
});

/**
 * Get player career statistics (Batting, bowling, fielding)
 * GET /api/v1/players/:id/stats
 */
export const getPlayerStats = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const stats = await playerService.getPlayerStats(
    req.params.id as string,
    normalizeStatisticsFilters(req.query)
  );
  ApiResponse.success(
    res,
    200,
    MESSAGES.PLAYER.STATS_FETCHED || 'Player statistics retrieved successfully.',
    stats
  );
});

/**
 * Get current and past teams for a player
 * GET /api/v1/players/:id/teams
 */
export const getPlayerTeams = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const teams = await playerService.getPlayerTeams(req.params.id as string);
  ApiResponse.success(
    res,
    200,
    'Player teams retrieved successfully.',
    teams
  );
});

/**
 * Get match history for a player
 * GET /api/v1/players/:id/matches
 */
export const getPlayerMatches = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await playerService.getPlayerMatches(req.params.id as string, req.query);
  ApiResponse.paginated(
    res,
    result.data,
    result.pagination.page,
    result.pagination.limit,
    result.pagination.total,
    'Player matches retrieved successfully.'
  );
});

export default {
  createPlayer,
  getPlayers,
  searchPlayers,
  getPlayerById,
  updatePlayer,
  deletePlayer,
  getPlayerStats,
  getPlayerTeams,
  getPlayerMatches,
};
