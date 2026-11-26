import 'package:mobile/core/errors/exceptions.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/core/models/paginated_response.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource remoteDataSource;

  const NotificationsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<PaginatedResponse<AppNotification>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
    String? type,
    String? category,
    String? relatedEntityId,
  }) async {
    try {
      return await remoteDataSource.getNotifications(
        page: page,
        limit: limit,
        isRead: isRead,
        type: type,
        category: category,
        relatedEntityId: relatedEntityId,
      );
    } on AppException catch (error) {
      throw Failure.fromException(error);
    } catch (error) {
      throw ServerFailure(message: error.toString());
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      return await remoteDataSource.getUnreadCount();
    } on AppException catch (error) {
      throw Failure.fromException(error);
    } catch (error) {
      throw ServerFailure(message: error.toString());
    }
  }

  @override
  Future<AppNotification> markAsRead(String id) async {
    try {
      return await remoteDataSource.markAsRead(id);
    } on AppException catch (error) {
      throw Failure.fromException(error);
    } catch (error) {
      throw ServerFailure(message: error.toString());
    }
  }

  @override
  Future<int> markAllAsRead() async {
    try {
      return await remoteDataSource.markAllAsRead();
    } on AppException catch (error) {
      throw Failure.fromException(error);
    } catch (error) {
      throw ServerFailure(message: error.toString());
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    try {
      await remoteDataSource.deleteNotification(id);
    } on AppException catch (error) {
      throw Failure.fromException(error);
    } catch (error) {
      throw ServerFailure(message: error.toString());
    }
  }

  @override
  Future<NotificationPreferences> getPreferences() async {
    try {
      return await remoteDataSource.getPreferences();
    } on AppException catch (error) {
      throw Failure.fromException(error);
    } catch (error) {
      throw ServerFailure(message: error.toString());
    }
  }

  @override
  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences preferences,
  ) async {
    try {
      return await remoteDataSource.updatePreferences(preferences);
    } on AppException catch (error) {
      throw Failure.fromException(error);
    } catch (error) {
      throw ServerFailure(message: error.toString());
    }
  }

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? deviceId,
    String? appVersion,
  }) async {
    try {
      await remoteDataSource.registerDeviceToken(
        token: token,
        platform: platform,
        deviceId: deviceId,
        appVersion: appVersion,
      );
    } on AppException catch (error) {
      throw Failure.fromException(error);
    } catch (error) {
      throw ServerFailure(message: error.toString());
    }
  }

  @override
  Future<void> removeDeviceToken(String token) async {
    try {
      await remoteDataSource.removeDeviceToken(token);
    } on AppException catch (error) {
      throw Failure.fromException(error);
    } catch (error) {
      throw ServerFailure(message: error.toString());
    }
  }
}
