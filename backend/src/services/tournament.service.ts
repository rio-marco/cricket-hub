import { Types } from 'mongoose';
import Tournament, { ITournament } from '../models/Tournament';
import TournamentTeam from '../models/TournamentTeam';
import Match from '../models/Match';
import Innings from '../models/Innings';
import Team from '../models/Team';
import User from '../models/User';
import {
  TournamentStatus,
  TournamentFormat,
  TournamentTeamStatus,
  MatchStatus,
  MatchFormat,
} from '../constants/enums';
import { UserRole } from '../constants/roles';
import { MESSAGES } from '../constants/messages';
import { ApiError } from '../utils/apiError';
import { getPaginationParams, buildPaginationResponse, IPaginationMeta } from '../utils/pagination';

export interface ITournamentListResult {
  tournaments: ITournament[];
  pagination: IPaginationMeta;
}

export class TournamentService {
  /**
   * Helper to verify if user has administrative rights or is tournament organizer
   */
  private async isOrganizerOrAdmin(tournament: any, userId: string): Promise<boolean> {
    if (tournament.organizer.toString() === userId) {
      return true;
    }
    const user = await User.findById(userId);
    return user?.role === UserRole.ADMIN;
  }

  /**
   * Create a new tournament
   */
  public async createTournament(userId: string, data: any): Promise<ITournament> {
    const startDate = new Date(data.startDate);
    const endDate = new Date(data.endDate);

    if (endDate < startDate) {
      throw ApiError.badRequest('End date must be greater than or equal to start date.');
    }

    if (data.registrationStartDate && data.registrationEndDate) {
      const regStart = new Date(data.registrationStartDate);
      const regEnd = new Date(data.registrationEndDate);
      if (regEnd < regStart) {
        throw ApiError.badRequest('Registration end date must be on or after registration start date.');
      }
    }

    const tournament = await Tournament.create({
      ...data,
      organizer: new Types.ObjectId(userId),
      status: TournamentStatus.DRAFT,
      registrationFee: data.registrationFee || 0,
      maxPlayersPerTeam: data.maxPlayersPerTeam || 15,
      venues: Array.isArray(data.venues) ? data.venues : [],
    });

    return tournament;
  }

  /**
   * Get all tournaments with pagination, status filter, city filter, and search
   */
  public async getTournaments(query: Record<string, any>): Promise<ITournamentListResult> {
    const { page, limit, skip, sort } = getPaginationParams(query, 10, 100, '-createdAt');

    const filter: Record<string, any> = {};

    if (query.status) {
      filter.status = query.status;
    }

    if (query.city) {
      filter.city = new RegExp(String(query.city).trim(), 'i');
    }

    if (query.format) {
      filter.format = query.format;
    }

    if (query.organizer) {
      filter.organizer = new Types.ObjectId(String(query.organizer));
    }

    if (query.search) {
      const searchRegex = new RegExp(String(query.search).trim(), 'i');
      filter.$or = [
        { name: searchRegex },
        { city: searchRegex },
        { description: searchRegex },
      ];
    }

    const [tournaments, total] = await Promise.all([
      Tournament.find(filter)
        .populate('organizer', 'name email avatar phone')
        .sort(sort as any)
        .skip(skip)
        .limit(limit)
        .lean(),
      Tournament.countDocuments(filter),
    ]);

    const pagination = buildPaginationResponse(total, page, limit);

    return {
      tournaments: tournaments as unknown as ITournament[],
      pagination,
    };
  }

  /**
   * Get tournament details by ID with populated organizer and registered teams
   */
  public async getTournamentById(id: string): Promise<any> {
    if (!Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest('Invalid tournament ID.');
    }

    const tournament = await Tournament.findById(id)
      .populate('organizer', 'name email avatar phone')
      .lean();

    if (!tournament) {
      throw ApiError.notFound(MESSAGES.TOURNAMENT.NOT_FOUND || 'Tournament not found.');
    }

    // Fetch registered teams
    const registeredTeams = await TournamentTeam.find({ tournament: id })
      .populate({
        path: 'team',
        select: 'name logo location owner captain',
        populate: [
          { path: 'owner', select: 'name email avatar' },
          { path: 'captain', select: 'user', populate: { path: 'user', select: 'name avatar' } },
        ],
      })
      .sort({ createdAt: 1 })
      .lean();

    const matchCount = await Match.countDocuments({ tournament: id });

    return {
      ...tournament,
      registeredTeams,
      totalRegisteredTeams: registeredTeams.length,
      approvedTeamsCount: registeredTeams.filter((t) => t.status === TournamentTeamStatus.APPROVED).length,
      matchCount,
    };
  }

