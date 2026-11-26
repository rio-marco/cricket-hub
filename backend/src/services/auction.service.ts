import { randomUUID } from 'crypto';
import mongoose, { ClientSession, Types } from 'mongoose';
import Auction, { IAuction } from '../models/Auction';
import AuctionPlayer from '../models/AuctionPlayer';
import AuctionBid from '../models/AuctionBid';
import AuctionTeam from '../models/AuctionTeam';
import AuctionAudit from '../models/AuctionAudit';
import Team from '../models/Team';
import Tournament from '../models/Tournament';
import User from '../models/User';
import Player from '../models/Player';
import {
  AuctionAuditAction,
  AuctionBidDecision,
  AuctionPlayerStatus,
  AuctionStatus,
} from '../constants/enums';
import { UserRole } from '../constants/roles';
import { MESSAGES } from '../constants/messages';
import { ApiError } from '../utils/apiError';
import { getPaginationParams, IPaginationMeta } from '../utils/pagination';

export interface AuctionInput {
  name: string;
  tournament?: string;
  teams?: string[];
  purseAmount: number;
  basePrice?: number;
  minBidIncrement?: number;
  maxSquadSize?: number;
  minSquadSize?: number;
  playerCategories?: string[];
  rules?: Record<string, unknown>;
  status?: AuctionStatus;
  idempotencyKey?: string;
}

export interface AuctionRegistrationInput {
  playerId: string;
  basePrice?: number;
  category?: string;
  set?: number;
  order?: number;
}

export interface AuctionBidInput {
  team?: string;
  amount?: number;
  expectedVersion?: number;
  idempotencyKey?: string;
}

export interface AuctionDecisionInput {
  accept: boolean;
  reason?: string;
  expectedVersion?: number;
  idempotencyKey?: string;
}

export interface AuctionCommit {
  committed: true;
  auctionId: string;
  kind: AuctionAuditAction;
  action: string;
  requestKey: string;
  stateVersion: number;
  actorId: string;
  auctionPlayerId?: string;
  bidId?: string;
  teamId?: string;
  amount?: number;
  sequenceNumber?: number;
  decision?: AuctionBidDecision;
}

export interface AuctionStateResult {
  auction: any;
  currentPlayer: any;
  players: any[];
  bids: any[];
  teams: any[];
  counts: Record<string, number>;
  results: { sold: any[]; unsold: any[] };
  stateVersion: number;
  permissions?: Record<string, unknown>;
  commit?: AuctionCommit;
}

export interface AuctionListResult {
  data: any[];
  pagination: IPaginationMeta;
}

const escapeRegExp = (value: string): string => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const idString = (value: unknown): string | undefined =>
  value === undefined || value === null ? undefined : String(value);

const isSameId = (left: unknown, right: unknown): boolean =>
  Boolean(left && right && String(left) === String(right));

const isDuplicateKeyError = (error: unknown): boolean =>
  typeof error === 'object' && error !== null && (error as { code?: number }).code === 11000;

const isRetryableTransactionError = (error: unknown): boolean => {
  const code = typeof error === 'object' && error !== null ? (error as { code?: number }).code : undefined;
  const message =
    typeof error === 'object' && error !== null ? String((error as { message?: string }).message || '') : '';
  return (
    code === 112 ||
    code === 91 ||
    code === 189 ||
    /write conflict|transaction.*committed|transient transaction|please retry/i.test(message)
  );
};

const objectId = (value: unknown, label: string): Types.ObjectId => {
  const text = String(value || '');
  if (!Types.ObjectId.isValid(text)) {
    throw ApiError.badRequest(`Invalid ${label}.`);
  }
  return new Types.ObjectId(text);
};

const requestKeyFor = (action: AuctionAuditAction, auctionId: string, input?: { idempotencyKey?: string }): string =>
  input?.idempotencyKey?.trim() || `${action.toLowerCase()}:${auctionId}:${randomUUID()}`;

export class AuctionService {
  private async transaction<T>(work: (session: ClientSession) => Promise<T>): Promise<T> {
    let lastError: unknown;
    for (let attempt = 0; attempt < 3; attempt += 1) {
      const session = await mongoose.connection.startSession();
      session.startTransaction();
      try {
        const result = await work(session);
        await session.commitTransaction();
        return result;
      } catch (error) {
        lastError = error;
        try {
          await session.abortTransaction();
        } catch {
          lastError = error;
        }
        if (!isRetryableTransactionError(error) || attempt === 2) {
          throw error;
        }
      } finally {
        session.endSession();
      }
    }
    throw lastError;
  }

  private async findAuction(auctionId: string, session?: ClientSession): Promise<any> {
    const query = Auction.findById(objectId(auctionId, 'auction ID'));
    if (session) query.session(session);
    const auction = await query;
    if (!auction) throw ApiError.notFound(MESSAGES.AUCTION.NOT_FOUND);
    return auction;
  }

  private async findAuctionPlayer(auctionPlayerId: string, session?: ClientSession): Promise<any> {
    const query = AuctionPlayer.findById(objectId(auctionPlayerId, 'auction player ID'));
    if (session) query.session(session);
    const player = await query;
    if (!player) throw ApiError.notFound('Auction player not found.');
    return player;
  }

  private async findAuctionTeam(
    auctionId: string,
    teamId: string,
    session?: ClientSession
  ): Promise<any> {
    const query = AuctionTeam.findOne({ auction: auctionId, team: teamId });
    if (session) query.session(session);
    const team = await query;
    if (!team) throw ApiError.badRequest('Team is not registered in this auction.');
    return team;
  }

  private applyVersion(input: { expectedVersion?: number }, currentVersion: number): void {
    if (input.expectedVersion !== undefined && Number(input.expectedVersion) !== currentVersion) {
      throw ApiError.conflict(
        `Auction state changed. Expected version ${input.expectedVersion}, current version ${currentVersion}.`
      );
    }
  }

  private async existingAudit(auctionId: string, key?: string): Promise<any | null> {
    if (!key) return null;
    return AuctionAudit.findOne({ auction: auctionId, requestKey: key }).lean();
  }

  private async writeAudit(
    action: AuctionAuditAction,
    auctionId: string,
    actorId: string,
    requestKey: string,
    stateVersion: number,
    payload: Record<string, unknown>,
    result: Record<string, unknown>,
    session: ClientSession,
    auctionPlayerId?: string,
    sequenceNumber?: number
  ): Promise<void> {
    await AuctionAudit.create(
      [
        {
          auction: objectId(auctionId, 'auction ID'),
          auctionPlayer: auctionPlayerId ? objectId(auctionPlayerId, 'auction player ID') : undefined,
          action,
          actor: objectId(actorId, 'user ID'),
          requestKey,
          sequenceNumber,
          stateVersion,
          payload,
          result,
        },
      ],
      { session, ordered: true }
    );
  }

  private async touchAuction(auction: any, session: ClientSession): Promise<number> {
    const expectedVersion = Number(auction.stateVersion) || 0;
    const result = await Auction.updateOne(
      { _id: auction._id, stateVersion: expectedVersion },
      { $inc: { stateVersion: 1 } },
      { session }
    );
    if (result.matchedCount !== 1) {
      throw ApiError.conflict('Auction state changed. Reload the auction and retry.');
    }
    auction.stateVersion = expectedVersion + 1;
    return auction.stateVersion;
  }

