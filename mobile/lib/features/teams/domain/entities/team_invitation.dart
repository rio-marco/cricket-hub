/// TeamInvitation entity representing team invitations and join requests.
class TeamInvitation {
  final String id;
  final String team;
  final String? teamName;
  final String? teamLogo;
  final String? player;
  final String? playerName;
  final String invitedBy;
  final String? invitedByName;
  final String type; // 'INVITE' or 'JOIN_REQUEST'
  final String status; // 'PENDING', 'ACCEPTED', 'REJECTED', 'CANCELLED'
  final String? message;
  final DateTime? createdAt;

  const TeamInvitation({
    required this.id,
    required this.team,
    this.teamName,
    this.teamLogo,
    this.player,
    this.playerName,
    required this.invitedBy,
    this.invitedByName,
    this.type = 'INVITE',
    this.status = 'PENDING',
    this.message,
    this.createdAt,
  });

  factory TeamInvitation.fromJson(Map<String, dynamic> json) {
    // Extract team info
    String teamId = '';
    String? teamName;
    String? teamLogo;
    if (json['team'] is Map) {
      final tMap = json['team'] as Map<String, dynamic>;
      teamId = tMap['_id']?.toString() ?? tMap['id']?.toString() ?? '';
      teamName = tMap['name']?.toString();
      teamLogo = tMap['logo']?.toString();
    } else if (json['team'] != null) {
      teamId = json['team'].toString();
    }
    if (teamName == null && json['teamName'] != null) {
      teamName = json['teamName'].toString();
    }
    if (teamLogo == null && json['teamLogo'] != null) {
      teamLogo = json['teamLogo'].toString();
    }

    // Extract player info
    String? playerId;
    String? playerName;
    if (json['player'] is Map) {
      final pMap = json['player'] as Map<String, dynamic>;
      playerId = pMap['_id']?.toString() ?? pMap['id']?.toString();
      if (pMap['user'] is Map) {
        playerName = (pMap['user'] as Map)['name']?.toString();
      } else {
        playerName = pMap['name']?.toString();
      }
    } else if (json['player'] != null) {
      playerId = json['player'].toString();
    }
    if (playerName == null && json['playerName'] != null) {
      playerName = json['playerName'].toString();
    }

    // Extract invitedBy info
    String invitedById = '';
    String? invitedByName;
    if (json['invitedBy'] is Map) {
      final iMap = json['invitedBy'] as Map<String, dynamic>;
      invitedById = iMap['_id']?.toString() ?? iMap['id']?.toString() ?? '';
      invitedByName = iMap['name']?.toString();
    } else if (json['invitedBy'] != null) {
      invitedById = json['invitedBy'].toString();
    }
    if (invitedByName == null && json['invitedByName'] != null) {
      invitedByName = json['invitedByName'].toString();
    }

    return TeamInvitation(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      team: teamId,
      teamName: teamName,
      teamLogo: teamLogo,
      player: playerId,
      playerName: playerName,
      invitedBy: invitedById,
      invitedByName: invitedByName,
      type: json['type'] as String? ?? 'INVITE',
      status: json['status'] as String? ?? 'PENDING',
      message: json['message'] as String?,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is DateTime
              ? json['createdAt'] as DateTime
              : DateTime.tryParse(json['createdAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team': team,
      if (teamName != null) 'teamName': teamName,
      if (teamLogo != null) 'teamLogo': teamLogo,
      if (player != null) 'player': player,
      if (playerName != null) 'playerName': playerName,
      'invitedBy': invitedBy,
      if (invitedByName != null) 'invitedByName': invitedByName,
      'type': type,
      'status': status,
      if (message != null) 'message': message,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  TeamInvitation copyWith({
    String? id,
    String? team,
    String? teamName,
    String? teamLogo,
    String? player,
    String? playerName,
    String? invitedBy,
    String? invitedByName,
    String? type,
    String? status,
    String? message,
    DateTime? createdAt,
  }) {
    return TeamInvitation(
      id: id ?? this.id,
      team: team ?? this.team,
      teamName: teamName ?? this.teamName,
      teamLogo: teamLogo ?? this.teamLogo,
      player: player ?? this.player,
      playerName: playerName ?? this.playerName,
      invitedBy: invitedBy ?? this.invitedBy,
      invitedByName: invitedByName ?? this.invitedByName,
      type: type ?? this.type,
      status: status ?? this.status,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isAccepted => status.toUpperCase() == 'ACCEPTED';
  bool get isRejected => status.toUpperCase() == 'REJECTED';
  bool get isJoinRequest => type.toUpperCase() == 'JOIN_REQUEST';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamInvitation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
