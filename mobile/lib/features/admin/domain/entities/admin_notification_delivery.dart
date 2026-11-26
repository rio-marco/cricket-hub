import 'admin_json.dart';

class AdminNotificationDelivery {
  final String id;
  final String notificationTitle;
  final String userId;
  final String status;
  final String channel;
  final DateTime? sentAt;
  final String failureReason;
  final Map<String, dynamic> raw;

  const AdminNotificationDelivery({
    required this.id,
    this.notificationTitle = '',
    this.userId = '',
    this.status = '',
    this.channel = '',
    this.sentAt,
    this.failureReason = '',
    this.raw = const <String, dynamic>{},
  });

  factory AdminNotificationDelivery.fromJson(dynamic json) {
    final data = AdminJson.entity(json, const <String>['delivery']);
    final notification = AdminJson.map(data['notification']);
    final user = AdminJson.map(data['user']);
    return AdminNotificationDelivery(
      id: AdminJson.entityId(data),
      notificationTitle: AdminJson.string(
        notification['title'] ?? data['title'] ?? data['notificationTitle'],
      ),
      userId: AdminJson.entityId(user).isEmpty
          ? AdminJson.string(data['userId'])
          : AdminJson.entityId(user),
      status: AdminJson.string(data['status'] ?? data['deliveryStatus']),
      channel: AdminJson.string(data['channel'] ?? data['provider']),
      sentAt: AdminJson.date(
        data['sentAt'] ?? data['deliveredAt'] ?? data['createdAt'],
      ),
      failureReason: AdminJson.string(
        data['failureReason'] ?? data['error'] ?? data['errorMessage'],
      ),
      raw: AdminJson.map(data),
    );
  }
}
