/// Player domain entity representing a cricketer's registered sporting profile.
class Player {
  final String id;
  final String user;
  final String name;
  final String? avatar;
  final String playingRole; // BATSMAN, BOWLER, ALL_ROUNDER, WICKETKEEPER
  final String battingStyle; // RIGHT_HAND, LEFT_HAND
  final String bowlingStyle; // RIGHT_ARM_FAST, RIGHT_ARM_MEDIUM, LEFT_ARM_FAST, etc.
  final int? jerseyNumber;
  final DateTime? dateOfBirth;
  final String? city;
  final String? bio;

  // Career Summary Stats
  final int matchesCount;
  final int runs;
  final int ballsFaced;
  final int wickets;
  final int oversBowled;
  final int runsConceded;
  final double battingAverage;
  final double strikeRate;
  final double bowlingAverage;
  final double economyRate;
  final int highestScore;
  final String? bestBowling;
  final int catches;
  final int stumpings;

  const Player({
    required this.id,
    required this.user,
    required this.name,
    this.avatar,
    this.playingRole = 'BATSMAN',
    this.battingStyle = 'RIGHT_HAND',
    this.bowlingStyle = 'NONE',
    this.jerseyNumber,
    this.dateOfBirth,
    this.city,
    this.bio,
    this.matchesCount = 0,
    this.runs = 0,
    this.ballsFaced = 0,
    this.wickets = 0,
    this.oversBowled = 0,
    this.runsConceded = 0,
    this.battingAverage = 0.0,
    this.strikeRate = 0.0,
    this.bowlingAverage = 0.0,
    this.economyRate = 0.0,
    this.highestScore = 0,
    this.bestBowling,
    this.catches = 0,
    this.stumpings = 0,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    // Extract user info if populated
    String userId = '';
    String name = '';
    String? avatar;

    if (json['user'] is Map) {
      final uMap = json['user'] as Map<String, dynamic>;
      userId = uMap['_id']?.toString() ?? uMap['id']?.toString() ?? '';
      name = uMap['name']?.toString() ?? '';
      avatar = uMap['avatar']?.toString();
    } else if (json['user'] != null) {
      userId = json['user'].toString();
    }

    if (name.isEmpty && json['name'] != null) {
      name = json['name'].toString();
    }
    if (avatar == null && json['avatar'] != null) {
      avatar = json['avatar'].toString();
    }

    // Extract stats if nested in 'stats'
    final stats = json['stats'] is Map<String, dynamic>
        ? json['stats'] as Map<String, dynamic>
        : json;

    return Player(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      user: userId,
      name: name.isNotEmpty ? name : 'Cricket Player',
      avatar: avatar,
      playingRole: json['playingRole'] as String? ?? 'BATSMAN',
      battingStyle: json['battingStyle'] as String? ?? 'RIGHT_HAND',
      bowlingStyle: json['bowlingStyle'] as String? ?? 'NONE',
      jerseyNumber: json['jerseyNumber'] as int?,
      dateOfBirth: json['dateOfBirth'] != null
          ? (json['dateOfBirth'] is DateTime
              ? json['dateOfBirth'] as DateTime
              : DateTime.tryParse(json['dateOfBirth'].toString()))
          : null,
      city: json['city'] as String?,
      bio: json['bio'] as String?,
      matchesCount: stats['matches'] as int? ?? stats['matchesCount'] as int? ?? 0,
      runs: stats['runs'] as int? ?? 0,
      ballsFaced: stats['ballsFaced'] as int? ?? 0,
      wickets: stats['wickets'] as int? ?? 0,
      oversBowled: stats['oversBowled'] as int? ?? stats['overs'] as int? ?? 0,
      runsConceded: stats['runsConceded'] as int? ?? 0,
      battingAverage: (stats['battingAverage'] as num?)?.toDouble() ??
          (stats['average'] as num?)?.toDouble() ??
          0.0,
      strikeRate: (stats['strikeRate'] as num?)?.toDouble() ?? 0.0,
      bowlingAverage: (stats['bowlingAverage'] as num?)?.toDouble() ?? 0.0,
      economyRate: (stats['economyRate'] as num?)?.toDouble() ??
          (stats['economy'] as num?)?.toDouble() ??
          0.0,
      highestScore: stats['highestScore'] as int? ?? 0,
      bestBowling: stats['bestBowling']?.toString(),
      catches: stats['catches'] as int? ?? 0,
      stumpings: stats['stumpings'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user,
      'name': name,
      if (avatar != null) 'avatar': avatar,
      'playingRole': playingRole,
      'battingStyle': battingStyle,
      'bowlingStyle': bowlingStyle,
      if (jerseyNumber != null) 'jerseyNumber': jerseyNumber,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      if (city != null) 'city': city,
      if (bio != null) 'bio': bio,
      'stats': {
        'matchesCount': matchesCount,
        'runs': runs,
        'ballsFaced': ballsFaced,
        'wickets': wickets,
        'oversBowled': oversBowled,
        'runsConceded': runsConceded,
        'battingAverage': battingAverage,
        'strikeRate': strikeRate,
        'bowlingAverage': bowlingAverage,
        'economyRate': economyRate,
        'highestScore': highestScore,
        if (bestBowling != null) 'bestBowling': bestBowling,
        'catches': catches,
        'stumpings': stumpings,
      },
    };
  }

  Player copyWith({
    String? id,
    String? user,
    String? name,
    String? avatar,
    String? playingRole,
    String? battingStyle,
    String? bowlingStyle,
    int? jerseyNumber,
    DateTime? dateOfBirth,
    String? city,
    String? bio,
    int? matchesCount,
    int? runs,
    int? ballsFaced,
    int? wickets,
    int? oversBowled,
    int? runsConceded,
    double? battingAverage,
    double? strikeRate,
    double? bowlingAverage,
    double? economyRate,
    int? highestScore,
    String? bestBowling,
    int? catches,
    int? stumpings,
  }) {
    return Player(
      id: id ?? this.id,
      user: user ?? this.user,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      playingRole: playingRole ?? this.playingRole,
      battingStyle: battingStyle ?? this.battingStyle,
      bowlingStyle: bowlingStyle ?? this.bowlingStyle,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      matchesCount: matchesCount ?? this.matchesCount,
      runs: runs ?? this.runs,
      ballsFaced: ballsFaced ?? this.ballsFaced,
      wickets: wickets ?? this.wickets,
      oversBowled: oversBowled ?? this.oversBowled,
      runsConceded: runsConceded ?? this.runsConceded,
      battingAverage: battingAverage ?? this.battingAverage,
      strikeRate: strikeRate ?? this.strikeRate,
      bowlingAverage: bowlingAverage ?? this.bowlingAverage,
      economyRate: economyRate ?? this.economyRate,
      highestScore: highestScore ?? this.highestScore,
      bestBowling: bestBowling ?? this.bestBowling,
      catches: catches ?? this.catches,
      stumpings: stumpings ?? this.stumpings,
    );
  }

  String get initials {
    if (name.trim().isEmpty) return 'P';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String get roleDisplay {
    switch (playingRole.toUpperCase()) {
      case 'BATSMAN':
        return 'Batsman';
      case 'BOWLER':
        return 'Bowler';
      case 'ALL_ROUNDER':
        return 'All-Rounder';
      case 'WICKETKEEPER':
        return 'Wicketkeeper';
      default:
        return playingRole.replaceAll('_', ' ');
    }
  }

  String get battingStyleDisplay {
    switch (battingStyle.toUpperCase()) {
      case 'RIGHT_HAND':
        return 'Right-hand Bat';
      case 'LEFT_HAND':
        return 'Left-hand Bat';
      default:
        return battingStyle.replaceAll('_', ' ');
    }
  }

  String get bowlingStyleDisplay {
    switch (bowlingStyle.toUpperCase()) {
      case 'RIGHT_ARM_FAST':
        return 'Right-arm Fast';
      case 'RIGHT_ARM_MEDIUM':
        return 'Right-arm Medium';
      case 'LEFT_ARM_FAST':
        return 'Left-arm Fast';
      case 'LEFT_ARM_MEDIUM':
        return 'Left-arm Medium';
      case 'RIGHT_ARM_OFF_SPIN':
        return 'Right-arm Off Spin';
      case 'RIGHT_ARM_LEG_SPIN':
        return 'Right-arm Leg Spin';
      case 'LEFT_ARM_ORTHODOX':
        return 'Left-arm Orthodox Spin';
      case 'LEFT_ARM_CHINAMAN':
        return 'Left-arm Chinaman';
      case 'NONE':
        return 'Does not bowl';
      default:
        return bowlingStyle.replaceAll('_', ' ');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Player(id: $id, name: $name, role: $playingRole)';
}
