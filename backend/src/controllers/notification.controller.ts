import { Request, Response } from 'express';
import { MESSAGES } from '../constants/messages';
import notificationService from '../services/notification.service';
import { ApiResponse } from '../utils/apiResponse';
import { asyncHandler } from '../utils/asyncHandler';

const userIdOf = (req: Request): string => String(req.user!._id);

export const getNotifications = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const result = await notificationService.getNotifications(userIdOf(req), req.query);
  ApiResponse.paginated(
    res,
    result.data,
    result.pagination.page,
    result.pagination.limit,
    result.pagination.total,
    MESSAGES.NOTIFICATION.FETCHED
  );
});

export const getNotificationById = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const notification = await notificationService.getNotificationById(
    userIdOf(req),
    req.params.id as string
  );
  ApiResponse.success(res, 200, MESSAGES.NOTIFICATION.FETCHED, notification);
});

export const getUnreadCount = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const count = await notificationService.getUnreadCount(userIdOf(req));
  ApiResponse.success(res, 200, MESSAGES.NOTIFICATION.UNREAD_COUNT_FETCHED, { count });
});

export const markAsRead = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const notification = await notificationService.markAsRead(userIdOf(req), req.params.id as string);
  ApiResponse.success(res, 200, MESSAGES.NOTIFICATION.MARKED_READ, notification);
});

export const markAllAsRead = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const modifiedCount = await notificationService.markAllAsRead(userIdOf(req));
  ApiResponse.success(res, 200, MESSAGES.NOTIFICATION.ALL_MARKED_READ, { modifiedCount });
});

export const deleteNotification = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  await notificationService.deleteNotification(userIdOf(req), req.params.id as string);
  ApiResponse.success(res, 200, MESSAGES.NOTIFICATION.DELETED);
});

export const registerDeviceToken = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const token = await notificationService.registerDeviceToken(userIdOf(req), req.body);
  ApiResponse.success(res, 201, MESSAGES.NOTIFICATION.DEVICE_TOKEN_REGISTERED, token);
});

export const removeDeviceToken = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  await notificationService.removeDeviceToken(userIdOf(req), req.body.token);
  ApiResponse.success(res, 200, MESSAGES.NOTIFICATION.DEVICE_TOKEN_REMOVED);
});

export const listDeviceTokens = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const tokens = await notificationService.listDeviceTokens(userIdOf(req));
  ApiResponse.success(res, 200, MESSAGES.NOTIFICATION.DEVICE_TOKENS_FETCHED, tokens);
});

export const getPreferences = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const preferences = await notificationService.getPreferences(userIdOf(req));
  ApiResponse.success(res, 200, MESSAGES.NOTIFICATION.PREFERENCES_FETCHED, preferences);
});

export const updatePreferences = asyncHandler(async (req: Request, res: Response): Promise<void> => {
  const preferences = await notificationService.updatePreferences(userIdOf(req), req.body);
  ApiResponse.success(res, 200, MESSAGES.NOTIFICATION.PREFERENCES_UPDATED, preferences);
});

export default {
  getNotifications,
  getNotificationById,
  getUnreadCount,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  registerDeviceToken,
  removeDeviceToken,
  listDeviceTokens,
  getPreferences,
  updatePreferences,
};
