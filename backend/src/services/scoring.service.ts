import { randomUUID } from 'crypto';
import mongoose, { ClientSession, Types } from 'mongoose';
import Match from '../models/Match';
import Innings from '../models/Innings';
import Delivery from '../models/Delivery';
import Player from '../models/Player';
import ScoringAudit, { ScoringAuditAction } from '../models/ScoringAudit';
import {
  ExtraType,
  InningsStatus,
  MatchStatus,
  ResultType,
  NotificationCategory,
  NotificationType,
} from '../constants/enums';
import { ApiError } from '../utils/apiError';
import { config } from '../config/env';
import { ScoringCommit } from '../sockets/types';
import matchService from './match.service';
import { notifySafely } from './notificationHooks.service';
import {
  ApplyDeliveryResult,
  CommentaryNames,
  EngineDeliveryInput,
  EngineDeliveryRecord,
  EngineInningsState,
  ScoringRules,
  applyDelivery,
  deriveInningsResult,
  isInningsComplete,
  rebuildInnings,
} from './scoringEngine';

export interface ScoringInput {
  runs?: number;
  extraType?: ExtraType;
  extraRuns?: number;
  wicket?: {
    type: string;
    batter?: string;
    fielder?: string;
    description?: string;
  };
  commentary?: string;
  batter?: string;
  nonStriker?: string;
  bowler?: string;
  expectedVersion?: number;
  idempotencyKey?: string;
  inningsNumber?: number;
}

export interface StartInningsInput extends ScoringInput {
  striker: string;
  nonStriker: string;
  bowler: string;
}

export interface ScoringStateQuery {
  inningsNumber?: number;
  limit?: number;
  order?: 'asc' | 'desc';
}

const MAX_WICKETS = 10;

const toIdString = (value: unknown): string | undefined =>
  value === undefined || value === null ? undefined : String(value);

const isSameTeam = (left: unknown, right: unknown): boolean =>
  Boolean(left && right && String(left) === String(right));

const isDuplicateKeyError = (error: unknown): boolean =>
  typeof error === 'object' && error !== null && (error as { code?: number }).code === 11000;

export class ScoringService {
  private async transaction<T>(work: (session?: ClientSession) => Promise<T>): Promise<T> {
    const session = await mongoose.connection.startSession();
    try {
      session.startTransaction();
      const result = await work(session);
      await session.commitTransaction();
      return result;
    } catch (error) {
      try { await session.abortTransaction(); } catch {}
      const msg = error instanceof Error ? error.message : String(error);
      if (/Transaction numbers are only allowed|replica set|Transaction.*not supported/i.test(msg)) {
        if (config.ALLOW_NON_TRANSACTIONAL_WRITES || config.isTest) {
          // Isolated dev/test fallback: integrity reduced without transactions.
          return work(undefined);
        }
        throw ApiError.serviceUnavailable('MongoDB replica set transactions are required for scoring integrity. Configure a replica set or set ALLOW_NON_TRANSACTIONAL_WRITES=true only for isolated development.');
      }
      throw error;
    } finally {
      session.endSession();
    }
  }

  private async notifyMatchEvent(
    matchId: string,
    input: {
      type: NotificationType;
      title: string;
      body: string;
      data?: Record<string, any>;
      dedupeKey: string;
    },
    actorId?: string
  ): Promise<void> {
    const recipients = await matchService.getNotificationRecipients(matchId, actorId);
    await notifySafely(recipients, {
      ...input,
      category: NotificationCategory.MATCH,
      relatedEntityType: 'Match',
      relatedEntityId: matchId,
    });
  }

  private async findMatch(matchId: string, session?: ClientSession): Promise<any> {
    if (!Types.ObjectId.isValid(matchId)) {
      throw ApiError.badRequest('Invalid match ID.');
    }
    const query = Match.findById(matchId);
    if (session) query.session(session);
    const match = await query;
    if (!match) throw ApiError.notFound('Match not found.');
    return match;
  }

  private async findInnings(
    matchId: string,
    inningsNumber: number,
    session?: ClientSession
  ): Promise<any> {
    const query = Innings.findOne({ match: matchId, inningsNumber });
    if (session) query.session(session);
    const innings = await query;
    if (!innings) throw ApiError.notFound(`Innings ${inningsNumber} has not been created.`);
    return innings;
  }

  private async authorize(match: any, userId?: string): Promise<void> {
    if (!userId) {
      throw ApiError.unauthorized('User is not authenticated.');
    }
    const allowed = await matchService.canManageMatch(match, userId);
    if (!allowed) {
      throw ApiError.forbidden('You do not have permission to score this match.');
    }
  }

  private rules(match: any): ScoringRules {
    return {
      ballsPerOver: Number(match.ballsPerOver) || 6,
      totalOvers: Number(match.totalOvers) || 20,
    };
  }

  private playingXI(match: any, teamId: unknown): string[] {
    return isSameTeam(teamId, match.teamA)
      ? (match.playingXI_A || []).map(String)
      : (match.playingXI_B || []).map(String);
  }

  private requireVersion(input: ScoringInput): number {
    if (input.expectedVersion === undefined || input.expectedVersion === null) {
      throw ApiError.badRequest('expectedVersion is required for scoring mutations.');
    }
    const version = Number(input.expectedVersion);
    if (!Number.isInteger(version) || version < 0) {
      throw ApiError.badRequest('expectedVersion must be a non-negative integer.');
    }
    return version;
  }

  private applyVersion(input: ScoringInput, currentVersion: number): number {
    const expected = this.requireVersion(input);
    if (expected !== Number(currentVersion)) {
      throw ApiError.conflict(
        `Scoring state changed. Expected version ${expected}, current version ${currentVersion}.`
      );
    }
    return expected;
  }

  private inningsSet(innings: any): Record<string, unknown> {
    const obj = innings.toObject ? innings.toObject() : { ...innings };
    delete obj._id; delete obj.__v; delete obj.createdAt; delete obj.updatedAt;
    return obj;
  }

  private async persistInnings(innings: any, expectedVersion: number, session?: ClientSession): Promise<void> {
    const res = await Innings.updateOne(
      { _id: innings._id, stateVersion: expectedVersion },
      { $set: this.inningsSet(innings) },
      session ? { session } : undefined
    );
    if ((res.matchedCount || 0) !== 1) {
      throw ApiError.conflict('Stale scoring state. Please sync and retry.');
    }
  }

