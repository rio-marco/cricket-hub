import { Types } from 'mongoose';
import { env } from '../config/env';
import { NotificationDeliveryStatus } from '../constants/enums';
import DeviceToken from '../models/DeviceToken';
import Notification from '../models/Notification';
import NotificationDelivery from '../models/NotificationDelivery';
import { logger } from '../utils/logger';
import { FcmMessage, FcmSender, FirebaseFcmSender } from './fcmSender.service';

type DeliveryRow = {
  _id: Types.ObjectId;
  notification: Types.ObjectId;
  deviceToken: Types.ObjectId;
  status: NotificationDeliveryStatus;
  attempts: number;
  maxAttempts: number;
  nextAttemptAt?: Date;
};

export interface DeliveryProcessingResult {
  sent: number;
  failed: number;
  cancelled: number;
  processed: number;
}

const toFcmData = (data?: Record<string, any>): Record<string, string> | undefined => {
  if (!data || typeof data !== 'object' || Array.isArray(data)) return undefined;
  const result: Record<string, string> = {};
  for (const [key, value] of Object.entries(data)) {
    if (value === undefined || value === null) continue;
    result[key] = typeof value === 'string' ? value : JSON.stringify(value);
  }
  return Object.keys(result).length ? result : undefined;
};

const nextRetryAt = (attempts: number): Date => {
  const delayMs = Math.min(15 * 60 * 1000, 1000 * Math.pow(2, Math.max(0, attempts - 1)));
  return new Date(Date.now() + delayMs);
};

export class NotificationDeliveryService {
  private scheduled = false;
  private worker: NodeJS.Timeout | null = null;

  constructor(private readonly sender: FcmSender = new FirebaseFcmSender()) {}

  async createDeliveries(notificationId: Types.ObjectId | string, tokens: string[]): Promise<number> {
    const uniqueTokens = Array.from(new Set(tokens.map((token) => String(token).trim()).filter(Boolean)));
    if (!uniqueTokens.length) return 0;

    const deviceTokens = await DeviceToken.find({
      token: { $in: uniqueTokens },
      isActive: true,
    })
      .select('_id token')
      .lean();
    if (!deviceTokens.length) return 0;

    await NotificationDelivery.insertMany(
      deviceTokens.map((deviceToken: any) => ({
        notification: notificationId,
        deviceToken: deviceToken._id,
        status: NotificationDeliveryStatus.PENDING,
        attempts: 0,
        maxAttempts: 5,
        nextAttemptAt: new Date(),
      })),
      { ordered: false }
    );

    await DeviceToken.updateMany(
      { _id: { $in: deviceTokens.map((deviceToken: any) => deviceToken._id) } },
      { $set: { lastUsedAt: new Date() } }
    );

    return deviceTokens.length;
  }

  scheduleProcessing(): void {
    if (this.scheduled) return;
    this.scheduled = true;
    setImmediate(() => {
      this.scheduled = false;
      void this.processPendingDeliveries().catch((error) => {
        logger.error('[Notifications] Failed to process pending deliveries:', error);
      });
    });
  }

  startWorker(intervalMs: number = env.FIREBASE_PUSH_RETRY_INTERVAL_MS): void {
    if (this.worker || intervalMs <= 0) return;
    this.worker = setInterval(() => {
      void this.processPendingDeliveries().catch((error) => {
        logger.error('[Notifications] Delivery retry worker failed:', error);
      });
    }, intervalMs);
    this.worker.unref();
  }

  stopWorker(): void {
    if (!this.worker) return;
    clearInterval(this.worker);
    this.worker = null;
  }

  async processPendingDeliveries(
    limit: number = env.FIREBASE_PUSH_RETRY_BATCH_SIZE
  ): Promise<DeliveryProcessingResult> {
    const result: DeliveryProcessingResult = { sent: 0, failed: 0, cancelled: 0, processed: 0 };
    const safeLimit = Math.min(Math.max(1, limit), 100);
    const deliveries = (await NotificationDelivery.find({
      status: NotificationDeliveryStatus.PENDING,
      nextAttemptAt: { $lte: new Date() },
    })
      .sort({ nextAttemptAt: 1 })
      .limit(safeLimit)
      .lean()) as unknown as DeliveryRow[];

    if (deliveries.length === 0) return result;

    const notificationIds = Array.from(
      new Set(deliveries.map((d) => String(d.notification)))
    ).map((id) => new Types.ObjectId(id));
    const deviceTokenIds = Array.from(
      new Set(deliveries.map((d) => String(d.deviceToken)))
    ).map((id) => new Types.ObjectId(id));

    const [notifications, deviceTokens] = await Promise.all([
      Notification.find({ _id: { $in: notificationIds } })
        .select('_id user type category title body data relatedEntityType relatedEntityId')
        .lean(),
      DeviceToken.find({ _id: { $in: deviceTokenIds } })
        .select('_id token user isActive')
        .lean(),
    ]);

    const notificationById = new Map<string, any>(
      notifications.map((n: any) => [String(n._id), n])
    );
    const deviceTokenById = new Map<string, any>(
      deviceTokens.map((t: any) => [String(t._id), t])
    );

    for (const delivery of deliveries) {
      const outcome = await this.processOne(
        delivery,
        notificationById.get(String(delivery.notification)),
        deviceTokenById.get(String(delivery.deviceToken))
      );
      result.processed += 1;
      if (outcome === 'sent') result.sent += 1;
      if (outcome === 'failed') result.failed += 1;
      if (outcome === 'cancelled') result.cancelled += 1;
    }

    return result;
  }

