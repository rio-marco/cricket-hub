import { Request, Response } from 'express';
import { MatchStatus, TournamentStatus } from '../constants/enums';
import adminService from '../services/admin.service';
import { adminAuditService } from '../services/adminAudit.service';
import { asyncHandler } from '../utils/asyncHandler';
import { ApiResponse } from '../utils/apiResponse';

const requestParam = (value: string | string[]): string => (Array.isArray(value) ? value[0] : value);

export const adminLogin = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminService.loginAdmin(req, req.body);
  ApiResponse.success(res, 200, 'Administrator login successful.', result);
});

export const getDashboard = asyncHandler(async (_req: Request, res: Response): Promise<void> => {
  const stats = await adminService.getDashboard();
  ApiResponse.success(res, 200, 'Administrative dashboard retrieved successfully.', stats);
});

export const listUsers = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminService.listUsers(req.query);
  ApiResponse.paginated(
    res,
    result.data,
    result.pagination.page,
    result.pagination.limit,
    result.pagination.total,
    'Users retrieved successfully.'
  );
});

export const getUser = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const user = await adminService.getUserById(requestParam(req.params.id));
  ApiResponse.success(res, 200, 'User retrieved successfully.', user);
});

export const setUserStatus = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminService.setUserStatus(req, requestParam(req.params.id), req.body.isBlocked, req.body.reason);
  ApiResponse.success(
    res,
    200,
    result.user.isBlocked ? 'User has been blocked successfully.' : 'User has been unblocked successfully.',
    result
  );
});

export const setUserRole = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminService.setUserRole(req, requestParam(req.params.id), req.body.role, req.body.reason);
  ApiResponse.success(res, 200, 'User role updated successfully.', result);
});

export const listTeams = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminService.listTeams(req.query);
  ApiResponse.paginated(
    res,
    result.data,
    result.pagination.page,
    result.pagination.limit,
    result.pagination.total,
    'Teams retrieved successfully.'
  );
});

export const getTeam = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const team = await adminService.getTeamById(requestParam(req.params.id));
  ApiResponse.success(res, 200, 'Team retrieved successfully.', team);
});

export const setTeamStatus = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminService.setTeamStatus(req, requestParam(req.params.id), req.body.isActive, req.body.reason);
  ApiResponse.success(
    res,
    200,
    result.team.isActive ? 'Team activated successfully.' : 'Team deactivated successfully.',
    result
  );
});

export const listPlayers = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminService.listPlayers(req.query);
  ApiResponse.paginated(
    res,
    result.data,
    result.pagination.page,
    result.pagination.limit,
    result.pagination.total,
    'Players retrieved successfully.'
  );
});

export const getPlayer = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const player = await adminService.getPlayerById(requestParam(req.params.id));
  ApiResponse.success(res, 200, 'Player retrieved successfully.', player);
});

export const listTournaments = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminService.listTournaments(req.query);
  ApiResponse.paginated(
    res,
    result.data,
    result.pagination.page,
    result.pagination.limit,
    result.pagination.total,
    'Tournaments retrieved successfully.'
  );
});

export const getTournament = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const tournament = await adminService.getTournamentById(requestParam(req.params.id));
  ApiResponse.success(res, 200, 'Tournament retrieved successfully.', tournament);
});

export const setTournamentStatus = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const tournament = await adminService.setTournamentStatus(
    req,
    requestParam(req.params.id),
    req.body.status as TournamentStatus,
    req.body.reason,
    String(req.user?._id || req.user?.id || '')
  );
  ApiResponse.success(res, 200, 'Tournament status updated successfully.', tournament);
});

export const decideTournamentTeam = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminService.decideTournamentTeam(
    req,
    requestParam(req.params.id),
    requestParam(req.params.teamId),
    req.body.decision,
    req.body.reason,
    String(req.user?._id || req.user?.id || '')
  );
  ApiResponse.success(
    res,
    200,
    req.body.decision === 'APPROVED'
      ? 'Tournament team approved successfully.'
      : 'Tournament team rejected successfully.',
    result
  );
});

export const listMatches = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminService.listMatches(req.query);
  ApiResponse.paginated(
    res,
    result.data,
    result.pagination.page,
    result.pagination.limit,
    result.pagination.total,
    'Matches retrieved successfully.'
  );
});

export const getMatch = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const match = await adminService.getMatchById(requestParam(req.params.id));
  ApiResponse.success(res, 200, 'Match retrieved successfully.', match);
});

export const getMatchScorecard = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const scorecard = await adminService.getMatchScorecard(requestParam(req.params.id));
  ApiResponse.success(res, 200, 'Match scorecard retrieved successfully.', scorecard);
});

export const getMatchEvents = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const events = await adminService.getMatchEvents(requestParam(req.params.id), req.query);
  ApiResponse.success(res, 200, 'Match events retrieved successfully.', events);
});

export const setMatchStatus = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminService.setMatchStatus(
    req,
    requestParam(req.params.id),
    req.body.status as MatchStatus,
    req.body.reason
  );
  ApiResponse.success(res, 200, 'Match status updated successfully.', result);
});

export const correctMatchDelivery = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminService.correctMatchDelivery(req, requestParam(req.params.id), req.body);
  ApiResponse.success(res, 200, 'Scoring correction applied successfully.', result);
});

export const listScoringAudits = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminService.listScoringAudits(req.query);
  const pagination = result.pagination || {};
  ApiResponse.paginated(
    res,
    result.audits,
    pagination.page || 1,
    pagination.limit || 20,
    pagination.total || 0,
    'Scoring audits retrieved successfully.'
  );
});

