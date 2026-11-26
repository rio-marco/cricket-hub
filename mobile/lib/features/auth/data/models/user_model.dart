import '../../domain/entities/user.dart';

/// User data model extending domain [User] entity with API serialization.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.avatar,
    super.role = 'user',
    super.isVerified = false,
    super.isBlocked,
    super.createdAt,
  });

  /// Factory constructor to parse [UserModel] from API JSON map.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle unwrapping if wrapped inside a "user" key
    final map = json.containsKey('user') && json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;

    return UserModel(
      id: map['id'] as String? ?? map['_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String?,
      avatar: map['avatar'] as String?,
      role: parseUserRole(map['role']),
      isVerified: parseUserBool(map['isVerified'] ?? map['is_verified']) ?? false,
      isBlocked: parseUserBool(
        map['isBlocked'] ?? map['is_blocked'] ?? map['blocked'],
      ),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is DateTime
              ? map['createdAt'] as DateTime
              : DateTime.tryParse(map['createdAt'].toString()))
          : (map['created_at'] != null
              ? DateTime.tryParse(map['created_at'].toString())
              : null),
    );
  }

  /// Factory constructor to convert a domain [User] entity to [UserModel].
  factory UserModel.fromEntity(User entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      phone: entity.phone,
      avatar: entity.avatar,
      role: entity.role,
      isVerified: entity.isVerified,
      isBlocked: entity.isBlocked,
      createdAt: entity.createdAt,
    );
  }

  /// Converts this [UserModel] to JSON map for API requests.
  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      if (isBlocked != null) 'isBlocked': isBlocked,
    };
  }

  /// Returns domain [User] instance.
  User toEntity() {
    return User(
      id: id,
      name: name,
      email: email,
      phone: phone,
      avatar: avatar,
      role: role,
      isVerified: isVerified,
      isBlocked: isBlocked,
      createdAt: createdAt,
    );
  }

  @override
  UserModel copyWith({
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
    return UserModel(
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
}
