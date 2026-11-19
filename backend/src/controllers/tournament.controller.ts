import { Request, Response } from 'express';
import { asyncHandler } from '../utils/asyncHandler';
import { ApiResponse } from '../utils/apiResponse';
import { ApiError } from '../utils/apiError';
import { MESSAGES } from '../constants/messages';
import tournamentService from '../services/tournament.service';

/**
 * Create a new tournament
 * POST /api/v1/tournaments
 */
export const createTournament = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const userId = req.user?._id?.toString() || req.user?.id;
  if (!userId) {
    throw ApiError.unauthorized(MESSAGES.AUTH.UNAUTHORIZED || 'User is not authenticated.');
  }

  const tournament = await tournamentService.createTournament(userId, req.body);
  ApiResponse.success(
    res,
    201,
    MESSAGES.TOURNAMENT.CREATED || 'Tournament created successfully.',
    tournament
  );
});

/**
 * List tournaments with pagination, filtering, and search
 * GET /api/v1/tournaments
 */
export const getTournaments = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await tournamentService.getTournaments(req.query);
  ApiResponse.paginated(
    res,
    result.tournaments,
    result.pagination.page,
    result.pagination.limit,
    result.pagination.total,
    MESSAGES.TOURNAMENT.FETCHED || 'Tournaments retrieved successfully.'
  );
});

/**
 * Get tournament details by ID
 * GET /api/v1/tournaments/:id
 */
export const getTournamentById = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  const tournament = await tournamentService.getTournamentById(id);
  ApiResponse.success(
    res,
    200,
    MESSAGES.TOURNAMENT.FETCHED || 'Tournament details retrieved successfully.',
    tournament
  );
});

/**
 * Update tournament details
 * PUT /api/v1/tournaments/:id
 */
export const updateTournament = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const userId = req.user?._id?.toString() || req.user?.id;
  if (!userId) {
    throw ApiError.unauthorized(MESSAGES.AUTH.UNAUTHORIZED || 'User is not authenticated.');
  }

  const id = req.params.id as string;
  const updatedTournament = await tournamentService.updateTournament(id, userId, req.body);
  ApiResponse.success(
    res,
    200,
    MESSAGES.TOURNAMENT.UPDATED || 'Tournament updated successfully.',
    updatedTournament
  );
});

/**
 * Delete tournament (only DRAFT)
 * DELETE /api/v1/tournaments/:id
 */
export const deleteTournament = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const userId = req.user?._id?.toString() || req.user?.id;
  if (!userId) {
    throw ApiError.unauthorized(MESSAGES.AUTH.UNAUTHORIZED || 'User is not authenticated.');
  }

  const id = req.params.id as string;
  const result = await tournamentService.deleteTournament(id, userId);
  ApiResponse.success(
    res,
    200,
    result.message
  );
});

/**
 * Update tournament lifecycle status
 * PUT /api/v1/tournaments/:id/status
 */
export const updateStatus = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const userId = req.user?._id?.toString() || req.user?.id;
  if (!userId) {
    throw ApiError.unauthorized(MESSAGES.AUTH.UNAUTHORIZED || 'User is not authenticated.');
  }

  const id = req.params.id as string;
  const updatedTournament = await tournamentService.updateStatus(
    id,
    userId,
    req.body.status
  );
  ApiResponse.success(
    res,
    200,
    MESSAGES.TOURNAMENT.STATUS_UPDATED || 'Tournament status updated successfully.',
    updatedTournament
  );
});

/**
 * Register a team for a tournament
 * POST /api/v1/tournaments/:id/teams
 */
export const registerTeam = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const userId = req.user?._id?.toString() || req.user?.id;
  if (!userId) {
    throw ApiError.unauthorized(MESSAGES.AUTH.UNAUTHORIZED || 'User is not authenticated.');
  }

  const id = req.params.id as string;
  const registeredTeam = await tournamentService.registerTeam(
    id,
    userId,
    req.body.teamId
  );
  ApiResponse.success(
    res,
    201,
    MESSAGES.TOURNAMENT.REGISTRATION_SUCCESS || 'Team registration submitted successfully.',
    registeredTeam
  );
});

