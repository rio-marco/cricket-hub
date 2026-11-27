import { Types } from 'mongoose';

jest.mock('../../models/Notification', () => ({
  __esModule: true,
  default: {
    find: jest.fn(),
    insertMany: jest.fn(),
    countDocuments: jest.fn(),
    aggregate: jest.fn(),
  },
}));
jest.mock('../../models/NotificationPreference', () => ({
  __esModule: true,
  default: { find: jest.fn() },
}));
jest.mock('../../models/DeviceToken', () => ({
  __esModule: true,
  default: { find: jest.fn() },
}));
jest.mock('../../sockets/publisher', () => ({
  __esModule: true,
  NOTIFICATION_EVENTS: { created: 'created', unreadCount: 'unread-count' },
  publishNotificationEvent: jest.fn(),
}));
jest.mock('../notificationDelivery.service', () => ({
  __esModule: true,
  default: { createDeliveries: jest.fn().mockResolvedValue(1), scheduleProcessing: jest.fn() },
}));

import DeviceToken from '../../models/DeviceToken';
import Notification from '../../models/Notification';
import NotificationPreference from '../../models/NotificationPreference';
import { publishNotificationEvent } from '../../sockets/publisher';
import notificationDeliveryService from '../notificationDelivery.service';
import { NotificationService } from '../notification.service';
import { NotificationType } from '../../constants/enums';

const oid = (n: string) => new Types.ObjectId(`507f1f77bcf86cd7994390${n}`);
const lean = (value: any) => ({ select: jest.fn().mockReturnThis(), lean: jest.fn().mockResolvedValue(value) });

describe('NotificationService.notifyUsers fan-out', () => {
  beforeEach(() => jest.clearAllMocks());

  it('batches dedupe/preferences/tokens and creates deliveries', async () => {
    const userA = oid('11').toString();
    const userB = oid('12').toString();
    (NotificationPreference.find as jest.Mock).mockReturnValue({ lean: jest.fn().mockResolvedValue([]) });
    (Notification.find as jest.Mock).mockReturnValue(lean([{ user: oid('12') }]));
    (DeviceToken.find as jest.Mock).mockReturnValue(lean([{ user: oid('11'), token: 'tok-a' }]));
    (Notification.insertMany as jest.Mock).mockResolvedValue([{ _id: oid('21'), user: oid('11'), type: NotificationType.GENERAL, category: 'SYSTEM', title: 't', body: 'b', data: {}, isRead: false }]);
    (Notification.aggregate as jest.Mock).mockResolvedValue([{ _id: oid('11'), count: 3 }]);

    const svc = new NotificationService();
    const result = await svc.notifyUsers([userA, userB], { type: NotificationType.GENERAL, title: 't', body: 'b', dedupeKey: 'k1' });

    expect(result.created).toBe(1);
    expect(result.skipped).toBe(1);
    expect(Notification.find).toHaveBeenCalledTimes(1); // batch dedupe lookup
    expect(NotificationPreference.find).toHaveBeenCalledTimes(1);
    expect(DeviceToken.find).toHaveBeenCalledTimes(1);
    expect(notificationDeliveryService.createDeliveries).toHaveBeenCalledWith(oid('21'), ['tok-a']);
    expect(publishNotificationEvent).toHaveBeenCalled();
  });

  it('reports partial insert failures without claiming success', async () => {
    const userA = oid('11').toString();
    const userB = oid('12').toString();
    (NotificationPreference.find as jest.Mock).mockReturnValue({ lean: jest.fn().mockResolvedValue([]) });
    (Notification.find as jest.Mock).mockReturnValue(lean([]));
    (DeviceToken.find as jest.Mock).mockReturnValue(lean([]));
    const created = { _id: oid('21'), user: oid('11'), type: NotificationType.GENERAL, category: 'SYSTEM', title: 't', body: 'b', data: {}, isRead: false };
    (Notification.insertMany as jest.Mock).mockRejectedValue({ insertedDocs: [created], writeErrors: [{ index: 1, code: 999, errmsg: 'write failed' }] });
    (Notification.aggregate as jest.Mock).mockResolvedValue([{ _id: oid('11'), count: 1 }]);

    const svc = new NotificationService();
    const result = await svc.notifyUsers([userA, userB], { type: NotificationType.GENERAL, title: 't', body: 'b' });

    expect(result.created).toBe(1);
    expect(result.failed).toBe(1);
    expect(result.errors?.[0].userId).toBe(userB);
    expect(result.skipped).toBe(0);
  });
});
