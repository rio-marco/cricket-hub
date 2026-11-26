import '../../../../core/models/paginated_response.dart';
import '../entities/leaderboard_entry.dart';
import '../entities/player_statistics.dart';
import '../entities/statistics_filter.dart';
import '../entities/statistics_overview.dart';

abstract class StatisticsRepository {
  Future<StatisticsOverview> getOverview({
    StatisticsFilter filter = const StatisticsFilter(),
  });

  Future<PlayerStatistics> getPlayerStatistics(
    String playerId, {
    StatisticsFilter filter = const StatisticsFilter(),
  });

  Future<PaginatedResponse<LeaderboardEntry>> getLeaderboard({
    required String metric,
    StatisticsFilter filter = const StatisticsFilter(),
    int page = 1,
    int limit = 20,
  });
}
