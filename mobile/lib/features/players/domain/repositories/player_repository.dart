import '../../../../core/models/paginated_response.dart';
import '../entities/player.dart';

/// Repository interface for Player domain operations.
abstract class PlayerRepository {
  Future<PaginatedResponse<Player>> getPlayers({
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
  });

  Future<Player> getPlayerById(String id);

  Future<Player?> getPlayerByUserId(String userId);

  Future<Player> createPlayer(Map<String, dynamic> data);

  Future<Player> updatePlayer(String id, Map<String, dynamic> data);

  Future<Map<String, dynamic>> getPlayerStats(String id);

  Future<List<dynamic>> getPlayerMatches(String id);
}
