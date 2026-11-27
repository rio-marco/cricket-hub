import { Types } from 'mongoose';
import Match, { IMatch } from '../models/Match';
import Innings, { IInnings } from '../models/Innings';
import Tournament from '../models/Tournament';
import Team from '../models/Team';
import User from '../models/User';
import Player from '../models/Player';
import TeamMember from '../models/TeamMember';
import TournamentTeam from '../models/TournamentTeam';
import {
  MatchStatus,
  MatchFormat,
  TossDecision,
  InningsStatus,
  TournamentTeamStatus,
  TournamentStatus,
  TeamMemberStatus,
  NotificationCategory,
  NotificationType,
} from '../constants/enums';
import { UserRole } from '../constants/roles';
import { MESSAGES } from '../constants/messages';
import { ApiError } from '../utils/apiError';
import { getPaginationParams, buildPaginationResponse, IPaginationMeta } from '../utils/pagination';
import { notifySafely } from './notificationHooks.service';

export interface IMatchListResult {
  matches: IMatch[];
  pagination: IPaginationMeta;
}

const escapeRegExp = (value: string): string =>
  value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

export class MatchService {
  /**
   * Helper to check if a user is an admin
   */
  private async isAdmin(userId: string): Promise<boolean> {
    const user = await User.findById(userId);
    return user?.role === UserRole.ADMIN;
  }

  /**
   * Helper to check if a user can manage a match (organizer, team owner, admin, or assigned scorer)
   */
  public async canManageMatch(match: any, userId: string): Promise<boolean> {
    if (await this.isAdmin(userId)) {
      return true;
    }

    if (match.scorer && match.scorer.toString() === userId) {
      return true;
    }

    // Check tournament organizer
    if (match.tournament) {
      const tournament = await Tournament.findById(match.tournament);
      if (tournament && tournament.organizer?.toString() === userId) {
        return true;
      }
    }

    // Check team owners
    const [teamA, teamB] = await Promise.all([
      Team.findById(match.teamA),
      Team.findById(match.teamB),
    ]);

    if (teamA && teamA.owner?.toString() === userId) {
      return true;
    }
    if (teamB && teamB.owner?.toString() === userId) {
      return true;
    }

    return false;
  }

  public async getMatchAccess(match: any, userId: string): Promise<{
    canView: boolean;
    canScore: boolean;
    canManage: boolean;
    isTeamMember: boolean;
  }> {
    const canManage = await this.canManageMatch(match, userId);
    const player = await Player.findOne({ user: userId }).select('_id');
    const isTeamMember = player
      ? Boolean(
          await TeamMember.exists({
            team: { $in: [match.teamA, match.teamB] },
            player: player._id,
            status: TeamMemberStatus.ACTIVE,
          })
        )
      : false;

    return {
      canView: true,
      canScore: canManage,
      canManage,
      isTeamMember,
    };
  }

  public async getNotificationRecipients(
    match: any,
    excludeUserId?: string
  ): Promise<string[]> {
    const populated = await Match.findById(match._id || match)
      .populate('teamA', 'owner name')
      .populate('teamB', 'owner name')
      .populate('scorer', '_id')
      .populate('tournament', 'organizer name')
      .lean();
    if (!populated) return [];

    const recipients = [
      (populated.teamA as any)?.owner,
      (populated.teamB as any)?.owner,
      (populated.scorer as any)?._id || populated.scorer,
      (populated.tournament as any)?.organizer,
    ]
      .map((id: any) => (id ? String(id) : ''))
      .filter((id: string) => /^[0-9a-fA-F]{24}$/.test(id) && id !== String(excludeUserId || ''));
    return Array.from(new Set(recipients));
  }

