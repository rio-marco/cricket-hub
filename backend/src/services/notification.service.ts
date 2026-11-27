import { Types } from 'mongoose';
import { DevicePlatform, NotificationCategory, NotificationType } from '../constants/enums';
import { MESSAGES } from '../constants/messages';
import DeviceToken from '../models/DeviceToken';
import Notification, { INotification } from '../models/Notification';
import NotificationPreference, { INotificationPreference } from '../models/NotificationPreference';
import User from '../models/User';
import { NOTIFICATION_EVENTS, publishNotificationEvent } from '../sockets/publisher';
import { ApiError } from '../utils/apiError';
import { buildPaginationResponse, getPaginationParams } from '../utils/pagination';
import notificationDeliveryService, { NotificationDeliveryService } from './notificationDelivery.service';

export interface NotificationInput {
  type: NotificationType;
  title: string;
  body: string;
  data?: Record<string, any>;
  category?: NotificationCategory;
  relatedEntityType?: string;
  relatedEntityId?: string;
  dedupeKey?: string;
  expiresAt?: Date;
}

export interface DeviceTokenInput {
  token: string;
  platform: DevicePlatform;
  deviceId?: string;
  appVersion?: string;
}

export interface NotificationResult {
  created: number;
  skipped: number;
  users: string[];
  failed?: number;
  errors?: Array<{ userId: string; error: string }>;
}

const categoryByType: Record<NotificationType, NotificationCategory> = {
  [NotificationType.TEAM_INVITATION]: NotificationCategory.TEAM,
  [NotificationType.TEAM_INVITATION_ACCEPTED]: NotificationCategory.TEAM,
  [NotificationType.TEAM_INVITATION_REJECTED]: NotificationCategory.TEAM,
  [NotificationType.JOIN_REQUEST]: NotificationCategory.TEAM,
  [NotificationType.JOIN_REQUEST_APPROVED]: NotificationCategory.TEAM,
  [NotificationType.JOIN_REQUEST_REJECTED]: NotificationCategory.TEAM,
  [NotificationType.TOURNAMENT_REGISTRATION]: NotificationCategory.TOURNAMENT,
  [NotificationType.TOURNAMENT_REGISTRATION_APPROVED]: NotificationCategory.TOURNAMENT,
  [NotificationType.TOURNAMENT_REGISTRATION_REJECTED]: NotificationCategory.TOURNAMENT,
  [NotificationType.TOURNAMENT_STATUS]: NotificationCategory.TOURNAMENT,
  [NotificationType.MATCH_REMINDER]: NotificationCategory.MATCH,
  [NotificationType.MATCH_STARTED]: NotificationCategory.MATCH,
  [NotificationType.MATCH_TOSS]: NotificationCategory.MATCH,
  [NotificationType.MATCH_INNINGS_STARTED]: NotificationCategory.MATCH,
  [NotificationType.MATCH_INNINGS_ENDED]: NotificationCategory.MATCH,
  [NotificationType.MATCH_OVER_COMPLETED]: NotificationCategory.MATCH,
  [NotificationType.MATCH_WICKET]: NotificationCategory.MATCH,
  [NotificationType.MATCH_SCORE_UPDATE]: NotificationCategory.MATCH,
  [NotificationType.MATCH_RESULT]: NotificationCategory.MATCH,
  [NotificationType.AUCTION_UPDATE]: NotificationCategory.AUCTION,
  [NotificationType.AUCTION_STARTED]: NotificationCategory.AUCTION,
  [NotificationType.AUCTION_PAUSED]: NotificationCategory.AUCTION,
  [NotificationType.AUCTION_RESUMED]: NotificationCategory.AUCTION,
  [NotificationType.AUCTION_PLAYER_FORWARD]: NotificationCategory.AUCTION,
  [NotificationType.AUCTION_BID_PLACED]: NotificationCategory.AUCTION,
  [NotificationType.AUCTION_BID_OUTBID]: NotificationCategory.AUCTION,
  [NotificationType.AUCTION_PLAYER_SOLD]: NotificationCategory.AUCTION,
  [NotificationType.AUCTION_PLAYER_UNSOLD]: NotificationCategory.AUCTION,
  [NotificationType.AUCTION_COMPLETED]: NotificationCategory.AUCTION,
  [NotificationType.GENERAL]: NotificationCategory.SYSTEM,
};