  private commit(
    auctionId: string,
    kind: AuctionAuditAction,
    action: string,
    actorId: string,
    requestKey: string,
    stateVersion: number,
    extra: Partial<AuctionCommit> = {}
  ): AuctionCommit {
    return {
      committed: true,
      auctionId,
      kind,
      action,
      requestKey,
      stateVersion,
      actorId,
      ...extra,
    };
  }

  private async result(
    auctionId: string,
    commit?: AuctionCommit,
    userId?: string,
    session?: ClientSession
  ): Promise<AuctionStateResult> {
    const state = await this.getState(auctionId, userId, {}, session);
    return commit ? { ...state, commit } : state;
  }

  public async getAuctionAccess(auction: any, userId: string): Promise<{
    canView: boolean;
    canManage: boolean;
    canBid: boolean;
    ownedTeamIds: string[];
  }> {
    const [user, tournament, ownedTeams] = await Promise.all([
      User.findById(userId).select('role'),
      auction.tournament ? Tournament.findById(auction.tournament).select('organizer') : Promise.resolve(null),
      Team.find({ _id: { $in: auction.teams || [] }, owner: userId }).select('_id'),
    ]);
    const isAdmin = user?.role === UserRole.ADMIN;
    const isOrganizer =
      isSameId(auction.createdBy, userId) ||
      Boolean(tournament && isSameId((tournament as any).organizer, userId));
    const ownedTeamIds = ownedTeams.map((team) => String(team._id));
    return {
      canView: true,
      canManage: isAdmin || isOrganizer,
      canBid: ownedTeamIds.length > 0,
      ownedTeamIds,
    };
  }

  private async requireManage(auction: any, userId?: string): Promise<void> {
    if (!userId) throw ApiError.unauthorized('User is not authenticated.');
    const access = await this.getAuctionAccess(auction, userId);
    if (!access.canManage) {
      throw ApiError.forbidden('You do not have permission to manage this auction.');
    }
  }

  private async validateTeams(teamIds: string[]): Promise<void> {
    const uniqueIds = [...new Set(teamIds.map((id) => String(id)))];
    if (uniqueIds.length < 2) {
      throw ApiError.badRequest('An auction requires at least two participating teams.');
    }
    const count = await Team.countDocuments({ _id: { $in: uniqueIds } });
    if (count !== uniqueIds.length) {
      throw ApiError.badRequest('One or more participating teams do not exist.');
    }
  }

  private async validateTournament(tournamentId?: string): Promise<void> {
    if (!tournamentId) return;
    const tournament = await Tournament.findById(objectId(tournamentId, 'tournament ID'));
    if (!tournament) throw ApiError.badRequest('Tournament does not exist.');
  }

  private nextPlayerQuery(auction: any): Record<string, unknown> {
    const currentOrder = typeof auction.currentPlayerOrder === 'number' ? auction.currentPlayerOrder : 0;
    return {
      auction: auction._id,
      status: AuctionPlayerStatus.AVAILABLE,
      available: true,
      $or: [{ order: { $gt: currentOrder } }, { order: { $exists: false } }],
    };
  }

  private async chooseFirstPlayer(auction: any, session: ClientSession): Promise<any | null> {
    const query = AuctionPlayer.find({
      auction: auction._id,
      status: AuctionPlayerStatus.AVAILABLE,
      available: true,
    })
      .sort({ set: 1, order: 1, createdAt: 1 })
      .limit(1);
    query.session(session);
    return query.findOne();
  }

  private async releaseCurrentBid(auction: any, session: ClientSession): Promise<void> {
    if (!auction.currentPlayer) return;
    const current = await this.findAuctionPlayer(String(auction.currentPlayer), session);
    if (current.highestBidder && current.currentBid > 0) {
      await AuctionTeam.updateOne(
        { auction: auction._id, team: current.highestBidder },
        { $inc: { pendingCommitment: -Number(current.currentBid) } },
        { session }
      );
    }
    current.currentBid = 0;
    current.highestBidder = undefined;
    current.decision = AuctionBidDecision.PENDING;
    current.version = Number(current.version || 0) + 1;
    await current.save({ session });
  }

  public async createAuction(userId: string, data: AuctionInput): Promise<any> {
    const teamIds = (data.teams || []).map(String);
    await this.validateTeams(teamIds);
    await this.validateTournament(data.tournament);
    if (data.minSquadSize && data.maxSquadSize && data.minSquadSize > data.maxSquadSize) {
      throw ApiError.badRequest('Minimum squad size cannot exceed maximum squad size.');
    }

    const key = requestKeyFor(AuctionAuditAction.CREATE, 'pending', data);
    return this.transaction(async (session) => {
      const auction = await Auction.create(
        [
          {
            name: data.name.trim(),
            tournament: data.tournament ? objectId(data.tournament, 'tournament ID') : undefined,
            teams: teamIds.map((id) => objectId(id, 'team ID')),
            purseAmount: Number(data.purseAmount),
            basePrice: Number(data.basePrice || 0),
            minBidIncrement: Number(data.minBidIncrement || 1),
            maxSquadSize: Number(data.maxSquadSize || 25),
            minSquadSize: Number(data.minSquadSize || 11),
            playerCategories: data.playerCategories || [],
            rules: data.rules || {},
            status: data.status === AuctionStatus.UPCOMING ? AuctionStatus.UPCOMING : AuctionStatus.DRAFT,
            stateVersion: 0,
            nextSequence: 1,
            createdBy: objectId(userId, 'user ID'),
          },
        ],
        { session, ordered: true }
      );
      const created = auction[0];
      await AuctionTeam.create(
        teamIds.map((teamId) => ({
          auction: created._id,
          team: objectId(teamId, 'team ID'),
          initialBudget: Number(data.purseAmount),
          spent: 0,
          pendingCommitment: 0,
          playersPurchased: 0,
          })),
        { session, ordered: true }
      );
      await this.writeAudit(
        AuctionAuditAction.CREATE,
        String(created._id),
        userId,
        `${key}:${String(created._id)}`,
        0,
        { name: data.name, teams: teamIds, purseAmount: data.purseAmount },
        { auctionId: String(created._id) },
        session
      );
      return this.result(String(created._id), undefined, userId, session);
    });
  }

  public async listAuctions(query: Record<string, any> = {}): Promise<AuctionListResult> {
    const { page, limit, skip, sort } = getPaginationParams(query, 10, 100, '-createdAt');
    const filter: Record<string, any> = {};
    if (query.status) {
      filter.status = String(query.status)
        .split(',')
        .map((value) => value.trim())
        .filter(Boolean);
    }
    if (query.tournament) filter.tournament = objectId(query.tournament, 'tournament filter');
    if (query.team) filter.teams = objectId(query.team, 'team filter');
    if (query.createdBy) filter.createdBy = objectId(query.createdBy, 'creator filter');
    if (query.search) filter.name = new RegExp(escapeRegExp(String(query.search).trim()), 'i');

    const [items, total] = await Promise.all([
      Auction.find(filter)
        .populate('tournament', 'name')
        .populate('teams', 'name')
        .sort(sort as any)
        .skip(skip)
        .limit(limit)
        .lean(),
      Auction.countDocuments(filter),
    ]);
    const counts = await AuctionPlayer.aggregate([
      { $match: { auction: { $in: items.map((item: any) => item._id) } } },
      { $group: { _id: '$auction', total: { $sum: 1 }, sold: { $sum: { $cond: [{ $eq: ['$status', 'SOLD'] }, 1, 0] } } } },
    ]);
    const countMap = new Map(counts.map((item: any) => [String(item._id), item]));
    const data = items.map((item: any) => ({
      ...item,
      playerCount: Number(countMap.get(String(item._id))?.total || 0),
      soldCount: Number(countMap.get(String(item._id))?.sold || 0),
    }));
    return { data, pagination: { page, limit, total, totalPages: Math.ceil(total / limit) || 1, hasNextPage: page * limit < total, hasPrevPage: page > 1 } };
  }

