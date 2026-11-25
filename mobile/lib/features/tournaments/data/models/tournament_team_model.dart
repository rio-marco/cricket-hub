import '../../domain/entities/tournament_team.dart';

/// TournamentTeam data model extending domain [TournamentTeam] entity.
class TournamentTeamModel extends TournamentTeam {
  const TournamentTeamModel({
    required super.id,
    required super.tournament,
    required super.team,
    super.status = 'PENDING',
    super.rank = 0,
    super.played = 0,
    super.won = 0,
    super.lost = 0,
    super.tied = 0,
    super.noResult = 0,
    super.points = 0,
    super.netRunRate = 0.0,
    super.runsScored = 0,
    super.oversPlayed = 0.0,
    super.runsConceded = 0,
    super.oversBowled = 0.0,
    super.createdAt,
  });

  /// Factory constructor to parse [TournamentTeamModel] from JSON map.
  factory TournamentTeamModel.fromJson(Map<String, dynamic> json) {
    final entity = TournamentTeam.fromJson(json);
    return TournamentTeamModel.fromEntity(entity);
  }

  /// Converts domain [TournamentTeam] to [TournamentTeamModel].
  factory TournamentTeamModel.fromEntity(TournamentTeam entity) {
    return TournamentTeamModel(
      id: entity.id,
      tournament: entity.tournament,
      team: entity.team,
      status: entity.status,
      rank: entity.rank,
      played: entity.played,
      won: entity.won,
      lost: entity.lost,
      tied: entity.tied,
      noResult: entity.noResult,
      points: entity.points,
      netRunRate: entity.netRunRate,
      runsScored: entity.runsScored,
      oversPlayed: entity.oversPlayed,
      runsConceded: entity.runsConceded,
      oversBowled: entity.oversBowled,
      createdAt: entity.createdAt,
    );
  }

  TournamentTeam toEntity() => this;
}
