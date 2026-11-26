enum AppNotificationCategory {
  system,
  team,
  tournament,
  match,
  auction,
  unknown;

  static AppNotificationCategory from(String? value) {
    return AppNotificationCategory.values.firstWhere(
      (category) => category.name == value?.toLowerCase(),
      orElse: () => AppNotificationCategory.unknown,
    );
  }
}

class AppNotification {
  final String id;
  final String type;
  final AppNotificationCategory category;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.body,
    this.data = const <String, dynamic>{},
    this.relatedEntityType,
    this.relatedEntityId,
    this.isRead = false,
    this.readAt,
    this.createdAt,
    this.updatedAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: _string(json['id'] ?? json['_id']) ?? '',
      type: _string(json['type']) ?? 'GENERAL',
      category: AppNotificationCategory.from(_string(json['category'])),
      title: _string(json['title']) ?? 'Notification',
      body: _string(json['body']) ?? '',
      data: _map(json['data']),
      relatedEntityType: _string(json['relatedEntityType']),
      relatedEntityId: _string(json['relatedEntityId']),
      isRead: json['isRead'] == true,
      readAt: _date(json['readAt']),
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
    );
  }

  AppNotification copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id,
      type: type,
      category: category,
      title: title,
      body: body,
      data: data,
      relatedEntityType: relatedEntityType,
      relatedEntityId: relatedEntityId,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

DateTime? _date(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String? _string(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}