  private async processOne(
    delivery: DeliveryRow,
    notification?: any,
    deviceToken?: any
  ): Promise<'sent' | 'failed' | 'cancelled'> {
    if (!notification) {
      await NotificationDelivery.findByIdAndUpdate(delivery._id, {
        $set: {
          status: NotificationDeliveryStatus.CANCELLED,
          lastErrorCode: 'NOTIFICATION_MISSING',
          lastError: 'Notification no longer exists.',
        },
      });
      return 'cancelled';
    }

    if (!deviceToken || !deviceToken.isActive) {
      await NotificationDelivery.findByIdAndUpdate(delivery._id, {
        $set: {
          status: NotificationDeliveryStatus.CANCELLED,
          lastErrorCode: 'DEVICE_TOKEN_INACTIVE',
          lastError: 'Device token is no longer active.',
        },
      });
      return 'cancelled';
    }

    if (String(deviceToken.user) !== String(notification.user)) {
      await DeviceToken.findByIdAndUpdate(deviceToken._id, {
        $set: { isActive: false, lastError: 'Device token ownership mismatch', lastUsedAt: new Date() },
      });
      await NotificationDelivery.findByIdAndUpdate(delivery._id, {
        $set: {
          status: NotificationDeliveryStatus.CANCELLED,
          lastErrorCode: 'DEVICE_TOKEN_OWNER_MISMATCH',
          lastError: 'Device token ownership mismatch.',
        },
      });
      return 'cancelled';
    }

    const attempts = Number(delivery.attempts || 0) + 1;
    const message: FcmMessage = {
      title: String(notification.title),
      body: String(notification.body),
      data: {
        ...(toFcmData(notification.data) || {}),
        notificationId: String(notification._id),
        type: String(notification.type),
        category: String(notification.category || 'SYSTEM'),
        ...(notification.relatedEntityType ? { relatedEntityType: String(notification.relatedEntityType) } : {}),
        ...(notification.relatedEntityId ? { relatedEntityId: String(notification.relatedEntityId) } : {}),
      },
    };

    try {
      const sendResult = await this.sender.send(String(deviceToken.token), message);
      if (sendResult.success) {
        await NotificationDelivery.findByIdAndUpdate(delivery._id, {
          $set: {
            status: NotificationDeliveryStatus.SENT,
            attempts,
            lastAttemptAt: new Date(),
            sentAt: new Date(),
            lastErrorCode: undefined,
            lastError: undefined,
          },
        });
        return 'sent';
      }

      if (sendResult.invalidToken) {
        await DeviceToken.findByIdAndUpdate(deviceToken._id, { $set: { isActive: false } });
        await NotificationDelivery.findByIdAndUpdate(delivery._id, {
          $set: {
            status: NotificationDeliveryStatus.CANCELLED,
            attempts,
            lastAttemptAt: new Date(),
            lastErrorCode: sendResult.errorCode || 'INVALID_TOKEN',
            lastError: sendResult.error || 'Invalid device token.',
          },
        });
        return 'cancelled';
      }

      const exhausted = !sendResult.retryable || attempts >= Number(delivery.maxAttempts || 5);
      await NotificationDelivery.findByIdAndUpdate(delivery._id, {
        $set: {
          status: exhausted
            ? NotificationDeliveryStatus.FAILED
            : NotificationDeliveryStatus.PENDING,
          attempts,
          lastAttemptAt: new Date(),
          nextAttemptAt: exhausted ? new Date() : nextRetryAt(attempts),
          lastErrorCode: sendResult.errorCode || 'FCM_DELIVERY_FAILED',
          lastError: sendResult.error || 'FCM delivery failed.',
        },
      });
      return exhausted ? 'failed' : 'failed';
    } catch (error: any) {
      const exhausted = attempts >= Number(delivery.maxAttempts || 5);
      await NotificationDelivery.findByIdAndUpdate(delivery._id, {
        $set: {
          status: exhausted
            ? NotificationDeliveryStatus.FAILED
            : NotificationDeliveryStatus.PENDING,
          attempts,
          lastAttemptAt: new Date(),
          nextAttemptAt: exhausted ? new Date() : nextRetryAt(attempts),
          lastErrorCode: 'FCM_DELIVERY_EXCEPTION',
          lastError: typeof error?.message === 'string' ? error.message : 'FCM delivery failed.',
        },
      });
      return 'failed';
    }
  }
}

export const notificationDeliveryService = new NotificationDeliveryService();
export default notificationDeliveryService;
