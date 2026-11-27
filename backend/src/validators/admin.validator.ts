import Joi from 'joi';
import { AdminAction } from '../constants/admin';
import {
  AuctionAuditAction,
  AuctionBidDecision,
  AuctionStatus,
  DismissalType,
  ExtraType,
  MatchFormat,
  MatchStatus,
  NotificationCategory,
  NotificationDeliveryStatus,
  NotificationType,
  PlayingRole,
  ResultType,
  TournamentFormat,
  TournamentStatus,
} from '../constants/enums';
import { USER_ROLES } from '../constants/roles';
import { ScoringAuditAction } from '../models/ScoringAudit';

const objectId = Joi.string().trim().pattern(/^[0-9a-fA-F]{24}$/);
const reason = Joi.string().trim().min(3).max(500).required();
const optionalReason = Joi.string().trim().min(3).max(500);
const sortField = (fields: string[]) =>
  Joi.string()
    .trim()
    .pattern(new RegExp(`^-?(${fields.join('|')})$`));

const paginationKeys = (fields: string[]) => ({
  page: Joi.number().integer().min(1).max(100000).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
  sort: sortField(fields),
  order: Joi.string().valid('asc', 'desc'),
  from: Joi.date().iso(),
  to: Joi.date().iso().min(Joi.ref('from')),
});

export const adminLoginSchema = Joi.object({
  email: Joi.string().trim().email().lowercase(),
  phone: Joi.string().trim().pattern(/^\+?[0-9]{10,15}$/),
  password: Joi.string().required(),
}).xor('email', 'phone');

export const adminIdParamSchema = Joi.object({
  id: objectId.required(),
});

export const adminTeamDecisionParamSchema = Joi.object({
  id: objectId.required(),
  teamId: objectId.required(),
});

export const adminCorrectionParamSchema = Joi.object({
  id: objectId.required(),
});

export const adminUserQuerySchema = Joi.object({
  ...paginationKeys(['createdAt', 'updatedAt', 'name', 'email', 'role', 'isBlocked', 'isVerified']),
  search: Joi.string().trim().max(100).allow(''),
  role: Joi.string().valid(...USER_ROLES),
  isBlocked: Joi.boolean(),
  isVerified: Joi.boolean(),
});

export const adminUserStatusSchema = Joi.object({
  isBlocked: Joi.boolean().required(),
  reason,
});

export const adminUserRoleSchema = Joi.object({
  role: Joi.string().valid(...USER_ROLES).required(),
  reason,
});

export const legacyBlockUserSchema = Joi.object({
  isBlocked: Joi.boolean(),
  reason: optionalReason.default('Legacy administrative status update'),
});

export const legacyUpdateUserSchema = Joi.object({
  name: Joi.string().trim().min(2).max(50),
  email: Joi.string().trim().email().lowercase(),
  phone: Joi.string().trim().pattern(/^\+?[0-9]{10,15}$/),
  role: Joi.string().valid(...USER_ROLES),
  isVerified: Joi.boolean(),
  isBlocked: Joi.boolean(),
  reason: optionalReason.default('Legacy administrative profile update'),
}).min(1);

export const adminTeamQuerySchema = Joi.object({
  ...paginationKeys(['createdAt', 'updatedAt', 'name', 'location', 'isActive']),
  search: Joi.string().trim().max(100).allow(''),
  city: Joi.string().trim().max(100).allow(''),
  isActive: Joi.boolean(),
});

export const adminTeamStatusSchema = Joi.object({
  isActive: Joi.boolean().required(),
  reason,
});

export const adminPlayerQuerySchema = Joi.object({
  ...paginationKeys(['createdAt', 'updatedAt', 'playingRole', 'city', 'jerseyNumber']),
  search: Joi.string().trim().max(100).allow(''),
  playingRole: Joi.string().valid(...Object.values(PlayingRole)),
  city: Joi.string().trim().max(100).allow(''),
  isBlocked: Joi.boolean(),
  isVerified: Joi.boolean(),
});

export const adminTournamentQuerySchema = Joi.object({
  ...paginationKeys(['createdAt', 'updatedAt', 'name', 'startDate', 'endDate', 'status']),
  search: Joi.string().trim().max(100).allow(''),
  status: Joi.string().valid(...Object.values(TournamentStatus)),
  format: Joi.string().valid(...Object.values(TournamentFormat)),
  city: Joi.string().trim().max(100).allow(''),
  organizer: objectId,
});

export const adminTournamentStatusSchema = Joi.object({
  status: Joi.string().valid(...Object.values(TournamentStatus)).required(),
  reason,
});

export const adminTournamentDecisionSchema = Joi.object({
  decision: Joi.string().valid('APPROVED', 'REJECTED').required(),
  reason,
});

export const adminMatchQuerySchema = Joi.object({
  ...paginationKeys(['createdAt', 'updatedAt', 'matchDate', 'status', 'title']),
  search: Joi.string().trim().max(100).allow(''),
  status: Joi.string().valid(...Object.values(MatchStatus)),
  format: Joi.string().valid(...Object.values(MatchFormat)),
  tournament: objectId,
  team: objectId,
  city: Joi.string().trim().max(100).allow(''),
  disputed: Joi.boolean(),
  abandoned: Joi.boolean(),
});

export const adminMatchStatusSchema = Joi.object({
  status: Joi.string().valid(MatchStatus.ABANDONED, MatchStatus.CANCELLED).required(),
  reason,
});

