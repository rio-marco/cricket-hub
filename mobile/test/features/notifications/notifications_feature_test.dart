import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/paginated_response.dart';
import 'package:mobile/core/storage/secure_storage.dart';
import 'package:mobile/features/notifications/data/realtime/notification_realtime_event.dart';
import 'package:mobile/features/notifications/data/services/push_notification_service.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:mobile/features/notifications/domain/entities/notification_preferences.dart';
import 'package:mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:mobile/features/notifications/presentation/providers/notifications_provider.dart';

AppNotification _notification(
  String id, {
  bool isRead = false,
  String type = 'GENERAL',
}) {
  return AppNotification(
    id: id,
    type: type,
    category: AppNotificationCategory.match,
    title: 'Notification $id',
    body: 'Body $id',
    isRead: isRead,
    createdAt: DateTime.utc(2026, 1, 1, 12),
  );
}

class FakeNotificationsRepository implements NotificationsRepository {
  FakeNotificationsRepository({
    this.items = const <AppNotification>[],
    this.total = 0,
    this.unreadCount = 0,
  });

  List<AppNotification> items;
  int total;
  int unreadCount;
  bool? lastIsRead;
  int? lastPage;
  String? registeredToken;
  String? removedToken;
  String? registeredPlatform;

  @override
  Future<PaginatedResponse<AppNotification>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
    String? type,
    String? category,
    String? relatedEntityId,
  }) async {
    lastPage = page;
    lastIsRead = isRead;
    final pageItems = page == 1
        ? items.take(limit).toList()
        : items.skip((page - 1) * limit).take(limit).toList();
    return PaginatedResponse<AppNotification>(
      items: pageItems,
      page: page,
      limit: limit,
      total: total,
    );
  }

  @override
  Future<int> getUnreadCount() async => unreadCount;

  @override
  Future<AppNotification> markAsRead(String id) async =>
      items.firstWhere((item) => item.id == id).copyWith(
            isRead: true,
            readAt: DateTime.utc(2026, 1, 2),
          );

  @override
  Future<int> markAllAsRead() async {
    items = items.map((item) => item.copyWith(isRead: true)).toList();
    unreadCount = 0;
    return items.length;
  }

  @override
  Future<void> deleteNotification(String id) async {
    items = items.where((item) => item.id != id).toList();
    total = items.length;
  }

  @override
  Future<NotificationPreferences> getPreferences() async =>
      const NotificationPreferences();

  @override
  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences preferences,
  ) async =>
      preferences;

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? deviceId,
    String? appVersion,
  }) async {
    registeredToken = token;
    registeredPlatform = platform;
  }

  @override
  Future<void> removeDeviceToken(String token) async {
    removedToken = token;
  }
}

class FakeSecureStorage extends SecureStorage {
  FakeSecureStorage() : super(const FlutterSecureStorage());

  String? accessToken;
  String? pushToken;

  @override
  Future<String?> getToken() async => accessToken;

  @override
  Future<String?> getPushToken() async => pushToken;

  @override
  Future<void> savePushToken(String token) async => pushToken = token;

  @override
  Future<void> deletePushToken() async => pushToken = null;
}

class FakePushPlatform implements PushNotificationPlatform {
  final StreamController<String> _tokens =
      StreamController<String>.broadcast();
  final StreamController<PushNotificationMessage> _messages =
      StreamController<PushNotificationMessage>.broadcast();
  final StreamController<PushNotificationMessage> _taps =
      StreamController<PushNotificationMessage>.broadcast();

  String token = 'fcm-token-1234567890';
  bool permissionGranted = true;
  bool firebaseReady = true;
  int foregroundOptionsCalls = 0;

  @override
  Future<bool> initialize() async => firebaseReady;

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> setForegroundPresentationOptions() async {
    foregroundOptionsCalls += 1;
  }

  @override
  Stream<String> get onTokenRefresh => _tokens.stream;

  @override
  Stream<PushNotificationMessage> get onMessage => _messages.stream;

  @override
  Stream<PushNotificationMessage> get onMessageOpenedApp => _taps.stream;

  @override
  Future<PushNotificationMessage?> getInitialMessage() async => null;

  Future<void> dispose() async {
    await _tokens.close();
    await _messages.close();
    await _taps.close();
  }
}

