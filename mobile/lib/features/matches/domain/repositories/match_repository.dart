import '../entities/innings.dart';
import '../entities/match.dart';

/// Repository interface defining cricket match data operations in Cricket Hub.
abstract class MatchRepository {
  /// Fetches paginated matches with optional filtering by status, tournament, team, or search.
  Future<List<Match>> getMatches({
    int page = 1,
    int limit = 20,
    String? status,
    String? tournamentId,
    String? teamId,
    String? search,
  });

  /// Fetches all currently active live cricket matches.
  Future<List<Match>> getLiveMatches();

  /// Fetches upcoming scheduled matches.
  Future<List<Match>> getUpcomingMatches();

  /// Fetches concluded matches with results.
  Future<List<Match>> getCompletedMatches();

  /// Fetches a specific match by its ID.
  Future<Match> getMatchById(String id);

  /// Creates a new match fixture.
  Future<Match> createMatch(Map<String, dynamic> data);

  /// Updates an existing match.
  Future<Match> updateMatch(String id, Map<String, dynamic> data);

  /// Records the toss winner and election decision (BAT / BOWL).
  Future<Match> recordToss(String matchId, String winnerTeamId, String decision);

  /// Fetches innings scorecard for a specific innings number (1 or 2).
  Future<Innings> getInnings(String matchId, int inningsNumber);

  /// Fetches complete scorecard containing both innings and match metadata.
  Future<Map<String, dynamic>> getScorecard(String matchId);

  /// Fetches live ball-by-ball commentary for a match.
  Future<List<dynamic>> getCommentary(String matchId);
}