  public async getAuctionById(auctionId: string, userId?: string): Promise<AuctionStateResult> {
    return this.getState(auctionId, userId);
  }

  public async getState(
    auctionId: string,
    userId?: string,
    query: Record<string, any> = {},
    session?: ClientSession
  ): Promise<AuctionStateResult> {
    const auctionQuery = Auction.findById(objectId(auctionId, 'auction ID'))
      .populate('tournament', 'name')
      .populate('teams', 'name')
      .populate({ path: 'currentPlayer', populate: [{ path: 'player', populate: { path: 'user', select: 'name' } }, { path: 'highestBidder', select: 'name' }] });
    if (session) auctionQuery.session(session);
    const auctionDoc = await auctionQuery.lean();
    if (!auctionDoc) throw ApiError.notFound(MESSAGES.AUCTION.NOT_FOUND);

    const playersQuery = AuctionPlayer.find({ auction: auctionId })
      .populate({ path: 'player', populate: { path: 'user', select: 'name' } })
      .populate('soldTo', 'name')
      .populate('highestBidder', 'name')
      .sort({ set: 1, order: 1, createdAt: 1 });
    const budgetsQuery = AuctionTeam.find({ auction: auctionId }).populate('team', 'name owner');
    if (session) {
      playersQuery.session(session);
      budgetsQuery.session(session);
    }
    const [players, budgets] = await Promise.all([playersQuery.lean(), budgetsQuery.lean()]);
    const bidLimit = Math.min(Math.max(Number(query.limit) || 50, 1), 200);
    const bidsQuery = AuctionBid.find({ auction: auctionId })
      .populate('team', 'name')
      .populate('bidBy', 'name')
      .sort({ sequenceNumber: -1, createdAt: -1 })
      .limit(bidLimit);
    if (session) bidsQuery.session(session);
    const bids = await bidsQuery.lean();

    const teams = budgets.map((budget: any) => {
      const initialBudget = Number(budget.initialBudget) || 0;
      const spent = Number(budget.spent) || 0;
      const pendingCommitment = Number(budget.pendingCommitment) || 0;
      return {
        ...budget,
        remainingBudget: initialBudget - spent,
        availableBudget: Math.max(initialBudget - spent - pendingCommitment, 0),
        maxAffordableBid: Math.max(initialBudget - spent - pendingCommitment, 0),
      };
    });
    const sold = players.filter((player: any) => player.status === AuctionPlayerStatus.SOLD);
    const unsold = players.filter((player: any) => player.status === AuctionPlayerStatus.UNSOLD);
    const available = players.filter((player: any) => player.status === AuctionPlayerStatus.AVAILABLE);

    const state: AuctionStateResult = {
      auction: auctionDoc,
      currentPlayer: (auctionDoc as any).currentPlayer || null,
      players,
      bids,
      teams,
      counts: {
        totalPlayers: players.length,
        availablePlayers: available.length,
        soldPlayers: sold.length,
        unsoldPlayers: unsold.length,
        totalBids: await AuctionBid.countDocuments({ auction: auctionId }, session ? { session } : {}),
      },
      results: { sold, unsold },
      stateVersion: Number((auctionDoc as any).stateVersion) || 0,
    };
    state.permissions = userId
      ? await this.getAuctionAccess(auctionDoc, userId)
      : { canView: true, canManage: false, canBid: false, ownedTeamIds: [] };
    return state;
  }

  public async getAuctionPlayers(
    auctionId: string,
    query: Record<string, any> = {}
  ): Promise<{ data: any[]; pagination: IPaginationMeta }> {
    await this.findAuction(auctionId);
    const { page, limit, skip, sort } = getPaginationParams(query, 20, 100, 'order');
    const filter: Record<string, any> = { auction: objectId(auctionId, 'auction ID') };
    if (query.status) filter.status = String(query.status);
    if (query.category) filter.category = String(query.category);
    if (query.available !== undefined) filter.available = String(query.available) === 'true';
    if (query.search) {
      filter.$or = [{ category: new RegExp(escapeRegExp(String(query.search)), 'i') }];
    }
    const [data, total] = await Promise.all([
      AuctionPlayer.find(filter)
        .populate({ path: 'player', populate: { path: 'user', select: 'name' } })
        .populate('soldTo', 'name')
        .populate('highestBidder', 'name')
        .sort(sort as any)
        .skip(skip)
        .limit(limit)
        .lean(),
      AuctionPlayer.countDocuments(filter),
    ]);
    return { data, pagination: { page, limit, total, totalPages: Math.ceil(total / limit) || 1, hasNextPage: page * limit < total, hasPrevPage: page > 1 } };
  }

  public async getBidHistory(auctionId: string, query: Record<string, any> = {}): Promise<any[]> {
    await this.findAuction(auctionId);
    const limit = Math.min(Math.max(Number(query.limit) || 100, 1), 200);
    return AuctionBid.find({ auction: objectId(auctionId, 'auction ID') })
      .populate('team', 'name')
      .populate('bidBy', 'name')
      .populate('auctionPlayer', 'status basePrice currentBid soldPrice soldTo')
      .sort({ sequenceNumber: -1 })
      .limit(limit)
      .lean();
  }

  public async getResults(auctionId: string): Promise<{ sold: any[]; unsold: any[]; teams: any[] }> {
    const state = await this.getState(auctionId);
    return { sold: state.results.sold, unsold: state.results.unsold, teams: state.teams };
  }

  public async getTeamPurse(auctionId: string, teamId: string): Promise<any> {
    const budget = await this.findAuctionTeam(auctionId, teamId);
    const populated = await AuctionTeam.findById(budget._id).populate('team', 'name owner').lean();
    const initialBudget = Number(populated?.initialBudget) || 0;
    const spent = Number(populated?.spent) || 0;
    const pendingCommitment = Number(populated?.pendingCommitment) || 0;
    const availableBudget = Math.max(initialBudget - spent - pendingCommitment, 0);
    return {
      ...populated,
      initialBudget,
      spent,
      pendingCommitment,
      remainingBudget: initialBudget - spent,
      availableBudget,
      maxAffordableBid: availableBudget,
    };
  }

