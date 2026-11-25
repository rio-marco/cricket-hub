class ScoringDelivery {
  final String id;
  final String inningsId;
  final String matchId;
  final int overNumber;
  final int ballNumber;
  final int sequenceNumber;
  final dynamic batter;
  final dynamic bowler;
  final dynamic nonStriker;
  final int batterRuns;
  final int extraRuns;
  final int totalRuns;
  final String extraType;
  final bool isLegal;
  final bool isWicket;
  final bool isBoundary;
  final bool isSix;
  final String? wicketType;
  final String? commentary;

  const ScoringDelivery({
    required this.id,
    required this.inningsId,
    required this.matchId,
    required this.overNumber,
    required this.ballNumber,
    required this.sequenceNumber,
    required this.batter,
    required this.bowler,
    required this.nonStriker,
    this.batterRuns = 0,
    this.extraRuns = 0,
    this.totalRuns = 0,
    this.extraType = 'NONE',
    this.isLegal = true,
    this.isWicket = false,
    this.isBoundary = false,
    this.isSix = false,
    this.wicketType,
    this.commentary,
  });

  String get overLabel => '$overNumber.$ballNumber';

  String get outcomeLabel {
    if (isWicket) return 'W';
    if (isSix) return '6';
    if (isBoundary) return '4';
    if (extraType == 'WIDE') return 'WD';
    if (extraType == 'NO_BALL') return 'NB';
    if (totalRuns == 0) return '•';
    return '$totalRuns';
  }
}

class ScoringMatch {
  final String id;
  final dynamic teamA;
  final dynamic teamB;
  final String status;
  final int currentInnings;
  final int totalOvers;
  final int ballsPerOver;
  final String format;
  final String? venue;
  final Map<String, dynamic> toss;
  final Map<String, dynamic>? result;
  final List<String> playingXI_A;
  final List<String> playingXI_B;
  final List<dynamic> bowlingXI;

  const ScoringMatch({
    required this.id,
    required this.teamA,
    required this.teamB,
    required this.status,
    required this.currentInnings,
    required this.totalOvers,
    required this.ballsPerOver,
    required this.format,
    this.venue,
    required this.toss,
    this.result,
    required this.playingXI_A,
    required this.playingXI_B,
    this.bowlingXI = const [],
  });

  String get teamAName => entityName(teamA);
  String get teamBName => entityName(teamB);
}

class ScoringSnapshot {
  final ScoringMatch? match;
  final List<dynamic> innings;
  final dynamic activeInnings;
  final List<ScoringDelivery> deliveries;
  final Map<String, dynamic>? result;

  const ScoringSnapshot({
    this.match,
    this.innings = const [],
    this.activeInnings,
    this.deliveries = const [],
    this.result,
  });
}

String entityId(dynamic value) {
  if (value is Map) {
    return (value['id'] ?? value['_id'] ?? '').toString();
  }
  return value?.toString() ?? '';
}

String entityName(dynamic value, {String fallback = 'Player'}) {
  if (value is Map) {
    final direct = value['name']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;
    final user = value['user'];
    if (user is Map) {
      final userName = user['name']?.toString();
      if (userName != null && userName.isNotEmpty) return userName;
    }
  }
  final text = value?.toString();
  return text == null || text.isEmpty ? fallback : text;
}
