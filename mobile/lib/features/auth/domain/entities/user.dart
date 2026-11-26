/// User domain entity representing an authenticated user in the Cricket Hub platform.
class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String role;
  final bool isVerified;
  final bool? isBlocked;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    this.role = 'user',
    this.isVerified = false,
    this.isBlocked,
    this.createdAt,
  });

  /// Factory constructor to create a User from JSON map.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      role: parseUserRole(json['role']),
      isVerified: parseUserBool(json['isVerified'] ?? json['is_verified']) ?? false,
      isBlocked: parseUserBool(
        json['isBlocked'] ?? json['is_blocked'] ?? json['blocked'],
      ),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is DateTime
              ? json['createdAt'] as DateTime
              : DateTime.tryParse(json['createdAt'].toString()))
          : null,
    );
  }

  /// Converts the User instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      if (avatar != null) 'avatar': avatar,
      'role': role,
      'isVerified': isVerified,
      if (isBlocked != null) 'isBlocked': isBlocked,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  /// Creates a copy of this User with updated fields.
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    String? role,
    bool? isVerified,
    bool? isBlocked,
    DateTime? createdAt,
    bool clearIsBlocked = false,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      isBlocked: clearIsBlocked ? null : isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// User initials for avatar placeholder
  String get initials {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  /// Whether the user is an administrator
  bool get isAdmin {
    final normalized = role.trim().replaceAll('-', '_').replaceAll(' ', '_').toUpperCase();
    return normalized == 'ADMIN' ||
        normalized == 'ROLE_ADMIN' ||
        normalized.endsWith('_ADMIN');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          phone == other.phone &&
          avatar == other.avatar &&
          role == other.role &&
          isVerified == other.isVerified &&
          isBlocked == other.isBlocked &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      email.hashCode ^
      phone.hashCode ^
      avatar.hashCode ^
      role.hashCode ^
      isVerified.hashCode ^
      (isBlocked?.hashCode ?? 0) ^
      createdAt.hashCode;

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, phone: $phone, role: $role, isVerified: $isVerified, isBlocked: $isBlocked)';
  }
}

bool? parseUserBool(dynamic value) {
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
  return null;
}

String parseUserRole(dynamic value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  if (value is Map) {
    final nested = value['role'] ?? value['name'] ?? value['value'];
    if (nested is String && nested.trim().isNotEmpty) return nested.trim();
  }
  return 'user';
}
