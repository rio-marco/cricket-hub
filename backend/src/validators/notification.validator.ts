import Joi from 'joi';
import { DevicePlatform, NotificationCategory, NotificationType } from '../constants/enums';

const objectIdPattern = /^[0-9a-fA-F]{24}$/;
const timePattern = /^([01]\d|2[0-3]):[0-5]\d$/;

export const listNotificationsQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).max(100000).optional(),
  limit: Joi.number().integer().min(1).max(100).optional(),
  isRead: Joi.boolean().optional(),
  type: Joi.string().valid(...Object.values(NotificationType)).optional(),
  category: Joi.string().valid(...Object.values(NotificationCategory)).optional(),
  relatedEntityId: Joi.string().trim().max(50).optional(),
  from: Joi.date().iso().optional(),
  to: Joi.date().iso().optional(),
  sort: Joi.string().trim().pattern(/^-?[a-zA-Z][a-zA-Z0-9-]*$/).optional(),
  order: Joi.string().valid('asc', 'desc').optional(),
});

export const notificationIdParamSchema = Joi.object({
  id: Joi.string().trim().pattern(objectIdPattern).required(),
});

export const registerDeviceTokenSchema = Joi.object({
  token: Joi.string().trim().min(10).max(2048).required(),
  platform: Joi.string().valid(...Object.values(DevicePlatform)).required(),
  deviceId: Joi.string().trim().max(150).optional().allow(''),
  appVersion: Joi.string().trim().max(50).optional().allow(''),
});

export const removeDeviceTokenSchema = Joi.object({
  token: Joi.string().trim().min(10).max(2048).required(),
});

export const notificationPreferencesSchema = Joi.object({
  pushEnabled: Joi.boolean().optional(),
  teamInvitations: Joi.boolean().optional(),
  joinRequests: Joi.boolean().optional(),
  tournamentUpdates: Joi.boolean().optional(),
  matchReminders: Joi.boolean().optional(),
  matchResults: Joi.boolean().optional(),
  liveScoreUpdates: Joi.boolean().optional(),
  wicketAlerts: Joi.boolean().optional(),
  overAlerts: Joi.boolean().optional(),
  inningsAlerts: Joi.boolean().optional(),
  auctionUpdates: Joi.boolean().optional(),
  quietHoursEnabled: Joi.boolean().optional(),
  quietHoursStart: Joi.string().pattern(timePattern).optional(),
  quietHoursEnd: Joi.string().pattern(timePattern).optional(),
}).min(1);

export default {
  listNotificationsQuerySchema,
  notificationIdParamSchema,
  registerDeviceTokenSchema,
  removeDeviceTokenSchema,
  notificationPreferencesSchema,
};