  public async updateAuction(auctionId: string, userId: string, data: Partial<AuctionInput>): Promise<any> {
    const auction = await this.findAuction(auctionId);
    await this.requireManage(auction, userId);
    if ([AuctionStatus.LIVE, AuctionStatus.PAUSED].includes(auction.status)) {
      throw ApiError.conflict('Auction configuration cannot be changed while the auction is active.');
    }
    const key = requestKeyFor(AuctionAuditAction.UPDATE, auctionId, data);
    const replay = await this.existingAudit(auctionId, data.idempotencyKey?.trim());
    if (replay) return this.result(auctionId, undefined, userId);

    const update: Record<string, unknown> = {};
    const fields: (keyof AuctionInput)[] = [
      'name',
      'tournament',
      'purseAmount',
      'basePrice',
      'minBidIncrement',
      'maxSquadSize',
      'minSquadSize',
      'playerCategories',
      'rules',
      'status',
    ];
    fields.forEach((field) => {
      if (data[field] !== undefined) update[field] = data[field];
    });
    if (data.teams !== undefined) {
      const hasHistory = await AuctionPlayer.exists({ auction: auction._id, status: { $ne: AuctionPlayerStatus.AVAILABLE } });
      if (hasHistory) throw ApiError.conflict('Participating teams cannot change after bidding starts.');
      await this.validateTeams(data.teams.map(String));
      update.teams = data.teams.map((id) => objectId(id, 'team ID'));
    }
    const minSquad = Number(data.minSquadSize ?? auction.minSquadSize);
    const maxSquad = Number(data.maxSquadSize ?? auction.maxSquadSize);
    if (minSquad > maxSquad) throw ApiError.badRequest('Minimum squad size cannot exceed maximum squad size.');

    return this.transaction(async (session) => {
      const fresh = await this.findAuction(auctionId, session);
      if (data.teams !== undefined) {
        await AuctionTeam.deleteMany({ auction: auction._id }, { session });
        await AuctionTeam.create(
          data.teams.map((teamId) => ({
            auction: auction._id,
            team: objectId(teamId, 'team ID'),
            initialBudget: Number(data.purseAmount ?? fresh.purseAmount),
            spent: 0,
            pendingCommitment: 0,
            playersPurchased: 0,
          })),
          { session, ordered: true }
        );
      }
      Object.assign(fresh, update);
      await this.touchAuction(fresh, session);
      await fresh.save({ session });
      await this.writeAudit(
        AuctionAuditAction.UPDATE,
        auctionId,
        userId,
        key,
        fresh.stateVersion,
        update,
        { updated: true },
        session
      );
      return this.result(auctionId, this.commit(auctionId, AuctionAuditAction.UPDATE, 'UPDATE', userId, key, fresh.stateVersion), userId, session);
    });
  }

  public async deleteAuction(auctionId: string, userId: string): Promise<{ deleted: boolean }> {
    const auction = await this.findAuction(auctionId);
    await this.requireManage(auction, userId);
    if (![AuctionStatus.DRAFT, AuctionStatus.UPCOMING, AuctionStatus.CANCELLED].includes(auction.status)) {
      throw ApiError.conflict('Only draft, upcoming, or cancelled auctions can be deleted.');
    }
    return this.transaction(async (session) => {
      await AuctionBid.deleteMany({ auction: auction._id }, { session });
      await AuctionPlayer.deleteMany({ auction: auction._id }, { session });
      await AuctionTeam.deleteMany({ auction: auction._id }, { session });
      await AuctionAudit.deleteMany({ auction: auction._id }, { session });
      await Auction.deleteOne({ _id: auction._id }, { session });
      return { deleted: true };
    });
  }

  public async registerPlayers(
    auctionId: string,
    userId: string,
    registrations: AuctionRegistrationInput[],
    idempotencyKey?: string
  ): Promise<any> {
    const auction = await this.findAuction(auctionId);
    await this.requireManage(auction, userId);
    if (![AuctionStatus.DRAFT, AuctionStatus.UPCOMING].includes(auction.status)) {
      throw ApiError.conflict('Players can only be registered before the auction starts.');
    }
    if (!registrations.length) throw ApiError.badRequest('At least one player is required.');
    const key = requestKeyFor(AuctionAuditAction.ADD_PLAYER, auctionId, { idempotencyKey });
    const replay = await this.existingAudit(auctionId, idempotencyKey?.trim());
    if (replay) return this.result(auctionId, undefined, userId);

    const playerIds = registrations.map((item) => objectId(item.playerId, 'player ID').toString());
    if (new Set(playerIds).size !== playerIds.length) {
      throw ApiError.badRequest('The same player cannot be registered twice in one request.');
    }
    const [playerCount, existing] = await Promise.all([
      Player.countDocuments({ _id: { $in: playerIds } }),
      AuctionPlayer.find({ auction: auction._id, player: { $in: playerIds } }).select('player').lean(),
    ]);
    if (playerCount !== playerIds.length) throw ApiError.badRequest('One or more players do not exist.');
    if (existing.length) throw ApiError.conflict('A player is already registered in this auction.');

    return this.transaction(async (session) => {
      await AuctionPlayer.create(
        registrations.map((item) => ({
          auction: auction._id,
          player: objectId(item.playerId, 'player ID'),
          basePrice: Number(item.basePrice ?? auction.basePrice ?? 0),
          category: item.category?.trim(),
          set: item.set,
          order: item.order,
          available: true,
          status: AuctionPlayerStatus.AVAILABLE,
          })),
        { session, ordered: true }
      );
      const fresh = await this.findAuction(auctionId, session);
      const version = await this.touchAuction(fresh, session);
      await this.writeAudit(
        AuctionAuditAction.ADD_PLAYER,
        auctionId,
        userId,
        key,
        version,
        { players: registrations },
        { added: registrations.length },
        session
      );
      return this.result(auctionId, this.commit(auctionId, AuctionAuditAction.ADD_PLAYER, 'ADD_PLAYER', userId, key, version), userId, session);
    });
  }

  public async removeAuctionPlayer(auctionId: string, auctionPlayerId: string, userId: string): Promise<any> {
    const auction = await this.findAuction(auctionId);
    await this.requireManage(auction, userId);
    if (![AuctionStatus.DRAFT, AuctionStatus.UPCOMING].includes(auction.status)) {
      throw ApiError.conflict('Players cannot be removed after the auction starts.');
    }
    const player = await this.findAuctionPlayer(auctionPlayerId);
    if (!isSameId(player.auction, auction._id)) throw ApiError.badRequest('Player does not belong to this auction.');
    if (player.status !== AuctionPlayerStatus.AVAILABLE) {
      throw ApiError.conflict('A sold or unsold player cannot be removed.');
    }
    return this.transaction(async (session) => {
      await AuctionBid.deleteMany({ auctionPlayer: player._id }, { session });
      await AuctionPlayer.deleteOne({ _id: player._id }, { session });
      const fresh = await this.findAuction(auctionId, session);
      const version = await this.touchAuction(fresh, session);
      await this.writeAudit(AuctionAuditAction.REMOVE_PLAYER, auctionId, userId, requestKeyFor(AuctionAuditAction.REMOVE_PLAYER, auctionId), version, { auctionPlayerId }, { removed: true }, session, auctionPlayerId);
      return this.result(auctionId, this.commit(auctionId, AuctionAuditAction.REMOVE_PLAYER, 'REMOVE_PLAYER', userId, requestKeyFor(AuctionAuditAction.REMOVE_PLAYER, auctionId), version, { auctionPlayerId }), userId, session);
    });
  }

