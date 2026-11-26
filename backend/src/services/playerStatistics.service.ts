import mongoose, { Types } from 'mongoose';

import {
  DismissalType,
  InningsStatus,
  MatchFormat,
  MatchStatus,
  ResultType,
} from '../constants/enums';
import { MESSAGES } from '../constants/messages';
import Delivery from '../models/Delivery';
import Innings from '../models/Innings';
import Match from '../models/Match';
import Player from '../models/Player';
import { ApiError } from '../utils/apiError';
import {
  BattingRow,
  BattingSummary,
  BowlingRow,
  BowlingSummary,
  FieldingRow,
  FieldingSummary,
  LeaderboardMetric,
  LeaderboardStats,
  calculateBattingSummary,
  calculateBowlingSummary,
  calculateFieldingSummary,
  compareLeaderboardEntries,
  leaderboardValue,
  normalizeLeaderboardMetric,
} from '../utils/statistics';

export interface StatisticsFilters {
  tournament?: string;
  season?: number;
  format?: MatchFormat;
  from?: Date;
  to?: Date;
}

export interface IdentifiedBattingRow extends BattingRow {
  playerId: string;
}

export interface IdentifiedBowlingRow extends BowlingRow {
  playerId: string;
}

export interface IdentifiedFieldingRow extends FieldingRow {
  playerId: string;
}

export interface GroupedPerformance {
  key: string;
  label: string;
  matches: number;
  runs: number;
  balls: number;
  wickets: number;
  economy: number;
  catches: number;
}

export interface RecentPerformance {
  matchId: string;
  title: string;
  matchDate?: Date;
  format?: MatchFormat;
  result?: string;
  batting: BattingSummary;
  bowling: BowlingSummary;
  fielding: FieldingSummary;
}

export interface PlayerStatisticsResponse {
  playerId: string;
  filters: StatisticsFilters;
  matches: number;
  playerOfMatch: number;
  batting: BattingSummary;
  bowling: BowlingSummary;
  fielding: FieldingSummary;
  recentForm: RecentPerformance[];
  tournamentWise: GroupedPerformance[];
  seasonWise: GroupedPerformance[];
  formatWise: GroupedPerformance[];
}

export interface LeaderboardEntry {
  rank: number;
  playerId: string;
  playerName: string;
  playingRole?: string;
  jerseyNumber?: number;
  city?: string;
  metric: LeaderboardMetric;
  value: number;
  stats: LeaderboardStats;
}

export interface LeaderboardResult {
  metric: LeaderboardMetric;
  filters: StatisticsFilters;
  entries: LeaderboardEntry[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
    hasNextPage: boolean;
    hasPrevPage: boolean;
  };
}

const TERMINAL_INNINGS_STATUSES = [InningsStatus.COMPLETED, InningsStatus.DECLARED];
const EXCLUDED_RESULT_TYPES = [ResultType.NO_RESULT, ResultType.ABANDONED, ResultType.DRAW];
const FIELDING_DISMISSALS = [DismissalType.CAUGHT, DismissalType.RUN_OUT, DismissalType.STUMPED];

const asObjectId = (value: string | Types.ObjectId): Types.ObjectId => {
  if (!mongoose.Types.ObjectId.isValid(value.toString())) {
    throw ApiError.badRequest('Invalid player ID format.');
  }
  return new Types.ObjectId(value.toString());
};

export const normalizeStatisticsFilters = (
  query: Record<string, any> = {}
): StatisticsFilters => {
  const filters: StatisticsFilters = {};

  if (query.tournament && mongoose.Types.ObjectId.isValid(String(query.tournament))) {
    filters.tournament = String(query.tournament);
  }
  if (query.format && Object.values(MatchFormat).includes(query.format as MatchFormat)) {
    filters.format = query.format as MatchFormat;
  }

  const season = Number(query.season);
  if (Number.isInteger(season) && season >= 1900 && season <= 2100) {
    filters.season = season;
  }

  if (query.from) {
    const from = new Date(String(query.from));
    if (!Number.isNaN(from.getTime())) filters.from = from;
  }
  if (query.to) {
    const to = new Date(String(query.to));
    if (!Number.isNaN(to.getTime())) filters.to = to;
  }
  if (filters.from && filters.to && filters.from > filters.to) {
    throw ApiError.badRequest('from date cannot be later than to date.');
  }

  return filters;
};

