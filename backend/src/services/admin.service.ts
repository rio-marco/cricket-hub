import { randomUUID } from 'crypto';
import { Request } from 'express';
import { Types } from 'mongoose';
import { AdminAction } from '../constants/admin';
import AuctionBid from '../models/AuctionBid';
import {
  MatchFormat,
  MatchStatus,
  NotificationCategory,
  NotificationType,
  ResultType,
  TournamentStatus,
  TournamentTeamStatus,
} from '../constants/enums';
import { UserRole } from '../constants/roles';
import Delivery from '../models/Delivery';
import Match from '../models/Match';
import NotificationDelivery from '../models/NotificationDelivery';
import Player from '../models/Player';
import RefreshToken from '../models/RefreshToken';
import Team from '../models/Team';
import Tournament from '../models/Tournament';
import TournamentTeam from '../models/TournamentTeam';
import User from '../models/User';
import { redactSensitive } from '../models/AdminAudit';
import { ApiError } from '../utils/apiError';
import { buildPaginationResponse, getPaginationParams, IPaginationMeta } from '../utils/pagination';
import adminAuditService, { resolveSort } from './adminAudit.service';
import auctionService from './auction.service';
import authService from './auth.service';
import matchService from './match.service';
import notificationService from './notification.service';
import playerStatisticsService from './playerStatistics.service';
import scoringService from './scoring.service';
import tournamentService from './tournament.service';

export interface AdminListResult<T = any> {
  data: T[];
  pagination: IPaginationMeta;
}

const escapeRegExp = (value: string): string => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const sanitize = (value: any): any => {
  if (!value) return value;
  const object = typeof value.toObject === 'function' ? value.toObject() : { ...value };
  delete object.password;
  delete object.otp;
  delete object.fcmToken;
  delete object.authLockout;
  delete object.__v;
  return object;
};

const maskIdentifier = (value?: string): string =>
  value && value.length > 3 ? `${'*'.repeat(Math.max(0, value.length - 3))}${value.slice(-3)}` : '***';

const paginationOf = (query: Record<string, any>, fields: string[], defaultSort: string) => {
  const { page, limit, skip } = getPaginationParams(query, 20, 100, `-${defaultSort}`, fields);
  return { page, limit, skip, sort: resolveSort(query, fields, defaultSort) };
};

const paginate = <T>(data: T[], total: number, page: number, limit: number): AdminListResult<T> => ({
  data,
  pagination: buildPaginationResponse(total, page, limit),
});

const isObjectId = (value: unknown): boolean => Types.ObjectId.isValid(String(value || ''));

export class AdminService {
  private async audit(
    req: Request,
    action: AdminAction,
    target: string | { type: string; id?: string },
    before?: unknown,
    after?: unknown,
    reason?: string,
    metadata?: Record<string, unknown>
  ): Promise<void> {
    await adminAuditService.recordAdminAction(req, action, target, before, after, reason, metadata);
  }

  async loginAdmin(
    req: Request,
    data: { email?: string; phone?: string; password: string }
  ): Promise<{ user: any; tokens: any }> {
    const query: Record<string, unknown> = {};
    if (data.email) query.email = data.email.toLowerCase().trim();
    else if (data.phone) query.phone = data.phone.trim();
    else throw ApiError.badRequest('An email address or phone number is required.');

    const identifier = String(data.email || data.phone || '');
    const user = await User.findOne(query).select('+password');

    if (!user) {
      await this.audit(
        req,
        AdminAction.ADMIN_LOGIN_FAILED,
        { type: 'ADMIN_LOGIN', id: maskIdentifier(identifier) },
        undefined,
        undefined,
        undefined,
        { outcome: 'USER_NOT_FOUND' }
      );
      throw ApiError.unauthorized('Invalid administrator credentials.');
    }

    if (user.role !== UserRole.ADMIN) {
      await this.audit(
        req,
        AdminAction.ADMIN_LOGIN_FAILED,
        { type: 'USER', id: String(user._id) },
        undefined,
        undefined,
        undefined,
        { outcome: 'NOT_ADMIN' }
      );
      throw ApiError.forbidden('Administrator access is required.');
    }

    if (!user.isVerified) {
      await this.audit(
        req,
        AdminAction.ADMIN_LOGIN_FAILED,
        { type: 'USER', id: String(user._id) },
        undefined,
        undefined,
        undefined,
        { outcome: 'NOT_VERIFIED' }
      );
      throw ApiError.forbidden('This administrator account is not verified.');
    }

    if (user.isBlocked) {
      await this.audit(
        req,
        AdminAction.ADMIN_LOGIN_FAILED,
        { type: 'USER', id: String(user._id) },
        undefined,
        undefined,
        undefined,
        { outcome: 'BLOCKED' }
      );
      throw ApiError.forbidden('This administrator account is blocked.');
    }

    const validPassword = await user.comparePassword(data.password);
    if (!validPassword) {
      await this.audit(
        req,
        AdminAction.ADMIN_LOGIN_FAILED,
        { type: 'USER', id: String(user._id) },
        undefined,
        undefined,
        undefined,
        { outcome: 'INVALID_PASSWORD' }
      );
      throw ApiError.unauthorized('Invalid administrator credentials.');
    }

    const tokens = await authService.generateTokens(user);
    await this.audit(
      req,
      AdminAction.ADMIN_LOGIN,
      { type: 'USER', id: String(user._id) },
      undefined,
      { role: user.role, isVerified: user.isVerified },
      undefined,
      { outcome: 'SUCCESS' }
    );

    return { user: sanitize(user), tokens };
  }