  public async setPlayerAvailability(
    auctionId: string,
    auctionPlayerId: string,
    userId: string,
    available: boolean
  ): Promise<any> {
    const auction = await this.findAuction(auctionId);
    await this.requireManage(auction, userId);
    const player = await this.findAuctionPlayer(auctionPlayerId);
    if (!isSameId(player.auction, auction._id)) throw ApiError.badRequest('Player does not belong to this auction.');
    if (player.status !== AuctionPlayerStatus.AVAILABLE) {
      throw ApiError.conflict('Only available players can change availability.');
    }
    return this.transaction(async (session) => {
      player.available = available;
      player.version = Number(player.version || 0) + 1;
      await player.save({ session });
      const fresh = await this.findAuction(auctionId, session);
      const version = await this.touchAuction(fresh, session);
      const key = requestKeyFor(AuctionAuditAction.AVAILABILITY, auctionId);
      await this.writeAudit(AuctionAuditAction.AVAILABILITY, auctionId, userId, key, version, { auctionPlayerId, available }, { available }, session, auctionPlayerId);
      return this.result(auctionId, this.commit(auctionId, AuctionAuditAction.AVAILABILITY, 'AVAILABILITY', userId, key, version, { auctionPlayerId }), userId, session);
    });
  }

  public async bringPlayerForward(
    auctionId: string,
    auctionPlayerId: string,
    userId: string,
    input: { expectedVersion?: number; idempotencyKey?: string } = {}
  ): Promise<any> {
    const auction = await this.findAuction(auctionId);
    await this.requireManage(auction, userId);
    if (![AuctionStatus.LIVE, AuctionStatus.PAUSED].includes(auction.status)) {
      throw ApiError.conflict(MESSAGES.AUCTION.NOT_ACTIVE);
    }
    this.applyVersion(input, Number(auction.stateVersion) || 0);
    const player = await this.findAuctionPlayer(auctionPlayerId);
    if (!isSameId(player.auction, auction._id)) throw ApiError.badRequest('Player does not belong to this auction.');
    if (!player.available || player.status !== AuctionPlayerStatus.AVAILABLE) {
      throw ApiError.conflict('Only an available player can be brought forward.');
    }
    const key = requestKeyFor(AuctionAuditAction.FORWARD, auctionId, input);
    const replay = await this.existingAudit(auctionId, input.idempotencyKey?.trim());
    if (replay) return this.result(auctionId, undefined, userId);

    return this.transaction(async (session) => {
      const fresh = await this.findAuction(auctionId, session);
      this.applyVersion(input, Number(fresh.stateVersion) || 0);
      await this.releaseCurrentBid(fresh, session);
      fresh.currentPlayer = player._id;
      const version = await this.touchAuction(fresh, session);
      await fresh.save({ session });
      await this.writeAudit(AuctionAuditAction.FORWARD, auctionId, userId, key, version, { auctionPlayerId }, { auctionPlayerId }, session, auctionPlayerId);
      return this.result(auctionId, this.commit(auctionId, AuctionAuditAction.FORWARD, 'PLAYER_CHANGED', userId, key, version, { auctionPlayerId }), userId, session);
    });
  }

  public async addAuctionTeam(auctionId: string, teamId: string, userId: string): Promise<any> {
    const auction = await this.findAuction(auctionId);
    await this.requireManage(auction, userId);
    if (![AuctionStatus.DRAFT, AuctionStatus.UPCOMING].includes(auction.status)) {
      throw ApiError.conflict('Teams cannot be added after the auction starts.');
    }
    const team = await Team.findById(objectId(teamId, 'team ID'));
    if (!team) throw ApiError.badRequest('Team does not exist.');
    if ((auction.teams || []).some((id: any) => isSameId(id, teamId))) {
      throw ApiError.conflict('Team is already a participant in this auction.');
    }
    return this.transaction(async (session) => {
      await AuctionTeam.create([{ auction: auction._id, team: team._id, initialBudget: auction.purseAmount, spent: 0, pendingCommitment: 0, playersPurchased: 0 }], { session, ordered: true });
      const fresh = await this.findAuction(auctionId, session);
      fresh.teams.push(team._id);
      const version = await this.touchAuction(fresh, session);
      await fresh.save({ session });
      const key = requestKeyFor(AuctionAuditAction.ADD_TEAM, auctionId);
      await this.writeAudit(AuctionAuditAction.ADD_TEAM, auctionId, userId, key, version, { teamId }, { teamId }, session);
      return this.result(auctionId, this.commit(auctionId, AuctionAuditAction.ADD_TEAM, 'ADD_TEAM', userId, key, version, { teamId }), userId, session);
    });
  }

  public async removeAuctionTeam(auctionId: string, teamId: string, userId: string): Promise<any> {
    const auction = await this.findAuction(auctionId);
    await this.requireManage(auction, userId);
    if (![AuctionStatus.DRAFT, AuctionStatus.UPCOMING].includes(auction.status)) {
      throw ApiError.conflict('Teams cannot be removed after the auction starts.');
    }
    const budget = await this.findAuctionTeam(auctionId, teamId);
    if (Number(budget.playersPurchased) > 0) throw ApiError.conflict('A team with purchased players cannot be removed.');
    return this.transaction(async (session) => {
      await AuctionTeam.deleteOne({ _id: budget._id }, { session });
      const fresh = await this.findAuction(auctionId, session);
      fresh.teams = (fresh.teams || []).filter((id: any) => !isSameId(id, teamId));
      const version = await this.touchAuction(fresh, session);
      await fresh.save({ session });
      const key = requestKeyFor(AuctionAuditAction.REMOVE_TEAM, auctionId);
      await this.writeAudit(AuctionAuditAction.REMOVE_TEAM, auctionId, userId, key, version, { teamId }, { teamId }, session);
      return this.result(auctionId, this.commit(auctionId, AuctionAuditAction.REMOVE_TEAM, 'REMOVE_TEAM', userId, key, version, { teamId }), userId, session);
    });
  }

  public async startAuction(auctionId: string, userId: string, input: { expectedVersion?: number; idempotencyKey?: string } = {}): Promise<any> {
    const auction = await this.findAuction(auctionId);
    await this.requireManage(auction, userId);
    const key = requestKeyFor(AuctionAuditAction.START, auctionId, input);
    const replay = await this.existingAudit(auctionId, input.idempotencyKey?.trim());
    if (replay) return this.result(auctionId, undefined, userId);
    if (![AuctionStatus.DRAFT, AuctionStatus.UPCOMING].includes(auction.status)) {
      throw ApiError.conflict('Auction has already started or is finished.');
    }
    this.applyVersion(input, Number(auction.stateVersion) || 0);
    if ((auction.teams || []).length < 2) throw ApiError.badRequest('An auction requires at least two teams.');
    const availableCount = await AuctionPlayer.countDocuments({ auction: auction._id, status: AuctionPlayerStatus.AVAILABLE, available: true });
    if (availableCount === 0) throw ApiError.badRequest('Register at least one available player before starting.');

    return this.transaction(async (session) => {
      const fresh = await this.findAuction(auctionId, session);
      this.applyVersion(input, Number(fresh.stateVersion) || 0);
      const teamCount = await AuctionTeam.countDocuments({ auction: auction._id }).session(session);
      if (teamCount !== (fresh.teams || []).length) {
        throw ApiError.badRequest('Participating team budgets are not initialized.');
      }
      const first = await this.chooseFirstPlayer(fresh, session);
      fresh.status = AuctionStatus.LIVE;
      fresh.startedAt = new Date();
      fresh.currentPlayer = first?._id;
      const version = await this.touchAuction(fresh, session);
      await fresh.save({ session });
      await this.writeAudit(AuctionAuditAction.START, auctionId, userId, key, version, {}, { currentPlayerId: idString(first?._id) }, session);
      return this.result(auctionId, this.commit(auctionId, AuctionAuditAction.START, 'STARTED', userId, key, version, { auctionPlayerId: idString(first?._id) }), userId, session);
    });
  }

