import { NotificationInput } from './notification.service';
import notificationService from './notification.service';
import { logger } from '../utils/logger';

export const notifySafely = async (
  recipients: Array<string | { toString(): string } | undefined | null>,
  input: NotificationInput
): Promise<void> => {
  const userIds = recipients
    .map((recipient) => (recipient ? String(recipient) : ''))
    .filter((id) => /^[0-9a-fA-F]{24}$/.test(id));
  if (!userIds.length) return;

  try {
    await notificationService.notifyUsers(userIds, input);
  } catch (error: any) {
    logger.error('[Notifications] Failed to create notification:', {
      type: input.type,
      message: error?.message || 'Unknown notification error',
    });
  }
};

export default notifySafely;