  /**
   * Update tournament details (Organizer or Admin only)
   */
  public async updateTournament(id: string, userId: string, data: any): Promise<ITournament> {
    if (!Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest('Invalid tournament ID.');
    }

    const tournament = await Tournament.findById(id);
    if (!tournament) {
      throw ApiError.notFound(MESSAGES.TOURNAMENT.NOT_FOUND || 'Tournament not found.');
    }

    const canEdit = await this.isOrganizerOrAdmin(tournament, userId);
    if (!canEdit) {
      throw ApiError.forbidden('Only tournament organizer or admin can modify tournament details.');
    }

    if (
      tournament.status === TournamentStatus.COMPLETED ||
      tournament.status === TournamentStatus.CANCELLED
    ) {
      throw ApiError.badRequest(`Cannot update tournament in ${tournament.status} state.`);
    }

    // Date validations if updated
    const startDate = data.startDate ? new Date(data.startDate) : tournament.startDate;
    const endDate = data.endDate ? new Date(data.endDate) : tournament.endDate;
    if (endDate < startDate) {
      throw ApiError.badRequest('End date must be on or after start date.');
    }

    // Max teams validation against approved teams
    if (data.maxTeams) {
      const approvedCount = await TournamentTeam.countDocuments({
        tournament: id,
        status: TournamentTeamStatus.APPROVED,
      });
      if (data.maxTeams < approvedCount) {
        throw ApiError.badRequest(
          `Cannot reduce max teams to ${data.maxTeams} as ${approvedCount} teams are already approved.`
        );
      }
    }

    Object.assign(tournament, data);
    await tournament.save();

    return tournament;
  }

  /**
   * Delete tournament (Only Organizer or Admin, and only if DRAFT)
   */
  public async deleteTournament(id: string, userId: string): Promise<{ message: string }> {
    if (!Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest('Invalid tournament ID.');
    }

    const tournament = await Tournament.findById(id);
    if (!tournament) {
      throw ApiError.notFound(MESSAGES.TOURNAMENT.NOT_FOUND || 'Tournament not found.');
    }

    const canDelete = await this.isOrganizerOrAdmin(tournament, userId);
    if (!canDelete) {
      throw ApiError.forbidden('Only tournament organizer or admin can delete tournament.');
    }

    if (tournament.status !== TournamentStatus.DRAFT) {
      throw ApiError.badRequest('Only tournaments in DRAFT status can be deleted.');
    }

    // Clean up tournament teams and scheduled matches if any
    await Promise.all([
      TournamentTeam.deleteMany({ tournament: id }),
      Match.deleteMany({ tournament: id }),
      Tournament.findByIdAndDelete(id),
    ]);

    return {
      message: MESSAGES.TOURNAMENT.DELETED || 'Tournament deleted successfully.',
    };
  }

  /**
   * Update tournament lifecycle status with transition validation
   */
  public async updateStatus(id: string, userId: string, newStatus: TournamentStatus): Promise<ITournament> {
    if (!Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest('Invalid tournament ID.');
    }

    const tournament = await Tournament.findById(id);
    if (!tournament) {
      throw ApiError.notFound(MESSAGES.TOURNAMENT.NOT_FOUND || 'Tournament not found.');
    }

    const canUpdate = await this.isOrganizerOrAdmin(tournament, userId);
    if (!canUpdate) {
      throw ApiError.forbidden('Only tournament organizer or admin can update tournament status.');
    }

    const currentStatus = tournament.status;

    // Allowed status transitions
    const validTransitions: Record<TournamentStatus, TournamentStatus[]> = {
      [TournamentStatus.DRAFT]: [TournamentStatus.REGISTRATION_OPEN, TournamentStatus.CANCELLED],
      [TournamentStatus.REGISTRATION_OPEN]: [
        TournamentStatus.REGISTRATION_CLOSED,
        TournamentStatus.DRAFT,
        TournamentStatus.CANCELLED,
      ],
      [TournamentStatus.REGISTRATION_CLOSED]: [
        TournamentStatus.IN_PROGRESS,
        TournamentStatus.REGISTRATION_OPEN,
        TournamentStatus.CANCELLED,
      ],
      [TournamentStatus.IN_PROGRESS]: [TournamentStatus.COMPLETED, TournamentStatus.CANCELLED],
      [TournamentStatus.COMPLETED]: [],
      [TournamentStatus.CANCELLED]: [],
    };

    if (currentStatus === newStatus) {
      return tournament;
    }

    const allowed = validTransitions[currentStatus] || [];
    if (!allowed.includes(newStatus)) {
      throw ApiError.badRequest(
        `Invalid status transition from '${currentStatus}' to '${newStatus}'.`
      );
    }

    // Specific state requirements
    if (newStatus === TournamentStatus.IN_PROGRESS) {
      const approvedCount = await TournamentTeam.countDocuments({
        tournament: id,
        status: TournamentTeamStatus.APPROVED,
      });
      if (approvedCount < 2) {
        throw ApiError.badRequest('At least 2 approved teams are required before starting the tournament.');
      }
    }

    tournament.status = newStatus;
    await tournament.save();

    return tournament;
  }