  /**
   * Create a new match (standalone or tournament match)
   */
  public async createMatch(userId: string, data: any): Promise<IMatch> {
    const teamAId = data.teamA;
    const teamBId = data.teamB;
    const teamAObjectId = new Types.ObjectId(String(teamAId));
    const teamBObjectId = new Types.ObjectId(String(teamBId));

    if (teamAObjectId.equals(teamBObjectId)) {
      throw ApiError.badRequest(MESSAGES.MATCH.INVALID_TEAMS || 'Teams for the match must be different.');
    }

    const [teamA, teamB] = await Promise.all([
      Team.findById(teamAId),
      Team.findById(teamBId),
    ]);

    if (!teamA) {
      throw ApiError.notFound('Team A not found.');
    }
    if (!teamB) {
      throw ApiError.notFound('Team B not found.');
    }

    // If part of a tournament, validate tournament constraints
    let tournamentDoc: any = null;
    const tournamentId = data.tournamentId || data.tournament;
    if (tournamentId) {
      if (!Types.ObjectId.isValid(tournamentId)) {
        throw ApiError.badRequest('Invalid tournament ID.');
      }
      tournamentDoc = await Tournament.findById(tournamentId);
      if (!tournamentDoc) {
        throw ApiError.notFound(MESSAGES.TOURNAMENT.NOT_FOUND || 'Tournament not found.');
      }

      if (
        tournamentDoc.status === TournamentStatus.DRAFT ||
        tournamentDoc.status === TournamentStatus.COMPLETED ||
        tournamentDoc.status === TournamentStatus.CANCELLED
      ) {
        throw ApiError.badRequest('Matches can only be scheduled for active tournaments.');
      }

      // Verify user is tournament organizer or admin
      const isOrganizer = tournamentDoc.organizer?.toString() === userId;
      const isAdminUser = await this.isAdmin(userId);
      if (!isOrganizer && !isAdminUser) {
        throw ApiError.forbidden('Only tournament organizer or admin can schedule tournament matches.');
      }

      // Verify both teams are approved in the tournament
      const [regTeamA, regTeamB] = await Promise.all([
        TournamentTeam.findOne({
          tournament: tournamentId,
          team: teamAId,
          status: TournamentTeamStatus.APPROVED,
        }),
        TournamentTeam.findOne({
          tournament: tournamentId,
          team: teamBId,
          status: TournamentTeamStatus.APPROVED,
        }),
      ]);

      if (!regTeamA) {
        throw ApiError.badRequest(`Team '${teamA.name}' is not an approved team in this tournament.`);
      }
      if (!regTeamB) {
        throw ApiError.badRequest(`Team '${teamB.name}' is not an approved team in this tournament.`);
      }
    }

    // Determine default overs
    let totalOvers = data.totalOvers;
    if (!totalOvers) {
      if (tournamentDoc && tournamentDoc.customOvers) {
        totalOvers = tournamentDoc.customOvers;
      } else if (data.format === MatchFormat.T20 || tournamentDoc?.matchFormat === MatchFormat.T20) {
        totalOvers = 20;
      } else if (data.format === MatchFormat.T10 || tournamentDoc?.matchFormat === MatchFormat.T10) {
        totalOvers = 10;
      } else {
        totalOvers = 50;
      }
    }

    const title =
      data.title && data.title.trim() !== ''
        ? data.title.trim()
        : `${teamA.name} vs ${teamB.name}`;

    const match = await Match.create({
      title,
      tournament: tournamentId ? new Types.ObjectId(tournamentId) : undefined,
      teamA: teamAObjectId,
      teamB: teamBObjectId,
      format: data.format || tournamentDoc?.matchFormat || MatchFormat.T20,
      totalOvers,
      ballsPerOver: data.ballsPerOver || 6,
      ballType: data.ballType || tournamentDoc?.ballType,
      venue: data.venue || (tournamentDoc?.venues && tournamentDoc.venues[0]) || '',
      city: data.city || tournamentDoc?.city || '',
      matchDate: data.matchDate ? new Date(data.matchDate) : new Date(),
      status: MatchStatus.UPCOMING,
      currentInnings: 1,
      playingXI_A: [],
      playingXI_B: [],
      substitutes_A: [],
      substitutes_B: [],
    });

    const populatedMatch = await Match.findById(match._id)
      .populate('teamA', 'name logo location')
      .populate('teamB', 'name logo location')
      .populate('tournament', 'name format matchFormat');

    const recipients = await this.getNotificationRecipients(match._id, userId);
    await notifySafely(recipients, {
      type: NotificationType.MATCH_REMINDER,
      category: NotificationCategory.MATCH,
      title: 'New match scheduled',
      body: `${title} is scheduled for ${match.matchDate ? new Date(match.matchDate).toLocaleString() : 'an upcoming date'}.`,
      data: { matchId: String(match._id), status: match.status },
      relatedEntityType: 'Match',
      relatedEntityId: String(match._id),
      dedupeKey: `match-created:${match._id}`,
    });

    return populatedMatch as unknown as IMatch;
  }