const serializeNotification = (notification: any) => ({
  id: String(notification._id ?? notification.id),
  user: String(notification.user),
  type: notification.type,
  category: notification.category,
  title: notification.title,
  body: notification.body,
  data: notification.data && typeof notification.data === 'object' ? notification.data : {},
  relatedEntityType: notification.relatedEntityType,
  relatedEntityId: notification.relatedEntityId,
  isRead: Boolean(notification.isRead),
  readAt: notification.readAt,
  createdAt: notification.createdAt,
  updatedAt: notification.updatedAt,
});

const serializeDeviceToken = (token: any) => ({
  id: String(token._id),
  platform: token.platform,
  deviceId: token.deviceId,
  appVersion: token.appVersion,
  isActive: Boolean(token.isActive),
  lastUsedAt: token.lastUsedAt,
  createdAt: token.createdAt,
});

const serializePreference = (preference: any) => ({
  pushEnabled: Boolean(preference.pushEnabled),
  teamInvitations: Boolean(preference.teamInvitations),
  joinRequests: Boolean(preference.joinRequests),
  tournamentUpdates: Boolean(preference.tournamentUpdates),
  matchReminders: Boolean(preference.matchReminders),
  matchResults: Boolean(preference.matchResults),
  liveScoreUpdates: Boolean(preference.liveScoreUpdates),
  wicketAlerts: Boolean(preference.wicketAlerts),
  overAlerts: Boolean(preference.overAlerts),
  inningsAlerts: Boolean(preference.inningsAlerts),
  auctionUpdates: Boolean(preference.auctionUpdates),
  quietHoursEnabled: Boolean(preference.quietHoursEnabled),
  quietHoursStart: preference.quietHoursStart,
  quietHoursEnd: preference.quietHoursEnd,
});

const notExpired = () => ({
  $or: [{ expiresAt: { $exists: false } }, { expiresAt: { $gt: new Date() } }],
});

const toMinutes = (time?: string): number => {
  const [hours, minutes] = String(time || '00:00').split(':').map(Number);
  return Number.isFinite(hours) && Number.isFinite(minutes) ? hours * 60 + minutes : 0;
};

const defaultPushPreferences: Partial<INotificationPreference> = {
  pushEnabled: true,
  teamInvitations: true,
  joinRequests: true,
  tournamentUpdates: true,
  matchReminders: true,
  matchResults: true,
  liveScoreUpdates: false,
  wicketAlerts: true,
  overAlerts: false,
  inningsAlerts: true,
  auctionUpdates: true,
  quietHoursEnabled: false,
  quietHoursStart: '22:00',
  quietHoursEnd: '08:00',
};

export class NotificationService {
  constructor(private readonly deliveryService: NotificationDeliveryService = notificationDeliveryService) {}

