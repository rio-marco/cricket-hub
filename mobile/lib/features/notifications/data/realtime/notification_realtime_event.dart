import '../../domain/entities/app_notification.dart';

class NotificationRealtimeEvent {
  final String name;
  final String? eventId;
  final int? unreadCount;
  final AppNotification? notification;
  final Map<String, dynamic> data;

  const NotificationRealtimeEvent({
    required this.name,
    required this.data,
    this.eventId,
    this.unreadCount,
    this.notification,
  });

  factory NotificationRealtimeEvent.from(String name, dynamic value) {
    final data = normalizeMap(value);
    final notification = normalizeMapOrNull(data['notification']);
    return NotificationRealtimeEvent(
      name: name,
      data: data,
      eventId: _string(data['eventId']),
      unreadCount: _int(data['unreadCount']),
      notification: notification == null
          ? null
          : AppNotification.fromJson(notification),
    );
  }
}

Map<String, dynamic> normalizeMap(dynamic value) {
  final normalized = normalizeValue(value);
  if (normalized is Map<String, dynamic>) return normalized;
  if (normalized is Map) {
    return normalized.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

Map<String, dynamic>? normalizeMapOrNull(dynamic value) {
  if (value == null) return null;
  final normalized = normalizeValue(value);
  if (normalized is Map<String, dynamic>) return normalized;
  if (normalized is Map) {
    return normalized.map((key, item) => MapEntry(key.toString(), item));
  }
  return null;
}

dynamic normalizeValue(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), normalizeValue(item)),
    );
  }
  if (value is List) {
    return value.map(normalizeValue).toList();
  }
  return value;
}

String? _string(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

int? _int(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
