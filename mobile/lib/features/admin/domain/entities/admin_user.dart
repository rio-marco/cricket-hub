import 'admin_json.dart';

class AdminUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final bool isVerified;
  final bool isBlocked;
  final String status;
  final DateTime? createdAt;
  final int teamCount;
  final Map<String, dynamic> raw;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role = 'user',
    this.isVerified = false,
    this.isBlocked = false,
    this.status = '',
    this.createdAt,
    this.teamCount = 0,
    this.raw = const <String, dynamic>{},
  });

  factory AdminUser.fromJson(dynamic json) {
    final data = AdminJson.entity(json, const <String>['user']);
    final profile = AdminJson.map(data['user'] ?? data['profile']);
    final source = <String, dynamic>{...data, ...profile};
    final status = AdminJson.string(
      source['status'] ?? source['accountStatus'],
    );

    return AdminUser(
      id: AdminJson.entityId(source),
      name: AdminJson.string(
        source['name'] ?? source['fullName'] ?? source['displayName'],
        'Unknown user',
      ),
      email: AdminJson.string(source['email'], 'No email'),
      phone: AdminJson.string(source['phone'] ?? source['phoneNumber']).isEmpty
          ? null
          : AdminJson.string(source['phone'] ?? source['phoneNumber']),
      role: AdminJson.string(source['role'], 'user'),
      isVerified: AdminJson.boolean(
        source['isVerified'] ?? source['is_verified'],
      ),
      isBlocked:
          AdminJson.boolean(
            source['isBlocked'] ?? source['is_blocked'] ?? source['blocked'],
          ) ||
          status.toUpperCase() == 'BLOCKED',
      status: status,
      createdAt: AdminJson.date(source['createdAt'] ?? source['created_at']),
      teamCount: AdminJson.integer(source['teamCount'] ?? source['teamsCount']),
      raw: AdminJson.map(data),
    );
  }

  String get statusLabel {
    if (isBlocked || status.toUpperCase() == 'BLOCKED') return 'BLOCKED';
    if (status.isNotEmpty) return status.toUpperCase();
    return isVerified ? 'ACTIVE' : 'PENDING';
  }
}
