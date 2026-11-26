class AdminJson {
  const AdminJson._();

  static Map<String, dynamic> map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return <String, dynamic>{};
  }

  static Map<String, dynamic> payload(dynamic value) {
    var current = map(value);
    for (var depth = 0; depth < 4; depth++) {
      final nested = map(current['data']);
      if (nested.isEmpty) break;
      if (_hasIdentity(current) && !nested.containsKey('data')) break;
      current = nested;
    }
    return current;
  }

  static Map<String, dynamic> entity(
    dynamic value, [
    List<String> keys = const <String>[],
  ]) {
    final current = payload(value);
    for (final key in [
      ...keys,
      'user',
      'team',
      'player',
      'tournament',
      'match',
      'auction',
      'report',
      'audit',
      'notification',
      'item',
    ]) {
      final nested = map(current[key]);
      if (nested.isNotEmpty) return payload(nested);
    }
    return current;
  }

  static Map<String, dynamic> listEnvelope(
    dynamic value, [
    List<String> keys = const <String>[],
  ]) {
    var current = payload(value);
    List<dynamic>? items;
    for (var depth = 0; depth < 4; depth++) {
      items = _findList(current, keys);
      if (items != null) break;
      final nested = map(current['data']);
      if (nested.isEmpty) break;
      current = nested;
    }

    final result = <String, dynamic>{'items': items ?? <dynamic>[]};
    final pagination = map(current['pagination']);
    if (pagination.isNotEmpty) result['pagination'] = pagination;
    final meta = map(current['meta']);
    if (meta.isNotEmpty) result['meta'] = meta;
    final total = current['total'] ?? current['totalCount'] ?? current['count'];
    if (total != null) result['total'] = total;
    return result;
  }

  static List<dynamic> list(
    dynamic value, [
    List<String> keys = const <String>[],
  ]) {
    return List<dynamic>.from(listEnvelope(value, keys)['items'] as List);
  }

  static String string(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String entityId(dynamic value) {
    if (value is Map) {
      return string(value['id'] ?? value['_id'] ?? value['uuid']);
    }
    return string(value);
  }

  static int integer(dynamic value, [int fallback = 0]) {
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed =
          int.tryParse(value.trim()) ?? double.tryParse(value.trim())?.toInt();
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static double number(dynamic value, [double fallback = 0]) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static bool boolean(dynamic value, [bool fallback = false]) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return fallback;
  }

  static DateTime? date(dynamic value) {
    if (value is DateTime) return value;
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static Map<String, dynamic> details(dynamic value) {
    if (value is Map) return map(value);
    if (value is String && value.trim().isNotEmpty) {
      return <String, dynamic>{'detail': value.trim()};
    }
    return <String, dynamic>{};
  }

  static bool _hasIdentity(Map<String, dynamic> value) {
    return value.containsKey('id') ||
        value.containsKey('_id') ||
        value.containsKey('name') ||
        value.containsKey('title');
  }

  static List<dynamic>? _findList(
    Map<String, dynamic> value,
    List<String> keys,
  ) {
    for (final key in [
      ...keys,
      'items',
      'results',
      'users',
      'teams',
      'players',
      'tournaments',
      'matches',
      'auctions',
      'deliveries',
      'audits',
      'logs',
      'reports',
      'bids',
      'events',
      'corrections',
      'records',
      'rows',
      'data',
    ]) {
      final candidate = value[key];
      if (candidate is List) return candidate;
    }
    return null;
  }
}
