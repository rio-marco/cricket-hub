import '../../../../core/models/paginated_response.dart';
import '../entities/app_notification.dart';
import '../entities/notification_preferences.dart';

abstract class NotificationsRepository {
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