/**
 * Approve a team's tournament registration
 * PUT /api/v1/tournaments/:id/teams/:tournamentTeamId/approve
 */
export const approveTeam = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const userId = req.user?._id?.toString() || req.user?.id;
  if (!userId) {
    throw ApiError.unauthorized(MESSAGES.AUTH.UNAUTHORIZED || 'User is not authenticated.');
  }

  const id = req.params.id as string;
  const tournamentTeamId = req.params.tournamentTeamId as string;
  const approved = await tournamentService.approveTeam(
    id,
    userId,
    tournamentTeamId
  );
  ApiResponse.success(
    res,
    200,
    MESSAGES.TOURNAMENT.TEAM_APPROVED || 'Team registration approved.',
    approved
  );
});

/**
 * Reject a team's tournament registration
 * PUT /api/v1/tournaments/:id/teams/:tournamentTeamId/reject
 */
export const rejectTeam = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const userId = req.user?._id?.toString() || req.user?.id;
  if (!userId) {
    throw ApiError.unauthorized(MESSAGES.AUTH.UNAUTHORIZED || 'User is not authenticated.');
  }

  const id = req.params.id as string;
  const tournamentTeamId = req.params.tournamentTeamId as string;
  const rejected = await tournamentService.rejectTeam(
    id,
    userId,
    tournamentTeamId
  );
  ApiResponse.success(
    res,
    200,
    MESSAGES.TOURNAMENT.TEAM_REJECTED || 'Team registration rejected.',
    rejected
  );
});

/**
 * Get all registered teams for a tournament
 * GET /api/v1/tournaments/:id/teams
 */
export const getRegisteredTeams = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  const teams = await tournamentService.getRegisteredTeams(id);
  ApiResponse.success(
    res,
    200,
    'Registered teams retrieved successfully.',
    teams
  );
});

/**
 * Generate tournament fixtures
 * POST /api/v1/tournaments/:id/fixtures
 */
export const generateFixtures = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const userId = req.user?._id?.toString() || req.user?.id;
  if (!userId) {
    throw ApiError.unauthorized(MESSAGES.AUTH.UNAUTHORIZED || 'User is not authenticated.');
  }

  const id = req.params.id as string;
  const fixtures = await tournamentService.generateFixtures(id, userId);
  ApiResponse.success(
    res,
    201,
    'Tournament fixtures generated successfully.',
    fixtures
  );
});

/**
 * Get tournament fixtures
 * GET /api/v1/tournaments/:id/fixtures
 */
export const getFixtures = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  const fixtures = await tournamentService.getFixtures(id);
  ApiResponse.success(
    res,
    200,
    MESSAGES.TOURNAMENT.SCHEDULE_FETCHED || 'Tournament schedule retrieved successfully.',
    fixtures
  );
});

/**
 * Get tournament points table / standings
 * GET /api/v1/tournaments/:id/standings
 */
export const getPointsTable = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  const standings = await tournamentService.getPointsTable(id);
  ApiResponse.success(
    res,
    200,
    MESSAGES.TOURNAMENT.STANDINGS_FETCHED || 'Tournament standings retrieved successfully.',
    standings
  );
});

/**
 * Get tournament leaderboards and statistics
 * GET /api/v1/tournaments/:id/stats
 */
export const getTournamentStats = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const id = req.params.id as string;
  const stats = await tournamentService.getTournamentStats(id);
  ApiResponse.success(
    res,
    200,
    'Tournament statistics retrieved successfully.',
    stats
  );
});

export default {
  createTournament,
  getTournaments,
  getTournamentById,
  updateTournament,
  deleteTournament,
  updateStatus,
  registerTeam,
  approveTeam,
  rejectTeam,
  getRegisteredTeams,
  generateFixtures,
  getFixtures,
  getPointsTable,
  getTournamentStats,
};
