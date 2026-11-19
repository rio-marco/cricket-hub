import mongoose, { Types } from 'mongoose';
import Player, { IPlayer } from '../models/Player';
import User from '../models/User';
import TeamMember from '../models/TeamMember';
import Team from '../models/Team';
import Match from '../models/Match';
import Innings from '../models/Innings';
import { ApiError } from '../utils/apiError';
import { MESSAGES } from '../constants/messages';
import {
  PlayingRole,
  BattingStyle,
  BowlingStyle,
  TeamMemberStatus,
  DismissalType,
} from '../constants/enums';
import { UserRole } from '../constants/roles';
import { getPaginationParams, IPaginationMeta, buildPaginationResponse } from '../utils/pagination';

export interface ICreatePlayerData {
  playingRole: PlayingRole;
  battingStyle: BattingStyle;
  bowlingStyle?: BowlingStyle;
  jerseyNumber?: number;
  dateOfBirth?: Date | string;
  city?: string;
  bio?: string;
}

export interface IUpdatePlayerData {
  playingRole?: PlayingRole;
  battingStyle?: BattingStyle;
  bowlingStyle?: BowlingStyle;
  jerseyNumber?: number | null;
  dateOfBirth?: Date | string | null;
  city?: string;
  bio?: string;
}

export interface IPaginatedResult<T> {
  data: T[];
  pagination: IPaginationMeta;
}

export class PlayerService {
  /**
   * Create a new player profile linked to authenticated user and update user role
   */
  public async createPlayer(
    userId: string | Types.ObjectId,
    data: ICreatePlayerData
  ): Promise<any> {
    const userObjId = new Types.ObjectId(userId.toString());

    // Check if player profile already exists
    const existingPlayer = await Player.findOne({ user: userObjId });
    if (existingPlayer) {
      throw ApiError.conflict(MESSAGES.PLAYER.ALREADY_EXISTS || 'Player profile already exists for this user.');
    }

    const player = await Player.create({
      user: userObjId,
      playingRole: data.playingRole,
      battingStyle: data.battingStyle,
      bowlingStyle: data.bowlingStyle || BowlingStyle.NONE,
      jerseyNumber: data.jerseyNumber !== undefined ? data.jerseyNumber : undefined,
      dateOfBirth: data.dateOfBirth ? new Date(data.dateOfBirth) : undefined,
      city: data.city?.trim(),
      bio: data.bio?.trim(),
    });

    // Upgrade user role if currently NORMAL_USER
    const user = await User.findById(userId);
    if (user && user.role === UserRole.NORMAL_USER) {
      user.role = UserRole.PLAYER;
      await user.save();
    }

    return Player.findById(player._id)
      .populate('user', 'name email phone avatar role')
      .lean();
  }

  /**
   * Get paginated list of players with filters and user search
   */
  public async getPlayers(
    query: Record<string, any> = {}
  ): Promise<IPaginatedResult<any>> {
    const { page, limit, skip, sort } = getPaginationParams(query, 10, 100, '-createdAt');

    const filter: Record<string, any> = {};

    if (query.playingRole) {
      filter.playingRole = query.playingRole;
    }

    if (query.battingStyle) {
      filter.battingStyle = query.battingStyle;
    }

    if (query.bowlingStyle) {
      filter.bowlingStyle = query.bowlingStyle;
    }

    if (query.city) {
      filter.city = new RegExp(String(query.city).trim(), 'i');
    }

    // Text search matching user name or player city/bio
    if (query.search) {
      const searchRegex = new RegExp(String(query.search).trim(), 'i');
      const matchingUsers = await User.find({ name: searchRegex }).select('_id').lean();
      const userIds = matchingUsers.map((u) => u._id);

      filter.$or = [
        { user: { $in: userIds } },
        { city: searchRegex },
        { bio: searchRegex },
      ];
    }

    const [players, total] = await Promise.all([
      Player.find(filter)
        .sort(sort as any)
        .skip(skip)
        .limit(limit)
        .populate('user', 'name email phone avatar')
        .lean(),
      Player.countDocuments(filter),
    ]);

    return {
      data: players,
      pagination: buildPaginationResponse(total, page, limit),
    };
  }

