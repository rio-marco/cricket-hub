import { getFirebaseMessaging, isFirebaseConfigured } from '../config/firebase';

export interface FcmMessage {
  title: string;
  body: string;
  data?: Record<string, string>;
}

export interface FcmSendResult {
  success: boolean;
  messageId?: string;
  errorCode?: string;
  error?: string;
  invalidToken?: boolean;
  retryable?: boolean;
}

export interface FcmSender {
  send(token: string, message: FcmMessage): Promise<FcmSendResult>;
}

const invalidTokenCodes = new Set([
  'messaging/invalid-registration-token',
  'messaging/registration-token-not-registered',
]);

const normalizeError = (error: any): FcmSendResult => {
  const code = typeof error?.code === 'string' ? error.code : 'messaging/unknown';
  return {
    success: false,
    errorCode: code,
    error: typeof error?.message === 'string' ? error.message : 'FCM delivery failed.',
    invalidToken: invalidTokenCodes.has(code),
    retryable: !invalidTokenCodes.has(code),
  };
};

export class FirebaseFcmSender implements FcmSender {
  async send(token: string, message: FcmMessage): Promise<FcmSendResult> {
    const messaging = getFirebaseMessaging();
    if (!messaging) {
      return {
        success: false,
        errorCode: isFirebaseConfigured() ? 'messaging/unavailable' : 'FCM_NOT_CONFIGURED',
        error: 'Firebase Cloud Messaging is not configured.',
        retryable: false,
      };
    }

    try {
      const messageId = await messaging.send({
        token,
        notification: {
          title: message.title,
          body: message.body,
        },
        data: message.data,
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      });
      return { success: true, messageId };
    } catch (error: any) {
      return normalizeError(error);
    }
  }
}

export default FirebaseFcmSender;
