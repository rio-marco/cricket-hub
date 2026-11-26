import { Router } from 'express';
import { AdminPermission } from '../constants/admin';
import { authorizeAdmin } from '../middlewares/admin.middleware';
import { protect } from '../middlewares/auth.middleware';
import { adminLimiter } from '../middlewares/rateLimiter.middleware';
import { validate } from '../middlewares/validate.middleware';
import {
  adminIdParamSchema,
  adminLoginSchema,
  adminTeamDecisionParamSchema,
  adminUserQuerySchema,
  adminUserStatusSchema,
  adminUserRoleSchema,
  adminTeamQuerySchema,
  adminTeamStatusSchema,
  adminPlayerQuerySchema,
  adminTournamentQuerySchema,
  adminTournamentStatusSchema,
  adminTournamentDecisionSchema,
  adminMatchCorrectionSchema,
  adminMatchQuerySchema,
  adminMatchStatusSchema,
  adminScoringQuerySchema,
  adminAuctionQuerySchema,
  adminAuctionHistoryQuerySchema,
  adminAuctionAuditQuerySchema,
  adminAuctionSuspiciousQuerySchema,
  adminNotificationBroadcastSchema,
  adminNotificationUsersSchema,
  adminNotificationDeliveryQuerySchema,
  adminReportQuerySchema,
  adminAuditQuerySchema,
  adminResultAuditQuerySchema,
} from '../validators/admin.validator';
import * as adminController from '../controllers/admin.controller';

const router = Router();

router.post('/auth/login', adminLimiter, validate(adminLoginSchema), adminController.adminLogin);

router.use(protect, adminLimiter, authorizeAdmin());

router.get('/dashboard', authorizeAdmin(AdminPermission.DASHBOARD_READ), adminController.getDashboard);

router.get('/users', authorizeAdmin(AdminPermission.USERS_MANAGE), validate(adminUserQuerySchema, 'query'), adminController.listUsers);
router.get('/users/:id', authorizeAdmin(AdminPermission.USERS_MANAGE), validate(adminIdParamSchema, 'params'), adminController.getUser);
router.patch('/users/:id/status', authorizeAdmin(AdminPermission.USERS_MANAGE), validate(adminIdParamSchema, 'params'), validate(adminUserStatusSchema), adminController.setUserStatus);
router.patch('/users/:id/role', authorizeAdmin(AdminPermission.USERS_MANAGE), validate(adminIdParamSchema, 'params'), validate(adminUserRoleSchema), adminController.setUserRole);

router.get('/teams', authorizeAdmin(AdminPermission.TEAMS_MANAGE), validate(adminTeamQuerySchema, 'query'), adminController.listTeams);
router.get('/teams/:id', authorizeAdmin(AdminPermission.TEAMS_MANAGE), validate(adminIdParamSchema, 'params'), adminController.getTeam);
router.patch('/teams/:id/status', authorizeAdmin(AdminPermission.TEAMS_MANAGE), validate(adminIdParamSchema, 'params'), validate(adminTeamStatusSchema), adminController.setTeamStatus);

router.get('/players', authorizeAdmin(AdminPermission.PLAYERS_READ), validate(adminPlayerQuerySchema, 'query'), adminController.listPlayers);
router.get('/players/:id', authorizeAdmin(AdminPermission.PLAYERS_READ), validate(adminIdParamSchema, 'params'), adminController.getPlayer);

router.get('/tournaments', authorizeAdmin(AdminPermission.TOURNAMENTS_MANAGE), validate(adminTournamentQuerySchema, 'query'), adminController.listTournaments);
router.get('/tournaments/:id', authorizeAdmin(AdminPermission.TOURNAMENTS_MANAGE), validate(adminIdParamSchema, 'params'), adminController.getTournament);
router.patch('/tournaments/:id/status', authorizeAdmin(AdminPermission.TOURNAMENTS_MANAGE), validate(adminIdParamSchema, 'params'), validate(adminTournamentStatusSchema), adminController.setTournamentStatus);
router.patch('/tournaments/:id/teams/:teamId/decision', authorizeAdmin(AdminPermission.TOURNAMENTS_MANAGE), validate(adminTeamDecisionParamSchema, 'params'), validate(adminTournamentDecisionSchema), adminController.decideTournamentTeam);