  /**
   * Get all matches with pagination, filters by status, tournament, team, search
   */
  public async getMatches(query: Record<string, any>): Promise<IMatchListResult> {
    const { page, limit, skip, sort } = getPaginationParams(query, 10, 100, '-matchDate', ['matchDate','createdAt','updatedAt','status','title']);

    const filter: Record<string, any> = {};

    if (query.status) {
      filter.status = query.status;
    }

    const tournamentId = query.tournamentId || query.tournament;
    if (tournamentId && Types.ObjectId.isValid(tournamentId)) {
      filter.tournament = new Types.ObjectId(String(tournamentId));
    }

    const teamId = query.teamId || query.team;
    if (teamId && Types.ObjectId.isValid(teamId)) {
      const teamObjectId = new Types.ObjectId(String(teamId));
      filter.$or = [{ teamA: teamObjectId }, { teamB: teamObjectId }];
    }

    if (query.city) {
      filter.city = new RegExp(escapeRegExp(String(query.city).trim()), 'i');
    }

    if (query.search) {
      const searchRegex = new RegExp(escapeRegExp(String(query.search).trim()), 'i');
      if (filter.$or) {
        filter.$and = [{ $or: filter.$or }, { $or: [{ title: searchRegex }, { venue: searchRegex }] }];
        delete filter.$or;
      } else {
        filter.$or = [{ title: searchRegex }, { venue: searchRegex }];
      }
    }

    const [matches, total] = await Promise.all([
      Match.find(filter)
        .populate('teamA', 'name logo location')
        .populate('teamB', 'name logo location')
        .populate('tournament', 'name format matchFormat')
        .populate('scorer', 'name avatar')
        .populate('result.winner', 'name logo')
        .populate({
          path: 'playerOfMatch',
          populate: { path: 'user', select: 'name avatar' },
        })
        .sort(sort as any)
        .skip(skip)
        .limit(limit)
        .lean(),
      Match.countDocuments(filter),
    ]);

    const pagination = buildPaginationResponse(total, page, limit);

    return {
      matches: matches as unknown as IMatch[],
      pagination,
    };
  }

  /**
   * Get match details by ID with populated teams, players, toss, scorer, and innings
   */
  public async getMatchById(id: string): Promise<any> {
    if (!Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest('Invalid match ID.');
    }

    const match = await Match.findById(id)
      .populate('teamA', 'name logo location captain')
      .populate('teamB', 'name logo location captain')
      .populate('tournament', 'name format matchFormat ballType')
      .populate('scorer', 'name avatar')
      .populate('toss.winner', 'name logo')
      .populate('result.winner', 'name logo')
      .populate({
        path: 'playerOfMatch',
        populate: { path: 'user', select: 'name avatar' },
      })
      .populate({
        path: 'playingXI_A',
        populate: { path: 'user', select: 'name avatar' },
      })
      .populate({
        path: 'playingXI_B',
        populate: { path: 'user', select: 'name avatar' },
      })
      .populate({
        path: 'substitutes_A',
        populate: { path: 'user', select: 'name avatar' },
      })
      .populate({
        path: 'substitutes_B',
        populate: { path: 'user', select: 'name avatar' },
      })
      .lean();

    if (!match) {
      throw ApiError.notFound(MESSAGES.MATCH.NOT_FOUND || 'Match not found.');
    }

    // Fetch innings associated with this match
    const inningsList = await Innings.find({ match: id })
      .populate('battingTeam', 'name logo')
      .populate('bowlingTeam', 'name logo')
      .sort({ inningsNumber: 1 })
      .lean();

    return {
      ...match,
      innings: inningsList,
    };
  }

