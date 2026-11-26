import {
  listNotificationsQuerySchema,
  notificationIdParamSchema,
  notificationPreferencesSchema,
  registerDeviceTokenSchema,
  removeDeviceTokenSchema,
} from '../notification.validator';

describe('notification validators', () => {
  const objectId = '507f1f77bcf86cd799439011';

  it('accepts valid notification list filters', () => {
    const { error, value } = listNotificationsQuerySchema.validate({
      page: 2,
      limit: 25,
      isRead: 'false',
      type: 'MATCH_RESULT',
      category: 'MATCH',
      relatedEntityId: objectId,
      from: '2026-01-01T00:00:00.000Z',
      to: '2026-02-01T00:00:00.000Z',
      sort: '-createdAt',
    });

    expect(error).toBeUndefined();
    expect(value.page).toBe(2);
    expect(value.isRead).toBe(false);
    expect(value.type).toBe('MATCH_RESULT');
    expect(value.category).toBe('MATCH');
    expect(value.from).toBeInstanceOf(Date);
  });

  it('rejects unknown notification types, categories, and invalid IDs', () => {
    expect(
      listNotificationsQuerySchema.validate({ type: 'UNKNOWN_TYPE' }).error
    ).toBeDefined();
    expect(
      listNotificationsQuerySchema.validate({ category: 'UNKNOWN_CATEGORY' }).error
    ).toBeDefined();
    expect(notificationIdParamSchema.validate({ id: 'not-an-id' }).error).toBeDefined();
    expect(notificationIdParamSchema.validate({ id: objectId }).error).toBeUndefined();
  });

  it('validates device token registration and removal payloads', () => {
    expect(
      registerDeviceTokenSchema.validate({ token: 'token', platform: 'ANDROID' }).error
    ).toBeDefined();

    const register = registerDeviceTokenSchema.validate({
      token: 'fcm-token-1234567890',
      platform: 'IOS',
      deviceId: 'device-1',
      appVersion: '1.0.0',
    });
    expect(register.error).toBeUndefined();
    expect(register.value.platform).toBe('IOS');
    expect(removeDeviceTokenSchema.validate({ token: 'fcm-token-1234567890' }).error).toBeUndefined();
  });

  it('requires at least one preference change and validates quiet hours', () => {
    expect(notificationPreferencesSchema.validate({}).error).toBeDefined();
    expect(
      notificationPreferencesSchema.validate({ quietHoursStart: '25:00' }).error
    ).toBeDefined();

    const { error, value } = notificationPreferencesSchema.validate({
      pushEnabled: false,
      wicketAlerts: true,
      quietHoursEnabled: true,
      quietHoursStart: '22:30',
      quietHoursEnd: '07:15',
    });
    expect(error).toBeUndefined();
    expect(value.pushEnabled).toBe(false);
    expect(value.quietHoursStart).toBe('22:30');
  });
});
