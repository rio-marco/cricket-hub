import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/paginated_response.dart';
import 'package:mobile/features/auth/domain/entities/user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/features/notifications/data/realtime/notification_realtime_client.dart';
import 'package:mobile/features/notifications/data/realtime/notification_realtime_event.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:mobile/features/notifications/domain/entities/notification_preferences.dart';
import 'package:mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:mobile/features/notifications/presentation/providers/notifications_provider.dart';

class FakeNotificationsRepository implements NotificationsRepository {
  int unreadCount = 0;
  int getNotificationsCalls = 0;
  int getUnreadCountCalls = 0;
  List<AppNotification> items = const [];

  @override
  Future<PaginatedResponse<AppNotification>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
    String? type,
    String? category,
    String? relatedEntityId,
  }) async {
    getNotificationsCalls++;
    return PaginatedResponse<AppNotification>(
      items: items,
      page: 1,
      limit: 20,
      total: items.length,
    );
  }

  @override
  Future<int> getUnreadCount() async {
    getUnreadCountCalls++;
    return unreadCount;
  }

  @override
  Future<AppNotification> markAsRead(String id) async => items.first;

  @override
  Future<int> markAllAsRead() async => 0;

  @override
  Future<void> deleteNotification(String id) async {}

  @override
  Future<NotificationPreferences> getPreferences() async =>
      const NotificationPreferences();

  @override
  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences preferences,
  ) async => preferences;

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? deviceId,
    String? appVersion,
  }) async {}

  @override
  Future<void> removeDeviceToken(String token) async {}
}

class FakeNotificationRealtimeClient implements NotificationRealtimeClient {
  final StreamController<NotificationRealtimeEvent> _controller =
      StreamController<NotificationRealtimeEvent>.broadcast();
  int connectCalls = 0;
  int disconnectCalls = 0;
  int disposeCalls = 0;
  bool connected = false;

  @override
  Stream<NotificationRealtimeEvent> get events => _controller.stream;

  @override
  bool get isConnected => connected;

  @override
  Future<void> connect() async {
    connectCalls++;
  }

  @override
  void disconnect() {
    disconnectCalls++;
    connected = false;
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
    await _controller.close();
  }

  void emit(NotificationRealtimeEvent event) => _controller.add(event);
}

class MutableAuthNotifier extends AuthNotifier {
  MutableAuthNotifier(AuthState initial) : super(_NoopAuthRepository()) {
    state = initial;
  }

  void setState(AuthState next) => state = next;

  @override
  Future<void> logout({String? fcmToken}) async {
    state = const AuthState.unauthenticated();
  }
}

class _NoopAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

User _user(String id) => User(
      id: id,
      name: 'User $id',
      email: '$id@example.com',
      phone: '1234567890',
      role: 'user',
    );

AppNotification _notif(String id, {bool isRead = false}) => AppNotification(
      id: id,
      type: 'GENERAL',
      category: AppNotificationCategory.match,
      title: 't$id',
      body: 'b$id',
      isRead: isRead,
      createdAt: DateTime.utc(2026, 1, 1),
    );

void main() {
  test('notification providers reset on logout and account switch', () async {
    final repo = FakeNotificationsRepository()
      ..items = [_notif('n1')]
      ..unreadCount = 1;
    final realtime = FakeNotificationRealtimeClient();
    final auth = MutableAuthNotifier(AuthState.authenticated(_user('u1')));
    final container = ProviderContainer(
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(repo),
        notificationRealtimeClientProvider.overrideWithValue(realtime),
        authStateProvider.overrideWith((ref) => auth),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(realtime.dispose);

    container.read(unreadCountProvider);
    container.read(notificationListProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(unreadCountProvider).asData?.value, 1);
    expect(container.read(notificationListProvider).items.length, 1);

    auth.setState(AuthState.authenticated(_user('u2')));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(repo.getNotificationsCalls, greaterThanOrEqualTo(2));
    expect(container.read(notificationListProvider).items.length, 1);

    auth.setState(const AuthState.unauthenticated());
    await Future<void>.delayed(Duration.zero);
    expect(container.read(unreadCountProvider).asData?.value, 0);
    expect(container.read(notificationListProvider).items, isEmpty);
  });

  test('notification reconnect refresh is triggered once per reconnect cycle', () async {
    final repo = FakeNotificationsRepository()..unreadCount = 2;
    final realtime = FakeNotificationRealtimeClient();
    final auth = MutableAuthNotifier(AuthState.authenticated(_user('u1')));
    final container = ProviderContainer(
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(repo),
        notificationRealtimeClientProvider.overrideWithValue(realtime),
        authStateProvider.overrideWith((ref) => auth),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(realtime.dispose);

    container.read(unreadCountProvider);
    container.read(notificationListProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    final unreadCallsAfterLoad = repo.getUnreadCountCalls;
    final listCallsAfterLoad = repo.getNotificationsCalls;

    realtime.emit(NotificationRealtimeEvent.from('notification:connection', {
      'connected': true,
    }));
    await Future<void>.delayed(Duration.zero);
    expect(repo.getUnreadCountCalls, unreadCallsAfterLoad);
    expect(repo.getNotificationsCalls, listCallsAfterLoad);

    realtime.emit(NotificationRealtimeEvent.from('notification:connection', {
      'connected': false,
    }));
    realtime.emit(NotificationRealtimeEvent.from('notification:connection', {
      'connected': true,
    }));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(repo.getUnreadCountCalls, greaterThan(unreadCallsAfterLoad));
    expect(repo.getNotificationsCalls, greaterThan(listCallsAfterLoad));
  });

  test('notification realtime subscription removed on container dispose', () async {
    final repo = FakeNotificationsRepository();
    final realtime = FakeNotificationRealtimeClient();
    final auth = MutableAuthNotifier(AuthState.authenticated(_user('u1')));
    final container = ProviderContainer(
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(repo),
        notificationRealtimeClientProvider.overrideWithValue(realtime),
        authStateProvider.overrideWith((ref) => auth),
      ],
    );

    container.read(unreadCountProvider);
    container.read(notificationListProvider);
    await Future<void>.delayed(Duration.zero);
    expect(realtime._controller.hasListener, isTrue);

    container.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(realtime._controller.hasListener, isFalse);
  });
}
