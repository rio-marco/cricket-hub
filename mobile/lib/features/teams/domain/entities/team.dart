/// Team domain entity representing a cricket squad in Cricket Hub.
class Team {
  final String id;
  final String name;
  final String? logo;
  final String? description;
  final String? location;
  final String owner;
  final String? ownerName;
  final String? captain;
  final String? captainName;
  final String? viceCaptain;
  final String? viceCaptainName;
  final String? wicketkeeper;
  final String? wicketkeeperName;
  final bool isActive;
  final int memberCount;
  final int totalMatches;
  final int wonMatches;
  final int lostMatches;
  final DateTime? createdAt;

  const Team({
    required this.id,
    required this.name,
    this.logo,
    this.description,
    this.location,
    required this.owner,
    this.ownerName,
    this.captain,
    this.captainName,
    this.viceCaptain,
    this.viceCaptainName,
    this.wicketkeeper,
    this.wicketkeeperName,
    this.isActive = true,
    this.memberCount = 0,
    this.totalMatches = 0,
    this.wonMatches = 0,
    this.lostMatches = 0,
    this.createdAt,
  });

  /// Factory constructor to parse Team from JSON map
  factory Team.fromJson(Map<String, dynamic> json) {
    // Handle owner which might be populated object or ID string
    String ownerId = '';
    String? ownerName;
    if (json['owner'] is Map) {
      final ownerMap = json['owner'] as Map<String, dynamic>;
      ownerId = ownerMap['_id']?.toString() ?? ownerMap['id']?.toString() ?? '';
      ownerName = ownerMap['name']?.toString();
    } else if (json['owner'] != null) {
      ownerId = json['owner'].toString();
    }
    if (ownerName == null && json['ownerName'] != null) {
      ownerName = json['ownerName'].toString();
    }

    // Handle captain
    String? captainId;
    String? captainName;
    if (json['captain'] is Map) {
      final captainMap = json['captain'] as Map<String, dynamic>;
      captainId = captainMap['_id']?.toString() ?? captainMap['id']?.toString();
      captainName = captainMap['name']?.toString() ??
          (captainMap['user'] is Map ? (captainMap['user'] as Map)['name']?.toString() : null);
    } else if (json['captain'] != null) {
      captainId = json['captain'].toString();
    }
    if (captainName == null && json['captainName'] != null) {
      captainName = json['captainName'].toString();
    }

    // Handle viceCaptain
    String? viceCaptainId;
    String? viceCaptainName;
    if (json['viceCaptain'] is Map) {
      final vcMap = json['viceCaptain'] as Map<String, dynamic>;
      viceCaptainId = vcMap['_id']?.toString() ?? vcMap['id']?.toString();
      viceCaptainName = vcMap['name']?.toString() ??
          (vcMap['user'] is Map ? (vcMap['user'] as Map)['name']?.toString() : null);
    } else if (json['viceCaptain'] != null) {
      viceCaptainId = json['viceCaptain'].toString();
    }
    if (viceCaptainName == null && json['viceCaptainName'] != null) {
      viceCaptainName = json['viceCaptainName'].toString();
    }

    // Handle wicketkeeper
    String? wkId;
    String? wkName;
    if (json['wicketkeeper'] is Map) {
      final wkMap = json['wicketkeeper'] as Map<String, dynamic>;
      wkId = wkMap['_id']?.toString() ?? wkMap['id']?.toString();
      wkName = wkMap['name']?.toString() ??
          (wkMap['user'] is Map ? (wkMap['user'] as Map)['name']?.toString() : null);
    } else if (json['wicketkeeper'] != null) {
      wkId = json['wicketkeeper'].toString();
    }
    if (wkName == null && json['wicketkeeperName'] != null) {
      wkName = json['wicketkeeperName'].toString();
    }

    final membersList = json['members'];
    int count = json['memberCount'] as int? ??
        (membersList is List ? membersList.length : 0);

    return Team(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      logo: json['logo'] as String?,
      description: json['description'] as String?,
      location: json['location'] as String?,
      owner: ownerId,
      ownerName: ownerName,
      captain: captainId,
      captainName: captainName,
      viceCaptain: viceCaptainId,
      viceCaptainName: viceCaptainName,
      wicketkeeper: wkId,
      wicketkeeperName: wkName,
      isActive: json['isActive'] as bool? ?? true,
      memberCount: count,
      totalMatches: json['totalMatches'] as int? ?? json['matches'] as int? ?? 0,
      wonMatches: json['wonMatches'] as int? ?? json['won'] as int? ?? 0,
      lostMatches: json['lostMatches'] as int? ?? json['lost'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is DateTime
              ? json['createdAt'] as DateTime
              : DateTime.tryParse(json['createdAt'].toString()))
          : null,
    );
  }

  /// Converts the Team instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (logo != null) 'logo': logo,
      if (description != null) 'description': description,
      if (location != null) 'location': location,
      'owner': owner,
      if (ownerName != null) 'ownerName': ownerName,
      if (captain != null) 'captain': captain,
      if (captainName != null) 'captainName': captainName,
      if (viceCaptain != null) 'viceCaptain': viceCaptain,
      if (viceCaptainName != null) 'viceCaptainName': viceCaptainName,
      if (wicketkeeper != null) 'wicketkeeper': wicketkeeper,
      if (wicketkeeperName != null) 'wicketkeeperName': wicketkeeperName,
      'isActive': isActive,
      'memberCount': memberCount,
      'totalMatches': totalMatches,
      'wonMatches': wonMatches,
      'lostMatches': lostMatches,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  /// Creates a copy of this Team with updated fields
  Team copyWith({
    String? id,
    String? name,
    String? logo,
    String? description,
    String? location,
    String? owner,
    String? ownerName,
    String? captain,
    String? captainName,
    String? viceCaptain,
    String? viceCaptainName,
    String? wicketkeeper,
    String? wicketkeeperName,
    bool? isActive,
    int? memberCount,
    int? totalMatches,
    int? wonMatches,
    int? lostMatches,
    DateTime? createdAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      description: description ?? this.description,
      location: location ?? this.location,
      owner: owner ?? this.owner,
      ownerName: ownerName ?? this.ownerName,
      captain: captain ?? this.captain,
      captainName: captainName ?? this.captainName,
      viceCaptain: viceCaptain ?? this.viceCaptain,
      viceCaptainName: viceCaptainName ?? this.viceCaptainName,
      wicketkeeper: wicketkeeper ?? this.wicketkeeper,
      wicketkeeperName: wicketkeeperName ?? this.wicketkeeperName,
      isActive: isActive ?? this.isActive,
      memberCount: memberCount ?? this.memberCount,
      totalMatches: totalMatches ?? this.totalMatches,
      wonMatches: wonMatches ?? this.wonMatches,
      lostMatches: lostMatches ?? this.lostMatches,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Team initials for avatar badge
  String get initials {
    if (name.trim().isEmpty) return 'T';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Win percentage calculation
  double get winRate {
    if (totalMatches <= 0) return 0.0;
    return (wonMatches / totalMatches) * 100;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Team &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          owner == other.owner;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ owner.hashCode;

  @override
  String toString() => 'Team(id: $id, name: $name, location: $location)';
}
