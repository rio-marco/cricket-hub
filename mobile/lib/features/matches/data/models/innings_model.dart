import '../../domain/entities/innings.dart';

/// Innings data model extending domain [Innings] entity with API serialization.
class InningsModel extends Innings {
  const InningsModel({
    required super.id,
    required super.match,
    super.inningsNumber = 1,
    required super.battingTeam,
    required super.bowlingTeam,
    super.totalRuns = 0,
    super.totalWickets = 0,
    super.totalOvers = 0.0,
    super.totalBalls = 0,
    super.stateVersion = 0,
    super.extras = const InningsExtras(),
    super.currentBatters,
    super.currentBowler,
    super.target,
    super.status = 'NOT_STARTED',
    super.battingStats = const [],
    super.bowlingStats = const [],
    super.fallOfWickets = const [],
    super.partnerships = const [],
  });

  /// Factory constructor to parse [InningsModel] from API JSON map.
  factory InningsModel.fromJson(Map<String, dynamic> json) {
    final map = json.containsKey('innings') && json['innings'] is Map<String, dynamic>
        ? json['innings'] as Map<String, dynamic>
        : (json.containsKey('data') && json['data'] is Map<String, dynamic> && !json.containsKey('totalRuns')
            ? json['data'] as Map<String, dynamic>
            : json);

    final entity = Innings.fromJson(map);
    return InningsModel.fromEntity(entity);
  }

  /// Converts domain [Innings] to [InningsModel].
  factory InningsModel.fromEntity(Innings entity) {
    return InningsModel(
      id: entity.id,
      match: entity.match,
      inningsNumber: entity.inningsNumber,
      battingTeam: entity.battingTeam,
      bowlingTeam: entity.bowlingTeam,
      totalRuns: entity.totalRuns,
      totalWickets: entity.totalWickets,
      totalOvers: entity.totalOvers,
      totalBalls: entity.totalBalls,
      stateVersion: entity.stateVersion,
      extras: entity.extras,
      currentBatters: entity.currentBatters,
      currentBowler: entity.currentBowler,
      target: entity.target,
      status: entity.status,
      battingStats: entity.battingStats,
      bowlingStats: entity.bowlingStats,
      fallOfWickets: entity.fallOfWickets,
      partnerships: entity.partnerships,
    );
  }

  Innings toEntity() => this;
}