  public async pauseAuction(auctionId: string, userId: string, input: { expectedVersion?: number; idempotencyKey?: string } = {}): Promise<any> {
    return this.changeStatus(auctionId, userId, AuctionStatus.LIVE, AuctionStatus.PAUSED, AuctionAuditAction.PAUSE, 'PAUSED', input);
  }

  public async resumeAuction(auctionId: string, userId: string, input: { expectedVersion?: number; idempotencyKey?: string } = {}): Promise<any> {
    return this.changeStatus(auctionId, userId, AuctionStatus.PAUSED, AuctionStatus.LIVE, AuctionAuditAction.RESUME, 'RESUMED', input);
  }

  private async changeStatus(
    auctionId: string,
    userId: string,
    from: AuctionStatus,
    to: AuctionStatus,
    action: AuctionAuditAction,
    event: string,
    input: { expectedVersion?: number; idempotencyKey?: string }
  ): Promise<any> {
    const auction = await this.findAuction(auctionId);
    await this.requireManage(auction, userId);
    const key = requestKeyFor(action, auctionId, input);
    const replay = await this.existingAudit(auctionId, input.idempotencyKey?.trim());
    if (replay) return this.result(auctionId, undefined, userId);
    if (auction.status !== from) throw ApiError.conflict(`Auction must be ${from} to perform this action.`);
    this.applyVersion(input, Number(auction.stateVersion) || 0);
    return this.transaction(async (session) => {
      const fresh = await this.findAuction(auctionId, session);
      if (fresh.status !== from) throw ApiError.conflict(`Auction must be ${from} to perform this action.`);
      this.applyVersion(input, Number(fresh.stateVersion) || 0);
      fresh.status = to;
      const version = await this.touchAuction(fresh, session);
      await fresh.save({ session });
      await this.writeAudit(action, auctionId, userId, key, version, {}, { status: to }, session);
      return this.result(auctionId, this.commit(auctionId, action, event, userId, key, version), userId, session);
    });
  }

  public async placeBid(auctionId: string, userId: string, input: AuctionBidInput): Promise<any> {
    if (!input.team) throw ApiError.badRequest('A bidding team is required.');
    const auction = await this.findAuction(auctionId);
    const access = await this.getAuctionAccess(auction, userId);
    if (!access.ownedTeamIds.includes(String(input.team))) {
      throw ApiError.forbidden('You are not authorized to bid for this team.');
    }
    const key = requestKeyFor(AuctionAuditAction.BID, auctionId, input);
    const replay = await this.existingAudit(auctionId, input.idempotencyKey?.trim());
    if (replay) return this.result(auctionId, undefined, userId);
    if (auction.status !== AuctionStatus.LIVE) throw ApiError.conflict(MESSAGES.AUCTION.NOT_ACTIVE);
    this.applyVersion(input, Number(auction.stateVersion) || 0);

    try {
      return await this.transaction(async (session) => {
        const fresh = await this.findAuction(auctionId, session);
        if (fresh.status !== AuctionStatus.LIVE) throw ApiError.conflict(MESSAGES.AUCTION.NOT_ACTIVE);
        this.applyVersion(input, Number(fresh.stateVersion) || 0);
        if (!fresh.currentPlayer) throw ApiError.conflict('No player is currently being auctioned.');

        const player = await this.findAuctionPlayer(String(fresh.currentPlayer), session);
        if (!isSameId(player.auction, fresh._id) || player.status !== AuctionPlayerStatus.AVAILABLE || !player.available) {
          throw ApiError.conflict('The current player is not available for bidding.');
        }
        if (isSameId(player.highestBidder, input.team)) {
          throw ApiError.conflict('This team already holds the highest bid.');
        }

        const budget = await this.findAuctionTeam(auctionId, String(input.team), session);
        const minBid = Number(player.currentBid) > 0
          ? Number(player.currentBid) + Number(fresh.minBidIncrement)
          : Number(player.basePrice);
        const amount = input.amount === undefined ? minBid : Number(input.amount);
        if (!Number.isFinite(amount) || amount <= 0) throw ApiError.badRequest('Bid amount must be positive.');
        if (amount < minBid) throw ApiError.badRequest(MESSAGES.AUCTION.BID_TOO_LOW);
        if (Number(budget.playersPurchased) >= Number(fresh.maxSquadSize)) {
          throw ApiError.badRequest(MESSAGES.AUCTION.TEAM_SLOTS_FULL);
        }
        const availableBudget =
          Number(budget.initialBudget) - Number(budget.spent) - Number(budget.pendingCommitment);
        if (amount > availableBudget) throw ApiError.badRequest(MESSAGES.AUCTION.INSUFFICIENT_PURSE);

        const sequenceNumber = Number(fresh.nextSequence) || 1;
        const [bid] = await AuctionBid.create(
          [{
            auction: fresh._id,
            auctionPlayer: player._id,
            team: objectId(input.team, 'team ID'),
            amount,
            bidBy: objectId(userId, 'user ID'),
            requestKey: key,
            sequenceNumber,
            decision: AuctionBidDecision.PENDING,
          }],
          { session, ordered: true }
        );
        if (player.highestBidder && Number(player.currentBid) > 0) {
          await AuctionTeam.updateOne(
            { auction: fresh._id, team: player.highestBidder },
            { $inc: { pendingCommitment: -Number(player.currentBid) } },
            { session }
          );
        }
        await AuctionTeam.updateOne(
          { _id: budget._id },
          { $inc: { pendingCommitment: amount } },
          { session }
        );
        player.currentBid = amount;
        player.highestBidder = bid.team;
        player.bidCount = Number(player.bidCount || 0) + 1;
        player.lastSequence = sequenceNumber;
        player.version = Number(player.version || 0) + 1;
        await player.save({ session });
        await Auction.updateOne({ _id: fresh._id }, { $set: { nextSequence: sequenceNumber + 1 } }, { session });
        const version = await this.touchAuction(fresh, session);
        await this.writeAudit(AuctionAuditAction.BID, auctionId, userId, key, version, { teamId: String(input.team), amount }, { bidId: String(bid._id), sequenceNumber }, session, String(player._id), sequenceNumber);
        return this.result(auctionId, this.commit(auctionId, AuctionAuditAction.BID, 'BID_PLACED', userId, key, version, { auctionPlayerId: String(player._id), bidId: String(bid._id), teamId: String(input.team), amount, sequenceNumber }), userId, session);
      });
    } catch (error) {
      if (isDuplicateKeyError(error) && input.idempotencyKey) {
        return this.result(auctionId, undefined, userId);
      }
      throw error;
    }
  }

