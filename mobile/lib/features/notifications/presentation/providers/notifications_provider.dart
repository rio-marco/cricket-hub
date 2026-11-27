import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/app_notification.dart';
import '../../data/services/push_notification_service.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../data/datasources/notifications_remote_datasource.dart';
import '../../data/realtime/notification_realtime_client.dart';
import '../../data/realtime/notification_realtime_event.dart';
import '../../data/repositories/notifications_repository_impl.dart';

enum NotificationReadFilter { all, unread, read }

class NotificationListState {
  final List<AppNotification> items;
  final int page;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final NotificationReadFilter filter;

  const NotificationListState({
    this.items = const <AppNotification>[],
    this.page = 1,
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.filter = NotificationReadFilter.all,
  });

  bool get hasMore => items.length < total;

  NotificationListState copyWith({
    List<AppNotification>? items,
    int? page,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
    NotificationReadFilter? filter,
  }) {
    return NotificationListState(
      items: items ?? this.items,
      page: page ?? this.page,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      filter: filter ?? this.filter,
    );
  }
}

class NotificationListNotifier extends StateNotifier<NotificationListState> {
  final NotificationsRepository _repository;
  final Future<void> Function() _onUnreadChanged;

  NotificationListNotifier(this._repository, this._onUnreadChanged)
    : super(const NotificationListState());