  async notifyUsers(userIds: Array<string | Types.ObjectId>, input: NotificationInput): Promise<NotificationResult> {
    const recipients = Array.from(
      new Set(userIds.map((id) => String(id)).filter((id) => /^[0-9a-fA-F]{24}$/.test(id)))
    );
    if (!recipients.length || !input?.type || !input?.title || !input?.body) {
      return { created: 0, skipped: recipients.length, users: [] };
    }

    const BATCH_SIZE = 100;
    const createdUsers: string[] = [];
    const errors: Array<{ userId: string; error: string }> = [];
    let skipped = 0;

    for (let i = 0; i < recipients.length; i += BATCH_SIZE) {
      const batch = recipients.slice(i, i + BATCH_SIZE);

      const [preferences, existingDedupe, tokens] = await Promise.all([
        NotificationPreference.find({ user: { $in: batch } }).lean(),
        input.dedupeKey
          ? Notification.find({ user: { $in: batch }, dedupeKey: input.dedupeKey })
              .select('user')
              .lean()
          : Promise.resolve([]),
        DeviceToken.find({ user: { $in: batch }, isActive: true }).select('user token').lean(),
      ]);

      const preferenceByUser = new Map<string, Partial<INotificationPreference>>(
        batch.map((userId) => [
          userId,
          (preferences.find((p: any) => String(p.user) === userId) ||
            defaultPushPreferences) as Partial<INotificationPreference>,
        ])
      );

      const dedupeUserIds = new Set(existingDedupe.map((n: any) => String(n.user)));
      const tokensByUser = new Map<string, string[]>();
      for (const t of tokens as any[]) {
        const uid = String(t.user);
        const list = tokensByUser.get(uid) || [];
        list.push(String(t.token));
        tokensByUser.set(uid, list);
      }

      const notificationsToCreate: Array<Partial<INotification>> = [];
      for (const userId of batch) {
        if (dedupeUserIds.has(userId)) {
          skipped += 1;
          continue;
        }
        notificationsToCreate.push({
          user: new Types.ObjectId(userId),
          type: input.type,
          category: input.category || categoryByType[input.type] || NotificationCategory.SYSTEM,
          title: input.title,
          body: input.body,
          data: input.data || {},
          relatedEntityType: input.relatedEntityType,
          relatedEntityId: input.relatedEntityId,
          dedupeKey: input.dedupeKey,
          expiresAt: input.expiresAt,
          isRead: false,
        });
      }

      if (!notificationsToCreate.length) continue;

      let createdNotifications: any[] = [];
      try {
        createdNotifications = await Notification.insertMany(notificationsToCreate, { ordered: false });
      } catch (error: any) {
        if (error?.writeErrors || error?.insertedDocs) {
          createdNotifications = Array.isArray(error.insertedDocs) ? error.insertedDocs : [];
          const writeErrors = Array.isArray(error.writeErrors) ? error.writeErrors : [];
          for (const we of writeErrors) {
            if (we?.code === 11000 && input.dedupeKey) {
              skipped += 1;
              continue;
            }
            const failedDoc = notificationsToCreate[we?.index];
            const uid = failedDoc ? String(failedDoc.user) : 'unknown';
            errors.push({ userId: uid, error: we?.errmsg || 'Failed to create notification' });
          }
        } else {
          throw error;
        }
      }

      if (createdNotifications.length === 0) continue;

      const createdUserIds = createdNotifications.map((n: any) => String(n.user));
      createdUsers.push(...createdUserIds);

      // Batch unread counts for created users
      const unreadCounts = await Notification.aggregate<{ _id: Types.ObjectId; count: number }>([
        { $match: { user: { $in: createdUserIds.map((id) => new Types.ObjectId(id)) }, isRead: false, ...notExpired() } },
        { $group: { _id: '$user', count: { $sum: 1 } } },
      ]);
      const unreadByUser = new Map<string, number>(
        unreadCounts.map((r) => [String(r._id), r.count])
      );

      for (const notification of createdNotifications) {
        const userId = String(notification.user);
        const serialized = serializeNotification(notification);
        const unreadCount = unreadByUser.get(userId) ?? 1;
        publishNotificationEvent(userId, NOTIFICATION_EVENTS.created, {
          eventId: `${serialized.id}:created`,
          notification: serialized,
          unreadCount,
        });
        publishNotificationEvent(userId, NOTIFICATION_EVENTS.unreadCount, {
          eventId: `${serialized.id}:unread-count`,
          unreadCount,
        });

        const preference = preferenceByUser.get(userId);
        if (preference && this.canPush(preference, input.type)) {
          const userTokens = tokensByUser.get(userId) || [];
          if (userTokens.length > 0) {
            try {
              await this.deliveryService.createDeliveries(notification._id, userTokens);
              this.deliveryService.scheduleProcessing();
            } catch (deliveryError: any) {
              errors.push({
                userId,
                error: deliveryError?.message || 'Failed to create delivery records',
              });
            }
          }
        }
      }
    }

    const result: NotificationResult = {
      created: createdUsers.length,
      skipped: recipients.length - createdUsers.length - errors.length,
      users: createdUsers,
    };
    if (errors.length > 0) {
      result.failed = errors.length;
      result.errors = errors;
    }
    return result;
  }

  async notifyUser(userId: string | Types.ObjectId, input: NotificationInput): Promise<NotificationResult> {
    return this.notifyUsers([userId], input);
  }

  async getNotifications(userId: string, query: Record<string, any> = {}) {
    const { page, limit, skip, sort } = getPaginationParams(query, 20, 100, '-createdAt', ['createdAt','updatedAt','readAt','type','category','isRead']);
    const filter: Record<string, any> = {
      user: new Types.ObjectId(userId),
      ...notExpired(),
    };

    if (typeof query.isRead === 'boolean') {
      filter.isRead = query.isRead;
    } else if (
      typeof query.isRead === 'string' &&
      ['true', 'false'].includes(query.isRead.toLowerCase())
    ) {
      filter.isRead = query.isRead.toLowerCase() === 'true';
    }
    if (typeof query.type === 'string') filter.type = query.type;
    if (typeof query.category === 'string') filter.category = query.category;
    if (typeof query.relatedEntityId === 'string') filter.relatedEntityId = query.relatedEntityId;

    const createdFrom = this.parseDate(query.from);
    const createdTo = this.parseDate(query.to);
    if (createdFrom || createdTo) {
      filter.createdAt = {};
      if (createdFrom) filter.createdAt.$gte = createdFrom;
      if (createdTo) filter.createdAt.$lte = createdTo;
    }

    const [notifications, total] = await Promise.all([
      Notification.find(filter).sort(sort).skip(skip).limit(limit).lean(),
      Notification.countDocuments(filter),
    ]);

    return {
      data: notifications.map(serializeNotification),
      pagination: buildPaginationResponse(total, page, limit),
    };
  }