  /**
   * Register a team for a tournament
   */
  public async registerTeam(tournamentId: string, userId: string, teamId: string): Promise<any> {
    if (!Types.ObjectId.isValid(tournamentId) || !Types.ObjectId.isValid(teamId)) {
      throw ApiError.badRequest('Invalid tournament ID or team ID.');
    }

    const tournament = await Tournament.findById(tournamentId);
    if (!tournament) {
      throw ApiError.notFound(MESSAGES.TOURNAMENT.NOT_FOUND || 'Tournament not found.');
    }

    if (tournament.status !== TournamentStatus.REGISTRATION_OPEN) {
      throw ApiError.badRequest(
        MESSAGES.TOURNAMENT.NOT_REGISTRATION_WINDOW || 'Tournament registration is not currently open.'
      );
    }

    const now = new Date();
    if (tournament.registrationStartDate && now < tournament.registrationStartDate) {
      throw ApiError.badRequest('Registration window has not opened yet.');
    }
    if (tournament.registrationEndDate && now > tournament.registrationEndDate) {
      throw ApiError.badRequest('Registration window has closed.');
    }

    const team = await Team.findById(teamId);
    if (!team) {
      throw ApiError.notFound('Team not found.');
    }

    // Check user permission: must be team owner or admin
    const user = await User.findById(userId);
    const isOwner = team.owner.toString() === userId;
    const isAdmin = user?.role === UserRole.ADMIN;
    if (!isOwner && !isAdmin) {
      throw ApiError.forbidden('Only the team owner or an administrator can register the team for a tournament.');
    }

    // Check approved teams count against maximum limit
    const approvedCount = await TournamentTeam.countDocuments({
      tournament: tournamentId,
      status: TournamentTeamStatus.APPROVED,
    });
    if (approvedCount >= tournament.maxTeams) {
      throw ApiError.badRequest(
        MESSAGES.TOURNAMENT.MAX_TEAMS_REACHED || 'Tournament has reached maximum registered teams limit.'
      );
    }

    // Check duplicate registration
    const existing = await TournamentTeam.findOne({ tournament: tournamentId, team: teamId });
    if (existing) {
      throw ApiError.conflict(
        MESSAGES.TOURNAMENT.ALREADY_REGISTERED || 'This team is already registered for this tournament.'
      );
    }

    const registration = await TournamentTeam.create({
      tournament: new Types.ObjectId(tournamentId),
      team: new Types.ObjectId(teamId),
      status: TournamentTeamStatus.PENDING,
      played: 0,
      won: 0,
      lost: 0,
      tied: 0,
      noResult: 0,
      points: 0,
      netRunRate: 0,
      runsScored: 0,
      oversPlayed: 0,
      runsConceded: 0,
      oversBowled: 0,
    });

    const populatedRegistration = await TournamentTeam.findById(registration._id).populate(
      'team',
      'name logo location owner'
    );

    return populatedRegistration;
  }