router.get('/matches', authorizeAdmin(AdminPermission.MATCHES_MANAGE), validate(adminMatchQuerySchema, 'query'), adminController.listMatches);
router.get('/matches/:id/scorecard', authorizeAdmin(AdminPermission.MATCHES_MANAGE), validate(adminIdParamSchema, 'params'), adminController.getMatchScorecard);
router.get('/matches/:id/events', authorizeAdmin(AdminPermission.SCORING_AUDIT_READ), validate(adminIdParamSchema, 'params'), validate(adminScoringQuerySchema, 'query'), adminController.getMatchEvents);
router.get('/matches/:id', authorizeAdmin(AdminPermission.MATCHES_MANAGE), validate(adminIdParamSchema, 'params'), adminController.getMatch);
router.patch('/matches/:id/status', authorizeAdmin(AdminPermission.MATCHES_MANAGE), validate(adminIdParamSchema, 'params'), validate(adminMatchStatusSchema), adminController.setMatchStatus);
router.post('/matches/:id/corrections', authorizeAdmin(AdminPermission.SCORING_AUDIT_READ), validate(adminIdParamSchema, 'params'), validate(adminMatchCorrectionSchema), adminController.correctMatchDelivery);

router.get('/auctions/suspicious-bids', authorizeAdmin(AdminPermission.AUCTIONS_READ), validate(adminAuctionSuspiciousQuerySchema, 'query'), adminController.getSuspiciousBids);
router.get('/auctions', authorizeAdmin(AdminPermission.AUCTIONS_READ), validate(adminAuctionQuerySchema, 'query'), adminController.listAuctions);
router.get('/auctions/:id/bids', authorizeAdmin(AdminPermission.AUCTIONS_READ), validate(adminIdParamSchema, 'params'), validate(adminAuctionHistoryQuerySchema, 'query'), adminController.getAuctionBids);
router.get('/auctions/:id/audit', authorizeAdmin(AdminPermission.AUCTIONS_READ), validate(adminIdParamSchema, 'params'), validate(adminAuctionAuditQuerySchema, 'query'), adminController.getAuctionAudit);
router.get('/auctions/:id', authorizeAdmin(AdminPermission.AUCTIONS_READ), validate(adminIdParamSchema, 'params'), adminController.getAuction);

router.post('/notifications/broadcast', authorizeAdmin(AdminPermission.NOTIFICATIONS_SEND), validate(adminNotificationBroadcastSchema), adminController.broadcastNotification);
router.post('/notifications/users', authorizeAdmin(AdminPermission.NOTIFICATIONS_SEND), validate(adminNotificationUsersSchema), adminController.notifyUsers);
router.get('/notifications/deliveries', authorizeAdmin(AdminPermission.NOTIFICATIONS_READ), validate(adminNotificationDeliveryQuerySchema, 'query'), adminController.listNotificationDeliveries);

router.get('/reports/export', authorizeAdmin(AdminPermission.REPORTS_READ), validate(adminReportQuerySchema, 'query'), adminController.exportReport);
router.get('/reports', authorizeAdmin(AdminPermission.REPORTS_READ), validate(adminReportQuerySchema, 'query'), adminController.getReport);

router.get('/audits/scoring', authorizeAdmin(AdminPermission.AUDITS_READ), validate(adminScoringQuerySchema, 'query'), adminController.listScoringAudits);
router.get('/audits/results', authorizeAdmin(AdminPermission.AUDITS_READ), validate(adminResultAuditQuerySchema, 'query'), adminController.listResultAudits);
router.get('/audits/auction', authorizeAdmin(AdminPermission.AUDITS_READ), validate(adminAuctionAuditQuerySchema, 'query'), adminController.listAuctionAudits);
router.get('/audits', authorizeAdmin(AdminPermission.AUDITS_READ), validate(adminAuditQuerySchema, 'query'), adminController.listAdminAudits);

export default router;
