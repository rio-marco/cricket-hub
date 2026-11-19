import '../../domain/entities/match.dart';

/// Match data model extending domain [Match] entity with API serialization.
class MatchModel extends Match {
  const MatchModel({
    required super.id,
    super.title,
    super.tournament,
    required super.teamA,
    required super.teamB,
    super.format = 'T20',
    super.totalOvers = 20,
    super.ballType = 'WHITE',
    super.venue,
    super.city,
    super.matchDate,
    super.toss,
    super.scorer,
    super.status = 'UPCOMING',
    super.result,
    super.playerOfMatch,
    super.currentInnings = 1,
    super.teamAScore,
    super.teamBScore,
    super.createdAt,
  });

  /// Factory constructor to parse [MatchModel] from API JSON map.
  factory MatchModel.fromJson(Map<String, dynamic> json) {
    // Unnest if wrapped in "match" or "data"
    final map = json.containsKey('match') && json['match'] is Map<String, dynamic>
        ? json['match'] as Map<String, dynamic>
        : (json.containsKey('data') && json['data'] is Map<String, dynamic> && !json.containsKey('teamA')
            ? json['data'] as Map<String, dynamic>
            : json);

    final entity = Match.fromJson(map);
    return MatchModel.fromEntity(entity);
  }

  /// Converts domain [Match] to [MatchModel].
  factory MatchModel.fromEntity(Match entity) {
    return MatchModel(
      id: entity.id,
      title: entity.title,
      tournament: entity.tournament,
      teamA: entity.teamA,
      teamB: entity.teamB,
      format: entity.format,
      totalOvers: entity.totalOvers,
      ballType: entity.ballType,
      venue: entity.venue,
      city: entity.city,
      matchDate: entity.matchDate,
      toss: entity.toss,
      scorer: entity.scorer,
      status: entity.status,
      result: entity.result,
      playerOfMatch: entity.playerOfMatch,
      currentInnings: entity.currentInnings,
      teamAScore: entity.teamAScore,
      teamBScore: entity.teamBScore,
      createdAt: entity.createdAt,
    );
  }

  Match toEntity() => this;
}