  /**
   * Approve a registered team (Organizer or Admin only)
   */
  public async approveTeam(
    tournamentId: string,
    userId: string,
    tournamentTeamId: string
  ): Promise<any> {
    if (!Types.ObjectId.isValid(tournamentId) || !Types.ObjectId.isValid(tournamentTeamId)) {
      throw ApiError.badRequest('Invalid tournament or registration identifier.');
    }

    const tournament = await Tournament.findById(tournamentId);
    if (!tournament) {
      throw ApiError.notFound(MESSAGES.TOURNAMENT.NOT_FOUND || 'Tournament not found.');
    }

    const canManage = await this.isOrganizerOrAdmin(tournament, userId);
    if (!canManage) {
      throw ApiError.forbidden('Only tournament organizer or admin can approve teams.');
    }

    const registration = await TournamentTeam.findOne({
      _id: tournamentTeamId,
      tournament: tournamentId,
    });

    if (!registration) {
      throw ApiError.notFound('Tournament team registration record not found.');
    }

    if (registration.status === TournamentTeamStatus.APPROVED) {
      return registration;
    }

    // Check capacity
    const approvedCount = await TournamentTeam.countDocuments({
      tournament: tournamentId,
      status: TournamentTeamStatus.APPROVED,
    });
    if (approvedCount >= tournament.maxTeams) {
      throw ApiError.badRequest(
        MESSAGES.TOURNAMENT.MAX_TEAMS_REACHED || 'Tournament capacity reached. Cannot approve more teams.'
      );
    }

    registration.status = TournamentTeamStatus.APPROVED;
    await registration.save();

    return registration.populate('team', 'name logo location');
  }

  /**
   * Reject a registered team (Organizer or Admin only)
   */
  public async rejectTeam(
    tournamentId: string,
    userId: string,
    tournamentTeamId: string
  ): Promise<any> {
    if (!Types.ObjectId.isValid(tournamentId) || !Types.ObjectId.isValid(tournamentTeamId)) {
      throw ApiError.badRequest('Invalid tournament or registration identifier.');
    }

    const tournament = await Tournament.findById(tournamentId);
    if (!tournament) {
      throw ApiError.notFound(MESSAGES.TOURNAMENT.NOT_FOUND || 'Tournament not found.');
    }

    const canManage = await this.isOrganizerOrAdmin(tournament, userId);
    if (!canManage) {
      throw ApiError.forbidden('Only tournament organizer or admin can reject teams.');
    }

    const registration = await TournamentTeam.findOne({
      _id: tournamentTeamId,
      tournament: tournamentId,
    });

    if (!registration) {
      throw ApiError.notFound('Tournament team registration record not found.');
    }

    registration.status = TournamentTeamStatus.REJECTED;
    await registration.save();

    return registration.populate('team', 'name logo location');
  }

  /**
   * List all registered teams for a tournament
   */
  public async getRegisteredTeams(tournamentId: string): Promise<any[]> {
    if (!Types.ObjectId.isValid(tournamentId)) {
      throw ApiError.badRequest('Invalid tournament ID.');
    }

    const tournament = await Tournament.findById(tournamentId);
    if (!tournament) {
      throw ApiError.notFound(MESSAGES.TOURNAMENT.NOT_FOUND || 'Tournament not found.');
    }

    const teams = await TournamentTeam.find({ tournament: tournamentId })
      .populate({
        path: 'team',
        select: 'name logo location owner captain viceCaptain',
        populate: [
          { path: 'owner', select: 'name email phone avatar' },
          { path: 'captain', select: 'user', populate: { path: 'user', select: 'name avatar' } },
        ],
      })
      .sort({ status: 1, createdAt: 1 })
      .lean();

    return teams;
  }