  private assertMatchMutable(match: any, allowCompleted = false): void {
    if (allowCompleted) return;
    if ([MatchStatus.COMPLETED, MatchStatus.ABANDONED, MatchStatus.CANCELLED].includes(match.status)) {
      throw ApiError.badRequest('Scoring cannot be modified for a completed, abandoned, or cancelled match.');
    }
  }

  private requestKey(action: ScoringAuditAction, matchId: string, input: ScoringInput): string {
    return input.idempotencyKey?.trim() || `${action.toLowerCase()}:${matchId}:${randomUUID()}`;
  }

  private async existingAudit(matchId: string, input: ScoringInput, session?: ClientSession): Promise<any | null> {
    if (!input.idempotencyKey?.trim()) return null;
    const query = ScoringAudit.findOne({
      match: matchId,
      requestKey: input.idempotencyKey.trim(),
    });
    if (session) query.session(session);
    return query.lean();
  }

  private async replayOrThrow(matchId: string, input: ScoringInput, session?: ClientSession): Promise<any | null> {
    const existing = await this.existingAudit(matchId, input, session);
    if (!existing) return null;
    return this.getState(matchId);
  }

  private async writeAudit(
    action: ScoringAuditAction,
    match: any,
    innings: any,
    userId: string,
    key: string,
    sequenceNumber: number | undefined,
    stateVersion: number,
    payload: Record<string, unknown>,
    result: Record<string, unknown>,
    session?: ClientSession
  ): Promise<void> {
    const doc = {
      match: match._id,
      innings: innings._id,
      action,
      actor: new Types.ObjectId(userId),
      requestKey: key,
      sequenceNumber,
      stateVersion,
      payload,
      result,
    };
    if (session) await ScoringAudit.create([doc], { session });
    else await ScoringAudit.create(doc as any);
  }

  private async playerNames(
    ids: string[],
    session?: ClientSession
  ): Promise<Record<string, string>> {
    const uniqueIds = [...new Set(ids.filter(Boolean))];
    if (uniqueIds.length === 0) return {};
    const query = Player.find({ _id: { $in: uniqueIds } }).populate('user', 'name');
    if (session) query.session(session);
    const players = await query.lean();
    const names: Record<string, string> = {};
    players.forEach((player: any) => {
      const id = String(player._id);
      names[id] = String(player.user?.name || id);
    });
    uniqueIds.forEach((id) => {
      if (!names[id]) names[id] = id;
    });
    return names;
  }

  private engineState(innings: any, match: any): EngineInningsState {
    const extras = innings.extras || {};
    return {
      battingTeam: String(innings.battingTeam),
      bowlingTeam: String(innings.bowlingTeam),
      battingOrder: (innings.battingOrder || []).map(String),
      bowlingOrder: this.playingXI(match, innings.bowlingTeam),
      totalRuns: Number(innings.totalRuns) || 0,
      totalWickets: Number(innings.totalWickets) || 0,
      totalBalls: Number(innings.totalBalls) || 0,
      extras: {
        wides: Number(extras.wides) || 0,
        noBalls: Number(extras.noBalls) || 0,
        byes: Number(extras.byes) || 0,
        legByes: Number(extras.legByes) || 0,
        penalties: Number(extras.penalties) || 0,
        total: Number(extras.total) || 0,
      },
      currentBatters: {
        striker: toIdString(innings.currentBatters?.striker),
        nonStriker: toIdString(innings.currentBatters?.nonStriker),
      },
      currentBowler: toIdString(innings.currentBowler),
      lastOverBowler: toIdString(innings.lastOverBowler),
      currentOverRuns: Number(innings.currentOverRuns) || 0,
      stateVersion: Number(innings.stateVersion) || 0,
      target: innings.target === undefined || innings.target === null ? undefined : Number(innings.target),
      status: innings.status as InningsStatus,
      fallOfWickets: (innings.fallOfWickets || []).map((item: any) => ({
        player: String(item.player),
        runs: Number(item.runs) || 0,
        balls: Number(item.balls) || 0,
        teamScore: Number(item.teamScore) || 0,
        teamOvers: String(item.teamOvers || '0.0'),
        wicketNumber: Number(item.wicketNumber) || 0,
      })),
      battingStats: (innings.battingStats || []).map((item: any) => ({
        player: String(item.player),
        runs: Number(item.runs) || 0,
        balls: Number(item.balls) || 0,
        fours: Number(item.fours) || 0,
        sixes: Number(item.sixes) || 0,
        strikeRate: Number(item.strikeRate) || 0,
        isNotOut: item.isNotOut !== false,
        position: item.position === undefined ? undefined : Number(item.position),
        dismissal: item.dismissal
          ? {
              type: item.dismissal.type,
              bowler: toIdString(item.dismissal.bowler),
              fielder: toIdString(item.dismissal.fielder),
              description: item.dismissal.description,
            }
          : undefined,
      })),
      bowlingStats: (innings.bowlingStats || []).map((item: any) => ({
        player: String(item.player),
        overs: Number(item.overs) || 0,
        balls: Number(item.balls) || 0,
        maidens: Number(item.maidens) || 0,
        runs: Number(item.runs) || 0,
        wickets: Number(item.wickets) || 0,
        economy: Number(item.economy) || 0,
        wides: Number(item.wides) || 0,
        noBalls: Number(item.noBalls) || 0,
        dotBalls: Number(item.dotBalls) || 0,
      })),
      partnerships: (innings.partnerships || []).map((item: any) => ({
        batter1: String(item.batter1),
        batter2: String(item.batter2),
        runs: Number(item.runs) || 0,
        balls: Number(item.balls) || 0,
        isActive: item.isActive !== false,
      })),
    };
  }

  private stateToInnings(
    innings: any,
    state: EngineInningsState,
    rules: ScoringRules
  ): void {
    innings.totalRuns = state.totalRuns;
    innings.totalWickets = state.totalWickets;
    innings.totalBalls = state.totalBalls;
    innings.totalOvers = Number((state.totalBalls / rules.ballsPerOver).toFixed(2));
    innings.extras = { ...state.extras };
    innings.currentBatters = {
      striker: state.currentBatters.striker ? new Types.ObjectId(state.currentBatters.striker) : undefined,
      nonStriker: state.currentBatters.nonStriker
        ? new Types.ObjectId(state.currentBatters.nonStriker)
        : undefined,
    };
    innings.currentBowler = state.currentBowler ? new Types.ObjectId(state.currentBowler) : undefined;
    innings.lastOverBowler = state.lastOverBowler
      ? new Types.ObjectId(state.lastOverBowler)
      : undefined;
    innings.currentOverRuns = state.currentOverRuns;
    innings.stateVersion = state.stateVersion;
    innings.fallOfWickets = state.fallOfWickets;
    innings.battingStats = state.battingStats;
    innings.bowlingStats = state.bowlingStats;
    innings.partnerships = state.partnerships;
    innings.status = state.status;
  }

