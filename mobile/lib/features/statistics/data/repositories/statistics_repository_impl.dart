import 'package:mobile/core/errors/exceptions.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/core/models/paginated_response.dart';

import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/player_statistics.dart';
import '../../domain/entities/statistics_filter.dart';
import '../../domain/entities/statistics_overview.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../datasources/statistics_remote_datasource.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  final StatisticsRemoteDataSource remoteDataSource;

  const StatisticsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<StatisticsOverview> getOverview({
    StatisticsFilter filter = const StatisticsFilter(),
  }) async {
    try {
      return await remoteDataSource.getOverview(filter: filter);
    } on AppException catch (error) {
      throw Failure.fromException(error);
    } catch (error) {
      throw ServerFailure(message: error.toString());
    }
  }

  @override
  Future<PlayerStatistics> getPlayerStatistics(
    String playerId, {
    StatisticsFilter filter = const StatisticsFilter(),
  }) async {
    try {
      return await remoteDataSource.getPlayerStatistics(playerId, filter: filter);
    } on AppException catch (error) {
      throw Failure.fromException(error);
    } catch (error) {
      throw ServerFailure(message: error.toString());
    }
  }

  @override
  Future<PaginatedResponse<LeaderboardEntry>> getLeaderboard({
    required String metric,
    StatisticsFilter filter = const StatisticsFilter(),
    int page = 1,
    int limit = 20,
  }) async {
    try {
      return await remoteDataSource.getLeaderboard(
        metric: metric,
        filter: filter,
        page: page,
        limit: limit,
      );
    } on AppException catch (error) {
      throw Failure.fromException(error);
    } catch (error) {
      throw ServerFailure(message: error.toString());
    }
  }
}