const matchFilterFor = (filters: StatisticsFilters): Record<string, any> => {
  const query: Record<string, any> = {
    status: MatchStatus.COMPLETED,
    'result.resultType': { $nin: EXCLUDED_RESULT_TYPES },
  };

  if (filters.tournament) {
    query.tournament = asObjectId(filters.tournament);
  }
  if (filters.format) {
    query.format = filters.format;
  }
  const matchDateConditions: Record<string, Date> = {};
  if (filters.from) matchDateConditions.$gte = filters.from;
  if (filters.to) matchDateConditions.$lte = filters.to;

  if (filters.season) {
    const seasonStart = new Date(Date.UTC(filters.season, 0, 1));
    const seasonEnd = new Date(Date.UTC(filters.season + 1, 0, 1));
    matchDateConditions.$gte = filters.from
      ? new Date(Math.max(filters.from.getTime(), seasonStart.getTime()))
      : seasonStart;
    matchDateConditions.$lt = filters.to
      ? new Date(Math.min(filters.to.getTime(), seasonEnd.getTime()))
      : seasonEnd;
  }

  if (Object.keys(matchDateConditions).length > 0) {
    query.matchDate = matchDateConditions as any;
  }

  return query;
};

export class PlayerStatisticsService {
  private async getEligibleMatchIds(filters: StatisticsFilters): Promise<Types.ObjectId[]> {
    const candidates = await Match.find(matchFilterFor(filters)).select('_id').lean();
    if (candidates.length === 0) return [];

    const candidateIds = candidates.map((candidate) => candidate._id);
    const completedGroups = await Innings.aggregate<{
      _id: Types.ObjectId;
      total: number;
      terminal: number;
    }>([
      { $match: { match: { $in: candidateIds } } },
      {
        $group: {
          _id: '$match',
          total: { $sum: 1 },
          terminal: {
            $sum: {
              $cond: [{ $in: ['$status', TERMINAL_INNINGS_STATUSES] }, 1, 0],
            },
          },
        },
      },
      {
        $match: {
          $expr: {
            $and: [{ $gt: ['$total', 0] }, { $eq: ['$total', '$terminal'] }],
          },
        },
      },
      { $project: { _id: 1 } },
    ]);

    return completedGroups.map((group) => group._id);
  }

  private async fetchBattingRows(
    matchIds: Types.ObjectId[],
    playerId?: Types.ObjectId
  ): Promise<IdentifiedBattingRow[]> {
    if (matchIds.length === 0) return [];
    const playerMatch = playerId ? { 'battingStats.player': playerId } : {};

    return Innings.aggregate<IdentifiedBattingRow>([
      {
        $match: {
          match: { $in: matchIds },
          status: { $in: TERMINAL_INNINGS_STATUSES },
          ...playerMatch,
        },
      },
      { $unwind: '$battingStats' },
      ...(playerId ? [{ $match: { 'battingStats.player': playerId } }] : []),
      {
        $project: {
          _id: 0,
          playerId: { $toString: '$battingStats.player' },
          matchId: { $toString: '$match' },
          inningsNumber: 1,
          runs: { $ifNull: ['$battingStats.runs', 0] },
          balls: { $ifNull: ['$battingStats.balls', 0] },
          fours: { $ifNull: ['$battingStats.fours', 0] },
          sixes: { $ifNull: ['$battingStats.sixes', 0] },
          isNotOut: { $ifNull: ['$battingStats.isNotOut', true] },
        },
      },
    ]).exec();
  }

