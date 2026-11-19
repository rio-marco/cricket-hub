/// Extras conceded in an innings
class InningsExtras {
  final int wides;
  final int noBalls;
  final int byes;
  final int legByes;
  final int penalties;
  final int total;

  const InningsExtras({
    this.wides = 0,
    this.noBalls = 0,
    this.byes = 0,
    this.legByes = 0,
    this.penalties = 0,
    this.total = 0,
  });

  factory InningsExtras.fromJson(Map<String, dynamic> json) {
    return InningsExtras(
      wides: json['wides'] is num ? (json['wides'] as num).toInt() : 0,
      noBalls: json['noBalls'] is num ? (json['noBalls'] as num).toInt() : 0,
      byes: json['byes'] is num ? (json['byes'] as num).toInt() : 0,
      legByes: json['legByes'] is num ? (json['legByes'] as num).toInt() : 0,
      penalties: json['penalties'] is num ? (json['penalties'] as num).toInt() : 0,
      total: json['total'] is num ? (json['total'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wides': wides,
      'noBalls': noBalls,
      'byes': byes,
      'legByes': legByes,
      'penalties': penalties,
      'total': total,
    };
  }

  String get summary {
    return '(b $byes, lb $legByes, w $wides, nb $noBalls, p $penalties)';
  }
}

/// Dismissal record for batting statistics
class DismissalInfo {
  final String? type; // BOWLED, CAUGHT, LBW, RUN_OUT, STUMPED, etc.
  final dynamic bowler;
  final dynamic fielder;
  final String? description;

  const DismissalInfo({
    this.type,
    this.bowler,
    this.fielder,
    this.description,
  });

  factory DismissalInfo.fromJson(Map<String, dynamic> json) {
    return DismissalInfo(
      type: json['type']?.toString().toUpperCase(),
      bowler: json['bowler'],
      fielder: json['fielder'],
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (type != null) 'type': type,
      if (bowler != null) 'bowler': bowler is Map ? (bowler as Map)['id'] ?? (bowler as Map)['_id'] : bowler,
      if (fielder != null) 'fielder': fielder is Map ? (fielder as Map)['id'] ?? (fielder as Map)['_id'] : fielder,
      if (description != null) 'description': description,
    };
  }

  String get text {
    if (description != null && description!.isNotEmpty) return description!;
    final bowlerName = bowler is Map ? (bowler as Map)['name']?.toString() : null;
    final fielderName = fielder is Map ? (fielder as Map)['name']?.toString() : null;

    switch (type) {
      case 'BOWLED':
        return bowlerName != null ? 'b $bowlerName' : 'b Bowler';
      case 'CAUGHT':
        if (fielderName != null && bowlerName != null) {
          if (fielderName == bowlerName) return 'c & b $bowlerName';
          return 'c $fielderName b $bowlerName';
        }
        return bowlerName != null ? 'c Fielder b $bowlerName' : 'Caught';
      case 'LBW':
        return bowlerName != null ? 'lbw b $bowlerName' : 'lbw';
      case 'RUN_OUT':
        return fielderName != null ? 'run out ($fielderName)' : 'run out';
      case 'STUMPED':
        return fielderName != null && bowlerName != null
            ? 'st $fielderName b $bowlerName'
            : 'stumped';
      default:
        return type ?? 'not out';
    }
  }
}

/// Batting statistic entry in an innings
class BattingStat {
  final dynamic player;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final double strikeRate;
  final DismissalInfo? dismissal;
  final bool isNotOut;
  final int? position;

  const BattingStat({
    required this.player,
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.strikeRate = 0.0,
    this.dismissal,
    this.isNotOut = false,
    this.position,
  });

  factory BattingStat.fromJson(Map<String, dynamic> json) {
    DismissalInfo? dismissalInfo;
    if (json['dismissal'] is Map<String, dynamic>) {
      dismissalInfo = DismissalInfo.fromJson(json['dismissal'] as Map<String, dynamic>);
    }

    final runs = json['runs'] is num ? (json['runs'] as num).toInt() : 0;
    final balls = json['balls'] is num ? (json['balls'] as num).toInt() : 0;
    final sr = json['strikeRate'] is num
        ? (json['strikeRate'] as num).toDouble()
        : (balls > 0 ? (runs / balls * 100) : 0.0);

    return BattingStat(
      player: json['player'],
      runs: runs,
      balls: balls,
      fours: json['fours'] is num ? (json['fours'] as num).toInt() : 0,
      sixes: json['sixes'] is num ? (json['sixes'] as num).toInt() : 0,
      strikeRate: sr,
      dismissal: dismissalInfo,
      isNotOut: json['isNotOut'] as bool? ?? (dismissalInfo == null),
      position: json['position'] is num ? (json['position'] as num).toInt() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'player': player is Map ? (player as Map)['id'] ?? (player as Map)['_id'] : player,
      'runs': runs,
      'balls': balls,
      'fours': fours,
      'sixes': sixes,
      'strikeRate': strikeRate,
      if (dismissal != null) 'dismissal': dismissal!.toJson(),
      'isNotOut': isNotOut,
      if (position != null) 'position': position,
    };
  }

  String get playerName {
    if (player is Map) {
      return (player as Map)['name']?.toString() ??
          (player as Map)['playerName']?.toString() ??
          'Batter';
    }
    return player?.toString() ?? 'Batter';
  }

  String get dismissalText {
    if (isNotOut) return 'not out';
    if (dismissal != null) return dismissal!.text;
    return 'out';
  }
}

/// Bowling statistic entry in an innings
class BowlingStat {
  final dynamic player;
  final double overs;
  final int balls;
  final int maidens;
  final int runs;
  final int wickets;
  final double economy;
  final int wides;
  final int noBalls;
  final int dotBalls;

  const BowlingStat({
    required this.player,
    this.overs = 0.0,
    this.balls = 0,
    this.maidens = 0,
    this.runs = 0,
    this.wickets = 0,
    this.economy = 0.0,
    this.wides = 0,
    this.noBalls = 0,
    this.dotBalls = 0,
  });

  factory BowlingStat.fromJson(Map<String, dynamic> json) {
    final runs = json['runs'] is num ? (json['runs'] as num).toInt() : 0;
    final balls = json['balls'] is num ? (json['balls'] as num).toInt() : 0;
    final overs = json['overs'] is num ? (json['overs'] as num).toDouble() : (balls / 6.0);

    final econ = json['economy'] is num
        ? (json['economy'] as num).toDouble()
        : (balls > 0 ? (runs / (balls / 6.0)) : 0.0);

    return BowlingStat(
      player: json['player'],
      overs: overs,
      balls: balls,
      maidens: json['maidens'] is num ? (json['maidens'] as num).toInt() : 0,
      runs: runs,
      wickets: json['wickets'] is num ? (json['wickets'] as num).toInt() : 0,
      economy: econ,
      wides: json['wides'] is num ? (json['wides'] as num).toInt() : 0,
      noBalls: json['noBalls'] is num ? (json['noBalls'] as num).toInt() : 0,
      dotBalls: json['dotBalls'] is num ? (json['dotBalls'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'player': player is Map ? (player as Map)['id'] ?? (player as Map)['_id'] : player,
      'overs': overs,
      'balls': balls,
      'maidens': maidens,
      'runs': runs,
      'wickets': wickets,
      'economy': economy,
      'wides': wides,
      'noBalls': noBalls,
      'dotBalls': dotBalls,
    };
  }

  String get playerName {
    if (player is Map) {
      return (player as Map)['name']?.toString() ??
          (player as Map)['playerName']?.toString() ??
          'Bowler';
    }
    return player?.toString() ?? 'Bowler';
  }

  String get oversFormatted {
    final completedOvers = balls ~/ 6;
    final remainingBalls = balls % 6;
    if (remainingBalls == 0) return '$completedOvers.0';
    return '$completedOvers.$remainingBalls';
  }
}

/// Fall of wicket record
class FallOfWicket {
  final dynamic player;
  final int runs;
  final int balls;
  final int teamScore;
  final String teamOvers;
  final int wicketNumber;

  const FallOfWicket({
    required this.player,
    this.runs = 0,
    this.balls = 0,
    required this.teamScore,
    required this.teamOvers,
    required this.wicketNumber,
  });

  factory FallOfWicket.fromJson(Map<String, dynamic> json) {
    return FallOfWicket(
      player: json['player'],
      runs: json['runs'] is num ? (json['runs'] as num).toInt() : 0,
      balls: json['balls'] is num ? (json['balls'] as num).toInt() : 0,
      teamScore: json['teamScore'] is num ? (json['teamScore'] as num).toInt() : 0,
      teamOvers: json['teamOvers']?.toString() ?? '0.0',
      wicketNumber: json['wicketNumber'] is num ? (json['wicketNumber'] as num).toInt() : 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'player': player is Map ? (player as Map)['id'] ?? (player as Map)['_id'] : player,
      'runs': runs,
      'balls': balls,
      'teamScore': teamScore,
      'teamOvers': teamOvers,
      'wicketNumber': wicketNumber,
    };
  }

  String get playerName {
    if (player is Map) {
      return (player as Map)['name']?.toString() ?? 'Batter';
    }
    return player?.toString() ?? 'Batter';
  }

  String get summary => '$teamScore-$wicketNumber ($playerName, $teamOvers ov)';
}

/// Active partnership
class PartnershipStat {
  final dynamic batter1;
  final dynamic batter2;
  final int runs;
  final int balls;
  final bool isActive;

  const PartnershipStat({
    required this.batter1,
    required this.batter2,
    this.runs = 0,
    this.balls = 0,
    this.isActive = true,
  });

  factory PartnershipStat.fromJson(Map<String, dynamic> json) {
    return PartnershipStat(
      batter1: json['batter1'],
      batter2: json['batter2'],
      runs: json['runs'] is num ? (json['runs'] as num).toInt() : 0,
      balls: json['balls'] is num ? (json['balls'] as num).toInt() : 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batter1': batter1 is Map ? (batter1 as Map)['id'] ?? (batter1 as Map)['_id'] : batter1,
      'batter2': batter2 is Map ? (batter2 as Map)['id'] ?? (batter2 as Map)['_id'] : batter2,
      'runs': runs,
      'balls': balls,
      'isActive': isActive,
    };
  }
}

/// Currently active batters on pitch
class CurrentBatters {
  final dynamic striker;
  final dynamic nonStriker;

  const CurrentBatters({this.striker, this.nonStriker});

  factory CurrentBatters.fromJson(Map<String, dynamic> json) {
    return CurrentBatters(
      striker: json['striker'],
      nonStriker: json['nonStriker'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (striker != null) 'striker': striker is Map ? (striker as Map)['id'] ?? (striker as Map)['_id'] : striker,
      if (nonStriker != null) 'nonStriker': nonStriker is Map ? (nonStriker as Map)['id'] ?? (nonStriker as Map)['_id'] : nonStriker,
    };
  }
}

/// Innings domain entity representing batting/bowling statistics for a match innings.
class Innings {
  final String id;
  final String match;
  final int inningsNumber;
  final dynamic battingTeam;
  final dynamic bowlingTeam;
  final int totalRuns;
  final int totalWickets;
  final double totalOvers;
  final int totalBalls;
  final InningsExtras extras;
  final CurrentBatters? currentBatters;
  final dynamic currentBowler;
  final int? target;
  final String status; // NOT_STARTED, IN_PROGRESS, COMPLETED, DECLARED
  final List<BattingStat> battingStats;
  final List<BowlingStat> bowlingStats;
  final List<FallOfWicket> fallOfWickets;
  final List<PartnershipStat> partnerships;

  const Innings({
    required this.id,
    required this.match,
    this.inningsNumber = 1,
    required this.battingTeam,
    required this.bowlingTeam,
    this.totalRuns = 0,
    this.totalWickets = 0,
    this.totalOvers = 0.0,
    this.totalBalls = 0,
    this.extras = const InningsExtras(),
    this.currentBatters,
    this.currentBowler,
    this.target,
    this.status = 'NOT_STARTED',
    this.battingStats = const [],
    this.bowlingStats = const [],
    this.fallOfWickets = const [],
    this.partnerships = const [],
  });

  /// Factory constructor to parse Innings from JSON map.
  factory Innings.fromJson(Map<String, dynamic> json) {
    final rawBatting = json['battingStats'] as List? ?? [];
    final rawBowling = json['bowlingStats'] as List? ?? [];
    final rawFoW = json['fallOfWickets'] as List? ?? [];
    final rawPart = json['partnerships'] as List? ?? [];

    InningsExtras extras = const InningsExtras();
    if (json['extras'] is Map<String, dynamic>) {
      extras = InningsExtras.fromJson(json['extras'] as Map<String, dynamic>);
    }

    CurrentBatters? cb;
    if (json['currentBatters'] is Map<String, dynamic>) {
      cb = CurrentBatters.fromJson(json['currentBatters'] as Map<String, dynamic>);
    }

    return Innings(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      match: json['match'] is Map
          ? ((json['match'] as Map)['id'] ?? (json['match'] as Map)['_id'] ?? '').toString()
          : (json['match'] as String? ?? ''),
      inningsNumber: json['inningsNumber'] is num ? (json['inningsNumber'] as num).toInt() : 1,
      battingTeam: json['battingTeam'],
      bowlingTeam: json['bowlingTeam'],
      totalRuns: json['totalRuns'] is num ? (json['totalRuns'] as num).toInt() : 0,
      totalWickets: json['totalWickets'] is num ? (json['totalWickets'] as num).toInt() : 0,
      totalOvers: json['totalOvers'] is num ? (json['totalOvers'] as num).toDouble() : 0.0,
      totalBalls: json['totalBalls'] is num ? (json['totalBalls'] as num).toInt() : 0,
      extras: extras,
      currentBatters: cb,
      currentBowler: json['currentBowler'],
      target: json['target'] is num ? (json['target'] as num).toInt() : null,
      status: (json['status'] as String? ?? 'NOT_STARTED').toUpperCase(),
      battingStats: rawBatting
          .whereType<Map<String, dynamic>>()
          .map((b) => BattingStat.fromJson(b))
          .toList(),
      bowlingStats: rawBowling
          .whereType<Map<String, dynamic>>()
          .map((b) => BowlingStat.fromJson(b))
          .toList(),
      fallOfWickets: rawFoW
          .whereType<Map<String, dynamic>>()
          .map((f) => FallOfWicket.fromJson(f))
          .toList(),
      partnerships: rawPart
          .whereType<Map<String, dynamic>>()
          .map((p) => PartnershipStat.fromJson(p))
          .toList(),
    );
  }

  /// Converts innings to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'match': match,
      'inningsNumber': inningsNumber,
      'battingTeam': battingTeam is Map ? (battingTeam as Map)['id'] ?? (battingTeam as Map)['_id'] : battingTeam,
      'bowlingTeam': bowlingTeam is Map ? (bowlingTeam as Map)['id'] ?? (bowlingTeam as Map)['_id'] : bowlingTeam,
      'totalRuns': totalRuns,
      'totalWickets': totalWickets,
      'totalOvers': totalOvers,
      'totalBalls': totalBalls,
      'extras': extras.toJson(),
      if (currentBatters != null) 'currentBatters': currentBatters!.toJson(),
      if (currentBowler != null)
        'currentBowler': currentBowler is Map ? (currentBowler as Map)['id'] ?? (currentBowler as Map)['_id'] : currentBowler,
      if (target != null) 'target': target,
      'status': status,
      'battingStats': battingStats.map((b) => b.toJson()).toList(),
      'bowlingStats': bowlingStats.map((b) => b.toJson()).toList(),
      'fallOfWickets': fallOfWickets.map((f) => f.toJson()).toList(),
      'partnerships': partnerships.map((p) => p.toJson()).toList(),
    };
  }

  // ---------------------------------------------------------------------------
  // Convenience Getters
  // ---------------------------------------------------------------------------

  String get battingTeamName {
    if (battingTeam is Map) return (battingTeam as Map)['name']?.toString() ?? 'Batting Team';
    return battingTeam?.toString() ?? 'Batting Team';
  }

  String get bowlingTeamName {
    if (bowlingTeam is Map) return (bowlingTeam as Map)['name']?.toString() ?? 'Bowling Team';
    return bowlingTeam?.toString() ?? 'Bowling Team';
  }

  String get oversFormatted {
    final completedOvers = totalBalls ~/ 6;
    final remainingBalls = totalBalls % 6;
    if (remainingBalls == 0) return '$completedOvers.0';
    return '$completedOvers.$remainingBalls';
  }

  double get runRate {
    if (totalBalls == 0) return 0.0;
    final overs = totalBalls / 6.0;
    return (totalRuns / overs);
  }

  String get runRateFormatted => runRate.toStringAsFixed(2);

  String get scoreSummary => '$totalRuns/$totalWickets ($oversFormatted ov)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Innings &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