  async getDashboard(): Promise<any> {
    const counts = await Promise.all([
      User.countDocuments().catch(() => 0),
      User.countDocuments({ isBlocked: false }).catch(() => 0),
      User.countDocuments({ isBlocked: true }).catch(() => 0),
      User.countDocuments({ isVerified: true }).catch(() => 0),
      User.aggregate([
        { $group: { _id: '$role', count: { $sum: 1 } } },
      ]).catch(() => []),
      Team.countDocuments().catch(() => 0),
      Player.countDocuments().catch(() => 0),
      Tournament.countDocuments().catch(() => 0),
      Match.countDocuments().catch(() => 0),
      Match.countDocuments({ status: MatchStatus.LIVE }).catch(() => 0),
      TournamentTeam.countDocuments({ status: TournamentTeamStatus.PENDING }).catch(() => 0),
      adminAuditService.listAdminActions({ page: 1, limit: 5 }).catch(() => ({ audits: [], pagination: {} })),
    ]);

    const byRole: Record<string, number> = {};
    (counts[4] || []).forEach((item: any) => {
      if (item?._id) byRole[String(item._id)] = Number(item.count) || 0;
    });

    return {
      users: {
        total: counts[0],
        active: counts[1],
        blocked: counts[2],
        verified: counts[3],
        byRole,
      },
      platform: {
        teams: counts[5],
        players: counts[6],
        tournaments: counts[7],
        matches: counts[8],
        liveMatches: counts[9],
        pendingTournamentTeams: counts[10],
      },
      recentAdminActions: counts[11].audits || [],
    };
  }

  async listUsers(query: Record<string, any> = {}): Promise<AdminListResult> {
    const { page, limit, skip, sort } = paginationOf(
      query,
      ['createdAt', 'updatedAt', 'name', 'email', 'role', 'isBlocked', 'isVerified'],
      'createdAt'
    );
    const filter: Record<string, any> = {};

    if (query.search) {
      const regex = new RegExp(escapeRegExp(String(query.search).trim()), 'i');
      filter.$or = [{ name: regex }, { email: regex }, { phone: regex }];
    }
    if (query.role) filter.role = query.role;
    if (query.isBlocked !== undefined) filter.isBlocked = query.isBlocked === true || query.isBlocked === 'true';
    if (query.isVerified !== undefined) filter.isVerified = query.isVerified === true || query.isVerified === 'true';
    if (query.from || query.to) {
      filter.createdAt = {};
      if (query.from) filter.createdAt.$gte = new Date(query.from);
      if (query.to) filter.createdAt.$lte = new Date(query.to);
    }

    const [users, total] = await Promise.all([
      User.find(filter).sort(sort as any).skip(skip).limit(limit).lean(),
      User.countDocuments(filter),
    ]);

    return paginate(
      users.map((user: any) => sanitize(user)),
      total,
      page,
      limit
    );
  }

  async getUserById(id: string): Promise<any> {
    if (!isObjectId(id)) throw ApiError.badRequest('Invalid user ID.');
    const user = await User.findById(id).lean();
    if (!user) throw ApiError.notFound('User not found.');
    return sanitize(user);
  }

  async legacyGetAllUsers(query: Record<string, any> = {}): Promise<AdminListResult> {
    return this.listUsers(query);
  }