  async getUnreadCount(userId: string): Promise<number> {
    return Notification.countDocuments({
      user: new Types.ObjectId(userId),
      isRead: false,
      ...notExpired(),
    });
  }

  async getNotificationById(userId: string, notificationId: string): Promise<any> {
    if (!/^[0-9a-fA-F]{24}$/.test(notificationId)) {
      throw ApiError.badRequest('Invalid notification ID.');
    }
    const notification = await Notification.findOne({
      _id: notificationId,
      user: new Types.ObjectId(userId),
      ...notExpired(),
    }).lean();
    if (!notification) throw ApiError.notFound(MESSAGES.NOTIFICATION.NOT_FOUND);
    return serializeNotification(notification);
  }

  async markAsRead(userId: string, notificationId: string): Promise<any> {
    if (!/^[0-9a-fA-F]{24}$/.test(notificationId)) {
      throw ApiError.badRequest('Invalid notification ID.');
    }

    const notification = await Notification.findOneAndUpdate(
      { _id: notificationId, user: userId },
      { $set: { isRead: true, readAt: new Date() } },
      { new: true }
    ).lean();
    if (!notification) throw ApiError.notFound(MESSAGES.NOTIFICATION.NOT_FOUND);

    const serialized = serializeNotification(notification);
    const unreadCount = await this.getUnreadCount(userId);
    publishNotificationEvent(userId, NOTIFICATION_EVENTS.read, {
      eventId: `${serialized.id}:read`,
      notification: serialized,
      unreadCount,
    });
    publishNotificationEvent(userId, NOTIFICATION_EVENTS.unreadCount, {
      eventId: `${serialized.id}:read-unread-count`,
      unreadCount,
    });
    return serialized;
  }

  async markAllAsRead(userId: string): Promise<number> {
    const result = await Notification.updateMany(
      { user: userId, isRead: false },
      { $set: { isRead: true, readAt: new Date() } }
    );
    publishNotificationEvent(userId, NOTIFICATION_EVENTS.unreadCount, {
      eventId: `${userId}:${Date.now()}:all-read`,
      unreadCount: 0,
    });
    return result.modifiedCount;
  }

  async deleteNotification(userId: string, notificationId: string): Promise<void> {
    if (!/^[0-9a-fA-F]{24}$/.test(notificationId)) {
      throw ApiError.badRequest('Invalid notification ID.');
    }
    const notification = await Notification.findOneAndDelete({ _id: notificationId, user: userId });
    if (!notification) throw ApiError.notFound(MESSAGES.NOTIFICATION.NOT_FOUND);

    const unreadCount = await this.getUnreadCount(userId);
    publishNotificationEvent(userId, NOTIFICATION_EVENTS.unreadCount, {
      eventId: `${notificationId}:deleted-unread-count`,
      unreadCount,
    });
  }

