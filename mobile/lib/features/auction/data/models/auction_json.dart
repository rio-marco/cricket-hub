Map<String, dynamic> normalizeAuctionMap(dynamic value) {
  final normalized = _normalize(value);
  if (normalized is Map<String, dynamic>) return normalized;
  if (normalized is Map) {
    return normalized.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

Map<String, dynamic>? normalizeAuctionMapOrNull(dynamic value) {
  if (value == null) return null;
  final normalized = _normalize(value);
  if (normalized is Map<String, dynamic>) return normalized;
  if (normalized is Map) {
    return normalized.map((key, item) => MapEntry(key.toString(), item));
  }
  return null;
}

List<dynamic> normalizeAuctionList(dynamic value) {
  final normalized = _normalize(value);
  if (normalized is List) return normalized;
  if (normalized == null) return const [];
  return [normalized];
}

dynamic _normalize(dynamic value) {
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), _normalize(item)));
  }
  if (value is List) {
    return value.map(_normalize).toList();
  }
  return value;
}

String? auctionString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String auctionId(dynamic value, [String fallback = '']) {
  final map = normalizeAuctionMapOrNull(value);
  if (map != null) {
    final id = auctionString(map['_id']) ??
        auctionString(map['id']) ??
        auctionString(map['team']) ??
        auctionString(map['player']);
    return id ?? fallback;
  }
  return auctionString(value) ?? fallback;
}

int auctionInt(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  final text = auctionString(value);
  if (text == null) return fallback;
  return int.tryParse(text) ?? double.tryParse(text)?.toInt() ?? fallback;
}

double auctionDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  final text = auctionString(value);
  if (text == null) return fallback;
  return double.tryParse(text) ?? fallback;
}

bool auctionBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = auctionString(value)?.toLowerCase();
  if (text == null) return fallback;
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return fallback;
}

DateTime? auctionDate(dynamic value) {
  if (value is DateTime) return value;
  final text = auctionString(value);
  if (text == null) return null;
  return DateTime.tryParse(text);
}

String? auctionName(dynamic value) {
  final map = normalizeAuctionMapOrNull(value);
  if (map == null) return auctionString(value);
  final user = normalizeAuctionMapOrNull(map['user']);
  return auctionString(map['name']) ?? auctionString(user?['name']);
}

List<String> auctionIdList(dynamic value) {
  return normalizeAuctionList(value)
      .map((item) => auctionId(item))
      .where((id) => id.isNotEmpty)
      .toList(growable: false);
}

List<String> auctionNameList(dynamic value) {
  return normalizeAuctionList(value)
      .map((item) => auctionName(item) ?? '')
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
}

Map<String, dynamic> auctionResponseData(dynamic response) {
  final envelope = normalizeAuctionMapOrNull(response);
  if (envelope == null) return <String, dynamic>{};
  final data = normalizeAuctionMapOrNull(envelope['data']);
  if (data != null) return data;
  if (envelope['data'] is List) {
    return <String, dynamic>{'items': envelope['data']};
  }
  return envelope;
}