  private deliveryRecord(delivery: any): EngineDeliveryRecord | null {
    if (delivery.isUndone || !delivery.wicket?.type) {
      const base = {
        sequenceNumber: Number(delivery.sequenceNumber),
        batter: String(delivery.batter),
        nonStriker: String(delivery.nonStriker),
        bowler: String(delivery.bowler),
        runs: {
          batter: Number(delivery.runs?.batter) || 0,
          extras: Number(delivery.runs?.extras) || 0,
          total: Number(delivery.runs?.total) || 0,
        },
        extras: {
          type: delivery.extras?.type || ExtraType.NONE,
          runs: Number(delivery.extras?.runs) || 0,
        },
        isLegal: delivery.isLegal !== false,
        isWicket: delivery.isWicket === true,
        commentary: delivery.commentary,
      };
      if (delivery.isUndone) return null;
      return base;
    }

    return {
      sequenceNumber: Number(delivery.sequenceNumber),
      batter: String(delivery.batter),
      nonStriker: String(delivery.nonStriker),
      bowler: String(delivery.bowler),
      runs: {
        batter: Number(delivery.runs?.batter) || 0,
        extras: Number(delivery.runs?.extras) || 0,
        total: Number(delivery.runs?.total) || 0,
      },
      extras: {
        type: delivery.extras?.type || ExtraType.NONE,
        runs: Number(delivery.extras?.runs) || 0,
      },
      isLegal: delivery.isLegal !== false,
      isWicket: delivery.isWicket === true,
      wicket: {
        type: delivery.wicket.type,
        batter: toIdString(delivery.wicket.batter),
        fielder: toIdString(delivery.wicket.fielder),
        isStriker: delivery.wicket.isStriker !== false,
      },
      commentary: delivery.commentary,
    };
  }

  private async activeDeliveries(
    inningsId: Types.ObjectId,
    session?: ClientSession
  ): Promise<EngineDeliveryRecord[]> {
    const query = Delivery.find({ innings: inningsId, isUndone: false }).sort({ sequenceNumber: 1 });
    if (session) query.session(session);
    const deliveries = await query.lean();
    return deliveries
      .map((delivery) => this.deliveryRecord(delivery))
      .filter((delivery): delivery is EngineDeliveryRecord => Boolean(delivery));
  }

  private async nextSequence(inningsId: Types.ObjectId, session?: ClientSession): Promise<number> {
    const query = Innings.findByIdAndUpdate(
      inningsId,
      { $inc: { nextSequence: 1 } },
      { new: false }
    ).select('nextSequence');
    if (session) query.session(session);
    const doc = await query.lean();
    const next = Number((doc as any)?.nextSequence || 1);
    return next;
  }

  private commentaryNames(
    names: Record<string, string>,
    striker?: string,
    nonStriker?: string,
    bowler?: string,
    fielder?: string
  ): CommentaryNames {
    return {
      striker: striker ? names[striker] || striker : 'Striker',
      nonStriker: nonStriker ? names[nonStriker] || nonStriker : 'Non-striker',
      bowler: bowler ? names[bowler] || bowler : 'Bowler',
      fielder: fielder ? names[fielder] || fielder : undefined,
    };
  }

  private deliveryInput(
    input: ScoringInput,
    state: EngineInningsState
  ): EngineDeliveryInput {
    return {
      runs: Number(input.runs) || 0,
      extraType: input.extraType || ExtraType.NONE,
      extraRuns: Number(input.extraRuns) || 0,
      batter: input.batter || state.currentBatters.striker || '',
      nonStriker: input.nonStriker || state.currentBatters.nonStriker || '',
      bowler: input.bowler || state.currentBowler || '',
      wicket: input.wicket
        ? {
            type: input.wicket.type as never,
            batter: input.wicket.batter,
            fielder: input.wicket.fielder,
            description: input.wicket.description,
          }
        : undefined,
      commentary: input.commentary,
    };
  }

  private async finalizeInnings(
    match: any,
    innings: any,
    state: EngineInningsState,
    expectedVersion: number,
    session?: ClientSession
  ): Promise<void> {
    const rules = this.rules(match);
    state.status = InningsStatus.COMPLETED;
    this.stateToInnings(innings, state, rules);
    innings.stateVersion = Number(state.stateVersion) || ((Number(expectedVersion) || 0) + 1);
    await this.persistInnings(innings, expectedVersion, session);

    if (Number(innings.inningsNumber) === 1) {
      let second = await (session ? (Innings.findOne({ match: match._id, inningsNumber: 2 })).session(session) : (Innings.findOne({ match: match._id, inningsNumber: 2 })));
      if (!second) {
        second = new Innings({
          match: match._id,
          inningsNumber: 2,
          battingTeam: innings.bowlingTeam,
          bowlingTeam: innings.battingTeam,
          target: state.totalRuns + 1,
          status: InningsStatus.NOT_STARTED,
          currentOverRuns: 0,
          stateVersion: 0,
          totalRuns: 0,
          totalWickets: 0,
          totalBalls: 0,
          totalOvers: 0,
          extras: {
            wides: 0,
            noBalls: 0,
            byes: 0,
            legByes: 0,
            penalties: 0,
            total: 0,
          },
          fallOfWickets: [],
          battingOrder: this.playingXI(match, innings.bowlingTeam),
          battingStats: [],
          bowlingStats: [],
          partnerships: [],
        });
        await (session ? second.save({ session }) : second.save());
      }
      match.currentInnings = 2;
      match.status = MatchStatus.LIVE;
    } else {
      const first = await (session ? (Innings.findOne({ match: match._id, inningsNumber: 1 })).session(session) : (Innings.findOne({ match: match._id, inningsNumber: 1 })));
      const firstRuns = Number(first?.totalRuns) || 0;
      const derived = deriveInningsResult(state, rules, firstRuns);
      const resultType = derived.resultType as ResultType;
      match.result = {
        winner: derived.winner ? new Types.ObjectId(derived.winner) : undefined,
        resultType,
        margin: derived.margin,
        description: derived.description,
      };
      match.status = MatchStatus.COMPLETED;
      match.currentInnings = 2;
    }

    await (session ? match.save({ session }) : match.save());
  }