  /**
   * Update match details (organizer, scorer, or admin only)
   */
  public async updateMatch(id: string, userId: string, data: any): Promise<IMatch> {
    if (!Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest('Invalid match ID.');
    }

    const match = await Match.findById(id);
    if (!match) {
      throw ApiError.notFound(MESSAGES.MATCH.NOT_FOUND || 'Match not found.');
    }

    const canEdit = await this.canManageMatch(match, userId);
    if (!canEdit) {
      throw ApiError.forbidden('You do not have permission to update this match.');
    }

    if (match.status === MatchStatus.COMPLETED || match.status === MatchStatus.ABANDONED) {
      throw ApiError.badRequest(`Cannot modify match setup details in ${match.status} status.`);
    }

    if (data.title !== undefined) match.title = data.title;
    if (data.venue !== undefined) match.venue = data.venue;
    if (data.city !== undefined) match.city = data.city;
    if (data.matchDate !== undefined) match.matchDate = new Date(data.matchDate);
    if (data.totalOvers !== undefined) match.totalOvers = data.totalOvers;
    if (data.ballsPerOver !== undefined) match.ballsPerOver = data.ballsPerOver;
    if (data.ballType !== undefined) match.ballType = data.ballType;
    if (data.format !== undefined) match.format = data.format;

    await match.save();

    return match;
  }

  /**
   * Delete match (only if UPCOMING, only organizer, creator, or admin)
   */
  public async deleteMatch(id: string, userId: string): Promise<{ message: string }> {
    if (!Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest('Invalid match ID.');
    }

    const match = await Match.findById(id);
    if (!match) {
      throw ApiError.notFound(MESSAGES.MATCH.NOT_FOUND || 'Match not found.');
    }

    const canDelete = await this.canManageMatch(match, userId);
    if (!canDelete) {
      throw ApiError.forbidden('You do not have permission to delete this match.');
    }

    if (match.status !== MatchStatus.UPCOMING) {
      throw ApiError.badRequest('Only matches with UPCOMING status can be deleted.');
    }

    await Promise.all([
      Innings.deleteMany({ match: id }),
      Match.findByIdAndDelete(id),
    ]);

    return {
      message: MESSAGES.MATCH.DELETED || 'Match deleted successfully.',
    };
  }

  /**
   * Record toss result and transition match status to TOSS
   */
  public async performToss(
    matchId: string,
    userId: string,
    winner: string,
    decision: TossDecision
  ): Promise<IMatch> {
    if (!Types.ObjectId.isValid(matchId) || !Types.ObjectId.isValid(winner)) {
      throw ApiError.badRequest('Invalid match ID or toss winner ID.');
    }

    const match = await Match.findById(matchId);
    if (!match) {
      throw ApiError.notFound(MESSAGES.MATCH.NOT_FOUND || 'Match not found.');
    }

    const canEdit = await this.canManageMatch(match, userId);
    if (!canEdit) {
      throw ApiError.forbidden('You do not have permission to record toss for this match.');
    }

    if (
      match.status === MatchStatus.TOSS ||
      match.status === MatchStatus.LIVE ||
      match.status === MatchStatus.COMPLETED ||
      match.status === MatchStatus.ABANDONED ||
      match.status === MatchStatus.CANCELLED
    ) {
      throw ApiError.badRequest('Cannot record toss for a match that is already past the toss stage.');
    }

    const winnerObjectId = new Types.ObjectId(winner);
    const isTeamA = winnerObjectId.equals(new Types.ObjectId(match.teamA.toString()));
    const isTeamB = winnerObjectId.equals(new Types.ObjectId(match.teamB.toString()));

    if (!isTeamA && !isTeamB) {
      throw ApiError.badRequest('Toss winner must be either Team A or Team B.');
    }

    match.toss = {
      winner: winnerObjectId,
      decision,
    };
    match.status = MatchStatus.TOSS;

    await match.save();

    const populatedMatch = await Match.findById(match._id)
      .populate('teamA', 'name logo')
      .populate('teamB', 'name logo')
      .populate('toss.winner', 'name logo');

    const recipients = await this.getNotificationRecipients(match._id, userId);
    const tossWinnerName = (populatedMatch as any)?.toss?.winner?.name || 'The toss winner';
    await notifySafely(recipients, {
      type: NotificationType.MATCH_TOSS,
      category: NotificationCategory.MATCH,
      title: 'Toss completed',
      body: `${tossWinnerName} won the toss and chose to ${decision.toLowerCase()}.`,
      data: { matchId: String(match._id), winner: String(winner), decision },
      relatedEntityType: 'Match',
      relatedEntityId: String(match._id),
      dedupeKey: `match-toss:${match._id}:${winner}:${decision}`,
    });

    return populatedMatch as unknown as IMatch;
  }