  Future<void> load({bool refresh = false}) async {
    final current = state;
    if (!refresh && current.isLoading) return;
    if (!refresh && !current.hasMore) return;

    final page = refresh ? 1 : current.page + 1;
    state = current.copyWith(
      page: page,
      isLoading: refresh,
      isLoadingMore: !refresh,
      clearError: true,
    );

    try {
      final result = await _repository.getNotifications(
        page: page,
        limit: 20,
        isRead: _readFilter(),
      );
      final items = refresh
          ? result.items
          : <AppNotification>[...current.items, ...result.items];
      state = state.copyWith(
        items: items,
        page: result.page,
        total: result.total,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (error) {
      state = state.copyWith(
        page: refresh ? 1 : current.page,
        isLoading: false,
        isLoadingMore: false,
        errorMessage: _message(error),
      );
    }
  }

  Future<void> setFilter(NotificationReadFilter filter) async {
    if (state.filter == filter) return;
    state = state.copyWith(
      items: const <AppNotification>[],
      page: 1,
      total: 0,
      filter: filter,
      clearError: true,
    );
    await load(refresh: true);
  }

  Future<void> markAsRead(String id) async {
    final existing = state.items.where((item) => item.id == id);
    if (existing.isEmpty || existing.first.isRead) return;

    _replace(existing.first.copyWith(isRead: true, readAt: DateTime.now()));
    try {
      final updated = await _repository.markAsRead(id);
      _replace(updated);
      unawaited(_onUnreadChanged());
    } catch (error) {
      _replace(existing.first);
      state = state.copyWith(errorMessage: _message(error));
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      await load(refresh: true);
      unawaited(_onUnreadChanged());
    } catch (error) {
      state = state.copyWith(errorMessage: _message(error));
    }
  }

  Future<void> delete(String id) async {
    final removed = state.items.where((item) => item.id == id).toList();
    if (removed.isEmpty) return;

    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
      total: state.total > 0 ? state.total - 1 : 0,
    );
    try {
      await _repository.deleteNotification(id);
      unawaited(_onUnreadChanged());
    } catch (error) {
      state = state.copyWith(
        items: <AppNotification>[...removed, ...state.items],
        total: state.total + 1,
        errorMessage: _message(error),
      );
    }
  }

  void applyRealtimeEvent(NotificationRealtimeEvent event) {
    final notification = event.notification;
    if (event.name == 'notification:new' && notification != null) {
      if (state.filter == NotificationReadFilter.read && notification.isRead) {
        return;
      }
      if (state.items.any((item) => item.id == notification.id)) return;
      state = state.copyWith(
        items: <AppNotification>[notification, ...state.items],
        total: state.total + 1,
      );
      return;
    }

    if ((event.name == 'notification:read' ||
            event.name == 'notification:unread-count') &&
        notification != null) {
      _replace(notification);
      if (state.filter == NotificationReadFilter.unread &&
          notification.isRead) {
        state = state.copyWith(
          items: state.items
              .where((item) => item.id != notification.id)
              .toList(),
          total: state.total > 0 ? state.total - 1 : 0,
        );
      }
    }
  }

  void reset() {
    state = const NotificationListState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void _replace(AppNotification notification) {
    state = state.copyWith(
      items: state.items
          .map((item) => item.id == notification.id ? notification : item)
          .toList(),
    );
  }

  bool? _readFilter() {
    switch (state.filter) {
      case NotificationReadFilter.unread:
        return false;
      case NotificationReadFilter.read:
        return true;
      case NotificationReadFilter.all:
        return null;
    }
  }
}

class UnreadCountNotifier extends StateNotifier<AsyncValue<int>> {
  final NotificationsRepository _repository;

  UnreadCountNotifier(this._repository) : super(const AsyncValue.data(0));

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final count = await _repository.getUnreadCount();
      state = AsyncValue.data(count);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void setCount(int count) {
    state = AsyncValue.data(count < 0 ? 0 : count);
  }

  void reset() {
    state = const AsyncValue.data(0);
  }
}

class PushNotificationNotifier extends StateNotifier<AsyncValue<bool>> {
  final PushNotificationService _service;

  PushNotificationNotifier(this._service) : super(const AsyncValue.data(false));

  Future<void> initialize() async {
    state = const AsyncValue.loading();
    try {
      final enabled = await _service.initialize();
      state = AsyncValue.data(enabled);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> unregister() async {
    try {
      await _service.unregisterCurrentToken();
      state = const AsyncValue.data(false);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final notificationsRemoteDataSourceProvider =
    Provider<NotificationsRemoteDataSource>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      return NotificationsRemoteDataSourceImpl(apiClient);
    });

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  final remoteDataSource = ref.watch(notificationsRemoteDataSourceProvider);
  return NotificationsRepositoryImpl(remoteDataSource: remoteDataSource);
});

final notificationRealtimeClientProvider = Provider<NotificationRealtimeClient>(
  (ref) {
    final config = ref.watch(appConfigProvider);
    final storage = ref.watch(secureStorageProvider);
    final client = SocketIONotificationRealtimeClient(
      url: config.socketUrl,
      tokenProvider: SecureStorageNotificationRealtimeTokenProvider(storage),
    );

    ref.keepAlive();
    ref.onDispose(() => unawaited(client.dispose()));

    final currentAuth = ref.read(authStateProvider);
    if (currentAuth is Authenticated) unawaited(client.connect());

    ref.listen<AuthState>(authStateProvider, (_, auth) {
      if (auth is Authenticated) {
        unawaited(client.connect());
      } else {
        client.disconnect();
      }
    });

    return client;
  },
);

final unreadCountProvider =
    StateNotifierProvider<UnreadCountNotifier, AsyncValue<int>>((ref) {
      final repository = ref.watch(notificationsRepositoryProvider);
      final realtime = ref.watch(notificationRealtimeClientProvider);
      final notifier = UnreadCountNotifier(repository);

      final currentAuth = ref.read(authStateProvider);
      if (currentAuth is Authenticated) unawaited(notifier.refresh());

      ref.listen<AuthState>(authStateProvider, (previous, auth) {
        if (auth is Authenticated) {
          if (previous is! Authenticated || previous.user.id != auth.user.id) {
            notifier.reset();
          }
          unawaited(notifier.refresh());
        } else {
          notifier.reset();
        }
      });

      var hasConnectedBefore = realtime.isConnected;
      final subscription = realtime.events.listen((event) {
        if (event.name == 'notification:error') return;
        if (event.name == 'notification:connection') {
          final connected = event.data['connected'] == true;
          if (connected) {
            if (hasConnectedBefore) {
              unawaited(notifier.refresh());
            }
            hasConnectedBefore = true;
          }
          return;
        }
        if (event.unreadCount != null) {
          notifier.setCount(event.unreadCount!);
          return;
        }
        if (event.name == 'notification:new' ||
            event.name == 'notification:read') {
          unawaited(notifier.refresh());
        }
      });
      ref.onDispose(subscription.cancel);

      return notifier;
    });

final notificationListProvider =
    StateNotifierProvider<NotificationListNotifier, NotificationListState>((
      ref,
    ) {
      final repository = ref.watch(notificationsRepositoryProvider);
      final realtime = ref.watch(notificationRealtimeClientProvider);
      final notifier = NotificationListNotifier(
        repository,
        () => ref.read(unreadCountProvider.notifier).refresh(),
      );

      final currentAuth = ref.read(authStateProvider);
      if (currentAuth is Authenticated) unawaited(notifier.load(refresh: true));

      ref.listen<AuthState>(authStateProvider, (previous, auth) {
        if (auth is Authenticated) {
          if (previous is! Authenticated || previous.user.id != auth.user.id) {
            notifier.reset();
          }
          unawaited(notifier.load(refresh: true));
        } else {
          notifier.reset();
        }
      });

      var hasConnectedBefore = realtime.isConnected;
      final subscription = realtime.events.listen((event) {
        if (event.name == 'notification:error') return;
        if (event.name == 'notification:connection') {
          final connected = event.data['connected'] == true;
          if (connected) {
            if (hasConnectedBefore) {
              unawaited(notifier.load(refresh: true));
              unawaited(ref.read(unreadCountProvider.notifier).refresh());
            }
            hasConnectedBefore = true;
          }
          return;
        }
        notifier.applyRealtimeEvent(event);
      });
      ref.onDispose(subscription.cancel);

      return notifier;
    });

final notificationPreferencesProvider = FutureProvider<NotificationPreferences>(
  (ref) async {
    final auth = ref.watch(authStateProvider);
    if (auth is! Authenticated) {
      throw const UnauthorizedFailure();
    }
    final repository = ref.watch(notificationsRepositoryProvider);
    return repository.getPreferences();
  },
);

final pushNotificationPlatformProvider = Provider<PushNotificationPlatform>((
  ref,
) {
  return FirebasePushNotificationPlatform();
});

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  final platform = ref.watch(pushNotificationPlatformProvider);
  final repository = ref.watch(notificationsRepositoryProvider);
  final storage = ref.watch(secureStorageProvider);
  final service = PushNotificationService(
    platform: platform,
    repository: repository,
    storage: storage,
  );

  ref.keepAlive();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

final pushNotificationsProvider =
    StateNotifierProvider<PushNotificationNotifier, AsyncValue<bool>>((ref) {
      final service = ref.watch(pushNotificationServiceProvider);
      final notifier = PushNotificationNotifier(service);

      final currentAuth = ref.read(authStateProvider);
      if (currentAuth is Authenticated) unawaited(notifier.initialize());

      ref.listen<AuthState>(authStateProvider, (previous, auth) {
        if (auth is Authenticated &&
            (previous is! Authenticated || previous.user.id != auth.user.id)) {
          unawaited(notifier.initialize());
        } else if (auth is! Authenticated) {
          unawaited(notifier.unregister());
        }
      });

      var lastTapKey = '';
      var lastTapAt = DateTime.fromMillisecondsSinceEpoch(0);
      final messageSubscription = service.messages.listen((_) {
        unawaited(ref.read(unreadCountProvider.notifier).refresh());
        if (ref.read(authStateProvider) is Authenticated) {
          unawaited(
            ref.read(notificationListProvider.notifier).load(refresh: true),
          );
        }
      });
      final tapSubscription = service.taps.listen((message) {
        final context = rootNavigatorKey.currentContext;
        if (context == null || !context.mounted) return;
        final route = _notificationRoute(message);
        final tapKey = route ?? AppRoutes.notifications;
        final now = DateTime.now();
        if (tapKey == lastTapKey &&
            now.difference(lastTapAt) < const Duration(seconds: 2)) {
          return;
        }
        lastTapKey = tapKey;
        lastTapAt = now;
        if (route == null) {
          context.push(AppRoutes.notifications);
          return;
        }
        context.push(route);
      });

      ref.onDispose(() {
        messageSubscription.cancel();
        tapSubscription.cancel();
      });

      return notifier;
    });

String _message(Object error) {
  if (error is Failure) return error.message;
  return error.toString();
}

final _idPattern = RegExp(r'^[a-fA-F0-9]{24}$');

bool _isValidId(String? value) {
  if (value == null) return false;
  return _idPattern.hasMatch(value.trim());
}

@visibleForTesting
String? notificationRouteForMessage(PushNotificationMessage message) {
  return _notificationRoute(message);
}

String? _notificationRoute(PushNotificationMessage message) {
  final data = message.data;
  final type = data['type']?.toString().toUpperCase();
  final relatedType = data['relatedEntityType']?.toString().toUpperCase();
  final relatedId = data['relatedEntityId']?.toString();
  final matchId = data['matchId']?.toString();
  final auctionId = data['auctionId']?.toString();

  final resolvedMatchId = _isValidId(matchId)
      ? matchId
      : (_isValidId(relatedId) &&
                (relatedType == 'MATCH' || type?.contains('MATCH') == true)
            ? relatedId
            : null);
  final resolvedAuctionId = _isValidId(auctionId)
      ? auctionId
      : (_isValidId(relatedId) &&
                (relatedType == 'AUCTION' || type?.contains('AUCTION') == true)
            ? relatedId
            : null);

  if (type == 'AUCTION_BID' ||
      type == 'AUCTION_OUTBID' ||
      type == 'AUCTION_WON' ||
      type == 'AUCTION_RESULT') {
    if (resolvedAuctionId != null)
      return '/auctions/$resolvedAuctionId/bidding';
  }
  if (resolvedAuctionId != null) return '/auctions/$resolvedAuctionId';
  if (resolvedMatchId != null) return '/matches/$resolvedMatchId';
  return null;
}