  private async revertCompletion(match: any, innings: any, session?: ClientSession): Promise<void> {
    if (
      innings.status !== InningsStatus.COMPLETED &&
      innings.status !== InningsStatus.DECLARED
    ) {
      return;
    }

    if (Number(innings.inningsNumber) === 1) {
      const second = await (session ? Innings.findOne({ match: match._id, inningsNumber: 2 }).session(session) : Innings.findOne({ match: match._id, inningsNumber: 2 }));
      if (second) {
        const secondDeliveries = await (session ? Delivery.countDocuments({ innings: second._id }).session(session) : Delivery.countDocuments({ innings: second._id }));
        if (secondDeliveries > 0) {
          throw ApiError.conflict('Cannot undo/correct a completed first innings after second innings deliveries exist. Undo second innings deliveries first.');
        }
        await (session ? Innings.deleteOne({ _id: second._id }).session(session) : Innings.deleteOne({ _id: second._id }));
      }
    }

    innings.status = InningsStatus.IN_PROGRESS;
    match.status = MatchStatus.LIVE;
    match.currentInnings = Number(innings.inningsNumber);
    match.result = undefined;
  }

  private async rebuildFromDeliveries(
    innings: any,
    match: any,
    session?: ClientSession
  ): Promise<EngineInningsState> {
    const base = this.engineState(innings, match);
    const deliveries = await this.activeDeliveries(innings._id, session);
    const rebuilt = rebuildInnings(base, deliveries, this.rules(match));
    rebuilt.stateVersion = Number(innings.stateVersion) + 1;
    return rebuilt;
  }

  private populatedInningsQuery(matchId: string) {
    return Innings.find({ match: matchId })
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
      .sort({ inningsNumber: 1 });
  }

  private populatedDeliveryQuery(matchId: string, limit: number, order: 'asc' | 'desc') {
    return Delivery.find({ match: matchId, isUndone: false })
      .populate({
        path: 'batter',
        populate: { path: 'user', select: 'name avatar' },
      })
      .populate({
        path: 'nonStriker',
        populate: { path: 'user', select: 'name avatar' },
      })
      .populate({
        path: 'bowler',
        populate: { path: 'user', select: 'name avatar' },
      })
      .populate('wicket.batter')
      .populate('wicket.fielder')
      .sort({ sequenceNumber: order === 'asc' ? 1 : -1 })
      .limit(limit);
  }

  public async getState(matchId: string, query: ScoringStateQuery = {}): Promise<any> {
    const match = await Match.findById(matchId)
      .populate('teamA', 'name logo shortName')
      .populate('teamB', 'name logo shortName')
      .populate('toss.winner', 'name logo')
      .populate('result.winner', 'name logo')
      .lean();
    if (!match) throw ApiError.notFound('Match not found.');

    const innings = await this.populatedInningsQuery(matchId).lean();
    const limit = Math.min(100, Math.max(1, Number(query.limit) || 30));
    const order = query.order === 'asc' ? 'asc' : 'desc';
    const deliveries = await this.populatedDeliveryQuery(matchId, limit, order).lean();
    const activeInnings = innings.find(
      (item: any) => Number(item.inningsNumber) === Number(match.currentInnings)
    );

    return {
      match,
      innings,
      activeInnings,
      deliveries,
      commentary: deliveries,
      result: match.result,
    };
  }

  public async getInnings(matchId: string, inningsNumber: number): Promise<any> {
    const innings = await this.populatedInningsQuery(matchId)
      .find({ inningsNumber })
      .lean();
    if (!innings.length) throw ApiError.notFound(`Innings ${inningsNumber} has not been created.`);
    return innings[0];
  }

  public async getCommentary(
    matchId: string,
    limit = 50,
    order: 'asc' | 'desc' = 'desc'
  ): Promise<any[]> {
    return this.populatedDeliveryQuery(matchId, Math.min(100, limit), order).lean();
  }

  public async startInnings(
    matchId: string,
    userId: string,
    input: StartInningsInput
  ): Promise<any> {
    const inningsNumber = Number(input.inningsNumber) || 1;
    let commit: ScoringCommit | undefined;
    try {
      commit = await this.transaction(async (session) => {
        const match = await this.findMatch(matchId, session);
        await this.authorize(match, userId);
        const replay = await this.replayOrThrow(matchId, input, session);
        if (replay) return undefined as any;
        this.assertMatchMutable(match);
        const innings = await this.findInnings(matchId, inningsNumber, session);
        const expectedVersion = this.applyVersion(input, Number(innings.stateVersion) || 0);

        if (innings.status === InningsStatus.COMPLETED) {
          throw ApiError.badRequest('This innings is already completed.');
        }
        if (innings.totalBalls > 0 || (innings.currentBowler && innings.currentBatters?.striker)) {
          throw ApiError.badRequest('This innings has already been started.');
        }

        const battingXI = this.playingXI(match, innings.battingTeam);
        const bowlingXI = this.playingXI(match, innings.bowlingTeam);
        if (!battingXI.includes(input.striker) || !battingXI.includes(input.nonStriker)) {
          throw ApiError.badRequest('Both openers must be in the batting Playing XI.');
        }
        if (input.striker === input.nonStriker) {
          throw ApiError.badRequest('Openers must be different players.');
        }
        if (!bowlingXI.includes(input.bowler)) {
          throw ApiError.badRequest('Bowler must be in the bowling Playing XI.');
        }

        innings.currentBatters = {
          striker: new Types.ObjectId(input.striker),
          nonStriker: new Types.ObjectId(input.nonStriker),
        };
        innings.currentBowler = new Types.ObjectId(input.bowler);
        innings.currentOverRuns = 0;
        innings.status = InningsStatus.IN_PROGRESS;
        innings.stateVersion = (Number(innings.stateVersion) || 0) + 1;
        match.currentInnings = inningsNumber;
        match.status = MatchStatus.LIVE;
        await this.persistInnings(innings, expectedVersion, session);
        await (session ? match.save({ session }) : match.save());

        const key = this.requestKey(ScoringAuditAction.START_INNINGS, matchId, input);
        await this.writeAudit(
          ScoringAuditAction.START_INNINGS,
          match,
          innings,
          userId,
          key,
          undefined,
          innings.stateVersion,
          { ...input },
          { stateVersion: innings.stateVersion, inningsNumber },
          session
        );

        return {
          committed: true,
          matchId,
          kind: 'START_INNINGS',
          action: ScoringAuditAction.START_INNINGS,
          requestKey: key,
          stateVersion: Number(innings.stateVersion),
          inningsNumber,
          actorId: userId,
        } as ScoringCommit;
      });
    } catch (error) {
      if (isDuplicateKeyError(error)) {
        const replay = await this.existingAudit(matchId, input);
        if (replay) return this.getState(matchId);
      }
      throw error;
    }
    if (!commit) return this.getState(matchId);

    await this.notifyMatchEvent(
      matchId,
      {
        type: NotificationType.MATCH_INNINGS_STARTED,
        title: 'Innings started',
        body: `Innings ${commit.inningsNumber} has started.`,
        data: { matchId, inningsNumber: commit.inningsNumber, stateVersion: commit.stateVersion },
        dedupeKey: `match-innings-started:${matchId}:${commit.requestKey}`,
      },
      userId
    );

    return { ...(await this.getState(matchId)), commit };
  }