void main() {
  group('notification entities and realtime events', () {
    test('parses backend notification payloads safely', () {
      final notification = AppNotification.fromJson(<String, dynamic>{
        'id': 'notification-1',
        'type': 'MATCH_RESULT',
        'category': 'MATCH',
        'title': 'Match completed',
        'body': 'Your team won.',
        'data': <String, dynamic>{'matchId': 'match-1'},
        'relatedEntityType': 'Match',
        'relatedEntityId': 'match-1',
        'isRead': true,
        'readAt': '2026-01-02T00:00:00.000Z',
        'createdAt': '2026-01-01T00:00:00.000Z',
      });

      expect(notification.id, 'notification-1');
      expect(notification.category, AppNotificationCategory.match);
      expect(notification.data['matchId'], 'match-1');
      expect(notification.isRead, isTrue);
      expect(notification.readAt, isNotNull);
    });

    test('uses backend defaults for missing preferences', () {
      final preferences = NotificationPreferences.fromJson(<String, dynamic>{
        'pushEnabled': false,
        'wicketAlerts': false,
      });

      expect(preferences.pushEnabled, isFalse);
      expect(preferences.wicketAlerts, isFalse);
      expect(preferences.liveScoreUpdates, isFalse);
      expect(preferences.quietHoursStart, '22:00');
      expect(preferences.toJson()['auctionUpdates'], isTrue);
    });

    test('normalizes realtime event maps and nested notifications', () {
      final event = NotificationRealtimeEvent.from(
        'notification:new',
        <String, dynamic>{
          'eventId': 'notification-1:created',
          'unreadCount': 2,
          'notification': <String, dynamic>{
            'id': 'notification-1',
            'type': 'MATCH_WICKET',
            'category': 'MATCH',
            'title': 'Wicket!',
            'body': 'A wicket fell.',
          },
        },
      );

      expect(event.name, 'notification:new');
      expect(event.eventId, 'notification-1:created');
      expect(event.unreadCount, 2);
      expect(event.notification?.id, 'notification-1');
      expect(event.notification?.category, AppNotificationCategory.match);
    });
  });

  group('notification providers', () {
    test('loads pages, filters, marks read, and deletes', () async {
      final repository = FakeNotificationsRepository(
        items: <AppNotification>[
          _notification('1'),
          _notification('2'),
          _notification('3', isRead: true),
        ],
        total: 3,
      );
      var unreadRefreshes = 0;
      final notifier = NotificationListNotifier(repository, () async {
        unreadRefreshes += 1;
      });

      await notifier.load(refresh: true);
      expect(notifier.state.items, hasLength(3));
      expect(notifier.state.page, 1);
      expect(notifier.state.hasMore, isFalse);

      await notifier.setFilter(NotificationReadFilter.unread);
      expect(repository.lastIsRead, isFalse);
      expect(notifier.state.filter, NotificationReadFilter.unread);

      await notifier.markAsRead('1');
      expect(notifier.state.items.firstWhere((item) => item.id == '1').isRead, isTrue);
      expect(unreadRefreshes, greaterThan(0));

      await notifier.delete('1');
      expect(notifier.state.items.any((item) => item.id == '1'), isFalse);
    });

    test('applies realtime created and read events', () {
      final repository = FakeNotificationsRepository();
      final notifier = NotificationListNotifier(repository, () async {});

      notifier.applyRealtimeEvent(
        NotificationRealtimeEvent(
          name: 'notification:new',
          notification: _notification('new-1'),
          unreadCount: 1,
        ),
      );
      expect(notifier.state.items.single.id, 'new-1');
      expect(notifier.state.total, 1);

      notifier.applyRealtimeEvent(
        NotificationRealtimeEvent(
          name: 'notification:read',
          notification: _notification('new-1', isRead: true),
          unreadCount: 0,
        ),
      );
      expect(notifier.state.items.single.isRead, isTrue);
    });

    test('tracks unread count from repository and realtime values', () async {
      final repository = FakeNotificationsRepository(unreadCount: 4);
      final notifier = UnreadCountNotifier(repository);

      await notifier.refresh();
      expect(notifier.state.value, 4);
      notifier.setCount(0);
      expect(notifier.state.value, 0);
    });
  });

  group('push notification service', () {
    test('initializes once and registers the token whenever auth becomes available', () async {
      final platform = FakePushPlatform();
      final repository = FakeNotificationsRepository();
      final storage = FakeSecureStorage();
      final service = PushNotificationService(
        platform: platform,
        repository: repository,
        storage: storage,
      );

      final first = await service.initialize();
      expect(first, isTrue);
      expect(platform.foregroundOptionsCalls, 1);
      expect(storage.pushToken, platform.token);
      expect(repository.registeredToken, isNull);

      storage.accessToken = 'access-token';
      final second = await service.initialize();
      expect(second, isTrue);
      expect(platform.foregroundOptionsCalls, 1);
      expect(repository.registeredToken, platform.token);
      expect(
        <String>['ANDROID', 'IOS', 'WEB'].contains(repository.registeredPlatform!),
        isTrue,
      );

      await service.unregisterCurrentToken();
      expect(repository.removedToken, platform.token);
      expect(storage.pushToken, isNull);

      await service.dispose();
      await platform.dispose();
    });

    test('does not enable push when permission is denied', () async {
      final platform = FakePushPlatform()..permissionGranted = false;
      final repository = FakeNotificationsRepository();
      final storage = FakeSecureStorage();
      final service = PushNotificationService(
        platform: platform,
        repository: repository,
        storage: storage,
      );

      expect(await service.initialize(), isFalse);
      expect(repository.registeredToken, isNull);

      await service.dispose();
      await platform.dispose();
    });
  });
}