  /**
   * Dynamically generate round-robin or knockout fixtures, preventing duplicates
   */
  public async generateFixtures(tournamentId: string, userId: string): Promise<any[]> {
    if (!Types.ObjectId.isValid(tournamentId)) {
      throw ApiError.badRequest('Invalid tournament ID.');
    }

    const tournament = await Tournament.findById(tournamentId);
    if (!tournament) {
      throw ApiError.notFound(MESSAGES.TOURNAMENT.NOT_FOUND || 'Tournament not found.');
    }

    const canManage = await this.isOrganizerOrAdmin(tournament, userId);
    if (!canManage) {
      throw ApiError.forbidden('Only tournament organizer or admin can generate fixtures.');
    }

    // Check if matches have already been generated
    const existingMatchesCount = await Match.countDocuments({ tournament: tournamentId });
    if (existingMatchesCount > 0) {
      throw ApiError.conflict('Fixtures have already been generated for this tournament.');
    }

    // Fetch all approved teams
    const approvedTournamentTeams = await TournamentTeam.find({
      tournament: tournamentId,
      status: TournamentTeamStatus.APPROVED,
    }).populate('team', 'name logo');

    if (approvedTournamentTeams.length < 2) {
      throw ApiError.badRequest('At least 2 approved teams are required to generate fixtures.');
    }

    const teams = approvedTournamentTeams.map((tt) => tt.team as any);
    const n = teams.length;

    const defaultOvers =
      tournament.customOvers ||
      (tournament.matchFormat === MatchFormat.T20
        ? 20
        : tournament.matchFormat === MatchFormat.T10
        ? 10
        : 50);

    const venues = tournament.venues && tournament.venues.length > 0 ? tournament.venues : ['Main Ground'];
    const startMs = new Date(tournament.startDate).getTime();
    const endMs = new Date(tournament.endDate).getTime();
    const durationMs = Math.max(endMs - startMs, 24 * 60 * 60 * 1000);

    const matchDocs: any[] = [];

    if (tournament.format === TournamentFormat.KNOCKOUT) {
      // Single Elimination Knockout Round 1
      const numMatches = Math.floor(n / 2);
      const intervalMs = Math.floor(durationMs / Math.max(numMatches, 1));

      for (let i = 0; i < numMatches; i++) {
        const teamA = teams[i * 2];
        const teamB = teams[i * 2 + 1];
        const matchDate = new Date(startMs + i * intervalMs);
        const venue = venues[i % venues.length];

        matchDocs.push({
          title: `Round 1 - Match ${i + 1}: ${teamA.name} vs ${teamB.name}`,
          tournament: tournament._id,
          teamA: teamA._id,
          teamB: teamB._id,
          format: tournament.matchFormat,
          totalOvers: defaultOvers,
          ballType: tournament.ballType,
          venue,
          city: tournament.city || '',
          matchDate,
          status: MatchStatus.UPCOMING,
          currentInnings: 1,
          playingXI_A: [],
          playingXI_B: [],
          substitutes_A: [],
          substitutes_B: [],
        });
      }
    } else {
      // Round Robin Scheduling (LEAGUE or LEAGUE_KNOCKOUT group stage)
      // Standard Berger round-robin algorithm
      const teamList = [...teams];
      if (teamList.length % 2 !== 0) {
        teamList.push(null as any); // BYE placeholder
      }

      const totalTeams = teamList.length;
      const rounds = totalTeams - 1;
      const matchesPerRound = totalTeams / 2;
      const roundIntervalMs = Math.floor(durationMs / Math.max(rounds, 1));

      let matchCounter = 1;

      for (let round = 0; round < rounds; round++) {
        const roundDate = new Date(startMs + round * roundIntervalMs);

        for (let matchIndex = 0; matchIndex < matchesPerRound; matchIndex++) {
          const homeIndex = (round + matchIndex) % (totalTeams - 1);
          let awayIndex = (totalTeams - 1 - matchIndex + round) % (totalTeams - 1);
          if (matchIndex === 0) {
            awayIndex = totalTeams - 1;
          }

          const teamHome = teamList[homeIndex];
          const teamAway = teamList[awayIndex];

          // Skip matches involving dummy BYE
          if (!teamHome || !teamAway) {
            continue;
          }

          const venue = venues[(matchCounter - 1) % venues.length];

          matchDocs.push({
            title: `League Match ${matchCounter}: ${teamHome.name} vs ${teamAway.name}`,
            tournament: tournament._id,
            teamA: teamHome._id,
            teamB: teamAway._id,
            format: tournament.matchFormat,
            totalOvers: defaultOvers,
            ballType: tournament.ballType,
            venue,
            city: tournament.city || '',
            matchDate: roundDate,
            status: MatchStatus.UPCOMING,
            currentInnings: 1,
            playingXI_A: [],
            playingXI_B: [],
            substitutes_A: [],
            substitutes_B: [],
          });

          matchCounter++;
        }
      }
    }

    const createdMatches = await Match.insertMany(matchDocs);

    return createdMatches;
  }