  public async recordBall(
    matchId: string,
    userId: string,
    input: ScoringInput
  ): Promise<any> {
    let deliveryId = '';
    let commit: ScoringCommit | undefined;
    try {
      commit = await this.transaction(async (session) => {
        const match = await this.findMatch(matchId, session);
        await this.authorize(match, userId);
        const replay = await this.replayOrThrow(matchId, input, session);
        if (replay) return undefined as any;
        this.assertMatchMutable(match);
        const inningsNumber = Number(match.currentInnings) || 1;
        const innings = await this.findInnings(matchId, inningsNumber, session);
        const expectedVersion = this.applyVersion(input, Number(innings.stateVersion) || 0);

        const rules = this.rules(match);
        const state = this.engineState(innings, match);
        if (state.status !== InningsStatus.IN_PROGRESS) {
          throw ApiError.badRequest('Start the innings before recording deliveries.');
        }
        const deliveryInput = this.deliveryInput(input, state);
        const battingXI = this.playingXI(match, innings.battingTeam);
        const bowlingXI = this.playingXI(match, innings.bowlingTeam);
        if (!battingXI.includes(deliveryInput.batter) || !battingXI.includes(deliveryInput.nonStriker)) {
          throw ApiError.badRequest('Batter and non-striker must be in the batting team playing XI.');
        }
        if (!bowlingXI.includes(deliveryInput.bowler)) {
          throw ApiError.badRequest('Bowler must be in the bowling team playing XI.');
        }
        if (deliveryInput.wicket?.fielder && !bowlingXI.includes(String(deliveryInput.wicket.fielder))) {
          throw ApiError.badRequest('Fielder must be in the bowling team playing XI.');
        }
        if (deliveryInput.wicket?.batter && ![deliveryInput.batter, deliveryInput.nonStriker].includes(String(deliveryInput.wicket.batter))) {
          throw ApiError.badRequest('Dismissed batter must be the striker or non-striker.');
        }
        const names = await this.playerNames(
          [
            deliveryInput.batter,
            deliveryInput.nonStriker,
            deliveryInput.bowler,
            deliveryInput.wicket?.fielder || '',
          ],
          session
        );
        const applied = applyDelivery(
          state,
          deliveryInput,
          rules,
          this.commentaryNames(
            names,
            deliveryInput.batter,
            deliveryInput.nonStriker,
            deliveryInput.bowler,
            deliveryInput.wicket?.fielder
          )
        );

        const sequenceNumber = await this.nextSequence(innings._id, session);
        const delivery = new Delivery({
          innings: innings._id,
          match: match._id,
          overNumber: Math.floor(state.totalBalls / rules.ballsPerOver),
          ballNumber: (state.totalBalls % rules.ballsPerOver) + 1,
          sequenceNumber,
          idempotencyKey: input.idempotencyKey?.trim(),
          batter: new Types.ObjectId(deliveryInput.batter),
          bowler: new Types.ObjectId(deliveryInput.bowler),
          nonStriker: new Types.ObjectId(deliveryInput.nonStriker),
          runs: {
            batter: applied.totals.batterRuns,
            extras: applied.totals.extras.total,
            total: applied.totals.totalRuns,
          },
          extras: {
            type: deliveryInput.extraType,
            runs: applied.totals.extras.total,
          },
          isLegal: applied.isLegal,
          wicket: applied.isWicket && deliveryInput.wicket
            ? {
                type: deliveryInput.wicket.type,
                batter: new Types.ObjectId(
                  deliveryInput.wicket.batter || deliveryInput.batter
                ),
                fielder: deliveryInput.wicket.fielder
                  ? new Types.ObjectId(deliveryInput.wicket.fielder)
                  : undefined,
                isStriker: sameBatterAsStriker(deliveryInput, state),
              }
            : undefined,
          isWicket: applied.isWicket,
          isBoundary: applied.isBoundary,
          isSix: applied.isSix,
          commentary: applied.commentary,
          isUndone: false,
        });
        await (session ? delivery.save({ session }) : delivery.save());
        deliveryId = String(delivery._id);

        applied.state.stateVersion = (Number(innings.stateVersion) || 0) + 1;
        if (isInningsComplete(applied.state, rules)) {
          await this.finalizeInnings(match, innings, applied.state, expectedVersion, session);
        } else {
          this.stateToInnings(innings, applied.state, rules);
          await this.persistInnings(innings, expectedVersion, session);
          await (session ? match.save({ session }) : match.save());
        }

        const key = this.requestKey(ScoringAuditAction.BALL, matchId, input);
        await this.writeAudit(
          ScoringAuditAction.BALL,
          match,
          innings,
          userId,
          key,
          sequenceNumber,
          applied.state.stateVersion,
          { ...input },
          { deliveryId, stateVersion: applied.state.stateVersion },
          session
        );

        return {
          committed: true,
          matchId,
          kind: 'BALL',
          action: ScoringAuditAction.BALL,
          requestKey: key,
          stateVersion: Number(applied.state.stateVersion),
          inningsNumber,
          actorId: userId,
          deliveryId,
          overCompleted: Boolean(applied.overCompleted),
          isWicket: Boolean(applied.isWicket),
        } as ScoringCommit;
      });
    } catch (error) {
      if (isDuplicateKeyError(error)) {
        const replay = await this.existingAudit(matchId, input);
        if (replay) return this.getState(matchId);
      }
      throw error;
    }
    if (!commit) return this.getState(matchId);

    const state = await this.getState(matchId);
    const score = state.activeInnings
      ? `${state.activeInnings.totalRuns ?? 0}/${state.activeInnings.totalWickets ?? 0} after ${state.activeInnings.totalOvers ?? 0} overs`
      : 'Score updated';

    await this.notifyMatchEvent(
      matchId,
      {
        type: NotificationType.MATCH_SCORE_UPDATE,
        title: 'Live score update',
        body: `${state.match?.title || 'Match'}: ${score}.`,
        data: {
          matchId,
          deliveryId,
          inningsNumber: commit.inningsNumber,
          stateVersion: commit.stateVersion,
        },
        dedupeKey: `match-score:${matchId}:${commit.requestKey}`,
      },
      userId
    );

    if (commit.isWicket) {
      await this.notifyMatchEvent(
        matchId,
        {
          type: NotificationType.MATCH_WICKET,
          title: 'Wicket!',
          body: `${state.match?.title || 'Match'}: a wicket has fallen. ${score}.`,
          data: { matchId, deliveryId, inningsNumber: commit.inningsNumber },
          dedupeKey: `match-wicket:${matchId}:${commit.requestKey}`,
        },
        userId
      );
    }

    if (commit.overCompleted) {
      await this.notifyMatchEvent(
        matchId,
        {
          type: NotificationType.MATCH_OVER_COMPLETED,
          title: 'Over completed',
          body: `${state.match?.title || 'Match'}: ${score}.`,
          data: { matchId, inningsNumber: commit.inningsNumber, stateVersion: commit.stateVersion },
          dedupeKey: `match-over:${matchId}:${commit.requestKey}`,
        },
        userId
      );
    }

    return { ...state, deliveryId, commit };
  }

