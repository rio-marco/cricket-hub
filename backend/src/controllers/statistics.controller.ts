import { Request, Response } from 'express';

import { MESSAGES } from '../constants/messages';
import playerStatisticsService, {
  normalizeStatisticsFilters,
} from '../services/playerStatistics.service';
import { ApiResponse } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';

const leaderboardOptions = (query: Record<string, any>) => ({
  page: Number(query.page) || 1,
  limit: Number(query.limit) || 20,
  minInnings: query.minInnings === undefined ? undefined : Number(query.minInnings),
});

const playerId = (req: Request): string => req.params.id as string;

export const getPlayerOverallStats = asyncHandler(
  async (req: Request, res: Response): Promise<void> => {
    const stats = await playerStatisticsService.getPlayerStatistics(
      playerId(req),
      normalizeStatisticsFilters(req.query)
    );
    ApiResponse.success(res, 200, MESSAGES.STATISTICS.FETCHED, stats);
  }
);

export const getPlayerBattingStats = asyncHandler(
  async (req: Request, res: Response): Promise<void> => {
    const stats = await playerStatisticsService.getBattingStatistics(
      playerId(req),
      normalizeStatisticsFilters(req.query)
    );
    ApiResponse.success(res, 200, MESSAGES.STATISTICS.BATTING_FETCHED, stats);
  }
);

export const getPlayerBowlingStats = asyncHandler(
  async (req: Request, res: Response): Promise<void> => {
    const stats = await playerStatisticsService.getBowlingStatistics(
      playerId(req),
      normalizeStatisticsFilters(req.query)
    );
    ApiResponse.success(res, 200, MESSAGES.STATISTICS.BOWLING_FETCHED, stats);
  }
);

export const getPlayerFieldingStats = asyncHandler(
  async (req: Request, res: Response): Promise<void> => {
    const stats = await playerStatisticsService.getFieldingStatistics(
      playerId(req),
      normalizeStatisticsFilters(req.query)
    );
    ApiResponse.success(res, 200, MESSAGES.STATISTICS.FIELDING_FETCHED, stats);
  }
);

export const getPlayerRecentForm = asyncHandler(
  async (req: Request, res: Response): Promise<void> => {
    const limit = Math.min(20, Math.max(1, Number(req.query.limit) || 5));
    const stats = await playerStatisticsService.getRecentPerformances(
      playerId(req),
      normalizeStatisticsFilters(req.query),
      limit
    );
    ApiResponse.success(res, 200, MESSAGES.STATISTICS.RECENT_FETCHED, stats);
  }
);

export const getPlayerTournamentWiseStats = asyncHandler(
  async (req: Request, res: Response): Promise<void> => {
    const stats = await playerStatisticsService.getTournamentWiseStatistics(
      playerId(req),
      normalizeStatisticsFilters(req.query)
    );
    ApiResponse.success(res, 200, MESSAGES.STATISTICS.BREAKDOWN_FETCHED, stats);
  }
);

export const getPlayerSeasonWiseStats = asyncHandler(
  async (req: Request, res: Response): Promise<void> => {
    const stats = await playerStatisticsService.getSeasonWiseStatistics(
      playerId(req),
      normalizeStatisticsFilters(req.query)
    );
    ApiResponse.success(res, 200, MESSAGES.STATISTICS.BREAKDOWN_FETCHED, stats);
  }
);

export const getPlayerFormatWiseStats = asyncHandler(
  async (req: Request, res: Response): Promise<void> => {
    const stats = await playerStatisticsService.getFormatWiseStatistics(
      playerId(req),
      normalizeStatisticsFilters(req.query)
    );
    ApiResponse.success(res, 200, MESSAGES.STATISTICS.BREAKDOWN_FETCHED, stats);
  }
);

export const getTopBatsmen = asyncHandler(
  async (req: Request, res: Response): Promise<void> => {
    const result = await playerStatisticsService.getLeaderboard(
      'runs',
      normalizeStatisticsFilters(req.query),
      { ...leaderboardOptions(req.query), limit: Math.min(20, Number(req.query.limit) || 10) }
    );
    ApiResponse.paginated(
      res,
      result.entries,
      result.pagination.page,
      result.pagination.limit,
      result.pagination.total,
      MESSAGES.STATISTICS.TOP_BATSMEN_FETCHED
    );
  }
);

export const getTopBowlers = asyncHandler(
  async (req: Request, res: Response): Promise<void> => {
    const result = await playerStatisticsService.getLeaderboard(
      'wickets',
      normalizeStatisticsFilters(req.query),
      { ...leaderboardOptions(req.query), limit: Math.min(20, Number(req.query.limit) || 10) }
    );
    ApiResponse.paginated(
      res,
      result.entries,
      result.pagination.page,
      result.pagination.limit,
      result.pagination.total,
      MESSAGES.STATISTICS.TOP_BOWLERS_FETCHED
    );
  }
);

export const getStatisticsOverview = asyncHandler(
  async (req: Request, res: Response): Promise<void> => {
    const filters = normalizeStatisticsFilters(req.query);
    const [batsmen, bowlers, fielders] = await Promise.all([
      playerStatisticsService.getLeaderboard('runs', filters, { page: 1, limit: 5 }),
      playerStatisticsService.getLeaderboard('wickets', filters, { page: 1, limit: 5 }),
      playerStatisticsService.getLeaderboard('catches', filters, { page: 1, limit: 5 }),
    ]);

    ApiResponse.success(res, 200, MESSAGES.STATISTICS.OVERVIEW_FETCHED, {
      filters,
      topBatsmen: batsmen.entries,
      topBowlers: bowlers.entries,
      topFielders: fielders.entries,
    });
  }
);

export const getTournamentStatistics = asyncHandler(
  async (req: Request, res: Response): Promise<void> => {
    const filters = normalizeStatisticsFilters(req.query);
    filters.tournament = req.params.id as string;

    const [batsmen, bowlers, fielders] = await Promise.all([
      playerStatisticsService.getLeaderboard('runs', filters, { page: 1, limit: 10 }),
      playerStatisticsService.getLeaderboard('wickets', filters, { page: 1, limit: 10 }),
      playerStatisticsService.getLeaderboard('catches', filters, { page: 1, limit: 10 }),
    ]);

    ApiResponse.success(res, 200, MESSAGES.STATISTICS.TOURNAMENT_FETCHED, {
      filters,
      topBatsmen: batsmen.entries,
      topBowlers: bowlers.entries,
      topFielders: fielders.entries,
    });
  }
);

export const getLeaderboard = asyncHandler(
  async (req: Request, res: Response): Promise<void> => {
    const metric = (req.params.type as string | undefined) || (req.query.metric as string) || 'runs';
    const result = await playerStatisticsService.getLeaderboard(
      metric,
      normalizeStatisticsFilters(req.query),
      leaderboardOptions(req.query)
    );

    ApiResponse.paginated(
      res,
      result.entries,
      result.pagination.page,
      result.pagination.limit,
      result.pagination.total,
      MESSAGES.STATISTICS.LEADERBOARD_FETCHED
    );
  }
);

export default {
  getPlayerOverallStats,
  getPlayerBattingStats,
  getPlayerBowlingStats,
  getPlayerFieldingStats,
  getPlayerRecentForm,
  getPlayerTournamentWiseStats,
  getPlayerSeasonWiseStats,
  getPlayerFormatWiseStats,
  getTopBatsmen,
  getTopBowlers,
  getStatisticsOverview,
  getTournamentStatistics,
  getLeaderboard,
};