  /**
   * Get single player by ID with user details and current/past teams
   */
  public async getPlayerById(id: string | Types.ObjectId): Promise<any> {
    if (!mongoose.Types.ObjectId.isValid(id.toString())) {
      throw ApiError.badRequest('Invalid player ID format.');
    }

    const player = await Player.findById(id)
      .populate('user', 'name email phone avatar role isBlocked')
      .lean();

    if (!player) {
      throw ApiError.notFound(MESSAGES.PLAYER.NOT_FOUND || 'Player profile not found.');
    }

    // Retrieve teams history
    const memberships = await TeamMember.find({ player: id })
      .populate('team', 'name logo location owner isActive')
      .sort('-joinedAt')
      .lean();

    return {
      ...player,
      teams: memberships,
    };
  }

  /**
   * Update player profile. Only profile owner is authorized.
   */
  public async updatePlayer(
    playerId: string | Types.ObjectId,
    userId: string | Types.ObjectId,
    data: IUpdatePlayerData
  ): Promise<any> {
    if (!mongoose.Types.ObjectId.isValid(playerId.toString())) {
      throw ApiError.badRequest('Invalid player ID format.');
    }

    const player = await Player.findById(playerId);
    if (!player) {
      throw ApiError.notFound(MESSAGES.PLAYER.NOT_FOUND || 'Player profile not found.');
    }

    if (player.user.toString() !== userId.toString()) {
      throw ApiError.forbidden(MESSAGES.AUTH.FORBIDDEN || 'You are not authorized to edit this player profile.');
    }

    if (data.playingRole !== undefined) player.playingRole = data.playingRole;
    if (data.battingStyle !== undefined) player.battingStyle = data.battingStyle;
    if (data.bowlingStyle !== undefined) player.bowlingStyle = data.bowlingStyle;
    if (data.jerseyNumber !== undefined) player.jerseyNumber = data.jerseyNumber === null ? undefined : data.jerseyNumber;
    if (data.dateOfBirth !== undefined) {
      player.dateOfBirth = data.dateOfBirth ? new Date(data.dateOfBirth) : undefined;
    }
    if (data.city !== undefined) player.city = data.city.trim();
    if (data.bio !== undefined) player.bio = data.bio.trim();

    await player.save();

    return Player.findById(player._id)
      .populate('user', 'name email phone avatar')
      .lean();
  }

  /**
   * Soft delete player profile and inactivate team memberships
   */
  public async deletePlayer(
    playerId: string | Types.ObjectId,
    userId: string | Types.ObjectId
  ): Promise<{ playerId: string; deleted: boolean }> {
    if (!mongoose.Types.ObjectId.isValid(playerId.toString())) {
      throw ApiError.badRequest('Invalid player ID format.');
    }

    const player = await Player.findById(playerId);
    if (!player) {
      throw ApiError.notFound(MESSAGES.PLAYER.NOT_FOUND || 'Player profile not found.');
    }

    if (player.user.toString() !== userId.toString()) {
      throw ApiError.forbidden(MESSAGES.AUTH.FORBIDDEN || 'You are not authorized to delete this player profile.');
    }

    // Inactivate team memberships and remove captaincy from active teams
    await TeamMember.updateMany(
      { player: player._id, status: TeamMemberStatus.ACTIVE },
      { status: TeamMemberStatus.INACTIVE }
    );

    await Team.updateMany(
      { captain: player._id },
      { $unset: { captain: 1 } }
    );
    await Team.updateMany(
      { viceCaptain: player._id },
      { $unset: { viceCaptain: 1 } }
    );
    await Team.updateMany(
      { wicketkeeper: player._id },
      { $unset: { wicketkeeper: 1 } }
    );

    // Soft delete: clear bio and mark profile inactive via strict false property
    player.set('isDeleted', true, { strict: false });
    await player.save();

    return {
      playerId: player._id.toString(),
      deleted: true,
    };
  }