  private async fetchBowlingRows(
    matchIds: Types.ObjectId[],
    playerId?: Types.ObjectId
  ): Promise<IdentifiedBowlingRow[]> {
    if (matchIds.length === 0) return [];
    const playerMatch = playerId ? { 'bowlingStats.player': playerId } : {};

    return Innings.aggregate<IdentifiedBowlingRow>([
      {
        $match: {
          match: { $in: matchIds },
          status: { $in: TERMINAL_INNINGS_STATUSES },
          'bowlingStats.balls': { $gt: 0 },
          ...playerMatch,
        },
      },
      { $unwind: '$bowlingStats' },
      ...(playerId ? [{ $match: { 'bowlingStats.player': playerId } }] : []),
      {
        $match: { 'bowlingStats.balls': { $gt: 0 } },
      },
      {
        $project: {
          _id: 0,
          playerId: { $toString: '$bowlingStats.player' },
          matchId: { $toString: '$match' },
          inningsNumber: 1,
          balls: { $ifNull: ['$bowlingStats.balls', 0] },
          runs: { $ifNull: ['$bowlingStats.runs', 0] },
          wickets: { $ifNull: ['$bowlingStats.wickets', 0] },
          maidens: { $ifNull: ['$bowlingStats.maidens', 0] },
          dotBalls: { $ifNull: ['$bowlingStats.dotBalls', 0] },
          wides: { $ifNull: ['$bowlingStats.wides', 0] },
          noBalls: { $ifNull: ['$bowlingStats.noBalls', 0] },
        },
      },
    ]).exec();
  }

  private async fetchFieldingRows(
    matchIds: Types.ObjectId[],
    playerId?: Types.ObjectId
  ): Promise<IdentifiedFieldingRow[]> {
    if (matchIds.length === 0) return [];
    const playerMatch = playerId ? { 'wicket.fielder': playerId } : {};

    const grouped = await Delivery.aggregate<{
      _id: { matchId: string; type: DismissalType };
      playerId: string;
      count: number;
    }>([
      {
        $match: {
          match: { $in: matchIds },
          isUndone: false,
          'wicket.type': { $in: FIELDING_DISMISSALS },
          'wicket.fielder': { $exists: true, $ne: null },
          ...playerMatch,
        },
      },
      {
        $group: {
          _id: {
            matchId: { $toString: '$match' },
            sequence: '$sequenceNumber',
            type: '$wicket.type',
          },
          playerId: { $first: { $toString: '$wicket.fielder' } },
        },
      },
      {
        $group: {
          _id: { matchId: '$_id.matchId', type: '$_id.type' },
          playerId: { $first: '$playerId' },
          count: { $sum: 1 },
        },
      },
    ]).exec();

    return grouped.map((item) => ({
      playerId: item.playerId,
      matchId: item._id.matchId,
      catches: item._id.type === DismissalType.CAUGHT ? item.count : 0,
      runOuts: item._id.type === DismissalType.RUN_OUT ? item.count : 0,
      stumpings: item._id.type === DismissalType.STUMPED ? item.count : 0,
    }));
  }

  private async getEligibleMatches(
    matchIds: Types.ObjectId[]
  ): Promise<any[]> {
    if (matchIds.length === 0) return [];
    return Match.find({ _id: { $in: matchIds } })
      .select('title matchDate format result tournament teamA teamB')
      .populate('teamA', 'name')
      .populate('teamB', 'name')
      .populate('tournament', 'name')
      .sort({ matchDate: -1, _id: -1 })
      .lean();
  }

  private buildRecentPerformances(
    matches: any[],
    battingRows: IdentifiedBattingRow[],
    bowlingRows: IdentifiedBowlingRow[],
    fieldingRows: IdentifiedFieldingRow[],
    limit: number
  ): RecentPerformance[] {
    const battingByMatch = new Map<string, BattingRow[]>();
    const bowlingByMatch = new Map<string, BowlingRow[]>();
    const fieldingByMatch = new Map<string, FieldingRow[]>();

    battingRows.forEach((row) => {
      if (!row.matchId) return;
      const list = battingByMatch.get(row.matchId) ?? [];
      list.push(row);
      battingByMatch.set(row.matchId, list);
    });
    bowlingRows.forEach((row) => {
      if (!row.matchId) return;
      const list = bowlingByMatch.get(row.matchId) ?? [];
      list.push(row);
      bowlingByMatch.set(row.matchId, list);
    });
    fieldingRows.forEach((row) => {
      if (!row.matchId) return;
      const list = fieldingByMatch.get(row.matchId) ?? [];
      list.push(row);
      fieldingByMatch.set(row.matchId, list);
    });

    return matches.slice(0, limit).map((match) => {
      const matchId = match._id.toString();
      const teamA = match.teamA as any;
      const teamB = match.teamB as any;
      const opponent = teamB?.name || teamA?.name || 'Opponent';

      return {
        matchId,
        title: match.title || `vs ${opponent}`,
        matchDate: match.matchDate,
        format: match.format,
        result: match.result?.description,
        batting: calculateBattingSummary(battingByMatch.get(matchId) ?? []),
        bowling: calculateBowlingSummary(bowlingByMatch.get(matchId) ?? []),
        fielding: calculateFieldingSummary(fieldingByMatch.get(matchId) ?? []),
      };
    });
  }