  async legacyGetUserById(id: string): Promise<any> {
    return this.getUserById(id);
  }

  async legacyUpdateUser(req: Request, id: string, data: any): Promise<any> {
    if (!isObjectId(id)) throw ApiError.badRequest('Invalid user ID.');
    const user = await User.findById(id);
    if (!user) throw ApiError.notFound('User not found.');
    const before = sanitize(user);

    const { name, email, phone, role, isVerified, isBlocked, reason } = data || {};
    if (email && String(email).toLowerCase() !== String(user.email || '').toLowerCase()) {
      const emailExists = await User.findOne({ email: String(email).toLowerCase(), _id: { $ne: user._id } });
      if (emailExists) throw ApiError.conflict('Email address already in use by another user.');
      user.email = String(email).toLowerCase().trim();
    }
    if (phone && String(phone) !== String(user.phone || '')) {
      const phoneExists = await User.findOne({ phone: String(phone), _id: { $ne: user._id } });
      if (phoneExists) throw ApiError.conflict('Phone number already in use by another user.');
      user.phone = String(phone).trim();
    }
    if (name !== undefined) user.name = String(name).trim();
    if (role !== undefined) user.role = role;
    if (isVerified !== undefined) user.isVerified = Boolean(isVerified);
    if (isBlocked !== undefined) {
      user.isBlocked = Boolean(isBlocked);
      if (user.isBlocked) await RefreshToken.updateMany({ user: user._id }, { isRevoked: true });
    }
    await user.save();

    await this.audit(
      req,
      AdminAction.USER_UPDATED,
      { type: 'USER', id },
      { name: before.name, email: before.email, phone: before.phone, role: before.role, isBlocked: before.isBlocked, isVerified: before.isVerified },
      { name: user.name, email: user.email, phone: user.phone, role: user.role, isBlocked: user.isBlocked, isVerified: user.isVerified },
      reason
    );

    return sanitize(user);
  }

  async legacyBlockUser(req: Request, id: string, isBlocked: boolean | undefined, reason?: string): Promise<{ userId: string; isBlocked: boolean }> {
    const shouldBlock = isBlocked === undefined ? true : Boolean(isBlocked);
    const result = await this.setUserStatus(req, id, shouldBlock, reason || 'Legacy admin action');
    return { userId: String(result.user._id || id), isBlocked: Boolean(result.user.isBlocked) };
  }

  async legacyDeleteUser(req: Request, id: string, reason?: string): Promise<{ userId: string; deleted: boolean }> {
    const result = await this.setUserStatus(req, id, true, reason || 'Legacy admin delete');
    await this.audit(req, AdminAction.USER_DELETED, { type: 'USER', id }, undefined, { deleted: true, isBlocked: true }, reason);
    return { userId: String(result.user._id || id), deleted: true };
  }

  async legacyGetDashboardStats(): Promise<any> {
    return this.getDashboard();
  }

  async setUserStatus(
    req: Request,
    id: string,
    isBlocked: boolean,
    reason: string
  ): Promise<{ user: any }> {
    if (!isObjectId(id)) throw ApiError.badRequest('Invalid user ID.');
    const user = await User.findById(id);
    if (!user) throw ApiError.notFound('User not found.');

    const before = sanitize(user);
    user.isBlocked = isBlocked;
    await user.save();
    if (isBlocked) await RefreshToken.updateMany({ user: user._id }, { isRevoked: true });

    await this.audit(
      req,
      AdminAction.USER_STATUS_CHANGED,
      { type: 'USER', id },
      { isBlocked: before.isBlocked },
      { isBlocked: user.isBlocked },
      reason
    );

    return { user: sanitize(user) };
  }

  async setUserRole(req: Request, id: string, role: string, reason: string): Promise<{ user: any }> {
    if (!isObjectId(id)) throw ApiError.badRequest('Invalid user ID.');
    const user = await User.findById(id);
    if (!user) throw ApiError.notFound('User not found.');

    const before = sanitize(user);
    user.role = role;
    await user.save();
    if (before.role !== role) await RefreshToken.updateMany({ user: user._id }, { isRevoked: true });

    await this.audit(
      req,
      AdminAction.USER_ROLE_CHANGED,
      { type: 'USER', id },
      { role: before.role },
      { role: user.role },
      reason
    );

    return { user: sanitize(user) };
  }