  /**
   * Calculate detailed career statistics (batting, bowling, fielding) from match innings
   */
  public async getPlayerStats(playerId: string | Types.ObjectId): Promise<any> {
    if (!mongoose.Types.ObjectId.isValid(playerId.toString())) {
      throw ApiError.badRequest('Invalid player ID format.');
    }

    const player = await Player.findById(playerId);
    if (!player) {
      throw ApiError.notFound(MESSAGES.PLAYER.NOT_FOUND || 'Player profile not found.');
    }

    const playerObjId = new Types.ObjectId(playerId.toString());

    // Fetch innings containing this player's batting, bowling, or fielding stats
    const [battingInnings, bowlingInnings, fieldingInnings, matchAppearances, playerOfMatchCount] =
      await Promise.all([
        Innings.find({ 'battingStats.player': playerObjId }).lean(),
        Innings.find({ 'bowlingStats.player': playerObjId }).lean(),
        Innings.find({ 'battingStats.dismissal.fielder': playerObjId }).lean(),
        Match.countDocuments({
          $or: [
            { playingXI_A: playerObjId },
            { playingXI_B: playerObjId },
            { substitutes_A: playerObjId },
            { substitutes_B: playerObjId },
          ],
        }),
        Match.countDocuments({ playerOfMatch: playerObjId }),
      ]);

    // Batting aggregation
    let inningsBatted = 0;
    let runsScored = 0;
    let ballsFaced = 0;
    let fours = 0;
    let sixes = 0;
    let notOuts = 0;
    let highestScore = 0;
    let highestScoreNotOut = false;
    let fifties = 0;
    let hundreds = 0;
    let ducks = 0;

    battingInnings.forEach((inn) => {
      const bat = inn.battingStats?.find(
        (b) => b.player && b.player.toString() === playerObjId.toString()
      );
      if (bat) {
        inningsBatted++;
        const runs = bat.runs || 0;
        runsScored += runs;
        ballsFaced += bat.balls || 0;
        fours += bat.fours || 0;
        sixes += bat.sixes || 0;

        if (bat.isNotOut) {
          notOuts++;
        }

        if (runs === 0 && !bat.isNotOut) {
          ducks++;
        }

        if (runs >= 100) {
          hundreds++;
        } else if (runs >= 50) {
          fifties++;
        }

        if (runs > highestScore) {
          highestScore = runs;
          highestScoreNotOut = Boolean(bat.isNotOut);
        } else if (runs === highestScore && bat.isNotOut) {
          highestScoreNotOut = true;
        }
      }
    });

    const dismissals = inningsBatted - notOuts;
    const battingAverage =
      dismissals > 0
        ? Number((runsScored / dismissals).toFixed(2))
        : runsScored > 0
        ? runsScored
        : 0;

    const battingStrikeRate =
      ballsFaced > 0 ? Number(((runsScored / ballsFaced) * 100).toFixed(2)) : 0;

    // Bowling aggregation
    let inningsBowled = 0;
    let oversBowled = 0;
    let ballsBowled = 0;
    let maidens = 0;
    let runsConceded = 0;
    let wickets = 0;
    let dotBalls = 0;
    let wides = 0;
    let noBalls = 0;
    let fourWicketHauls = 0;
    let fiveWicketHauls = 0;
    let bestBowlingWickets = -1;
    let bestBowlingRuns = Number.MAX_SAFE_INTEGER;

    bowlingInnings.forEach((inn) => {
      const bowl = inn.bowlingStats?.find(
        (b) => b.player && b.player.toString() === playerObjId.toString()
      );
      if (bowl) {
        inningsBowled++;
        oversBowled += bowl.overs || 0;
        ballsBowled += bowl.balls || 0;
        maidens += bowl.maidens || 0;
        const runs = bowl.runs || 0;
        const wkts = bowl.wickets || 0;
        runsConceded += runs;
        wickets += wkts;
        dotBalls += bowl.dotBalls || 0;
        wides += bowl.wides || 0;
        noBalls += bowl.noBalls || 0;

        if (wkts >= 5) {
          fiveWicketHauls++;
        } else if (wkts === 4) {
          fourWicketHauls++;
        }

        if (
          wkts > bestBowlingWickets ||
          (wkts === bestBowlingWickets && runs < bestBowlingRuns)
        ) {
          bestBowlingWickets = wkts;
          bestBowlingRuns = runs;
        }
      }
    });

    const bowlingAverage =
      wickets > 0 ? Number((runsConceded / wickets).toFixed(2)) : 0;

    const totalOversDec = ballsBowled > 0 ? ballsBowled / 6 : 0;
    const bowlingEconomy =
      totalOversDec > 0 ? Number((runsConceded / totalOversDec).toFixed(2)) : 0;

    const bowlingStrikeRate =
      wickets > 0 ? Number((ballsBowled / wickets).toFixed(2)) : 0;

    const bestBowlingFigure =
      bestBowlingWickets >= 0
        ? `${bestBowlingWickets}/${bestBowlingRuns === Number.MAX_SAFE_INTEGER ? 0 : bestBowlingRuns}`
        : '-';

    // Fielding aggregation
    let catches = 0;
    let runOuts = 0;
    let stumpings = 0;

    fieldingInnings.forEach((inn) => {
      inn.battingStats?.forEach((bat) => {
        if (
          bat.dismissal?.fielder &&
          bat.dismissal.fielder.toString() === playerObjId.toString()
        ) {
          if (bat.dismissal.type === DismissalType.CAUGHT) {
            catches++;
          } else if (bat.dismissal.type === DismissalType.RUN_OUT) {
            runOuts++;
          } else if (bat.dismissal.type === DismissalType.STUMPED) {
            stumpings++;
          }
        }
      });
    });

    return {
      matches: matchAppearances,
      playerOfMatch: playerOfMatchCount,
      batting: {
        innings: inningsBatted,
        runs: runsScored,
        balls: ballsFaced,
        fours,
        sixes,
        notOuts,
        highestScore: `${highestScore}${highestScoreNotOut ? '*' : ''}`,
        fifties,
        hundreds,
        ducks,
        average: battingAverage,
        strikeRate: battingStrikeRate,
      },
      bowling: {
        innings: inningsBowled,
        overs: oversBowled,
        balls: ballsBowled,
        maidens,
        runsConceded,
        wickets,
        dotBalls,
        wides,
        noBalls,
        average: bowlingAverage,
        economy: bowlingEconomy,
        strikeRate: bowlingStrikeRate,
        bestBowling: bestBowlingFigure,
        fourWicketHauls,
        fiveWicketHauls,
      },
      fielding: {
        catches,
        runOuts,
        stumpings,
        totalDismissals: catches + runOuts + stumpings,
      },
    };
  }