  /**
   * List scheduled matches/fixtures for a tournament
   */
  public async getFixtures(tournamentId: string): Promise<any[]> {
    if (!Types.ObjectId.isValid(tournamentId)) {
      throw ApiError.badRequest('Invalid tournament ID.');
    }

    const tournament = await Tournament.findById(tournamentId);
    if (!tournament) {
      throw ApiError.notFound(MESSAGES.TOURNAMENT.NOT_FOUND || 'Tournament not found.');
    }

    const fixtures = await Match.find({ tournament: tournamentId })
      .populate('teamA', 'name logo location')
      .populate('teamB', 'name logo location')
      .populate('scorer', 'name email avatar phone')
      .populate('result.winner', 'name logo')
      .sort({ matchDate: 1, createdAt: 1 })
      .lean();

    return fixtures;
  }

  /**
   * Calculate and retrieve standings / points table for a tournament
   * Sorted by points descending, netRunRate descending, won descending
   */
  public async getPointsTable(tournamentId: string): Promise<any[]> {
    if (!Types.ObjectId.isValid(tournamentId)) {
      throw ApiError.badRequest('Invalid tournament ID.');
    }

    const tournament = await Tournament.findById(tournamentId);
    if (!tournament) {
      throw ApiError.notFound(MESSAGES.TOURNAMENT.NOT_FOUND || 'Tournament not found.');
    }

    const standings = await TournamentTeam.find({
      tournament: tournamentId,
      status: TournamentTeamStatus.APPROVED,
    })
      .populate('team', 'name logo location')
      .sort({ points: -1, netRunRate: -1, won: -1, runsScored: -1 })
      .lean();

    // Map rank to each team entry
    const rankedStandings = standings.map((item, index) => ({
      rank: index + 1,
      ...item,
    }));

    return rankedStandings;
  }