  async listTeams(query: Record<string, any> = {}): Promise<AdminListResult> {
    const { page, limit, skip, sort } = paginationOf(
      query,
      ['createdAt', 'updatedAt', 'name', 'location', 'isActive'],
      'createdAt'
    );
    const filter: Record<string, any> = {};
    if (query.search) filter.name = new RegExp(escapeRegExp(String(query.search).trim()), 'i');
    if (query.city) filter.location = new RegExp(escapeRegExp(String(query.city).trim()), 'i');
    if (query.isActive !== undefined) filter.isActive = query.isActive === true || query.isActive === 'true';

    const [teams, total] = await Promise.all([
      Team.find(filter)
        .populate('owner', 'name avatar')
        .sort(sort as any)
        .skip(skip)
        .limit(limit)
        .lean(),
      Team.countDocuments(filter),
    ]);
    return paginate(teams, total, page, limit);
  }

  async getTeamById(id: string): Promise<any> {
    if (!isObjectId(id)) throw ApiError.badRequest('Invalid team ID.');
    const team = await Team.findById(id)
      .populate('owner', 'name avatar')
      .populate('captain', 'playingRole jerseyNumber')
      .lean();
    if (!team) throw ApiError.notFound('Team not found.');
    return team;
  }

  async setTeamStatus(
    req: Request,
    id: string,
    isActive: boolean,
    reason: string
  ): Promise<{ team: any }> {
    if (!isObjectId(id)) throw ApiError.badRequest('Invalid team ID.');
    const team = await Team.findById(id);
    if (!team) throw ApiError.notFound('Team not found.');

    const before = { isActive: Boolean(team.isActive) };
    team.isActive = isActive;
    await team.save();

    await this.audit(
      req,
      AdminAction.TEAM_STATUS_CHANGED,
      { type: 'TEAM', id },
      before,
      { isActive },
      reason
    );

    return { team: sanitize(team) };
  }

  async listPlayers(query: Record<string, any> = {}): Promise<AdminListResult> {
    const { page, limit, skip, sort } = paginationOf(
      query,
      ['createdAt', 'updatedAt', 'playingRole', 'city', 'jerseyNumber'],
      'createdAt'
    );
    const filter: Record<string, any> = {};
    const userFilter: Record<string, any> = {};

    if (query.search || query.isBlocked !== undefined || query.isVerified !== undefined) {
      if (query.search) {
        const regex = new RegExp(escapeRegExp(String(query.search).trim()), 'i');
        userFilter.name = regex;
      }
      if (query.isBlocked !== undefined) userFilter.isBlocked = query.isBlocked === true || query.isBlocked === 'true';
      if (query.isVerified !== undefined) userFilter.isVerified = query.isVerified === true || query.isVerified === 'true';
      const users = await User.find(userFilter).select('_id').lean();
      filter.user = { $in: users.map((user: any) => user._id) };
    }
    if (query.playingRole) filter.playingRole = query.playingRole;
    if (query.city) filter.city = new RegExp(escapeRegExp(String(query.city).trim()), 'i');

    const [players, total] = await Promise.all([
      Player.find(filter)
        .populate('user', 'name email avatar isBlocked isVerified role')
        .sort(sort as any)
        .skip(skip)
        .limit(limit)
        .lean(),
      Player.countDocuments(filter),
    ]);
    return paginate(players, total, page, limit);
  }

  async getPlayerById(id: string): Promise<any> {
    if (!isObjectId(id)) throw ApiError.badRequest('Invalid player ID.');
    const player = await Player.findById(id)
      .populate('user', 'name email avatar isBlocked isVerified role')
      .lean();
    if (!player) throw ApiError.notFound('Player not found.');
    const statistics = await playerStatisticsService.getPlayerStatistics(id);
    return { ...player, statistics };
  }

  async listTournaments(query: Record<string, any> = {}): Promise<AdminListResult> {
    const result = await tournamentService.getTournaments(query);
    return { data: result.tournaments as any[], pagination: result.pagination };
  }

  async getTournamentById(id: string): Promise<any> {
    return tournamentService.getTournamentById(id);
  }

  async setTournamentStatus(
    req: Request,
    id: string,
    status: TournamentStatus,
    reason: string,
    adminId: string
  ): Promise<any> {
    const before = await tournamentService.getTournamentById(id);
    const updated = await tournamentService.updateStatus(id, adminId, status);
    await this.audit(
      req,
      AdminAction.TOURNAMENT_STATUS_CHANGED,
      { type: 'TOURNAMENT', id },
      { status: before.status },
      { status: updated.status },
      reason
    );
    return updated;
  }