  /**
   * Retrieve current and past teams for a player
   */
  public async getPlayerTeams(playerId: string | Types.ObjectId): Promise<any> {
    if (!mongoose.Types.ObjectId.isValid(playerId.toString())) {
      throw ApiError.badRequest('Invalid player ID format.');
    }

    const player = await Player.findById(playerId);
    if (!player) {
      throw ApiError.notFound(MESSAGES.PLAYER.NOT_FOUND || 'Player profile not found.');
    }

    const memberships = await TeamMember.find({ player: playerId })
      .populate('team', 'name logo location owner isActive')
      .sort('-joinedAt')
      .lean();

    const activeTeams = memberships.filter((m) => m.status === TeamMemberStatus.ACTIVE);
    const pastTeams = memberships.filter((m) => m.status === TeamMemberStatus.INACTIVE);

    return {
      total: memberships.length,
      activeTeams,
      pastTeams,
      all: memberships,
    };
  }

  /**
   * Retrieve paginated match appearances for a player
   */
  public async getPlayerMatches(
    playerId: string | Types.ObjectId,
    query: Record<string, any> = {}
  ): Promise<IPaginatedResult<any>> {
    if (!mongoose.Types.ObjectId.isValid(playerId.toString())) {
      throw ApiError.badRequest('Invalid player ID format.');
    }

    const player = await Player.findById(playerId);
    if (!player) {
      throw ApiError.notFound(MESSAGES.PLAYER.NOT_FOUND || 'Player profile not found.');
    }

    const { page, limit, skip, sort } = getPaginationParams(query, 10, 50, '-matchDate');
    const playerObjId = new Types.ObjectId(playerId.toString());

    const filter: Record<string, any> = {
      $or: [
        { playingXI_A: playerObjId },
        { playingXI_B: playerObjId },
        { substitutes_A: playerObjId },
        { substitutes_B: playerObjId },
      ],
    };

    if (query.status) {
      filter.status = query.status;
    }

    const [matches, total] = await Promise.all([
      Match.find(filter)
        .sort(sort as any)
        .skip(skip)
        .limit(limit)
        .populate('teamA', 'name logo location')
        .populate('teamB', 'name logo location')
        .populate('tournament', 'name')
        .populate('result.winner', 'name logo')
        .populate({
          path: 'playerOfMatch',
          populate: { path: 'user', select: 'name avatar' },
        })
        .lean(),
      Match.countDocuments(filter),
    ]);

    return {
      data: matches,
      pagination: buildPaginationResponse(total, page, limit),
    };
  }

  /**
   * Search players by name, role, bowling style, or city
   */
  public async searchPlayers(query: Record<string, any> = {}): Promise<IPaginatedResult<any>> {
    return this.getPlayers(query);
  }
}

export const playerService = new PlayerService();
export default playerService;