  /**
   * Set Playing XI and Substitutes for a team in a match
   */
  public async setPlayingXI(
    matchId: string,
    userId: string,
    teamId: string,
    playingXI: string[],
    substitutes: string[] = []
  ): Promise<IMatch> {
    if (!Types.ObjectId.isValid(matchId) || !Types.ObjectId.isValid(teamId)) {
      throw ApiError.badRequest('Invalid match ID or team ID.');
    }

    const match = await Match.findById(matchId);
    if (!match) {
      throw ApiError.notFound(MESSAGES.MATCH.NOT_FOUND || 'Match not found.');
    }

    const isTeamA = match.teamA.toString() === teamId;
    const isTeamB = match.teamB.toString() === teamId;

    if (!isTeamA && !isTeamB) {
      throw ApiError.badRequest('Specified team is not a participant in this match.');
    }

    // Permission check: team owner, captain, organizer, scorer, or admin
    const team = await Team.findById(teamId);
    if (!team) {
      throw ApiError.notFound('Team not found.');
    }

    const isOwner = team.owner.toString() === userId;
    const callerPlayer = await Player.findOne({ user: userId }).select('_id').lean();
    const isCaptain = Boolean(
      team.captain && callerPlayer?._id && team.captain.toString() === callerPlayer._id.toString()
    );
    const isScorer = match.scorer && match.scorer.toString() === userId;
    const isAdminUser = await this.isAdmin(userId);

    let isOrganizer = false;
    if (match.tournament) {
      const tournament = await Tournament.findById(match.tournament);
      isOrganizer = tournament ? tournament.organizer.toString() === userId : false;
    }

    if (!isOwner && !isCaptain && !isScorer && !isOrganizer && !isAdminUser) {
      throw ApiError.forbidden('You do not have permission to submit the Playing XI for this team.');
    }

    if (match.status === MatchStatus.COMPLETED || match.status === MatchStatus.ABANDONED) {
      throw ApiError.badRequest('Cannot change Playing XI for a completed or abandoned match.');
    }

    if (playingXI.length !== 11) {
      throw ApiError.badRequest('Playing XI must consist of exactly 11 players.');
    }

    // Validate unique IDs
    const uniquePlayers = new Set(playingXI);
    if (uniquePlayers.size !== 11) {
      throw ApiError.badRequest('Playing XI contains duplicate players.');
    }

    const allSelected = [...playingXI, ...(substitutes || [])];
    const uniqueAll = new Set(allSelected.map(String));
    if (uniqueAll.size !== allSelected.length) {
      throw ApiError.badRequest('Playing XI and substitutes must not contain duplicate players.');
    }
    const selectedObjectIds = allSelected.map((p) => new Types.ObjectId(p));
    const activeMembers = await TeamMember.find({
      team: teamId,
      player: { $in: selectedObjectIds },
      isActive: true,
    }).select('player').lean();
    const activeSet = new Set(activeMembers.map((m: any) => m.player.toString()));
    const invalid = allSelected.filter((p) => !activeSet.has(String(p)));
    if (invalid.length > 0) {
      throw ApiError.badRequest('All selected players must be active members of the team.');
    }

    // Convert strings to ObjectIds
    const playingXIObjectIds = playingXI.map((p) => new Types.ObjectId(p));
    const substituteObjectIds = (substitutes || []).map((s) => new Types.ObjectId(s));

    if (isTeamA) {
      match.playingXI_A = playingXIObjectIds;
      match.substitutes_A = substituteObjectIds;
    } else {
      match.playingXI_B = playingXIObjectIds;
      match.substitutes_B = substituteObjectIds;
    }

    await match.save();

    return match;
  }

