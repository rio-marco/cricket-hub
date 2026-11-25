class MatchRealtimeEvent {
  final String name;
  final String? eventId;
  final String? matchId;
  final String? action;
  final int? stateVersion;
  final Map<String, dynamic> data;

  const MatchRealtimeEvent({
    required this.name,
    required this.data,
    this.eventId,
    this.matchId,
    this.action,
    this.stateVersion,
  });

  factory MatchRealtimeEvent.from(String name, dynamic value) {
    final data = normalizeMap(value);
    return MatchRealtimeEvent(
      name: name,
      data: data,
      eventId: _string(data['eventId']),
      matchId: _string(data['matchId']),
      action: _string(data['action']),
      stateVersion: _int(data['stateVersion']),
    );
  }

  Map<String, dynamic>? get state => normalizeMapOrNull(data['state']);

  String? get errorMessage {
    final error = normalizeMapOrNull(data['error']);
    final message = _string(error?['message']);
    if (message != null && message.isNotEmpty) return message;
    final direct = _string(data['message']);
    return direct == null || direct.isEmpty ? null : direct;
  }

  bool get hasState => state != null;
}

Map<String, dynamic> normalizeMap(dynamic value) {
  final normalized = normalize(value);
  if (normalized is Map<String, dynamic>) return normalized;
  if (normalized is Map) {
    return normalized.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

Map<String, dynamic>? normalizeMapOrNull(dynamic value) {
  if (value == null) return null;
  final normalized = normalize(value);
  if (normalized is Map<String, dynamic>) return normalized;
  if (normalized is Map) {
    return normalized.map((key, item) => MapEntry(key.toString(), item));
  }
  return null;
}

dynamic normalize(dynamic value) {
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), normalize(item)));
  }
  if (value is List) {
    return value.map(normalize).toList();
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