  public async undo(matchId: string, userId: string, input: ScoringInput): Promise<any> {
    let commit: ScoringCommit | undefined;
    try {
      commit = await this.transaction(async (session) => {
        const match = await this.findMatch(matchId, session);
        await this.authorize(match, userId);
        const replay = await this.replayOrThrow(matchId, input, session);
        if (replay) return undefined as any;
        this.assertMatchMutable(match);
        const inningsNumber = Number(match.currentInnings) || 1;
        const innings = await this.findInnings(matchId, inningsNumber, session);
        const expectedVersion = this.applyVersion(input, Number(innings.stateVersion) || 0);

        const last = await (session ? (Delivery.findOne({ innings: innings._id, isUndone: false })
          .sort({ sequenceNumber: -1 })
          ).session(session) : (Delivery.findOne({ innings: innings._id, isUndone: false })
          .sort({ sequenceNumber: -1 })
          ));
        if (!last) throw ApiError.badRequest('There is no delivery to undo.');

        await this.revertCompletion(match, innings, session);
        last.isUndone = true;
        await (session ? last.save({ session }) : last.save());

        const rebuilt = await this.rebuildFromDeliveries(innings, match, session);
        rebuilt.stateVersion = (Number(innings.stateVersion) || 0) + 1;
        this.stateToInnings(innings, rebuilt, this.rules(match));
        await this.persistInnings(innings, expectedVersion, session);

        if (isInningsComplete(rebuilt, this.rules(match))) {
          await this.finalizeInnings(match, innings, rebuilt, expectedVersion, session);
        } else {
          await (session ? match.save({ session }) : match.save());
        }

        const key = this.requestKey(ScoringAuditAction.UNDO, matchId, input);
        await this.writeAudit(
          ScoringAuditAction.UNDO,
          match,
          innings,
          userId,
          key,
          Number(last.sequenceNumber),
          rebuilt.stateVersion,
          { ...input },
          { undoneDeliveryId: String(last._id), stateVersion: rebuilt.stateVersion },
          session
        );

        return {
          committed: true,
          matchId,
          kind: 'UNDO',
          action: ScoringAuditAction.UNDO,
          requestKey: key,
          stateVersion: Number(rebuilt.stateVersion),
          inningsNumber,
          actorId: userId,
          undoneDeliveryId: String(last._id),
        } as ScoringCommit;
      });
    } catch (error) {
      if (isDuplicateKeyError(error)) {
        const replay = await this.existingAudit(matchId, input);
        if (replay) return this.getState(matchId);
      }
      throw error;
    }

    return { ...(await this.getState(matchId)), commit };
  }