  private async settleCurrentPlayer(
    auctionId: string,
    userId: string,
    sold: boolean,
    input: { expectedVersion?: number; idempotencyKey?: string; reason?: string }
  ): Promise<any> {
    const auction = await this.findAuction(auctionId);
    await this.requireManage(auction, userId);
    const action = sold ? AuctionAuditAction.SOLD : AuctionAuditAction.UNSOLD;
    const key = requestKeyFor(action, auctionId, input);
    const replay = await this.existingAudit(auctionId, input.idempotencyKey?.trim());
    if (replay) return this.result(auctionId, undefined, userId);
    if (![AuctionStatus.LIVE, AuctionStatus.PAUSED].includes(auction.status)) {
      throw ApiError.conflict(MESSAGES.AUCTION.NOT_ACTIVE);
    }
    this.applyVersion(input, Number(auction.stateVersion) || 0);
    if (!auction.currentPlayer) throw ApiError.conflict('No player is currently being auctioned.');

    return this.transaction(async (session) => {
      const fresh = await this.findAuction(auctionId, session);
      this.applyVersion(input, Number(fresh.stateVersion) || 0);
      const player = await this.findAuctionPlayer(String(fresh.currentPlayer), session);
      if (player.status !== AuctionPlayerStatus.AVAILABLE) {
        throw ApiError.conflict('This player has already been finalized.');
      }
      const amount = Number(player.currentBid) || 0;
      if (sold && (!player.highestBidder || amount <= 0)) {
        throw ApiError.conflict('A player cannot be sold without a valid highest bid.');
      }
      if (sold) {
        const budget = await this.findAuctionTeam(auctionId, String(player.highestBidder), session);
        if (amount > Number(budget.initialBudget) - Number(budget.spent)) {
          throw ApiError.badRequest(MESSAGES.AUCTION.INSUFFICIENT_PURSE);
        }
        if (Number(budget.playersPurchased) >= Number(fresh.maxSquadSize)) {
          throw ApiError.badRequest(MESSAGES.AUCTION.TEAM_SLOTS_FULL);
        }
        await AuctionTeam.updateOne(
          { _id: budget._id },
          { $inc: { pendingCommitment: -amount, spent: amount, playersPurchased: 1 } },
          { session }
        );
        player.status = AuctionPlayerStatus.SOLD;
        player.soldTo = player.highestBidder;
        player.soldPrice = amount;
        player.soldAt = new Date();
        player.decision = AuctionBidDecision.ACCEPTED;
        await AuctionBid.updateMany(
          { auctionPlayer: player._id, decision: AuctionBidDecision.PENDING },
          { $set: { decision: AuctionBidDecision.REJECTED, rejectionReason: 'Outbid or auction closed', decidedBy: objectId(userId, 'user ID'), decidedAt: new Date() } },
          { session }
        );
        await AuctionBid.updateOne(
          { auctionPlayer: player._id, team: player.highestBidder, amount },
          { $set: { decision: AuctionBidDecision.ACCEPTED, decidedBy: objectId(userId, 'user ID'), decidedAt: new Date() } },
          { session }
        );
      } else {
        if (player.highestBidder && amount > 0) {
          await AuctionTeam.updateOne(
            { auction: fresh._id, team: player.highestBidder },
            { $inc: { pendingCommitment: -amount } },
            { session }
          );
        }
        player.status = AuctionPlayerStatus.UNSOLD;
        player.decision = AuctionBidDecision.REJECTED;
        await AuctionBid.updateMany(
          { auctionPlayer: player._id, decision: AuctionBidDecision.PENDING },
          { $set: { decision: AuctionBidDecision.REJECTED, rejectionReason: input.reason || 'Player marked unsold', decidedBy: objectId(userId, 'user ID'), decidedAt: new Date() } },
          { session }
        );
      }
      player.version = Number(player.version || 0) + 1;
      await player.save({ session });
      fresh.currentPlayer = undefined;
      const version = await this.touchAuction(fresh, session);
      await fresh.save({ session });
      await this.writeAudit(
        action,
        auctionId,
        userId,
        key,
        version,
        { auctionPlayerId: String(player._id), amount, reason: input.reason },
        { status: player.status, amount },
        session,
        String(player._id)
      );
      return this.result(auctionId, this.commit(auctionId, action, sold ? 'PLAYER_SOLD' : 'PLAYER_UNSOLD', userId, key, version, { auctionPlayerId: String(player._id), teamId: idString(player.soldTo), amount }), userId, session);
    });
  }

  public async markCurrentPlayerSold(auctionId: string, userId: string, input: { expectedVersion?: number; idempotencyKey?: string } = {}): Promise<any> {
    return this.settleCurrentPlayer(auctionId, userId, true, input);
  }

  public async markCurrentPlayerUnsold(auctionId: string, userId: string, input: { expectedVersion?: number; idempotencyKey?: string; reason?: string } = {}): Promise<any> {
    return this.settleCurrentPlayer(auctionId, userId, false, input);
  }

  public async nextPlayer(auctionId: string, userId: string, input: { expectedVersion?: number; idempotencyKey?: string } = {}): Promise<any> {
    const auction = await this.findAuction(auctionId);
    await this.requireManage(auction, userId);
    const key = requestKeyFor(AuctionAuditAction.NEXT_PLAYER, auctionId, input);
    const replay = await this.existingAudit(auctionId, input.idempotencyKey?.trim());
    if (replay) return this.result(auctionId, undefined, userId);
    if (![AuctionStatus.LIVE, AuctionStatus.PAUSED].includes(auction.status)) {
      throw ApiError.conflict(MESSAGES.AUCTION.NOT_ACTIVE);
    }
    this.applyVersion(input, Number(auction.stateVersion) || 0);

    return this.transaction(async (session) => {
      const fresh = await this.findAuction(auctionId, session);
      this.applyVersion(input, Number(fresh.stateVersion) || 0);
      await this.releaseCurrentBid(fresh, session);
      const query = AuctionPlayer.find(this.nextPlayerQuery(fresh))
        .sort({ set: 1, order: 1, createdAt: 1 })
        .limit(1);
      query.session(session);
      const next = await query;
      if (!next.length) {
        throw ApiError.conflict('No more players are available in this auction.');
      }
      fresh.currentPlayer = next[0]._id;
      const version = await this.touchAuction(fresh, session);
      await fresh.save({ session });
      await this.writeAudit(AuctionAuditAction.NEXT_PLAYER, auctionId, userId, key, version, {}, { auctionPlayerId: String(next[0]._id) }, session, String(next[0]._id));
      return this.result(auctionId, this.commit(auctionId, AuctionAuditAction.NEXT_PLAYER, 'PLAYER_CHANGED', userId, key, version, { auctionPlayerId: String(next[0]._id) }), userId, session);
    });
  }