  /**
   * Assign official scorer to a match
   */
  public async assignScorer(matchId: string, userId: string, scorerId: string): Promise<IMatch> {
    if (!Types.ObjectId.isValid(matchId) || !Types.ObjectId.isValid(scorerId)) {
      throw ApiError.badRequest('Invalid match ID or scorer ID.');
    }

    const match = await Match.findById(matchId);
    if (!match) {
      throw ApiError.notFound(MESSAGES.MATCH.NOT_FOUND || 'Match not found.');
    }

    const canAssign = await this.canManageMatch(match, userId);
    if (!canAssign) {
      throw ApiError.forbidden('You do not have permission to assign a scorer to this match.');
    }

    const scorerUser = await User.findById(scorerId);
    if (!scorerUser) {
      throw ApiError.notFound('Scorer user account not found.');
    }

    match.scorer = new Types.ObjectId(scorerId);
    await match.save();

    const populatedMatch = await Match.findById(match._id)
      .populate('teamA', 'name logo')
      .populate('teamB', 'name logo')
      .populate('scorer', 'name avatar');

    await notifySafely([scorerId], {
      type: NotificationType.GENERAL,
      category: NotificationCategory.MATCH,
      title: 'Scorer assignment',
      body: `You were assigned as scorer for ${match.title}.`,
      data: { matchId: String(match._id), role: 'SCORER' },
      relatedEntityType: 'Match',
      relatedEntityId: String(match._id),
      dedupeKey: `match-scorer:${match._id}:${scorerId}`,
    });

    return populatedMatch as unknown as IMatch;
  }