  async decideTournamentTeam(
    req: Request,
    id: string,
    teamId: string,
    decision: 'APPROVED' | 'REJECTED',
    reason: string,
    adminId: string
  ): Promise<any> {
    const before = await TournamentTeam.findOne({ tournament: id, team: teamId }).lean();
    const result =
      decision === 'APPROVED'
        ? await tournamentService.approveTeam(id, adminId, String((before as any)?._id || ''))
        : await tournamentService.rejectTeam(id, adminId, String((before as any)?._id || ''));

    await this.audit(
      req,
      AdminAction.TOURNAMENT_TEAM_DECISION,
      { type: 'TOURNAMENT_TEAM', id: String((before as any)?._id || teamId) },
      { status: (before as any)?.status },
      { status: (result as any)?.status, decision },
      reason,
      { tournamentId: id, teamId }
    );

    return result;
  }

  async listMatches(query: Record<string, any> = {}): Promise<AdminListResult> {
    const { page, limit, skip, sort } = paginationOf(
      query,
      ['createdAt', 'updatedAt', 'matchDate', 'status', 'title'],
      'matchDate'
    );
    const filter: Record<string, any> = {};
    if (query.status) filter.status = query.status;
    if (query.format) filter.format = query.format;
    if (query.tournament && isObjectId(query.tournament)) filter.tournament = new Types.ObjectId(String(query.tournament));
    if (query.team && isObjectId(query.team)) {
      const teamId = new Types.ObjectId(String(query.team));
      filter.$or = [{ teamA: teamId }, { teamB: teamId }];
    }
    if (query.city) filter.city = new RegExp(escapeRegExp(String(query.city).trim()), 'i');
    if (query.search) {
      const regex = new RegExp(escapeRegExp(String(query.search).trim()), 'i');
      filter.title = regex;
    }
    if (query.abandoned !== undefined) {
      filter.$or = [
        ...(filter.$or || []),
        { status: MatchStatus.ABANDONED },
        { 'result.resultType': ResultType.ABANDONED },
      ];
    }
    if (query.disputed !== undefined && query.disputed !== false) {
      filter['result.description'] = new RegExp('dispute|protest|challenge', 'i');
    }

    const [matches, total] = await Promise.all([
      Match.find(filter)
        .populate('teamA', 'name logo location')
        .populate('teamB', 'name logo location')
        .populate('tournament', 'name format matchFormat')
        .populate('scorer', 'name avatar')
        .populate('result.winner', 'name logo')
        .sort(sort as any)
        .skip(skip)
        .limit(limit)
        .lean(),
      Match.countDocuments(filter),
    ]);
    return paginate(matches, total, page, limit);
  }

  async getMatchById(id: string): Promise<any> {
    return matchService.getMatchById(id);
  }

  async getMatchScorecard(id: string): Promise<any> {
    return matchService.getMatchScorecard(id);
  }

  async getMatchEvents(id: string, query: Record<string, any> = {}): Promise<any[]> {
    const limit = Math.min(100, Math.max(1, Number(query.limit) || 50));
    const order = query.order === 'asc' ? 'asc' : 'desc';
    return scoringService.getCommentary(id, limit, order);
  }

  async setMatchStatus(
    req: Request,
    id: string,
    status: MatchStatus,
    reason: string
  ): Promise<{ match: any }> {
    if (!isObjectId(id)) throw ApiError.badRequest('Invalid match ID.');
    const match = await Match.findById(id);
    if (!match) throw ApiError.notFound('Match not found.');
    if (status !== MatchStatus.ABANDONED && status !== MatchStatus.CANCELLED) {
      throw ApiError.badRequest('Only ABANDONED or CANCELLED status can be set by an administrator.');
    }

    const before = sanitize(match);
    match.status = status;
    await match.save();

    await this.audit(
      req,
      AdminAction.MATCH_STATUS_CHANGED,
      { type: 'MATCH', id },
      { status: before.status },
      { status: match.status },
      reason
    );

    return { match: sanitize(match) };
  }

