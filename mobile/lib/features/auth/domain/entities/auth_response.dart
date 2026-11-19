import 'user.dart';

/// Response received upon successful authentication (login, register, token refresh).
class AuthResponse {
  final User user;
  final String accessToken;
  final String refreshToken;

  const AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final outerData = _asMap(json['data']) ?? json;
    final data = _asMap(outerData['data']) ?? outerData;
    final userJson = _asMap(data['user']) ??
        _asMap(outerData['user']) ??
        _asMap(data['userData']) ??
        data;
    final tokens = _asMap(data['tokens']) ??
        _asMap(outerData['tokens']) ??
        _asMap(data['auth']) ??
        outerData;

    return AuthResponse(
      user: User.fromJson(userJson),
      accessToken: _firstString([
        tokens['accessToken'],
        tokens['token'],
        tokens['access_token'],
        data['accessToken'],
        data['token'],
        outerData['accessToken'],
        outerData['token'],
        json['accessToken'],
        json['token'],
      ]),
      refreshToken: _firstString([
        tokens['refreshToken'],
        tokens['refresh_token'],
        data['refreshToken'],
        data['refresh_token'],
        outerData['refreshToken'],
        outerData['refresh_token'],
        json['refreshToken'],
        json['refresh_token'],
      ]),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String _firstString(List<dynamic> values) {
    for (final value in values) {
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return '';
  }

  /// Converts AuthResponse to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }

  /// Creates a copy of AuthResponse with updated fields.
  AuthResponse copyWith({
    User? user,
    String? accessToken,
    String? refreshToken,
  }) {
    return AuthResponse(
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  @override
  String toString() {
    return 'AuthResponse(user: ${user.name}, accessToken: ${accessToken.isNotEmpty ? "[PROTECTED]" : "empty"}, refreshToken: ${refreshToken.isNotEmpty ? "[PROTECTED]" : "empty"})';
  }
}