  private buildGroupedPerformances(
    matches: any[],
    battingRows: IdentifiedBattingRow[],
    bowlingRows: IdentifiedBowlingRow[],
    fieldingRows: IdentifiedFieldingRow[],
    keyForMatch: (match: any) => { key: string; label: string } | null
  ): GroupedPerformance[] {
    const matchKeys = new Map<string, { key: string; label: string }>();
    const groups = new Map<
      string,
      {
        label: string;
        matchIds: Set<string>;
        batting: BattingRow[];
        bowling: BowlingRow[];
        fielding: FieldingRow[];
      }
    >();

    matches.forEach((match) => {
      const groupInfo = keyForMatch(match);
      if (!groupInfo) return;
      const matchId = match._id.toString();
      matchKeys.set(matchId, groupInfo);
      const group = groups.get(groupInfo.key) ?? {
        label: groupInfo.label,
        matchIds: new Set<string>(),
        batting: [],
        bowling: [],
        fielding: [],
      };
      group.matchIds.add(matchId);
      groups.set(groupInfo.key, group);
    });

    const addRow = <T extends { matchId?: string }>(
      row: T,
      target: 'batting' | 'bowling' | 'fielding'
    ) => {
      if (!row.matchId) return;
      const groupInfo = matchKeys.get(row.matchId);
      if (!groupInfo) return;
      const group = groups.get(groupInfo.key);
      if (!group) return;
      (group[target] as unknown as T[]).push(row);
      group.matchIds.add(row.matchId);
    };

    battingRows.forEach((row) => addRow(row, 'batting'));
    bowlingRows.forEach((row) => addRow(row, 'bowling'));
    fieldingRows.forEach((row) => addRow(row, 'fielding'));

    return Array.from(groups.entries())
      .map(([key, group]) => {
        const batting = calculateBattingSummary(group.batting);
        const bowling = calculateBowlingSummary(group.bowling);
        const fielding = calculateFieldingSummary(group.fielding);
        return {
          key,
          label: group.label,
          matches: group.matchIds.size,
          runs: batting.runs,
          balls: batting.balls,
          wickets: bowling.wickets,
          economy: bowling.economy,
          catches: fielding.catches,
        };
      })
      .sort((left, right) => right.matches - left.matches || left.label.localeCompare(right.label));
  }

