jest.mock('../../models/Notification', () => ({
  __esModule: true,
  default: {
    findOne: jest.fn(),
    findOneAndUpdate: jest.fn(),
    findOneAndDelete: jest.fn(),
    countDocuments: jest.fn(),
  },
}));
jest.mock('../../models/NotificationPreference', () => ({ __esModule: true, default: { findOne: jest.fn(), create: jest.fn(), findOneAndUpdate: jest.fn() } }));
jest.mock('../../models/DeviceToken', () => ({ __esModule: true, default: { find: jest.fn(), findOneAndUpdate: jest.fn(), deleteOne: jest.fn(), deleteMany: jest.fn() } }));
jest.mock('../../models/User', () => ({ __esModule: true, default: { findByIdAndUpdate: jest.fn(), updateOne: jest.fn() } }));
jest.mock('../../sockets/publisher', () => ({ __esModule: true, NOTIFICATION_EVENTS: { read: 'read', unreadCount: 'unread-count' }, publishNotificationEvent: jest.fn() }));
jest.mock('../notificationDelivery.service', () => ({ __esModule: true, default: { createDeliveries: jest.fn(), scheduleProcessing: jest.fn() } }));

import Notification from '../../models/Notification';
import { NotificationService } from '../notification.service';

const oid = (n: string) => `507f1f77bcf86cd7994390${n}`;
const q = (value: any) => ({ ...value, lean: jest.fn().mockResolvedValue(value) });

describe('notification ownership regressions', () => {
  beforeEach(() => jest.clearAllMocks());

  it('getNotificationById scopes query to authenticated user', async () => {
    (Notification.findOne as jest.Mock).mockReturnValue(q({ _id: oid('11'), user: oid('01'), type: 'GENERAL', title: 't', body: 'b', isRead: false }));
    const svc = new NotificationService();
    await svc.getNotificationById(oid('01'), oid('11'));
    expect(Notification.findOne).toHaveBeenCalledWith(expect.objectContaining({ _id: oid('11'), user: expect.any(Object) }));
  });

  it('deleteNotification does not delete another user notification', async () => {
    (Notification.findOneAndDelete as jest.Mock).mockResolvedValue(null);
    const svc = new NotificationService();
    await expect(svc.deleteNotification(oid('01'), oid('11'))).rejects.toMatchObject({ statusCode: 404 });
    expect(Notification.findOneAndDelete).toHaveBeenCalledWith({ _id: oid('11'), user: oid('01') });
  });
});