export const listAuctions = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminService.listAuctions(req.query);
  ApiResponse.paginated(
    res,
    result.data,
    result.pagination.page,
    result.pagination.limit,
    result.pagination.total,
    'Auctions retrieved successfully.'
  );
});

export const getAuction = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const auction = await adminService.getAuctionById(req, requestParam(req.params.id));
  ApiResponse.success(res, 200, 'Auction retrieved successfully.', auction);
});

export const getAuctionBids = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminService.getAuctionBids(requestParam(req.params.id), req.query);
  ApiResponse.paginated(
    res,
    result.data,
    result.pagination.page,
    result.pagination.limit,
    result.pagination.total,
    'Auction bids retrieved successfully.'
  );
});

export const getAuctionAudit = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminService.getAuctionAudit(requestParam(req.params.id), req.query);
  const pagination = result.pagination || {};
  ApiResponse.paginated(
    res,
    result.audits,
    pagination.page || 1,
    pagination.limit || 20,
    pagination.total || 0,
    'Auction audit trail retrieved successfully.'
  );
});

export const getSuspiciousBids = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminService.getSuspiciousBids(req.query);
  ApiResponse.paginated(
    res,
    result.data,
    result.pagination.page,
    result.pagination.limit,
    result.pagination.total,
    'Suspicious auction activity retrieved successfully.'
  );
});

export const broadcastNotification = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminService.broadcastNotification(req, req.body);
  ApiResponse.success(res, 200, 'Notification broadcast processed successfully.', result);
});

export const notifyUsers = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminService.notifyUsersByIds(req, req.body);
  ApiResponse.success(res, 200, 'Notifications sent successfully.', result);
});

export const listNotificationDeliveries = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminService.listNotificationDeliveries(req.query);
  ApiResponse.paginated(
    res,
    result.data,
    result.pagination.page,
    result.pagination.limit,
    result.pagination.total,
    'Notification deliveries retrieved successfully.'
  );
});

export const getReport = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const report = await adminService.getReport(req.query as any);
  ApiResponse.success(res, 200, 'Report generated successfully.', report);
});

export const exportReport = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const csv = await adminService.exportReport(req.query as any);
  res.status(200).type('text/csv').send(csv);
});

export const listAdminAudits = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminAuditService.listAdminActions(req.query as any);
  const pagination = result.pagination || {};
  ApiResponse.paginated(
    res,
    result.audits,
    pagination.page || 1,
    pagination.limit || 20,
    pagination.total || 0,
    'Administrative audit trail retrieved successfully.'
  );
});

export const listAuctionAudits = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminAuditService.listAuctionActions(req.query as any);
  const pagination = result.pagination || {};
  ApiResponse.paginated(
    res,
    result.audits,
    pagination.page || 1,
    pagination.limit || 20,
    pagination.total || 0,
    'Auction audit trail retrieved successfully.'
  );
});

export const listResultAudits = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminService.listResultAudits(req.query);
  ApiResponse.paginated(
    res,
    result.data,
    result.pagination.page,
    result.pagination.limit,
    result.pagination.total,
    'Result audit records retrieved successfully.'
  );
});

export const legacyGetDashboardStats = asyncHandler(async (_req: Request, res: Response): Promise<void> => {
  const stats = await adminService.getDashboard();
  ApiResponse.success(res, 200, 'Dashboard statistics retrieved successfully.', {
    users: stats.users,
    platform: {
      teams: stats.platform.teams,
      players: stats.platform.players,
      tournaments: stats.platform.tournaments,
      matches: stats.platform.matches,
    },
  });
});

export const legacyGetAllUsers = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminService.listUsers({
    ...req.query,
    limit: req.query.limit === undefined ? 10 : req.query.limit,
  });
  ApiResponse.paginated(
    res,
    result.data,
    result.pagination.page,
    result.pagination.limit,
    result.pagination.total,
    'Users retrieved successfully.'
  );
});

export const legacyGetUserById = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const user = await adminService.getUserById(requestParam(req.params.id));
  ApiResponse.success(res, 200, 'User retrieved successfully.', user);
});

export const legacyUpdateUser = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const user = await adminService.legacyUpdateUser(req, requestParam(req.params.id), req.body);
  ApiResponse.success(res, 200, 'User updated successfully.', user);
});

export const legacyBlockUser = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminService.legacyBlockUser(req, requestParam(req.params.id), req.body.isBlocked, req.body.reason);
  ApiResponse.success(
    res,
    200,
    result.isBlocked ? 'User has been blocked successfully.' : 'User has been unblocked successfully.',
    result
  );
});

export const legacyDeleteUser = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await adminService.softDeleteUser(req, requestParam(req.params.id));
  ApiResponse.success(res, 200, 'User soft-deleted and access revoked successfully.', result);
});

export default {
  adminLogin,
  getDashboard,
  listUsers,
  getUser,
  setUserStatus,
  setUserRole,
  listTeams,
  getTeam,
  setTeamStatus,
  listPlayers,
  getPlayer,
  listTournaments,
  getTournament,
  setTournamentStatus,
  decideTournamentTeam,
  listMatches,
  getMatch,
  getMatchScorecard,
  getMatchEvents,
  setMatchStatus,
  correctMatchDelivery,
  listScoringAudits,
  listAuctions,
  getAuction,
  getAuctionBids,
  getAuctionAudit,
  getSuspiciousBids,
  broadcastNotification,
  notifyUsers,
  listNotificationDeliveries,
  getReport,
  exportReport,
  listAdminAudits,
  listAuctionAudits,
  listResultAudits,
  legacyGetDashboardStats,
  legacyGetAllUsers,
  legacyGetUserById,
  legacyUpdateUser,
  legacyBlockUser,
  legacyDeleteUser,
};
