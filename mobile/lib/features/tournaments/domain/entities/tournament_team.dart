/// Tournament team domain entity representing team participation and standing.
class TournamentTeam {
  final String id;
  final String tournament;
  final dynamic team;
  final String status; // PENDING, APPROVED, REJECTED
  final int played;
  final int won;
  final int lost;
  final int tied;
  final int noResult;
  final int points;
  final double netRunRate;
  final int runsScored;
  final double oversPlayed;
  final int runsConceded;
  final double oversBowled;
  final DateTime? createdAt;

  const TournamentTeam({
    required this.id,
    required this.tournament,
    required this.team,
    this.status = 'PENDING',
    this.played = 0,
    this.won = 0,
    this.lost = 0,
    this.tied = 0,
    this.noResult = 0,
    this.points = 0,
    this.netRunRate = 0.0,
    this.runsScored = 0,
    this.oversPlayed = 0.0,
    this.runsConceded = 0,
    this.oversBowled = 0.0,
    this.createdAt,
  });

  /// Factory constructor to parse TournamentTeam from JSON map.
  factory TournamentTeam.fromJson(Map<String, dynamic> json) {
    return TournamentTeam(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      tournament: json['tournament'] is Map
          ? ((json['tournament'] as Map)['id'] ?? (json['tournament'] as Map)['_id'] ?? '').toString()
          : (json['tournament'] as String? ?? ''),
      team: json['team'],
      status: (json['status'] as String? ?? 'PENDING').toUpperCase(),
      played: json['played'] is num ? (json['played'] as num).toInt() : 0,
      won: json['won'] is num ? (json['won'] as num).toInt() : 0,
      lost: json['lost'] is num ? (json['lost'] as num).toInt() : 0,
      tied: json['tied'] is num ? (json['tied'] as num).toInt() : 0,
      noResult: json['noResult'] is num
          ? (json['noResult'] as num).toInt()
          : (json['nr'] is num ? (json['nr'] as num).toInt() : 0),
      points: json['points'] is num
          ? (json['points'] as num).toInt()
          : (json['pts'] is num ? (json['pts'] as num).toInt() : 0),
      netRunRate: json['netRunRate'] is num
          ? (json['netRunRate'] as num).toDouble()
          : (json['nrr'] is num ? (json['nrr'] as num).toDouble() : 0.0),
      runsScored: json['runsScored'] is num ? (json['runsScored'] as num).toInt() : 0,
      oversPlayed: json['oversPlayed'] is num ? (json['oversPlayed'] as num).toDouble() : 0.0,
      runsConceded: json['runsConceded'] is num ? (json['runsConceded'] as num).toInt() : 0,
      oversBowled: json['oversBowled'] is num ? (json['oversBowled'] as num).toDouble() : 0.0,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is DateTime
              ? json['createdAt'] as DateTime
              : DateTime.tryParse(json['createdAt'].toString()))
          : null,
    );
  }

  /// Converts TournamentTeam to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament': tournament,
      'team': team is Map ? (team as Map)['id'] ?? (team as Map)['_id'] : team,
      'status': status,
      'played': played,
      'won': won,
      'lost': lost,
      'tied': tied,
      'noResult': noResult,
      'points': points,
      'netRunRate': netRunRate,
      'runsScored': runsScored,
      'oversPlayed': oversPlayed,
      'runsConceded': runsConceded,
      'oversBowled': oversBowled,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  /// Creates a copy with updated fields.
  TournamentTeam copyWith({
    String? id,
    String? tournament,
    dynamic team,
    String? status,
    int? played,
    int? won,
    int? lost,
    int? tied,
    int? noResult,
    int? points,
    double? netRunRate,
    int? runsScored,
    double? oversPlayed,
    int? runsConceded,
    double? oversBowled,
    DateTime? createdAt,
  }) {
    return TournamentTeam(
      id: id ?? this.id,
      tournament: tournament ?? this.tournament,
      team: team ?? this.team,
      status: status ?? this.status,
      played: played ?? this.played,
      won: won ?? this.won,
      lost: lost ?? this.lost,
      tied: tied ?? this.tied,
      noResult: noResult ?? this.noResult,
      points: points ?? this.points,
      netRunRate: netRunRate ?? this.netRunRate,
      runsScored: runsScored ?? this.runsScored,
      oversPlayed: oversPlayed ?? this.oversPlayed,
      runsConceded: runsConceded ?? this.runsConceded,
      oversBowled: oversBowled ?? this.oversBowled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Convenience Getters
  // ---------------------------------------------------------------------------

  /// Team ID string
  String get teamId {
    if (team is Map) {
      return (team as Map)['id']?.toString() ?? (team as Map)['_id']?.toString() ?? '';
    }
    return team?.toString() ?? '';
  }

  /// Team Name helper
  String get teamName {
    if (team is Map) {
      return (team as Map)['name']?.toString() ?? 'Team';
    }
    return 'Team #$id';
  }

  /// Team short name (e.g. "MI", "CSK")
  String get teamShortName {
    if (team is Map) {
      final shortName = (team as Map)['shortName']?.toString();
      if (shortName != null && shortName.isNotEmpty) return shortName;
    }
    final words = teamName.trim().split(RegExp(r'\s+'));
    if (words.length > 1) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return teamName.isNotEmpty ? teamName.substring(0, teamName.length >= 3 ? 3 : teamName.length).toUpperCase() : 'TM';
  }

  /// Team Logo URL helper
  String? get teamLogo {
    if (team is Map) {
      return (team as Map)['logo']?.toString();
    }
    return null;
  }

  /// Formatted Net Run Rate string with +/- sign
  String get formattedNrr {
    if (netRunRate >= 0) {
      return '+${netRunRate.toStringAsFixed(3)}';
    }
    return netRunRate.toStringAsFixed(3);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TournamentTeam &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