  async correctMatchDelivery(
    req: Request,
    id: string,
    input: { deliveryId: string; reason: string; [key: string]: any }
  ): Promise<any> {
    if (!isObjectId(id)) throw ApiError.badRequest('Invalid match ID.');
    if (!input.deliveryId || !isObjectId(input.deliveryId)) {
      throw ApiError.badRequest('A valid delivery ID is required.');
    }
    if (!input.reason || input.reason.trim().length < 3) {
      throw ApiError.badRequest('A reason of at least 3 characters is required for a correction.');
    }
    if (typeof scoringService.correctBall !== 'function') {
      throw ApiError.badRequest('Authoritative scoring correction is unavailable.');
    }

    const before = await Delivery.findOne({ _id: input.deliveryId, match: id }).lean();
    const correctionInput: Record<string, any> = {};
    ['runs', 'extraType', 'extraRuns', 'wicket', 'commentary', 'expectedVersion', 'idempotencyKey'].forEach(
      (key) => {
        if (input[key] !== undefined) correctionInput[key] = input[key];
      }
    );

    const result = await scoringService.correctBall(
      id,
      input.deliveryId,
      String(req.user?._id || req.user?.id || ''),
      correctionInput
    );

    await this.audit(
      req,
      AdminAction.MATCH_CORRECTION,
      { type: 'MATCH', id },
      { delivery: before },
      { commit: result?.commit },
      input.reason,
      { deliveryId: input.deliveryId, authoritative: true }
    );

    return result;
  }

  async listScoringAudits(query: Record<string, any> = {}): Promise<any> {
    return adminAuditService.listScoringActions(query);
  }

  async listAuctions(query: Record<string, any> = {}): Promise<any> {
    return auctionService.listAuctions(query);
  }

  async getAuctionById(req: Request, id: string): Promise<any> {
    const adminId = String(req.user?._id || req.user?.id || '');
    return auctionService.getAuctionById(id, adminId);
  }

  async getAuctionBids(id: string, query: Record<string, any> = {}): Promise<AdminListResult> {
    const { page, limit, skip, sort } = paginationOf(
      query,
      ['createdAt', 'sequenceNumber', 'amount'],
      'sequenceNumber'
    );
    const filter: Record<string, any> = { auction: new Types.ObjectId(id) };
    if (query.decision) filter.decision = query.decision;

    const [bids, total] = await Promise.all([
      AuctionBid.find(filter)
        .populate('team', 'name')
        .populate('bidBy', 'name')
        .populate('auction', 'name')
        .sort(sort as any)
        .skip(skip)
        .limit(limit)
        .lean(),
      AuctionBid.countDocuments(filter),
    ]);

    return paginate(bids, total, page, limit);
  }

  async getAuctionAudit(id: string, query: Record<string, any> = {}): Promise<any> {
    return adminAuditService.listAuctionActions({ ...query, auction: id });
  }

  async getSuspiciousBids(query: Record<string, any> = {}): Promise<AdminListResult> {
    const { page, limit, skip } = getPaginationParams(query, 20, 100, '-createdAt');
    const windowSeconds = Math.min(3600, Math.max(1, Number(query.windowSeconds) || 30));
    const start = new Date(Date.now() - windowSeconds * 1000);
    const bids = await AuctionBid.find({ createdAt: { $gte: start } })
      .populate('auction', 'name')
      .populate('team', 'name')
      .populate('bidBy', 'name')
      .sort({ createdAt: -1 })
      .lean();

    const groups = new Map<string, any[]>();
    bids.forEach((bid: any) => {
      const key = `${String(bid.auction)}:${String(bid.team)}:${String(bid.bidBy)}`;
      const list = groups.get(key) || [];
      list.push(bid);
      groups.set(key, list);
    });

    const suspicious = Array.from(groups.entries())
      .filter(([, list]) => list.length > 2)
      .map(([key, list]) => ({
        key,
        auction: list[0]?.auction,
        team: list[0]?.team,
        bidBy: list[0]?.bidBy,
        bidCount: list.length,
        windowSeconds,
        totalAmount: list.reduce((sum: number, bid: any) => sum + (Number(bid.amount) || 0), 0),
        latestAt: list[0]?.createdAt,
        bids: list.slice(0, 20),
      }))
      .sort((left, right) => right.bidCount - left.bidCount);

    return paginate(suspicious.slice(skip, skip + limit), suspicious.length, page, limit);
  }

