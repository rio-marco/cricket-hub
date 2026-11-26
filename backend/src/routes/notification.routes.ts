import { Router } from 'express';
import {
  deleteNotification,
  getNotificationById,
  getNotifications,
  getPreferences,
  getUnreadCount,
  listDeviceTokens,
  markAllAsRead,
  markAsRead,
  registerDeviceToken,
  removeDeviceToken,
  updatePreferences,
} from '../controllers/notification.controller';
import { protect } from '../middlewares/auth.middleware';
import { validate } from '../middlewares/validate.middleware';
import {
  listNotificationsQuerySchema,
  notificationIdParamSchema,
  notificationPreferencesSchema,
  registerDeviceTokenSchema,
  removeDeviceTokenSchema,
} from '../validators/notification.validator';

const router = Router();

router.use(protect);

router.get('/', validate(listNotificationsQuerySchema, 'query'), getNotifications);
router.get('/unread-count', getUnreadCount);
router.get('/preferences', getPreferences);
router.put('/preferences', validate(notificationPreferencesSchema, 'body'), updatePreferences);
router.get('/device-tokens', listDeviceTokens);
router.post('/device-token', validate(registerDeviceTokenSchema, 'body'), registerDeviceToken);
router.delete('/device-token', validate(removeDeviceTokenSchema, 'body'), removeDeviceToken);
router.post('/read-all', markAllAsRead);

router.get('/:id', validate(notificationIdParamSchema, 'params'), getNotificationById);
router.patch('/:id/read', validate(notificationIdParamSchema, 'params'), markAsRead);
router.delete('/:id', validate(notificationIdParamSchema, 'params'), deleteNotification);

export default router;
