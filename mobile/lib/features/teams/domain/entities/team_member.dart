/// TeamMember entity representing a rostered cricket player on a team.
class TeamMember {
  final String id;
  final String team;
  final String player;
  final String? playerName;
  final String? playerAvatar;
  final String? playingRole;
  final String? battingStyle;
  final String? bowlingStyle;
  final int? jerseyNumber;
  final String role; // 'CAPTAIN', 'VICE_CAPTAIN', 'WICKETKEEPER', 'PLAYER'
  final String status; // 'ACTIVE', 'INACTIVE'
  final DateTime? joinedAt;

  const TeamMember({
    required this.id,
    required this.team,
    required this.player,
    this.playerName,
    this.playerAvatar,
    this.playingRole,
    this.battingStyle,
    this.bowlingStyle,
    this.jerseyNumber,
    this.role = 'PLAYER',
    this.status = 'ACTIVE',
    this.joinedAt,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    // Extract player details if populated
    String playerId = '';
    String? playerName;
    String? playerAvatar;
    String? playingRole;
    String? battingStyle;
    String? bowlingStyle;
    int? jerseyNumber;

    if (json['player'] is Map) {
      final pMap = json['player'] as Map<String, dynamic>;
      playerId = pMap['_id']?.toString() ?? pMap['id']?.toString() ?? '';
      playingRole = pMap['playingRole']?.toString();
      battingStyle = pMap['battingStyle']?.toString();
      bowlingStyle = pMap['bowlingStyle']?.toString();
      jerseyNumber = pMap['jerseyNumber'] as int?;

      if (pMap['user'] is Map) {
        final uMap = pMap['user'] as Map<String, dynamic>;
        playerName = uMap['name']?.toString();
        playerAvatar = uMap['avatar']?.toString();
      } else if (pMap['name'] != null) {
        playerName = pMap['name']?.toString();
        playerAvatar = pMap['avatar']?.toString();
      }
    } else if (json['player'] != null) {
      playerId = json['player'].toString();
    }

    if (playerName == null && json['playerName'] != null) {
      playerName = json['playerName']?.toString();
    }
    if (playerAvatar == null && json['playerAvatar'] != null) {
      playerAvatar = json['playerAvatar']?.toString();
    }
    if (playingRole == null && json['playingRole'] != null) {
      playingRole = json['playingRole']?.toString();
    }

    // Extract team ID
    String teamId = '';
    if (json['team'] is Map) {
      teamId = (json['team'] as Map)['_id']?.toString() ??
          (json['team'] as Map)['id']?.toString() ??
          '';
    } else if (json['team'] != null) {
      teamId = json['team'].toString();
    }

    return TeamMember(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      team: teamId,
      player: playerId,
      playerName: playerName,
      playerAvatar: playerAvatar,
      playingRole: playingRole,
      battingStyle: battingStyle,
      bowlingStyle: bowlingStyle,
      jerseyNumber: jerseyNumber ?? json['jerseyNumber'] as int?,
      role: json['role'] as String? ?? 'PLAYER',
      status: json['status'] as String? ?? 'ACTIVE',
      joinedAt: json['joinedAt'] != null
          ? (json['joinedAt'] is DateTime
              ? json['joinedAt'] as DateTime
              : DateTime.tryParse(json['joinedAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team': team,
      'player': player,
      if (playerName != null) 'playerName': playerName,
      if (playerAvatar != null) 'playerAvatar': playerAvatar,
      if (playingRole != null) 'playingRole': playingRole,
      if (battingStyle != null) 'battingStyle': battingStyle,
      if (bowlingStyle != null) 'bowlingStyle': bowlingStyle,
      if (jerseyNumber != null) 'jerseyNumber': jerseyNumber,
      'role': role,
      'status': status,
      if (joinedAt != null) 'joinedAt': joinedAt!.toIso8601String(),
    };
  }

  TeamMember copyWith({
    String? id,
    String? team,
    String? player,
    String? playerName,
    String? playerAvatar,
    String? playingRole,
    String? battingStyle,
    String? bowlingStyle,
    int? jerseyNumber,
    String? role,
    String? status,
    DateTime? joinedAt,
  }) {
    return TeamMember(
      id: id ?? this.id,
      team: team ?? this.team,
      player: player ?? this.player,
      playerName: playerName ?? this.playerName,
      playerAvatar: playerAvatar ?? this.playerAvatar,
      playingRole: playingRole ?? this.playingRole,
      battingStyle: battingStyle ?? this.battingStyle,
      bowlingStyle: bowlingStyle ?? this.bowlingStyle,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      role: role ?? this.role,
      status: status ?? this.status,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  bool get isCaptain => role.toUpperCase() == 'CAPTAIN';
  bool get isViceCaptain => role.toUpperCase() == 'VICE_CAPTAIN';
  bool get isWicketkeeper => role.toUpperCase() == 'WICKETKEEPER';

  String get initials {
    final name = playerName ?? 'Player';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamMember &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          team == other.team &&
          player == other.player;

  @override
  int get hashCode => id.hashCode ^ team.hashCode ^ player.hashCode;
}