  async broadcastNotification(
    req: Request,
    data: { title: string; body: string; type?: NotificationType; category?: NotificationCategory; role?: string; city?: string; userIds?: string[]; data?: Record<string, unknown>; reason?: string }
  ): Promise<any> {
    let recipients: string[] = [];
    if (data.userIds?.length) {
      recipients = data.userIds.map(String);
    } else if (data.city) {
      const players = await Player.find({ city: new RegExp(escapeRegExp(data.city.trim()), 'i') })
        .select('user')
        .lean();
      recipients = players.map((player: any) => String(player.user));
    } else {
      const filter: Record<string, any> = { isBlocked: false, isVerified: true };
      if (data.role) filter.role = data.role;
      const users = await User.find(filter).select('_id').lean();
      recipients = users.map((user: any) => String(user._id));
    }

    const sanitizedData = data.data && typeof data.data === 'object' ? redactSensitive(data.data) : {};
    const result = await notificationService.notifyUsers(recipients, {
      title: data.title,
      body: data.body,
      type: data.type || NotificationType.GENERAL,
      category: data.category,
      data: sanitizedData,
      dedupeKey: `admin-broadcast:${randomUUID()}`,
      relatedEntityType: 'AdminBroadcast',
    });

    await this.audit(
      req,
      AdminAction.NOTIFICATION_BROADCAST,
      { type: 'NOTIFICATION_BROADCAST', id: result.users[0] },
      undefined,
      { recipients: recipients.length, created: result.created, title: data.title },
      data.reason,
      { targeting: data.userIds ? 'users' : data.city ? 'city' : data.role ? 'role' : 'all' }
    );

    return { ...result, targeted: recipients.length };
  }

  async notifyUsersByIds(
    req: Request,
    data: { title: string; body: string; type?: NotificationType; category?: NotificationCategory; userIds: string[]; data?: Record<string, unknown>; reason?: string }
  ): Promise<any> {
    const result = await notificationService.notifyUsers(data.userIds.map(String), {
      title: data.title,
      body: data.body,
      type: data.type || NotificationType.GENERAL,
      category: data.category,
      data: data.data || {},
      dedupeKey: `admin-users:${randomUUID()}`,
      relatedEntityType: 'AdminNotification',
    });

    await this.audit(
      req,
      AdminAction.NOTIFICATION_USERS,
      { type: 'NOTIFICATION_USERS', id: result.users[0] },
      undefined,
      { recipients: data.userIds.length, created: result.created, title: data.title },
      data.reason
    );

    return result;
  }

  async listNotificationDeliveries(query: Record<string, any> = {}): Promise<AdminListResult> {
    const { page, limit, skip, sort } = paginationOf(
      query,
      ['createdAt', 'updatedAt', 'status', 'attempts'],
      'createdAt'
    );
    const filter: Record<string, any> = {};
    if (query.status) filter.status = query.status;
    if (query.notification && isObjectId(query.notification)) {
      filter.notification = new Types.ObjectId(String(query.notification));
    }

    const [deliveries, total] = await Promise.all([
      NotificationDelivery.find(filter)
        .populate('notification', 'title type category user createdAt')
        .sort(sort as any)
        .skip(skip)
        .limit(limit)
        .lean(),
      NotificationDelivery.countDocuments(filter),
    ]);
    return paginate(deliveries, total, page, limit);
  }

  async listResultAudits(query: Record<string, any> = {}): Promise<AdminListResult> {
    const { page, limit, skip, sort } = paginationOf(
      query,
      ['createdAt', 'updatedAt', 'matchDate', 'status'],
      'matchDate'
    );
    const filter: Record<string, any> = {};
    if (query.status) filter.status = query.status;
    if (query.format) filter.format = query.format;
    if (query.resultType) filter['result.resultType'] = query.resultType;
    if (query.disputed !== undefined && query.disputed !== false) {
      filter['result.description'] = new RegExp('dispute|protest|challenge', 'i');
    }

    const [matches, total] = await Promise.all([
      Match.find(filter)
        .populate('teamA', 'name logo')
        .populate('teamB', 'name logo')
        .populate('tournament', 'name')
        .populate('result.winner', 'name logo')
        .sort(sort as any)
        .skip(skip)
        .limit(limit)
        .lean(),
      Match.countDocuments(filter),
    ]);
    return paginate(matches, total, page, limit);
  }