  async registerDeviceToken(userId: string, input: DeviceTokenInput): Promise<any> {
    const token = input.token.trim();
    const staleTokens = await DeviceToken.find({ token, user: { $ne: new Types.ObjectId(userId) } })
      .select('_id user')
      .lean();
    if (staleTokens.length > 0) {
      await DeviceToken.deleteMany({ token, user: { $ne: new Types.ObjectId(userId) } });
      await User.updateMany(
        { _id: { $in: staleTokens.map((item: any) => item.user) }, fcmToken: token },
        { $unset: { fcmToken: 1 } }
      );
    }
    const deviceToken = await DeviceToken.findOneAndUpdate(
      { token },
      {
        $set: {
          user: new Types.ObjectId(userId),
          platform: input.platform,
          deviceId: input.deviceId?.trim() || undefined,
          appVersion: input.appVersion?.trim() || undefined,
          isActive: true,
          lastUsedAt: new Date(),
          lastError: undefined,
        },
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    ).lean();

    await User.findByIdAndUpdate(userId, { $set: { fcmToken: token } });
    return serializeDeviceToken(deviceToken);
  }

  async removeDeviceToken(userId: string, token: string): Promise<void> {
    const cleaned = token.trim();
    await DeviceToken.deleteOne({ user: new Types.ObjectId(userId), token: cleaned });
    const stillActive = await DeviceToken.findOne({ user: new Types.ObjectId(userId), isActive: true })
      .sort({ updatedAt: -1 })
      .select('token')
      .lean();
    if (stillActive?.token) {
      await User.updateOne({ _id: userId }, { $set: { fcmToken: stillActive.token } });
    } else {
      await User.updateOne({ _id: userId, fcmToken: cleaned }, { $unset: { fcmToken: 1 } });
    }
  }

  async listDeviceTokens(userId: string): Promise<any[]> {
    const tokens = await DeviceToken.find({ user: new Types.ObjectId(userId) })
      .sort({ lastUsedAt: -1 })
      .lean();
    return tokens.map(serializeDeviceToken);
  }

  async getPreferences(userId: string): Promise<any> {
    const existing = await NotificationPreference.findOne({ user: new Types.ObjectId(userId) }).lean();
    if (existing) return serializePreference(existing);

    try {
      const created = await NotificationPreference.create({ user: new Types.ObjectId(userId) });
      return serializePreference(created);
    } catch (error: any) {
      if (error?.code !== 11000) throw error;
      const created = await NotificationPreference.findOne({ user: new Types.ObjectId(userId) }).lean();
      return serializePreference(created);
    }
  }

  async updatePreferences(userId: string, updates: Partial<INotificationPreference>): Promise<any> {
    const preference = await NotificationPreference.findOneAndUpdate(
      { user: new Types.ObjectId(userId) },
      { $set: updates },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    ).lean();
    return serializePreference(preference);
  }

  private canPush(preference: Partial<INotificationPreference>, type: NotificationType): boolean {
    if (!preference.pushEnabled) return false;
    if (this.isQuietHours(preference)) return false;

    switch (type) {
      case NotificationType.TEAM_INVITATION:
      case NotificationType.TEAM_INVITATION_ACCEPTED:
      case NotificationType.TEAM_INVITATION_REJECTED:
        return Boolean(preference.teamInvitations);
      case NotificationType.JOIN_REQUEST:
      case NotificationType.JOIN_REQUEST_APPROVED:
      case NotificationType.JOIN_REQUEST_REJECTED:
        return Boolean(preference.joinRequests);
      case NotificationType.TOURNAMENT_REGISTRATION:
      case NotificationType.TOURNAMENT_REGISTRATION_APPROVED:
      case NotificationType.TOURNAMENT_REGISTRATION_REJECTED:
      case NotificationType.TOURNAMENT_STATUS:
        return Boolean(preference.tournamentUpdates);
      case NotificationType.MATCH_SCORE_UPDATE:
        return Boolean(preference.liveScoreUpdates);
      case NotificationType.MATCH_WICKET:
        return Boolean(preference.wicketAlerts);
      case NotificationType.MATCH_OVER_COMPLETED:
        return Boolean(preference.overAlerts);
      case NotificationType.MATCH_INNINGS_STARTED:
      case NotificationType.MATCH_INNINGS_ENDED:
        return Boolean(preference.inningsAlerts);
      case NotificationType.MATCH_REMINDER:
        return Boolean(preference.matchReminders);
      case NotificationType.MATCH_STARTED:
      case NotificationType.MATCH_TOSS:
        return Boolean(preference.matchReminders || preference.liveScoreUpdates);
      case NotificationType.MATCH_RESULT:
        return Boolean(preference.matchResults);
      case NotificationType.AUCTION_UPDATE:
      case NotificationType.AUCTION_STARTED:
      case NotificationType.AUCTION_PAUSED:
      case NotificationType.AUCTION_RESUMED:
      case NotificationType.AUCTION_PLAYER_FORWARD:
      case NotificationType.AUCTION_BID_PLACED:
      case NotificationType.AUCTION_BID_OUTBID:
      case NotificationType.AUCTION_PLAYER_SOLD:
      case NotificationType.AUCTION_PLAYER_UNSOLD:
      case NotificationType.AUCTION_COMPLETED:
        return Boolean(preference.auctionUpdates);
      case NotificationType.GENERAL:
        return true;
      default:
        return true;
    }
  }

  private isQuietHours(preference: Partial<INotificationPreference>): boolean {
    if (!preference.quietHoursEnabled) return false;
    const now = new Date();
    const current = now.getHours() * 60 + now.getMinutes();
    const start = toMinutes(preference.quietHoursStart);
    const end = toMinutes(preference.quietHoursEnd);
    if (start === end) return false;
    if (start < end) return current >= start && current < end;
    return current >= start || current < end;
  }

  private parseDate(value: unknown): Date | undefined {
    if (value instanceof Date) {
      return Number.isNaN(value.getTime()) ? undefined : value;
    }
    if (typeof value !== 'string') return undefined;
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? undefined : date;
  }
}

export const notificationService = new NotificationService();
export default notificationService;