  public async decideBid(auctionId: string, bidId: string, userId: string, input: AuctionDecisionInput): Promise<any> {
    const auction = await this.findAuction(auctionId);
    await this.requireManage(auction, userId);
    if (![AuctionStatus.LIVE, AuctionStatus.PAUSED].includes(auction.status)) {
      throw ApiError.conflict(MESSAGES.AUCTION.NOT_ACTIVE);
    }
    const bid = await AuctionBid.findOne({ _id: objectId(bidId, 'bid ID'), auction: auction._id });
    if (!bid) throw ApiError.notFound('Bid not found.');
    if (bid.decision !== AuctionBidDecision.PENDING) throw ApiError.conflict('Bid has already been decided.');
    if (!input.accept && (!auction.currentPlayer || !isSameId(bid.auctionPlayer, auction.currentPlayer))) {
      throw ApiError.conflict('Only the current bid can be rejected.');
    }
    if (input.accept) {
      const player = await this.findAuctionPlayer(String(bid.auctionPlayer));
      if (!auction.currentPlayer || !isSameId(auction.currentPlayer, player._id)) {
        throw ApiError.conflict('Only the current player can be sold.');
      }
      if (!isSameId(player.highestBidder, bid.team) || Number(player.currentBid) !== Number(bid.amount)) {
        throw ApiError.conflict('Only the highest bid can be accepted.');
      }
      return this.settleCurrentPlayer(auctionId, userId, true, input);
    }

    const key = requestKeyFor(AuctionAuditAction.BID_DECISION, auctionId, input);
    const replay = await this.existingAudit(auctionId, input.idempotencyKey?.trim());
    if (replay) return this.result(auctionId, undefined, userId);
    return this.transaction(async (session) => {
      const fresh = await this.findAuction(auctionId, session);
      this.applyVersion(input, Number(fresh.stateVersion) || 0);
      const player = await this.findAuctionPlayer(String(bid.auctionPlayer), session);
      if (player.highestBidder && isSameId(player.highestBidder, bid.team) && Number(player.currentBid) === Number(bid.amount)) {
        await AuctionTeam.updateOne(
          { auction: fresh._id, team: bid.team },
          { $inc: { pendingCommitment: -Number(bid.amount) } },
          { session }
        );
        const previous = await AuctionBid.find({
          auctionPlayer: player._id,
          decision: AuctionBidDecision.PENDING,
          _id: { $ne: bid._id },
        })
          .sort({ amount: -1, sequenceNumber: -1 })
          .limit(1)
          .session(session);
        if (previous.length) {
          player.currentBid = Number(previous[0].amount);
          player.highestBidder = previous[0].team;
          await AuctionTeam.updateOne(
            { auction: fresh._id, team: previous[0].team },
            { $inc: { pendingCommitment: Number(previous[0].amount) } },
            { session }
          );
        } else {
          player.currentBid = 0;
          player.highestBidder = undefined;
        }
        player.version = Number(player.version || 0) + 1;
        await player.save({ session });
      }
      bid.decision = AuctionBidDecision.REJECTED;
      bid.rejectionReason = input.reason || 'Bid rejected by auction organizer.';
      bid.decidedBy = objectId(userId, 'user ID');
      bid.decidedAt = new Date();
      await bid.save({ session });
      const version = await this.touchAuction(fresh, session);
      await this.writeAudit(AuctionAuditAction.BID_DECISION, auctionId, userId, key, version, { bidId, accept: false, reason: input.reason }, { decision: AuctionBidDecision.REJECTED }, session, String(bid.auctionPlayer), bid.sequenceNumber);
      return this.result(auctionId, this.commit(auctionId, AuctionAuditAction.BID_DECISION, 'BID_REJECTED', userId, key, version, { auctionPlayerId: String(bid.auctionPlayer), bidId, teamId: String(bid.team), amount: Number(bid.amount), decision: AuctionBidDecision.REJECTED }), userId, session);
    });
  }

  public async completeAuction(auctionId: string, userId: string, input: { expectedVersion?: number; idempotencyKey?: string } = {}): Promise<any> {
    const auction = await this.findAuction(auctionId);
    await this.requireManage(auction, userId);
    const key = requestKeyFor(AuctionAuditAction.COMPLETE, auctionId, input);
    const replay = await this.existingAudit(auctionId, input.idempotencyKey?.trim());
    if (replay) return this.result(auctionId, undefined, userId);
    if (![AuctionStatus.LIVE, AuctionStatus.PAUSED].includes(auction.status)) {
      throw ApiError.conflict('Auction must be live or paused to complete.');
    }
    this.applyVersion(input, Number(auction.stateVersion) || 0);

    return this.transaction(async (session) => {
      const fresh = await this.findAuction(auctionId, session);
      this.applyVersion(input, Number(fresh.stateVersion) || 0);
      let finalPlayerId: string | undefined;
      let finalAmount: number | undefined;
      let finalTeamId: string | undefined;
      if (fresh.currentPlayer) {
        const player = await this.findAuctionPlayer(String(fresh.currentPlayer), session);
        if (player.status === AuctionPlayerStatus.AVAILABLE) {
          finalPlayerId = String(player._id);
          finalAmount = Number(player.currentBid) || 0;
          finalTeamId = idString(player.highestBidder);
          if (finalTeamId && finalAmount > 0) {
            const budget = await this.findAuctionTeam(auctionId, finalTeamId, session);
            if (finalAmount <= Number(budget.initialBudget) - Number(budget.spent)) {
              await AuctionTeam.updateOne(
                { _id: budget._id },
                { $inc: { pendingCommitment: -finalAmount, spent: finalAmount, playersPurchased: 1 } },
                { session }
              );
              player.status = AuctionPlayerStatus.SOLD;
              player.soldTo = player.highestBidder;
              player.soldPrice = finalAmount;
              player.soldAt = new Date();
              player.decision = AuctionBidDecision.ACCEPTED;
              await AuctionBid.updateOne(
                { auctionPlayer: player._id, team: player.highestBidder, amount: finalAmount },
                { $set: { decision: AuctionBidDecision.ACCEPTED, decidedAt: new Date(), decidedBy: objectId(userId, 'user ID') } },
                { session }
              );
            } else {
              await AuctionTeam.updateOne(
                { auction: fresh._id, team: player.highestBidder },
                { $inc: { pendingCommitment: -finalAmount } },
                { session }
              );
              player.status = AuctionPlayerStatus.UNSOLD;
              player.decision = AuctionBidDecision.REJECTED;
            }
          } else {
            player.status = AuctionPlayerStatus.UNSOLD;
            player.decision = AuctionBidDecision.REJECTED;
          }
          await AuctionBid.updateMany(
            { auctionPlayer: player._id, decision: AuctionBidDecision.PENDING },
            { $set: { decision: AuctionBidDecision.REJECTED, rejectionReason: 'Auction completed', decidedAt: new Date(), decidedBy: objectId(userId, 'user ID') } },
            { session }
          );
          player.version = Number(player.version || 0) + 1;
          await player.save({ session });
        }
      }
      const remainingQuery = AuctionPlayer.find({
        auction: fresh._id,
        status: AuctionPlayerStatus.AVAILABLE,
      });
      remainingQuery.session(session);
      const remaining = await remainingQuery;
      for (const leftover of remaining) {
        leftover.status = AuctionPlayerStatus.UNSOLD;
        leftover.decision = AuctionBidDecision.REJECTED;
        leftover.version = Number(leftover.version || 0) + 1;
        await leftover.save({ session });
        await AuctionBid.updateMany(
          { auctionPlayer: leftover._id, decision: AuctionBidDecision.PENDING },
          { $set: { decision: AuctionBidDecision.REJECTED, rejectionReason: 'Auction completed', decidedAt: new Date(), decidedBy: objectId(userId, 'user ID') } },
          { session }
        );
      }
      fresh.status = AuctionStatus.COMPLETED;
      fresh.endedAt = new Date();
      fresh.currentPlayer = undefined;
      const version = await this.touchAuction(fresh, session);
      await fresh.save({ session });
      await this.writeAudit(AuctionAuditAction.COMPLETE, auctionId, userId, key, version, {}, { status: AuctionStatus.COMPLETED, finalPlayerId, finalAmount }, session);
      return this.result(auctionId, this.commit(auctionId, AuctionAuditAction.COMPLETE, 'COMPLETED', userId, key, version, { auctionPlayerId: finalPlayerId, teamId: finalTeamId, amount: finalAmount }), userId, session);
    });
  }
}

export default new AuctionService();
