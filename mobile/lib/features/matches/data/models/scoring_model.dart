import '../../domain/entities/scoring.dart';

class ScoringSnapshotModel extends ScoringSnapshot {
  const ScoringSnapshotModel({
    super.match,
    super.innings = const [],
    super.activeInnings,
    super.deliveries = const [],
    super.result,
  });

  factory ScoringSnapshotModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final matchMap = data['match'] is Map<String, dynamic>
        ? data['match'] as Map<String, dynamic>
        : null;
    final inningsList = data['innings'] is List
        ? (data['innings'] as List).whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];
    final activeMap = data['activeInnings'] is Map<String, dynamic>
        ? data['activeInnings'] as Map<String, dynamic>
        : null;
    final deliveryList = (data['deliveries'] is List
            ? data['deliveries'] as List
            : data['commentary'] is List
                ? data['commentary'] as List
                : <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(ScoringDeliveryModel.fromJson)
        .toList();

    return ScoringSnapshotModel(
      match: matchMap == null ? null : ScoringMatchModel.fromJson(matchMap),
      innings: inningsList,
      activeInnings: activeMap,
      deliveries: deliveryList,
      result: data['result'] is Map<String, dynamic>
          ? data['result'] as Map<String, dynamic>
          : matchMap?['result'] is Map<String, dynamic>
              ? matchMap!['result'] as Map<String, dynamic>
              : null,
    );
  }
}

class ScoringMatchModel extends ScoringMatch {
  const ScoringMatchModel({
    required super.id,
    required super.teamA,
    required super.teamB,
    required super.status,
    required super.currentInnings,
    required super.totalOvers,
    required super.ballsPerOver,
    required super.format,
    super.venue,
    required super.toss,
    super.result,
    required super.playingXI_A,
    required super.playingXI_B,
    super.bowlingXI,
  });

  factory ScoringMatchModel.fromJson(Map<String, dynamic> json) {
    return ScoringMatchModel(
      id: entityId(json['id'] ?? json['_id']),
      teamA: json['teamA'],
      teamB: json['teamB'],
      status: (json['status']?.toString() ?? 'UPCOMING').toUpperCase(),
      currentInnings: json['currentInnings'] is num
          ? (json['currentInnings'] as num).toInt()
          : 1,
      totalOvers: json['totalOvers'] is num
          ? (json['totalOvers'] as num).toInt()
          : 20,
      ballsPerOver: json['ballsPerOver'] is num
          ? (json['ballsPerOver'] as num).toInt()
          : 6,
      format: (json['format']?.toString() ?? 'T20').toUpperCase(),
      venue: json['venue']?.toString(),
      toss: json['toss'] is Map<String, dynamic>
          ? json['toss'] as Map<String, dynamic>
          : <String, dynamic>{},
      result: json['result'] is Map<String, dynamic>
          ? json['result'] as Map<String, dynamic>
          : null,
      playingXI_A: _idList(json['playingXI_A']),
      playingXI_B: _idList(json['playingXI_B']),
      bowlingXI: _dynamicList(json['bowlingXI']),
    );
  }
}

class ScoringDeliveryModel extends ScoringDelivery {
  const ScoringDeliveryModel({
    required super.id,
    required super.inningsId,
    required super.matchId,
    required super.overNumber,
    required super.ballNumber,
    required super.sequenceNumber,
    required super.batter,
    required super.bowler,
    required super.nonStriker,
    super.batterRuns,
    super.extraRuns,
    super.totalRuns,
    super.extraType,
    super.isLegal,
    super.isWicket,
    super.isBoundary,
    super.isSix,
    super.wicketType,
    super.commentary,
  });

  factory ScoringDeliveryModel.fromJson(Map<String, dynamic> json) {
    final runs = json['runs'] is Map<String, dynamic>
        ? json['runs'] as Map<String, dynamic>
        : <String, dynamic>{};
    final extras = json['extras'] is Map<String, dynamic>
        ? json['extras'] as Map<String, dynamic>
        : <String, dynamic>{};
    final wicket = json['wicket'] is Map<String, dynamic>
        ? json['wicket'] as Map<String, dynamic>
        : null;

    return ScoringDeliveryModel(
      id: entityId(json['id'] ?? json['_id']),
      inningsId: entityId(json['innings']),
      matchId: entityId(json['match']),
      overNumber: json['overNumber'] is num ? (json['overNumber'] as num).toInt() : 0,
      ballNumber: json['ballNumber'] is num ? (json['ballNumber'] as num).toInt() : 1,
      sequenceNumber: json['sequenceNumber'] is num
          ? (json['sequenceNumber'] as num).toInt()
          : 0,
      batter: json['batter'],
      bowler: json['bowler'],
      nonStriker: json['nonStriker'],
      batterRuns: runs['batter'] is num ? (runs['batter'] as num).toInt() : 0,
      extraRuns: runs['extras'] is num ? (runs['extras'] as num).toInt() : 0,
      totalRuns: runs['total'] is num ? (runs['total'] as num).toInt() : 0,
      extraType: (extras['type']?.toString() ?? 'NONE').toUpperCase(),
      isLegal: json['isLegal'] as bool? ?? true,
      isWicket: json['isWicket'] as bool? ?? false,
      isBoundary: json['isBoundary'] as bool? ?? false,
      isSix: json['isSix'] as bool? ?? false,
      wicketType: wicket?['type']?.toString(),
      commentary: json['commentary']?.toString(),
    );
  }
}

List<String> _idList(dynamic value) {
  if (value is! List) return const <String>[];
  return value.map(entityId).where((id) => id.isNotEmpty).toList();
}

List<dynamic> _dynamicList(dynamic value) => value is List ? value : const [];