export const adminMatchCorrectionSchema = Joi.object({
  deliveryId: objectId.required(),
  reason,
  runs: Joi.number().integer().min(0).max(20),
  extraType: Joi.string().valid(...Object.values(ExtraType)),
  extraRuns: Joi.number().integer().min(0).max(20),
  wicket: Joi.object({
    type: Joi.string().valid(...Object.values(DismissalType)).required(),
    batter: objectId,
    fielder: objectId,
    description: Joi.string().trim().max(200).allow(''),
  }),
  commentary: Joi.string().trim().max(500).allow(''),
  expectedVersion: Joi.number().integer().min(0),
  idempotencyKey: Joi.string().trim().min(3).max(100),
});

export const adminScoringQuerySchema = Joi.object({
  ...paginationKeys(['createdAt', 'action', 'match', 'stateVersion', 'sequenceNumber']),
  match: objectId,
  action: Joi.string().valid(...Object.values(ScoringAuditAction)),
  actor: objectId,
});

export const adminAuctionQuerySchema = Joi.object({
  ...paginationKeys(['createdAt', 'updatedAt', 'name', 'status']),
  status: Joi.string().valid(...Object.values(AuctionStatus)),
  search: Joi.string().trim().max(100).allow(''),
  tournament: objectId,
  team: objectId,
});

export const adminAuctionHistoryQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).max(100000).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
  sort: sortField(['createdAt', 'sequenceNumber', 'amount']),
  order: Joi.string().valid('asc', 'desc'),
  decision: Joi.string().valid(...Object.values(AuctionBidDecision)),
});

export const adminAuctionAuditQuerySchema = Joi.object({
  ...paginationKeys(['createdAt', 'action', 'auction', 'stateVersion', 'sequenceNumber']),
  auction: objectId,
  action: Joi.string().valid(...Object.values(AuctionAuditAction)),
  actor: objectId,
});

export const adminAuctionSuspiciousQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).max(100000).default(1),
  limit: Joi.number().integer().min(1).max(100).default(20),
  windowSeconds: Joi.number().integer().min(1).max(3600).default(30),
});

export const adminNotificationBroadcastSchema = Joi.object({
  title: Joi.string().trim().min(3).max(120).required(),
  body: Joi.string().trim().min(3).max(1000).required(),
  type: Joi.string().valid(...Object.values(NotificationType)).default(NotificationType.GENERAL),
  category: Joi.string().valid(...Object.values(NotificationCategory)),
  role: Joi.string().valid(...USER_ROLES),
  city: Joi.string().trim().max(100).allow(''),
  userIds: Joi.array().items(objectId).min(1).max(1000),
  data: Joi.object().max(30),
  reason: optionalReason,
});

export const adminNotificationUsersSchema = Joi.object({
  title: Joi.string().trim().min(3).max(120).required(),
  body: Joi.string().trim().min(3).max(1000).required(),
  type: Joi.string().valid(...Object.values(NotificationType)).default(NotificationType.GENERAL),
  category: Joi.string().valid(...Object.values(NotificationCategory)),
  userIds: Joi.array().items(objectId).min(1).max(1000).required(),
  data: Joi.object().max(30),
  reason: optionalReason,
});

export const adminNotificationDeliveryQuerySchema = Joi.object({
  ...paginationKeys(['createdAt', 'updatedAt', 'status', 'attempts']),
  status: Joi.string().valid(...Object.values(NotificationDeliveryStatus)),
  notification: objectId,
});

export const adminReportQuerySchema = Joi.object({
  report: Joi.string()
    .valid('registrations', 'tournaments', 'matches', 'teams', 'players')
    .required(),
  from: Joi.date().iso().required(),
  to: Joi.date().iso().min(Joi.ref('from')).required(),
  page: Joi.number().integer().min(1).max(100000).default(1),
  limit: Joi.number().integer().min(1).max(500).default(100),
});

export const adminAuditQuerySchema = Joi.object({
  ...paginationKeys(['createdAt', 'action', 'adminId', 'targetType']),
  adminId: objectId,
  action: Joi.string().valid(...Object.values(AdminAction)),
  targetType: Joi.string().trim().max(100),
  targetId: Joi.string().trim().max(100),
});

export const adminResultAuditQuerySchema = Joi.object({
  ...paginationKeys(['createdAt', 'updatedAt', 'matchDate', 'status', 'title', 'action', 'resultType']),
  status: Joi.string().valid(...Object.values(MatchStatus)),
  format: Joi.string().valid(...Object.values(MatchFormat)),
  resultType: Joi.string().valid(...Object.values(ResultType)),
  disputed: Joi.boolean(),
});

export default {
  adminLoginSchema,
  adminIdParamSchema,
  adminTeamDecisionParamSchema,
  adminCorrectionParamSchema,
  adminUserQuerySchema,
  adminUserStatusSchema,
  adminUserRoleSchema,
  legacyBlockUserSchema,
  legacyUpdateUserSchema,
  adminTeamQuerySchema,
  adminTeamStatusSchema,
  adminPlayerQuerySchema,
  adminTournamentQuerySchema,
  adminTournamentStatusSchema,
  adminTournamentDecisionSchema,
  adminMatchQuerySchema,
  adminMatchStatusSchema,
  adminMatchCorrectionSchema,
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
};