  /**
   * Start match: Create 1st innings and transition status to LIVE
   */
  public async startMatch(matchId: string, userId: string): Promise<any> {
    if (!Types.ObjectId.isValid(matchId)) {
      throw ApiError.badRequest('Invalid match ID.');
    }

    const match = await Match.findById(matchId);
    if (!match) {
      throw ApiError.notFound(MESSAGES.MATCH.NOT_FOUND || 'Match not found.');
    }

    const canStart = await this.canManageMatch(match, userId);
    if (!canStart) {
      throw ApiError.forbidden('You do not have permission to start this match.');
    }

    if (match.status === MatchStatus.LIVE) {
      throw ApiError.badRequest('Match is already live and in progress.');
    }

    if (
      match.status === MatchStatus.COMPLETED ||
      match.status === MatchStatus.ABANDONED ||
      match.status === MatchStatus.CANCELLED
    ) {
      throw ApiError.badRequest(`Cannot start match in ${match.status} status.`);
    }

    // Check toss
    if (!match.toss || !match.toss.winner || !match.toss.decision) {
      throw ApiError.badRequest('Toss must be completed before starting the match.');
    }

    // Check Playing XI for both teams
    if (!match.playingXI_A || match.playingXI_A.length !== 11) {
      throw ApiError.badRequest('Playing XI for Team A must have 11 players before starting.');
    }
    if (!match.playingXI_B || match.playingXI_B.length !== 11) {
      throw ApiError.badRequest('Playing XI for Team B must have 11 players before starting.');
    }

    // Determine 1st Innings batting and bowling teams
    const tossWinner = match.toss.winner;
    const tossDecision = match.toss.decision;

    let battingTeam: Types.ObjectId;
    let bowlingTeam: Types.ObjectId;

    if (tossDecision === TossDecision.BAT) {
      battingTeam = tossWinner;
      bowlingTeam = tossWinner.equals(match.teamA) ? match.teamB : match.teamA;
    } else {
      bowlingTeam = tossWinner;
      battingTeam = tossWinner.equals(match.teamA) ? match.teamB : match.teamA;
    }

    // Find or create Innings 1
    let innings1 = await Innings.findOne({ match: match._id, inningsNumber: 1 });
    if (!innings1) {
      const battingOrder = battingTeam.equals(match.teamA) ? match.playingXI_A : match.playingXI_B;

      innings1 = await Innings.create({
        match: match._id,
        inningsNumber: 1,
        battingTeam,
        bowlingTeam,
        totalRuns: 0,
        totalWickets: 0,
        totalOvers: 0,
        totalBalls: 0,
        extras: {
          wides: 0,
          noBalls: 0,
          byes: 0,
          legByes: 0,
          penalties: 0,
          total: 0,
        },
        status: InningsStatus.IN_PROGRESS,
        currentOverRuns: 0,
        stateVersion: 0,
        fallOfWickets: [],
        battingOrder,
        battingStats: [],
        bowlingStats: [],
        partnerships: [],
      });
    } else if (innings1.status === InningsStatus.NOT_STARTED) {
      innings1.status = InningsStatus.IN_PROGRESS;
      await innings1.save();
    }

    match.status = MatchStatus.LIVE;
    match.currentInnings = 1;
    await match.save();

    // If tournament match, transition tournament to IN_PROGRESS if registration was closed
    if (match.tournament) {
      await Tournament.updateOne(
        { _id: match.tournament, status: TournamentStatus.REGISTRATION_CLOSED },
        { status: TournamentStatus.IN_PROGRESS }
      );
    }

    const populatedInnings = await Innings.findById(innings1._id)
      .populate('battingTeam', 'name logo')
      .populate('bowlingTeam', 'name logo');

    const populatedMatch = await Match.findById(match._id)
      .populate('teamA', 'name logo')
      .populate('teamB', 'name logo')
      .populate('scorer', 'name avatar');

    const recipients = await this.getNotificationRecipients(match._id, userId);
    await notifySafely(recipients, {
      type: NotificationType.MATCH_STARTED,
      category: NotificationCategory.MATCH,
      title: 'Match is live',
      body: `${match.title} has started. Follow the live score.`,
      data: { matchId: String(match._id), inningsId: String(innings1._id) },
      relatedEntityType: 'Match',
      relatedEntityId: String(match._id),
      dedupeKey: `match-started:${match._id}`,
    });

    return {
      match: populatedMatch,
      innings: populatedInnings,
    };
  }

  /**
   * Get all currently live matches with live score summary
   */
  public async getLiveMatches(): Promise<any[]> {
    const liveMatches = await Match.find({ status: MatchStatus.LIVE })
      .populate('teamA', 'name logo location')
      .populate('teamB', 'name logo location')
      .populate('tournament', 'name format matchFormat')
      .populate('scorer', 'name avatar')
      .sort({ updatedAt: -1 })
      .lean();

    if (liveMatches.length === 0) return [];

    const matchIds = liveMatches.map((m: any) => m._id);
    const inningsNumbers = liveMatches.map((m: any) => m.currentInnings || 1);
    const inningsList = await Innings.find({
      match: { $in: matchIds },
      inningsNumber: { $in: inningsNumbers },
    })
      .populate('battingTeam', 'name logo')
      .populate('bowlingTeam', 'name logo')
      .populate({
        path: 'currentBatters.striker',
        populate: { path: 'user', select: 'name avatar' },
      })
      .populate({
        path: 'currentBatters.nonStriker',
        populate: { path: 'user', select: 'name avatar' },
      })
      .populate({
        path: 'currentBowler',
        populate: { path: 'user', select: 'name avatar' },
      })
      .lean();

    const inningsByMatch = new Map<string, any>();
    for (const innings of inningsList as any[]) {
      inningsByMatch.set(`${String(innings.match)}:${innings.inningsNumber}`, innings);
    }

    return liveMatches.map((m: any) => ({
      ...m,
      activeInnings: inningsByMatch.get(`${String(m._id)}:${m.currentInnings || 1}`) || null,
    }));
  }

