import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/core/errors/exceptions.dart';
import 'package:mobile/core/models/paginated_response.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_preferences.dart';

abstract class NotificationsRemoteDataSource {
  Future<PaginatedResponse<AppNotification>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
    String? type,
    String? category,
    String? relatedEntityId,
  });

  Future<int> getUnreadCount();

  Future<AppNotification> markAsRead(String id);

  Future<int> markAllAsRead();

  Future<void> deleteNotification(String id);

  Future<NotificationPreferences> getPreferences();

  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences preferences,
  );

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? deviceId,
    String? appVersion,
  });

  Future<void> removeDeviceToken(String token);
}

class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  final ApiClient _apiClient;

  const NotificationsRemoteDataSourceImpl(this._apiClient);

  @override
  Future<PaginatedResponse<AppNotification>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
    String? type,
    String? category,
    String? relatedEntityId,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.notifications,
      queryParameters: <String, dynamic>{
        'page': page,
        'limit': limit,
        if (isRead != null) 'isRead': isRead,
        if (type != null && type.isNotEmpty) 'type': type,
        if (category != null && category.isNotEmpty) 'category': category,
        if (relatedEntityId != null && relatedEntityId.isNotEmpty)
          'relatedEntityId': relatedEntityId,
      },
    );
    return PaginatedResponse.fromJson(
      _envelope(response.data),
      (item) => AppNotification.fromJson(_map(item)),
    );
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.notificationUnreadCount,
    );
    final data = _data(response.data);
    return _int(data['count']) ?? 0;
  }

  @override
  Future<AppNotification> markAsRead(String id) async {
    final response = await _apiClient.patch<dynamic>(
      ApiEndpoints.notificationRead(id),
      data: const <String, dynamic>{},
    );
    return AppNotification.fromJson(_data(response.data));
  }

  @override
  Future<int> markAllAsRead() async {
    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.markAllNotificationsRead,
      data: const <String, dynamic>{},
    );
    return _int(_data(response.data)['modifiedCount']) ?? 0;
  }

  @override
  Future<void> deleteNotification(String id) async {
    await _apiClient.delete<dynamic>(ApiEndpoints.notificationById(id));
  }

  @override
  Future<NotificationPreferences> getPreferences() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.notificationPreferences,
    );
    return NotificationPreferences.fromJson(_data(response.data));
  }

  @override
  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences preferences,
  ) async {
    final response = await _apiClient.put<dynamic>(
      ApiEndpoints.notificationPreferences,
      data: preferences.toJson(),
    );
    return NotificationPreferences.fromJson(_data(response.data));
  }

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? deviceId,
    String? appVersion,
  }) async {
    await _apiClient.post<dynamic>(
      ApiEndpoints.registerPushToken,
      data: <String, dynamic>{
        'token': token,
        'platform': platform,
        if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
        if (appVersion != null && appVersion.isNotEmpty)
          'appVersion': appVersion,
      },
    );
  }

  @override
  Future<void> removeDeviceToken(String token) async {
    await _apiClient.delete<dynamic>(
      ApiEndpoints.removePushToken,
      data: <String, dynamic>{'token': token},
    );
  }
}

Map<String, dynamic> _envelope(dynamic value) {
  final map = _map(value);
  if (!map.containsKey('success')) {
    throw const ServerException(
      message: 'Invalid notification response received.',
    );
  }
  return map;
}

Map<String, dynamic> _data(dynamic value) {
  final envelope = _map(value);
  final data = _map(envelope['data']);
  if (data.isEmpty && envelope['data'] != null) {
    throw const ServerException(
      message: 'Invalid notification data received.',
    );
  }
  return data;
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

int? _int(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