  /**
   * Aggregate and retrieve tournament statistics: top batsmen, top bowlers, boundaries
   */
  public async getTournamentStats(tournamentId: string): Promise<any> {
    if (!Types.ObjectId.isValid(tournamentId)) {
      throw ApiError.badRequest('Invalid tournament ID.');
    }

    const tournament = await Tournament.findById(tournamentId);
    if (!tournament) {
      throw ApiError.notFound(MESSAGES.TOURNAMENT.NOT_FOUND || 'Tournament not found.');
    }

    const matches = await Match.find({ tournament: tournamentId }).select('_id');
    const matchIds = matches.map((m) => m._id);

    if (matchIds.length === 0) {
      return {
        topBatsmen: [],
        topBowlers: [],
        mostSixes: [],
        mostFours: [],
        summary: {
          totalMatches: 0,
          completedMatches: 0,
          totalRuns: 0,
          totalWickets: 0,
        },
      };
    }

    const [topBatsmen, topBowlers, summaryAgg] = await Promise.all([
      // Aggregation: Top Run Scorers
      Innings.aggregate([
        { $match: { match: { $in: matchIds } } },
        { $unwind: '$battingStats' },
        {
          $group: {
            _id: '$battingStats.player',
            totalRuns: { $sum: '$battingStats.runs' },
            totalBalls: { $sum: '$battingStats.balls' },
            fours: { $sum: '$battingStats.fours' },
            sixes: { $sum: '$battingStats.sixes' },
            highestScore: { $max: '$battingStats.runs' },
            inningsCount: { $sum: 1 },
            notOuts: { $sum: { $cond: ['$battingStats.isNotOut', 1, 0] } },
          },
        },
        {
          $addFields: {
            dismissals: { $subtract: ['$inningsCount', '$notOuts'] },
            strikeRate: {
              $cond: [
                { $gt: ['$totalBalls', 0] },
                { $round: [{ $multiply: [{ $divide: ['$totalRuns', '$totalBalls'] }, 100] }, 2] },
                0,
              ],
            },
            average: {
              $cond: [
                { $gt: [{ $subtract: ['$inningsCount', '$notOuts'] }, 0] },
                {
                  $round: [
                    { $divide: ['$totalRuns', { $subtract: ['$inningsCount', '$notOuts'] }] },
                    2,
                  ],
                },
                '$totalRuns',
              ],
            },
          },
        },
        { $sort: { totalRuns: -1, strikeRate: -1 } },
        { $limit: 10 },
        {
          $lookup: {
            from: 'players',
            localField: '_id',
            foreignField: '_id',
            as: 'playerDoc',
          },
        },
        { $unwind: { path: '$playerDoc', preserveNullAndEmptyArrays: true } },
        {
          $lookup: {
            from: 'users',
            localField: 'playerDoc.user',
            foreignField: '_id',
            as: 'userDoc',
          },
        },
        { $unwind: { path: '$userDoc', preserveNullAndEmptyArrays: true } },
        {
          $project: {
            playerId: '$_id',
            playerName: { $ifNull: ['$userDoc.name', 'Unknown'] },
            playerAvatar: { $ifNull: ['$userDoc.avatar', ''] },
            playingRole: '$playerDoc.playingRole',
            totalRuns: 1,
            totalBalls: 1,
            fours: 1,
            sixes: 1,
            highestScore: 1,
            inningsCount: 1,
            average: 1,
            strikeRate: 1,
          },
        },
      ]),

      // Aggregation: Top Wicket Takers
      Innings.aggregate([
        { $match: { match: { $in: matchIds } } },
        { $unwind: '$bowlingStats' },
        {
          $group: {
            _id: '$bowlingStats.player',
            totalWickets: { $sum: '$bowlingStats.wickets' },
            totalRunsConceded: { $sum: '$bowlingStats.runs' },
            totalBallsBowled: { $sum: '$bowlingStats.balls' },
            totalMaidens: { $sum: '$bowlingStats.maidens' },
            totalDotBalls: { $sum: '$bowlingStats.dotBalls' },
            inningsCount: { $sum: 1 },
          },
        },
        {
          $addFields: {
            totalOvers: {
              $add: [
                { $floor: { $divide: ['$totalBallsBowled', 6] } },
                { $divide: [{ $mod: ['$totalBallsBowled', 6] }, 10] },
              ],
            },
            economy: {
              $cond: [
                { $gt: ['$totalBallsBowled', 0] },
                {
                  $round: [
                    { $multiply: [{ $divide: ['$totalRunsConceded', '$totalBallsBowled'] }, 6] },
                    2,
                  ],
                },
                0,
              ],
            },
          },
        },
        { $sort: { totalWickets: -1, economy: 1 } },
        { $limit: 10 },
        {
          $lookup: {
            from: 'players',
            localField: '_id',
            foreignField: '_id',
            as: 'playerDoc',
          },
        },
        { $unwind: { path: '$playerDoc', preserveNullAndEmptyArrays: true } },
        {
          $lookup: {
            from: 'users',
            localField: 'playerDoc.user',
            foreignField: '_id',
            as: 'userDoc',
          },
        },
        { $unwind: { path: '$userDoc', preserveNullAndEmptyArrays: true } },
        {
          $project: {
            playerId: '$_id',
            playerName: { $ifNull: ['$userDoc.name', 'Unknown'] },
            playerAvatar: { $ifNull: ['$userDoc.avatar', ''] },
            bowlingStyle: '$playerDoc.bowlingStyle',
            totalWickets: 1,
            totalRunsConceded: 1,
            totalBallsBowled: 1,
            totalOvers: 1,
            totalMaidens: 1,
            totalDotBalls: 1,
            economy: 1,
            inningsCount: 1,
          },
        },
      ]),

      // Aggregation: Tournament Overall Summary
      Innings.aggregate([
        { $match: { match: { $in: matchIds } } },
        {
          $group: {
            _id: null,
            totalRuns: { $sum: '$totalRuns' },
            totalWickets: { $sum: '$totalWickets' },
          },
        },
      ]),
    ]);

    const completedMatches = await Match.countDocuments({
      tournament: tournamentId,
      status: MatchStatus.COMPLETED,
    });

    const mostSixes = [...topBatsmen]
      .filter((b) => b.sixes > 0)
      .sort((a, b) => b.sixes - a.sixes)
      .slice(0, 10);

    const mostFours = [...topBatsmen]
      .filter((b) => b.fours > 0)
      .sort((a, b) => b.fours - a.fours)
      .slice(0, 10);

    const summary = {
      totalMatches: matches.length,
      completedMatches,
      totalRuns: summaryAgg[0]?.totalRuns || 0,
      totalWickets: summaryAgg[0]?.totalWickets || 0,
    };

    return {
      topBatsmen,
      topBowlers,
      mostSixes,
      mostFours,
      summary,
    };
  }
}

export const tournamentService = new TournamentService();
export default tournamentService;