  public async getPlayerStatistics(
    playerId: string | Types.ObjectId,
    filters: StatisticsFilters = {}
  ): Promise<PlayerStatisticsResponse> {
    const playerObjectId = asObjectId(playerId);
    const player = await Player.findById(playerObjectId).select('_id');
    if (!player) {
      throw ApiError.notFound(MESSAGES.PLAYER.NOT_FOUND || 'Player profile not found.');
    }

    const matchIds = await this.getEligibleMatchIds(filters);
    const [battingRows, bowlingRows, fieldingRows, matchAppearances, playerOfMatchCount, matches] =
      await Promise.all([
        this.fetchBattingRows(matchIds, playerObjectId),
        this.fetchBowlingRows(matchIds, playerObjectId),
        this.fetchFieldingRows(matchIds, playerObjectId),
        matchIds.length
          ? Match.countDocuments({
              _id: { $in: matchIds },
              $or: [
                { playingXI_A: playerObjectId },
                { playingXI_B: playerObjectId },
                { substitutes_A: playerObjectId },
                { substitutes_B: playerObjectId },
              ],
            })
          : Promise.resolve(0),
        matchIds.length
          ? Match.countDocuments({ _id: { $in: matchIds }, playerOfMatch: playerObjectId })
          : Promise.resolve(0),
        this.getEligibleMatches(matchIds),
      ]);

    return {
      playerId: playerObjectId.toString(),
      filters,
      matches: matchAppearances,
      playerOfMatch: playerOfMatchCount,
      batting: calculateBattingSummary(battingRows),
      bowling: calculateBowlingSummary(bowlingRows),
      fielding: calculateFieldingSummary(fieldingRows),
      recentForm: this.buildRecentPerformances(
        matches,
        battingRows,
        bowlingRows,
        fieldingRows,
        5
      ),
      tournamentWise: this.buildGroupedPerformances(
        matches,
        battingRows,
        bowlingRows,
        fieldingRows,
        (match) => {
          const tournament = match.tournament as any;
          if (!tournament) return null;
          return {
            key: tournament._id?.toString() || tournament.toString(),
            label: tournament.name || 'Tournament',
          };
        }
      ),
      seasonWise: this.buildGroupedPerformances(
        matches,
        battingRows,
        bowlingRows,
        fieldingRows,
        (match) => {
          if (!match.matchDate) return null;
          const season = new Date(match.matchDate).getUTCFullYear();
          return { key: String(season), label: String(season) };
        }
      ),
      formatWise: this.buildGroupedPerformances(
        matches,
        battingRows,
        bowlingRows,
        fieldingRows,
        (match) =>
          match.format ? { key: String(match.format), label: String(match.format) } : null
      ),
    };
  }

  public async getBattingStatistics(
    playerId: string | Types.ObjectId,
    filters: StatisticsFilters = {}
  ): Promise<BattingSummary> {
    return (await this.getPlayerStatistics(playerId, filters)).batting;
  }

  public async getBowlingStatistics(
    playerId: string | Types.ObjectId,
    filters: StatisticsFilters = {}
  ): Promise<BowlingSummary> {
    return (await this.getPlayerStatistics(playerId, filters)).bowling;
  }

  public async getFieldingStatistics(
    playerId: string | Types.ObjectId,
    filters: StatisticsFilters = {}
  ): Promise<FieldingSummary> {
    return (await this.getPlayerStatistics(playerId, filters)).fielding;
  }

  public async getRecentPerformances(
    playerId: string | Types.ObjectId,
    filters: StatisticsFilters = {},
    limit: number = 5
  ): Promise<RecentPerformance[]> {
    return (await this.getPlayerStatistics(playerId, filters)).recentForm.slice(0, limit);
  }

  public async getTournamentWiseStatistics(
    playerId: string | Types.ObjectId,
    filters: StatisticsFilters = {}
  ): Promise<GroupedPerformance[]> {
    return (await this.getPlayerStatistics(playerId, filters)).tournamentWise;
  }

  public async getSeasonWiseStatistics(
    playerId: string | Types.ObjectId,
    filters: StatisticsFilters = {}
  ): Promise<GroupedPerformance[]> {
    return (await this.getPlayerStatistics(playerId, filters)).seasonWise;
  }

  public async getFormatWiseStatistics(
    playerId: string | Types.ObjectId,
    filters: StatisticsFilters = {}
  ): Promise<GroupedPerformance[]> {
    return (await this.getPlayerStatistics(playerId, filters)).formatWise;
  }