  async getReport(query: { report: string; from: Date | string; to: Date | string; page?: number; limit?: number }): Promise<any> {
    const from = new Date(query.from);
    const to = new Date(query.to);
    const createdAt = { $gte: from, $lte: to };
    const report = String(query.report);
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.min(500, Math.max(1, Number(query.limit) || 100));
    const skip = (page - 1) * limit;

    const build = async (rows: any[], total: number) => ({
      report, from, to, total, rows,
      pagination: buildPaginationResponse(total, page, limit),
    });

    if (report === 'registrations') {
      const [users, total] = await Promise.all([
        User.find({ createdAt })
          .select('name email phone role isVerified isBlocked createdAt')
          .sort({ createdAt: -1 }).skip(skip).limit(limit).lean(),
        User.countDocuments({ createdAt }),
      ]);
      return build(users.map(sanitize), total);
    }
    if (report === 'tournaments') {
      const [tournaments, total] = await Promise.all([
        Tournament.find({ createdAt }).populate('organizer', 'name avatar').sort({ createdAt: -1 }).skip(skip).limit(limit).lean(),
        Tournament.countDocuments({ createdAt }),
      ]);
      return build(tournaments, total);
    }
    if (report === 'matches') {
      const [matches, total] = await Promise.all([
        Match.find({ createdAt })
          .populate('teamA', 'name').populate('teamB', 'name').populate('tournament', 'name')
          .sort({ createdAt: -1 }).skip(skip).limit(limit).lean(),
        Match.countDocuments({ createdAt }),
      ]);
      return build(matches, total);
    }
    if (report === 'teams') {
      const [teams, total] = await Promise.all([
        Team.find({ createdAt }).populate('owner', 'name avatar').sort({ createdAt: -1 }).skip(skip).limit(limit).lean(),
        Team.countDocuments({ createdAt }),
      ]);
      return build(teams, total);
    }
    if (report === 'players') {
      const [players, total] = await Promise.all([
        Player.find({ createdAt }).populate('user', 'name avatar').sort({ createdAt: -1 }).skip(skip).limit(limit).lean(),
        Player.countDocuments({ createdAt }),
      ]);
      return build(players, total);
    }
    throw ApiError.badRequest('Unsupported report type.');
  }

  async exportReport(query: { report: string; from: Date | string; to: Date | string }): Promise<string> {
    const from = new Date(query.from);
    const to = new Date(query.to);
    const createdAt = { $gte: from, $lte: to };
    const report = String(query.report);
    const batchSize = 500;
    let skip = 0;
    let columns: string[] = [];
    const lines: string[] = [];
    let total = 0;

    const fetchBatch = async (): Promise<any[]> => {
      if (report === 'registrations') {
        const rows = await User.find({ createdAt }).select('name email phone role isVerified isBlocked createdAt').sort({ createdAt: -1 }).skip(skip).limit(batchSize).lean();
        return rows.map(sanitize);
      }
      if (report === 'tournaments') return Tournament.find({ createdAt }).populate('organizer', 'name avatar').sort({ createdAt: -1 }).skip(skip).limit(batchSize).lean();
      if (report === 'matches') return Match.find({ createdAt }).populate('teamA', 'name').populate('teamB', 'name').populate('tournament', 'name').sort({ createdAt: -1 }).skip(skip).limit(batchSize).lean();
      if (report === 'teams') return Team.find({ createdAt }).populate('owner', 'name avatar').sort({ createdAt: -1 }).skip(skip).limit(batchSize).lean();
      if (report === 'players') return Player.find({ createdAt }).populate('user', 'name avatar').sort({ createdAt: -1 }).skip(skip).limit(batchSize).lean();
      throw ApiError.badRequest('Unsupported report type.');
    };

    while (true) {
      const rows = await fetchBatch();
      if (!rows.length) break;
      total += rows.length;
      if (columns.length === 0) {
        columns = Array.from(new Set(rows.flatMap((row) => Object.keys(sanitize(row)).filter((key) => !key.startsWith('_')))));
        lines.push(columns.join(','));
      }
      const cell = (value: unknown): string => {
        if (value === undefined || value === null) return '';
        const text = value instanceof Date ? value.toISOString() : String(value);
        return `"${text.replace(/"/g, '""')}"`;
      };
      for (const row of rows) {
        const value = sanitize(row);
        lines.push(columns.map((column) => cell(value[column])).join(','));
      }
      if (rows.length < batchSize) break;
      skip += batchSize;
    }

    if (total === 0) return `${report},from,to,total\n${report},${from.toISOString()},${to.toISOString()},0\n`;
    return lines.join('\n');
  }
}

export const adminService = new AdminService();
export default adminService;
