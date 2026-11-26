import { Types } from 'mongoose';

jest.mock('../../models/NotificationDelivery', () => ({
  __esModule: true,
  default: {
    find: jest.fn(),
    findByIdAndUpdate: jest.fn(),
  },
}));

jest.mock('../../models/Notification', () => ({
  __esModule: true,
  default: {
    findById: jest.fn(),
  },
}));

jest.mock('../../models/DeviceToken', () => ({
  __esModule: true,
  default: {
    findById: jest.fn(),
    findByIdAndUpdate: jest.fn(),
  },
}));

jest.mock('../../config/env', () => ({
  __esModule: true,
  env: {
    FIREBASE_PUSH_RETRY_BATCH_SIZE: 50,
    FIREBASE_PUSH_RETRY_INTERVAL_MS: 60000,
  },
  default: {
    FIREBASE_PUSH_RETRY_BATCH_SIZE: 50,
    FIREBASE_PUSH_RETRY_INTERVAL_MS: 60000,
  },
}));

jest.mock('../../utils/logger', () => ({
  __esModule: true,
  logger: {
    error: jest.fn(),
    info: jest.fn(),
    warn: jest.fn(),
    debug: jest.fn(),
  },
}));

import { NotificationDeliveryStatus } from '../../constants/enums';
import DeviceToken from '../../models/DeviceToken';
import Notification from '../../models/Notification';
import NotificationDelivery from '../../models/NotificationDelivery';
import { FcmSendResult, FcmSender } from '../fcmSender.service';
import { NotificationDeliveryService } from '../notificationDelivery.service';

class FakeSender implements FcmSender {
  result: FcmSendResult = { success: true, messageId: 'message-1' };
  calls: Array<{ token: string; message: any }> = [];

  async send(token: string, message: any): Promise<FcmSendResult> {
    this.calls.push({ token, message });
    return this.result;
  }
}

const notificationId = new Types.ObjectId();
const deviceTokenId = new Types.ObjectId();
const deliveryId = new Types.ObjectId();

const deliveryRow = {
  _id: deliveryId,
  notification: notificationId,
  deviceToken: deviceTokenId,
  status: NotificationDeliveryStatus.PENDING,
  attempts: 0,
  maxAttempts: 3,
  nextAttemptAt: new Date(Date.now() - 1000),
};

const notificationDocument = {
  _id: notificationId,
  type: 'MATCH_RESULT',
  category: 'MATCH',
  title: 'Match completed',
  body: 'India won by 5 runs.',
  data: { matchId: 'match-1' },
  relatedEntityType: 'Match',
  relatedEntityId: 'match-1',
};

const deviceTokenDocument = {
  _id: deviceTokenId,
  token: 'fcm-token-1234567890',
  isActive: true,
};

const mocked = (value: unknown) => value as jest.Mock;

describe('NotificationDeliveryService', () => {
  let sender: FakeSender;
  let service: NotificationDeliveryService;

  beforeEach(() => {
    jest.clearAllMocks();
    sender = new FakeSender();
    service = new NotificationDeliveryService(sender);

    mocked(NotificationDelivery.find).mockReturnValue({
      sort: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
      lean: jest.fn().mockResolvedValue([deliveryRow]),
    });
    mocked(NotificationDelivery.findByIdAndUpdate).mockResolvedValue({});
    mocked(Notification.findById).mockReturnValue({
      select: jest.fn().mockReturnThis(),
      lean: jest.fn().mockResolvedValue(notificationDocument),
    });
    mocked(DeviceToken.findById).mockReturnValue({
      select: jest.fn().mockReturnThis(),
      lean: jest.fn().mockResolvedValue(deviceTokenDocument),
    });
    mocked(DeviceToken.findByIdAndUpdate).mockResolvedValue({});
  });

  it('sends a pending delivery with notification metadata for deep links', async () => {
    const result = await service.processPendingDeliveries();

    expect(result).toEqual({ sent: 1, failed: 0, cancelled: 0, processed: 1 });
    expect(sender.calls).toHaveLength(1);
    expect(sender.calls[0].token).toBe(deviceTokenDocument.token);
    expect(sender.calls[0].message.data).toEqual({
      matchId: 'match-1',
      notificationId: String(notificationId),
      type: 'MATCH_RESULT',
      category: 'MATCH',
      relatedEntityType: 'Match',
      relatedEntityId: 'match-1',
    });
    expect(mocked(NotificationDelivery.findByIdAndUpdate)).toHaveBeenCalledWith(
      deliveryId,
      expect.objectContaining({
        $set: expect.objectContaining({ status: NotificationDeliveryStatus.SENT, attempts: 1 }),
      })
    );
  });

  it('deactivates invalid device tokens and cancels the delivery', async () => {
    sender.result = {
      success: false,
      errorCode: 'messaging/registration-token-not-registered',
      error: 'Token is no longer registered.',
      invalidToken: true,
      retryable: false,
    };

    const result = await service.processPendingDeliveries();

    expect(result.cancelled).toBe(1);
    expect(mocked(DeviceToken.findByIdAndUpdate)).toHaveBeenCalledWith(
      deviceTokenId,
      { $set: { isActive: false } }
    );
    expect(mocked(NotificationDelivery.findByIdAndUpdate)).toHaveBeenCalledWith(
      deliveryId,
      expect.objectContaining({
        $set: expect.objectContaining({ status: NotificationDeliveryStatus.CANCELLED }),
      })
    );
  });

  it('keeps retryable failures pending with a later retry time', async () => {
    sender.result = {
      success: false,
      errorCode: 'messaging/unavailable',
      error: 'Temporary outage.',
      retryable: true,
    };

    const result = await service.processPendingDeliveries();

    expect(result.failed).toBe(1);
    expect(mocked(NotificationDelivery.findByIdAndUpdate)).toHaveBeenCalledWith(
      deliveryId,
      expect.objectContaining({
        $set: expect.objectContaining({
          status: NotificationDeliveryStatus.PENDING,
          attempts: 1,
          lastErrorCode: 'messaging/unavailable',
        }),
      })
    );
  });

  it('marks non-retryable failures as failed', async () => {
    sender.result = {
      success: false,
      errorCode: 'FCM_NOT_CONFIGURED',
      error: 'Firebase Cloud Messaging is not configured.',
      retryable: false,
    };

    const result = await service.processPendingDeliveries();

    expect(result.failed).toBe(1);
    expect(mocked(NotificationDelivery.findByIdAndUpdate)).toHaveBeenCalledWith(
      deliveryId,
      expect.objectContaining({
        $set: expect.objectContaining({ status: NotificationDeliveryStatus.FAILED }),
      })
    );
  });
});