  public async getLeaderboard(
    metricInput: string,
    filters: StatisticsFilters = {},
    options: { page?: number; limit?: number; minInnings?: number } = {}
  ): Promise<LeaderboardResult> {
    const metric = normalizeLeaderboardMetric(metricInput);
    if (!metric) {
      throw ApiError.badRequest('Unsupported leaderboard metric.');
    }

    const page = Math.max(1, Number(options.page) || 1);
    const limit = Math.min(100, Math.max(1, Number(options.limit) || 20));
    const minInnings = Math.max(1, Number(options.minInnings) || 1);
    const matchIds = await this.getEligibleMatchIds(filters);

    const [battingRows, bowlingRows, fieldingRows] = await Promise.all([
      this.fetchBattingRows(matchIds),
      this.fetchBowlingRows(matchIds),
      this.fetchFieldingRows(matchIds),
    ]);

    const playerIds = new Set<string>();
    battingRows.forEach((row) => playerIds.add(row.playerId));
    bowlingRows.forEach((row) => playerIds.add(row.playerId));
    fieldingRows.forEach((row) => playerIds.add(row.playerId));

    if (playerIds.size === 0) {
      return {
        metric,
        filters,
        entries: [],
        pagination: {
          page,
          limit,
          total: 0,
          totalPages: 1,
          hasNextPage: false,
          hasPrevPage: false,
        },
      };
    }

    const playerDocs = await Player.find({
      _id: { $in: Array.from(playerIds).map((id) => asObjectId(id)) },
      isDeleted: { $ne: true },
    })
      .populate('user', 'name avatar')
      .lean();

    const battingByPlayer = new Map<string, BattingRow[]>();
    const bowlingByPlayer = new Map<string, BowlingRow[]>();
    const fieldingByPlayer = new Map<string, FieldingRow[]>();

    battingRows.forEach((row) => {
      const list = battingByPlayer.get(row.playerId) ?? [];
      list.push(row);
      battingByPlayer.set(row.playerId, list);
    });
    bowlingRows.forEach((row) => {
      const list = bowlingByPlayer.get(row.playerId) ?? [];
      list.push(row);
      bowlingByPlayer.set(row.playerId, list);
    });
    fieldingRows.forEach((row) => {
      const list = fieldingByPlayer.get(row.playerId) ?? [];
      list.push(row);
      fieldingByPlayer.set(row.playerId, list);
    });

    const isBattingMetric = ['runs', 'battingAverage', 'battingStrikeRate', 'sixes', 'fours'].includes(
      metric
    );
    const isBowlingMetric = ['wickets', 'bowlingEconomy', 'bowlingAverage'].includes(metric);

    const comparable = playerDocs.map((doc: any) => {
      const playerId = doc._id.toString();
      const batting = calculateBattingSummary(battingByPlayer.get(playerId) ?? []);
      const bowling = calculateBowlingSummary(bowlingByPlayer.get(playerId) ?? []);
      const fielding = calculateFieldingSummary(fieldingByPlayer.get(playerId) ?? []);
      const user = doc.user as any;
      const playerName =
        user?.name || `Player ${playerId.substring(playerId.length - 6).toUpperCase()}`;

      return {
        playerId,
        playerName,
        playingRole: doc.playingRole,
        jerseyNumber: doc.jerseyNumber,
        city: doc.city,
        batting,
        bowling,
        fielding,
        metricValue: leaderboardValue(metric, { batting, bowling, fielding }),
      };
    });

    const qualified = comparable.filter((entry) => {
      if (isBattingMetric && entry.batting.innings < minInnings) return false;
      if (isBowlingMetric && entry.bowling.innings < minInnings) return false;
      if (metric === 'battingStrikeRate' && entry.batting.balls === 0) return false;
      if (metric === 'bowlingAverage' && entry.bowling.wickets === 0) return false;
      if (metric === 'bowlingEconomy' && entry.bowling.balls === 0) return false;
      return entry.metricValue > 0;
    });

    qualified.sort((left, right) => compareLeaderboardEntries(metric, left, right));

    const total = qualified.length;
    const totalPages = Math.ceil(total / limit) || 1;
    const entries = qualified
      .slice((page - 1) * limit, page * limit)
      .map((entry, index) => ({
        rank: (page - 1) * limit + index + 1,
        playerId: entry.playerId,
        playerName: entry.playerName,
        playingRole: entry.playingRole,
        jerseyNumber: entry.jerseyNumber,
        city: entry.city,
        metric,
        value: entry.metricValue,
        stats: {
          batting: entry.batting,
          bowling: entry.bowling,
          fielding: entry.fielding,
        },
      }));

    return {
      metric,
      filters,
      entries,
      pagination: {
        page,
        limit,
        total,
        totalPages,
        hasNextPage: page < totalPages,
        hasPrevPage: page > 1,
      },
    };
  }
}

export default new PlayerStatisticsService();
