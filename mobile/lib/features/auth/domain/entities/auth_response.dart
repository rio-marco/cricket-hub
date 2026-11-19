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

  /// Factory constructor to parse AuthResponse from API response JSON.
  /// Handles both direct payload and wrapped `{ data: ... }` formats.
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json.containsKey('data') && json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final userJson = data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : (data.containsKey('data') && data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : data);

    final accessToken = (data['accessToken'] ??
            data['token'] ??
            data['access_token'] ??
            json['token'] ??
            json['accessToken'] ??
            '') as String;

    final refreshToken = (data['refreshToken'] ??
            data['refresh_token'] ??
            json['refreshToken'] ??
            json['refresh_token'] ??
            '') as String;

    return AuthResponse(
      user: User.fromJson(userJson),
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
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