  /**
   * Get upcoming matches
   */
  public async getUpcomingMatches(): Promise<any[]> {
    const upcomingMatches = await Match.find({ status: MatchStatus.UPCOMING })
      .populate('teamA', 'name logo location')
      .populate('teamB', 'name logo location')
      .populate('tournament', 'name format matchFormat')
      .sort({ matchDate: 1 })
      .limit(100)
      .lean();

    return upcomingMatches;
  }

  /**
   * Get completed matches with results and innings summary
   */
  public async getCompletedMatches(): Promise<any[]> {
    const completedMatches = await Match.find({ status: MatchStatus.COMPLETED })
      .populate('teamA', 'name logo location')
      .populate('teamB', 'name logo location')
      .populate('tournament', 'name format matchFormat')
      .populate('result.winner', 'name logo')
      .populate({
        path: 'playerOfMatch',
        populate: { path: 'user', select: 'name avatar' },
      })
      .sort({ matchDate: -1, updatedAt: -1 })
      .limit(100)
      .lean();

    if (completedMatches.length === 0) return [];

    const matchIds = completedMatches.map((m: any) => m._id);
    const inningsList = await Innings.find({ match: { $in: matchIds } })
      .populate('battingTeam', 'name logo')
      .select('inningsNumber battingTeam totalRuns totalWickets totalOvers totalBalls extras target status match')
      .sort({ inningsNumber: 1 })
      .lean();

    const inningsByMatch = new Map<string, any[]>();
    for (const innings of inningsList as any[]) {
      const key = String(innings.match);
      const list = inningsByMatch.get(key) || [];
      list.push(innings);
      inningsByMatch.set(key, list);
    }

    return completedMatches.map((m: any) => ({
      ...m,
      innings: inningsByMatch.get(String(m._id)) || [],
    }));
  }

  /**
   * Retrieve full match scorecard from innings data
   */
  public async getMatchScorecard(matchId: string): Promise<any> {
    if (!Types.ObjectId.isValid(matchId)) {
      throw ApiError.badRequest('Invalid match ID.');
    }

    const match = await Match.findById(matchId)
      .populate('teamA', 'name logo location captain')
      .populate('teamB', 'name logo location captain')
      .populate('tournament', 'name format matchFormat ballType')
      .populate('scorer', 'name avatar')
      .populate('toss.winner', 'name logo')
      .populate('result.winner', 'name logo')
      .populate({
        path: 'playerOfMatch',
        populate: { path: 'user', select: 'name avatar' },
      })
      .lean();

    if (!match) {
      throw ApiError.notFound(MESSAGES.MATCH.NOT_FOUND || 'Match not found.');
    }

    // Fetch full innings data
    const inningsList = await Innings.find({ match: matchId })
      .populate('battingTeam', 'name logo')
      .populate('bowlingTeam', 'name logo')
      .populate({
        path: 'battingStats.player',
        populate: { path: 'user', select: 'name avatar' },
      })
      .populate({
        path: 'battingStats.dismissal.bowler',
        populate: { path: 'user', select: 'name avatar' },
      })
      .populate({
        path: 'battingStats.dismissal.fielder',
        populate: { path: 'user', select: 'name avatar' },
      })
      .populate({
        path: 'bowlingStats.player',
        populate: { path: 'user', select: 'name avatar' },
      })
      .populate({
        path: 'fallOfWickets.player',
        populate: { path: 'user', select: 'name avatar' },
      })
      .populate({
        path: 'currentBatters.striker',
        populate: { path: 'user', select: 'name avatar' },
      })
      .populate({
        path: 'currentBatters.nonStriker',
        populate: { path: 'user', select: 'name avatar' },
      })
      .populate({
        path: 'currentBowler',
        populate: { path: 'user', select: 'name avatar' },
      })
      .sort({ inningsNumber: 1 })
      .lean();

    return {
      match,
      innings: inningsList,
    };
  }
}

export const matchService = new MatchService();
export default matchService;