  public async correctBall(
    matchId: string,
    deliveryId: string,
    userId: string,
    input: ScoringInput
  ): Promise<any> {
    if (!Types.ObjectId.isValid(deliveryId)) {
      throw ApiError.badRequest('Invalid delivery ID.');
    }

    let commit: ScoringCommit | undefined;
    try {
      commit = await this.transaction(async (session) => {
        const match = await this.findMatch(matchId, session);
        await this.authorize(match, userId);
        const replay = await this.replayOrThrow(matchId, input, session);
        if (replay) return undefined as any;
        this.assertMatchMutable(match);
        const target = await (session ? (Delivery.findOne({ _id: deliveryId, match: match._id })).session(session) : (Delivery.findOne({ _id: deliveryId, match: match._id })));
        if (!target) throw ApiError.notFound('Delivery not found for this match.');
        if (target.isUndone) throw ApiError.badRequest('This delivery has already been undone or corrected.');
        const innings = await (session ? (Innings.findById(target.innings)).session(session) : (Innings.findById(target.innings)));
        if (!innings) throw ApiError.notFound('Innings for this delivery was not found.');
        const activeInnings = await this.findInnings(
          matchId,
          Number(match.currentInnings) || 1,
          session
        );
        if (String(innings._id) !== String(activeInnings._id)) {
          throw ApiError.badRequest('Only deliveries from the current innings can be corrected.');
        }
        const expectedVersion = this.applyVersion(input, Number(innings.stateVersion) || 0);

        await this.revertCompletion(match, innings, session);
        target.isUndone = true;
        await (session ? target.save({ session }) : target.save());

        const rules = this.rules(match);
        const priorQuery = Delivery.find({
          innings: innings._id,
          isUndone: false,
          sequenceNumber: { $lt: Number(target.sequenceNumber) },
        }).sort({ sequenceNumber: 1 });
        if (session) priorQuery.session(session);
        const priorDeliveries = await priorQuery.lean();
        const priorState = rebuildInnings(
          this.engineState(innings, match),
          priorDeliveries
            .map((delivery) => this.deliveryRecord(delivery))
            .filter((delivery): delivery is EngineDeliveryRecord => Boolean(delivery)),
          rules
        );
        priorState.currentBatters = {
          striker: String(target.batter),
          nonStriker: String(target.nonStriker),
        };
        priorState.currentBowler = String(target.bowler);
        priorState.status = InningsStatus.IN_PROGRESS;

        const deliveryInput = this.deliveryInput(input, priorState);
        const battingXI = this.playingXI(match, innings.battingTeam);
        const bowlingXI = this.playingXI(match, innings.bowlingTeam);
        if (!battingXI.includes(deliveryInput.batter) || !battingXI.includes(deliveryInput.nonStriker)) {
          throw ApiError.badRequest('Batter and non-striker must be in the batting team playing XI.');
        }
        if (deliveryInput.batter === deliveryInput.nonStriker) {
          throw ApiError.badRequest('Batter and non-striker must be different players.');
        }
        if (!bowlingXI.includes(deliveryInput.bowler)) {
          throw ApiError.badRequest('Bowler must be in the bowling team playing XI.');
        }
        if (deliveryInput.wicket?.fielder && !bowlingXI.includes(String(deliveryInput.wicket.fielder))) {
          throw ApiError.badRequest('Fielder must be in the bowling team playing XI.');
        }
        if (deliveryInput.wicket?.batter && ![deliveryInput.batter, deliveryInput.nonStriker].includes(String(deliveryInput.wicket.batter))) {
          throw ApiError.badRequest('Dismissed batter must be the striker or non-striker.');
        }
        const names = await this.playerNames(
          [
            deliveryInput.batter,
            deliveryInput.nonStriker,
            deliveryInput.bowler,
            deliveryInput.wicket?.fielder || '',
          ],
          session
        );
        const applied = applyDelivery(
          priorState,
          deliveryInput,
          rules,
          this.commentaryNames(
            names,
            deliveryInput.batter,
            deliveryInput.nonStriker,
            deliveryInput.bowler,
            deliveryInput.wicket?.fielder
          )
        );

        const corrected = new Delivery({
          innings: innings._id,
          match: match._id,
          overNumber: Number(target.overNumber),
          ballNumber: Number(target.ballNumber),
          sequenceNumber: Number(target.sequenceNumber),
          idempotencyKey: input.idempotencyKey?.trim(),
          batter: new Types.ObjectId(deliveryInput.batter),
          bowler: new Types.ObjectId(deliveryInput.bowler),
          nonStriker: new Types.ObjectId(deliveryInput.nonStriker),
          runs: {
            batter: applied.totals.batterRuns,
            extras: applied.totals.extras.total,
            total: applied.totals.totalRuns,
          },
          extras: {
            type: deliveryInput.extraType,
            runs: applied.totals.extras.total,
          },
          isLegal: applied.isLegal,
          wicket: applied.isWicket && deliveryInput.wicket
            ? {
                type: deliveryInput.wicket.type,
                batter: new Types.ObjectId(deliveryInput.wicket.batter || deliveryInput.batter),
                fielder: deliveryInput.wicket.fielder
                  ? new Types.ObjectId(deliveryInput.wicket.fielder)
                  : undefined,
                isStriker:
                  String(deliveryInput.wicket.batter || deliveryInput.batter) === String(priorState.currentBatters.striker),
              }
            : undefined,
          isWicket: applied.isWicket,
          isBoundary: applied.isBoundary,
          isSix: applied.isSix,
          commentary: applied.commentary,
          isUndone: false,
        });
        await (session ? corrected.save({ session }) : corrected.save());
        target.correctedBy = corrected._id;
        await (session ? target.save({ session }) : target.save());

        const rebuilt = await this.rebuildFromDeliveries(innings, match, session);
        rebuilt.stateVersion = (Number(innings.stateVersion) || 0) + 1;
        this.stateToInnings(innings, rebuilt, rules);
        if (isInningsComplete(rebuilt, rules)) {
          await this.finalizeInnings(match, innings, rebuilt, expectedVersion, session);
        } else {
          await this.persistInnings(innings, expectedVersion, session);
          await (session ? match.save({ session }) : match.save());
        }

        const key = this.requestKey(ScoringAuditAction.CORRECT, matchId, input);
        await this.writeAudit(
          ScoringAuditAction.CORRECT,
          match,
          innings,
          userId,
          key,
          Number(target.sequenceNumber),
          rebuilt.stateVersion,
          { ...input, deliveryId },
          { correctedDeliveryId: String(corrected._id), stateVersion: rebuilt.stateVersion },
          session
        );

        return {
          committed: true,
          matchId,
          kind: 'CORRECT',
          action: ScoringAuditAction.CORRECT,
          requestKey: key,
          stateVersion: Number(rebuilt.stateVersion),
          inningsNumber: Number(activeInnings.inningsNumber),
          actorId: userId,
          correctedDeliveryId: String(corrected._id),
          overCompleted: Boolean(applied.overCompleted),
          isWicket: Boolean(applied.isWicket),
        } as ScoringCommit;
      });
    } catch (error) {
      if (isDuplicateKeyError(error)) {
        const replay = await this.existingAudit(matchId, input);
        if (replay) return this.getState(matchId);
      }
      throw error;
    }
    if (!commit) return this.getState(matchId);

    await this.notifyMatchEvent(
      matchId,
      {
        type: NotificationType.MATCH_SCORE_UPDATE,
        title: 'Score corrected',
        body: `A scoring correction was applied to innings ${commit.inningsNumber}.`,
        data: { matchId, deliveryId: commit.correctedDeliveryId, stateVersion: commit.stateVersion },
        dedupeKey: `match-score-corrected:${matchId}:${commit.requestKey}`,
      },
      userId
    );

    return { ...(await this.getState(matchId)), commit };
  }

