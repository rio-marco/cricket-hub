import {
  DevicePlatform,
  NotificationCategory,
  NotificationType,
} from '../../src/constants/enums';
import Notification from '../../src/models/Notification';
import NotificationDelivery from '../../src/models/NotificationDelivery';
import notificationService from '../../src/services/notification.service';
import { api, bearer, registerAndVerify, uniqueValue } from './helpers';

const authGet = (path: string, token: string) =>
  api().get(path).set('Authorization', bearer(token));

describe('MongoDB integration: notifications, device tokens, and preferences', () => {
  it('serves notification APIs with pagination, ownership checks, and read state', async () => {
    const owner = await registerAndVerify('notify-api-owner');
    const outsider = await registerAndVerify('notify-api-outsider');

    const empty = await authGet('/api/v1/notifications', owner.accessToken).expect(200);
    expect(empty.body.data).toEqual([]);
    expect(empty.body.pagination.total).toBe(0);

    const initialCount = await authGet('/api/v1/notifications/unread-count', owner.accessToken).expect(200);
    expect(initialCount.body.data.count).toBe(0);

    const created = await notificationService.notifyUser(owner.userId, {
      type: NotificationType.GENERAL,
      category: NotificationCategory.SYSTEM,
      title: 'Welcome',
      body: 'Your notification is ready.',
      data: { source: 'integration' },
      dedupeKey: `welcome-${uniqueValue()}`,
    });
    expect(created.created).toBe(1);

    const notificationId = created.users.length ? String((await Notification.findOne({ user: owner.userId }).lean())?._id) : '';
    expect(notificationId).toMatch(/^[0-9a-fA-F]{24}$/);

    const list = await authGet('/api/v1/notifications?isRead=false&limit=5', owner.accessToken).expect(200);
    expect(list.body.pagination.total).toBe(1);
    expect(list.body.data[0]).toMatchObject({
      id: notificationId,
      type: NotificationType.GENERAL,
      category: NotificationCategory.SYSTEM,
      title: 'Welcome',
      isRead: false,
    });
    expect(list.body.data[0].data).toEqual({ source: 'integration' });

    const detail = await authGet(`/api/v1/notifications/${notificationId}`, owner.accessToken).expect(200);
    expect(detail.body.data.id).toBe(notificationId);

    await authGet(`/api/v1/notifications/${notificationId}`, outsider.accessToken).expect(404);
    await authGet('/api/v1/notifications/not-an-id', owner.accessToken).expect(400);

    const marked = await api()
      .patch(`/api/v1/notifications/${notificationId}/read`)
      .set('Authorization', bearer(owner.accessToken))
      .expect(200);
    expect(marked.body.data.isRead).toBe(true);
    expect(marked.body.data.readAt).toBeDefined();

    const readFilter = await authGet('/api/v1/notifications?isRead=true', owner.accessToken).expect(200);
    expect(readFilter.body.pagination.total).toBe(1);
    const unreadFilter = await authGet('/api/v1/notifications?isRead=false', owner.accessToken).expect(200);
    expect(unreadFilter.body.pagination.total).toBe(0);

    await notificationService.notifyUser(owner.userId, {
      type: NotificationType.MATCH_RESULT,
      title: 'Match result',
      body: 'Your team won.',
      dedupeKey: `result-${uniqueValue()}`,
    });

    await api()
      .post('/api/v1/notifications/read-all')
      .set('Authorization', bearer(owner.accessToken))
      .expect(200);

    const finalCount = await authGet('/api/v1/notifications/unread-count', owner.accessToken).expect(200);
    expect(finalCount.body.data.count).toBe(0);
    expect(await Notification.countDocuments({ user: owner.userId })).toBe(2);

    await api()
      .delete(`/api/v1/notifications/${notificationId}`)
      .set('Authorization', bearer(owner.accessToken))
      .expect(200);
    expect(await Notification.findById(notificationId)).toBeNull();
  });

  it('deduplicates notifications and hides expired notifications', async () => {
    const user = await registerAndVerify('notify-dedupe');
    await api()
      .put('/api/v1/notifications/preferences')
      .set('Authorization', bearer(user.accessToken))
      .send({ pushEnabled: false })
      .expect(200);

    const input = {
      type: NotificationType.TEAM_INVITATION,
      title: 'Team invitation',
      body: 'You were invited to join a team.',
      dedupeKey: `invitation-${uniqueValue()}`,
    };

    const first = await notificationService.notifyUser(user.userId, input);
    const second = await notificationService.notifyUser(user.userId, input);
    expect(first.created).toBe(1);
    expect(second.created).toBe(0);
    expect(second.skipped).toBe(1);
    expect(await Notification.countDocuments({ user: user.userId })).toBe(1);

    await notificationService.notifyUser(user.userId, {
      type: NotificationType.GENERAL,
      title: 'Expired notice',
      body: 'This notice should not be listed.',
      expiresAt: new Date(Date.now() - 60_000),
      dedupeKey: `expired-${uniqueValue()}`,
    });

    const list = await authGet('/api/v1/notifications', user.accessToken).expect(200);
    expect(list.body.pagination.total).toBe(1);
    expect(list.body.data.some((item: any) => item.title === 'Expired notice')).toBe(false);
    const count = await authGet('/api/v1/notifications/unread-count', user.accessToken).expect(200);
    expect(count.body.data.count).toBe(1);
  });

  it('manages device tokens and notification preferences', async () => {
    const user = await registerAndVerify('notify-device');
    const token = `fcm-${uniqueValue()}`;

    const preferences = await authGet('/api/v1/notifications/preferences', user.accessToken).expect(200);
    expect(preferences.body.data).toMatchObject({
      pushEnabled: true,
      liveScoreUpdates: false,
      wicketAlerts: true,
      quietHoursStart: '22:00',
      quietHoursEnd: '08:00',
    });

    const updated = await api()
      .put('/api/v1/notifications/preferences')
      .set('Authorization', bearer(user.accessToken))
      .send({
        pushEnabled: false,
        liveScoreUpdates: true,
        quietHoursEnabled: true,
        quietHoursStart: '23:30',
        quietHoursEnd: '06:00',
      })
      .expect(200);
    expect(updated.body.data).toMatchObject({
      pushEnabled: false,
      liveScoreUpdates: true,
      quietHoursEnabled: true,
      quietHoursStart: '23:30',
      quietHoursEnd: '06:00',
    });

    await api()
      .post('/api/v1/notifications/device-token')
      .set('Authorization', bearer(user.accessToken))
      .send({ token, platform: DevicePlatform.ANDROID, deviceId: 'device-1', appVersion: '1.0.0' })
      .expect(201);

    const tokens = await authGet('/api/v1/notifications/device-tokens', user.accessToken).expect(200);
    expect(tokens.body.data).toHaveLength(1);
    expect(tokens.body.data[0]).toMatchObject({
      platform: DevicePlatform.ANDROID,
      deviceId: 'device-1',
      isActive: true,
    });

    await api()
      .delete('/api/v1/notifications/device-token')
      .set('Authorization', bearer(user.accessToken))
      .send({ token })
      .expect(200);
    const removed = await authGet('/api/v1/notifications/device-tokens', user.accessToken).expect(200);
    expect(removed.body.data).toHaveLength(0);
  });

  it('queues FCM deliveries only for users with push enabled and an active token', async () => {
    const user = await registerAndVerify('notify-fcm');
    const token = `fcm-${uniqueValue()}`;

    await api()
      .post('/api/v1/notifications/device-token')
      .set('Authorization', bearer(user.accessToken))
      .send({ token, platform: DevicePlatform.IOS })
      .expect(201);

    await notificationService.notifyUser(user.userId, {
      type: NotificationType.MATCH_RESULT,
      title: 'Match result',
      body: 'Your team won.',
      dedupeKey: `fcm-enabled-${uniqueValue()}`,
    });

    await new Promise((resolve) => setTimeout(resolve, 100));

    const deliveries = await NotificationDelivery.find({}).lean();
    expect(deliveries).toHaveLength(1);
    expect(deliveries[0].status).toBe('FAILED');
    expect(deliveries[0].lastErrorCode).toBe('FCM_NOT_CONFIGURED');
    expect(deliveries[0].attempts).toBe(1);

    await api()
      .put('/api/v1/notifications/preferences')
      .set('Authorization', bearer(user.accessToken))
      .send({ pushEnabled: false })
      .expect(200);

    await notificationService.notifyUser(user.userId, {
      type: NotificationType.GENERAL,
      title: 'No push',
      body: 'This notification should stay in the app.',
      dedupeKey: `fcm-disabled-${uniqueValue()}`,
    });

    expect(await NotificationDelivery.countDocuments({})).toBe(1);
  });
});
