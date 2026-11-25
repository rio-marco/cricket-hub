import '../entities/tournament.dart';
import '../entities/tournament_team.dart';

/// Repository interface defining tournament data operations in Cricket Hub.
abstract class TournamentRepository {
  /// Fetches paginated tournaments with optional filtering by status and search query.
  Future<List<Tournament>> getTournaments({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  });

  /// Fetches a single tournament by its unique identifier.
  Future<Tournament> getTournamentById(String id);

  /// Creates a new tournament.
  Future<Tournament> createTournament(Map<String, dynamic> data);

  /// Updates an existing tournament.
  Future<Tournament> updateTournament(String id, Map<String, dynamic> data);

  Future<Tournament> updateTournamentStatus(String id, String status);

  /// Deletes a tournament.
  Future<void> deleteTournament(String id);

  /// Registers a team for a tournament.
  Future<TournamentTeam> registerTeam(String tournamentId, String teamId);

  Future<TournamentTeam> approveTeam(String tournamentId, String tournamentTeamId);

  Future<TournamentTeam> rejectTeam(String tournamentId, String tournamentTeamId);

  /// Fetches all registered teams in a tournament.
  Future<List<TournamentTeam>> getRegisteredTeams(String tournamentId);

  /// Fetches scheduled fixtures / matches for a tournament.
  Future<List<dynamic>> getFixtures(String tournamentId);

  /// Generates tournament round fixtures automatically.
  Future<List<dynamic>> generateFixtures(String tournamentId);

  /// Fetches current points table / standings for a tournament.
  Future<List<TournamentTeam>> getPointsTable(String tournamentId);
}