  public async endInnings(
    matchId: string,
    userId: string,
    input: ScoringInput
  ): Promise<any> {
    let commit: ScoringCommit | undefined;
    try {
      commit = await this.transaction(async (session) => {
        const match = await this.findMatch(matchId, session);
        await this.authorize(match, userId);
        const replay = await this.replayOrThrow(matchId, input, session);
        if (replay) return undefined as any;
        this.assertMatchMutable(match);
        const inningsNumber = Number(input.inningsNumber) || Number(match.currentInnings) || 1;
        const innings = await this.findInnings(matchId, inningsNumber, session);
        const expectedVersion = this.applyVersion(input, Number(innings.stateVersion) || 0);
        if (innings.status !== InningsStatus.IN_PROGRESS) {
          throw ApiError.badRequest('Only an in-progress innings can be ended.');
        }

        const state = this.engineState(innings, match);
        state.status = InningsStatus.COMPLETED;
        state.stateVersion = (Number(innings.stateVersion) || 0) + 1;
        await this.finalizeInnings(match, innings, state, expectedVersion, session);

        const key = this.requestKey(ScoringAuditAction.INNINGS_END, matchId, input);
        await this.writeAudit(
          ScoringAuditAction.INNINGS_END,
          match,
          innings,
          userId,
          key,
          undefined,
          state.stateVersion,
          { ...input },
          { inningsNumber, stateVersion: state.stateVersion },
          session
        );

        return {
          committed: true,
          matchId,
          kind: 'INNINGS_END',
          action: ScoringAuditAction.INNINGS_END,
          requestKey: key,
          stateVersion: Number(state.stateVersion),
          inningsNumber,
          actorId: userId,
        } as ScoringCommit;
      });
    } catch (error) {
      if (isDuplicateKeyError(error)) {
        const replay = await this.existingAudit(matchId, input);
        if (replay) return this.getState(matchId);
      }
      throw error;
    }
    if (!commit) return this.getState(matchId);

    await this.notifyMatchEvent(
      matchId,
      {
        type: NotificationType.MATCH_INNINGS_ENDED,
        title: 'Innings completed',
        body: `Innings ${commit.inningsNumber} has ended.`,
        data: { matchId, inningsNumber: commit.inningsNumber, stateVersion: commit.stateVersion },
        dedupeKey: `match-innings-ended:${matchId}:${commit.requestKey}`,
      },
      userId
    );

    return { ...(await this.getState(matchId)), commit };
  }

  public async completeMatch(
    matchId: string,
    userId: string,
    input: ScoringInput & {
      resultType?: string;
      winner?: string;
      margin?: number;
      description?: string;
      playerOfMatch?: string;
    }
  ): Promise<any> {
    let commit: ScoringCommit | undefined;
    try {
      commit = await this.transaction(async (session) => {
        const match = await this.findMatch(matchId, session);
        await this.authorize(match, userId);
        const replay = await this.replayOrThrow(matchId, input, session);
        if (replay) return undefined as any;
        if ([MatchStatus.ABANDONED, MatchStatus.CANCELLED].includes(match.status)) {
          throw ApiError.badRequest('Cannot complete an abandoned or cancelled match through scoring.');
        }
        if (match.status === MatchStatus.COMPLETED) {
          throw ApiError.badRequest('Match is already completed.');
        }
        const activeInnings = await this.findInnings(
          matchId,
          Number(match.currentInnings) || 1,
          session
        );
        const expectedVersion = this.applyVersion(input, Number(activeInnings.stateVersion) || 0);

        const first = await this.findInnings(matchId, 1, session);
        const derived = deriveInningsResult(
          this.engineState(activeInnings, match),
          this.rules(match),
          Number(first.totalRuns) || 0
        );
        let resultType = (input.resultType as ResultType | undefined) || (derived.resultType as ResultType);
        let winner = input.winner !== undefined ? input.winner : derived.winner;
        let margin = input.margin !== undefined ? input.margin : derived.margin;
        let description = input.description || derived.description;

        if (winner && ![String(match.teamA), String(match.teamB)].includes(String(winner))) {
          throw ApiError.badRequest('Winner must be one of the match teams.');
        }
        if (resultType === ResultType.TIE || resultType === ResultType.NO_RESULT || resultType === ResultType.DRAW) {
          winner = undefined;
          margin = 0;
        }
        if (input.playerOfMatch) {
          const allowed = new Set([...(match.playingXI_A || []), ...(match.playingXI_B || [])].map(String));
          if (!allowed.has(String(input.playerOfMatch))) {
            throw ApiError.badRequest('Player of match must belong to the match playing XI.');
          }
        }

        const nextStateVersion = (Number(activeInnings.stateVersion) || 0) + 1;
        match.result = {
          winner: winner ? new Types.ObjectId(winner) : undefined,
          resultType,
          margin: margin ?? 0,
          description: description || 'Match result recorded.',
        };
        if (input.playerOfMatch) {
          match.playerOfMatch = new Types.ObjectId(input.playerOfMatch);
        }
        match.status = MatchStatus.COMPLETED;
        activeInnings.stateVersion = nextStateVersion;
        await this.persistInnings(activeInnings, expectedVersion, session);
        await (session ? match.save({ session }) : match.save());

        const key = this.requestKey(ScoringAuditAction.MATCH_COMPLETE, matchId, input);
        await this.writeAudit(
          ScoringAuditAction.MATCH_COMPLETE,
          match,
          activeInnings,
          userId,
          key,
          undefined,
          nextStateVersion,
          { ...input },
          { result: match.result, stateVersion: nextStateVersion },
          session
        );

        return {
          committed: true,
          matchId,
          kind: 'MATCH_COMPLETE',
          action: ScoringAuditAction.MATCH_COMPLETE,
          requestKey: key,
          stateVersion: nextStateVersion,
          inningsNumber: Number(match.currentInnings) || 1,
          actorId: userId,
        } as ScoringCommit;
      });
    } catch (error) {
      if (isDuplicateKeyError(error)) {
        const replay = await this.existingAudit(matchId, input);
        if (replay) return this.getState(matchId);
      }
      throw error;
    }
    if (!commit) return this.getState(matchId);

    const finalState = await this.getState(matchId);
    await this.notifyMatchEvent(
      matchId,
      {
        type: NotificationType.MATCH_RESULT,
        title: 'Match completed',
        body: `${finalState.match?.title || 'Match'} is complete. ${finalState.result?.description || 'Result recorded.'}`,
        data: {
          matchId,
          result: finalState.result,
          stateVersion: commit.stateVersion,
        },
        dedupeKey: `match-result:${matchId}:${commit.requestKey}`,
      },
      userId
    );

    return { ...finalState, commit };
  }
}

const sameBatterAsStriker = (
  input: EngineDeliveryInput,
  state: EngineInningsState
): boolean => {
  const dismissed = input.wicket?.batter || state.currentBatters.striker;
  return Boolean(dismissed && dismissed === state.currentBatters.striker);
};

export const scoringService = new ScoringService();
export default scoringService;
