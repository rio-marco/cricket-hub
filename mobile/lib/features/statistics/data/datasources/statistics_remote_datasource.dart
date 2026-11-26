import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/core/errors/exceptions.dart';
import 'package:mobile/core/models/paginated_response.dart';

import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/player_statistics.dart';
import '../../domain/entities/statistics_filter.dart';
import '../../domain/entities/statistics_overview.dart';
import '../../domain/repositories/statistics_repository.dart';

class StatisticsRemoteDataSource implements StatisticsRepository {
  final ApiClient _apiClient;

  const StatisticsRemoteDataSource(this._apiClient);

  @override
  Future<StatisticsOverview> getOverview({
    StatisticsFilter filter = const StatisticsFilter(),
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.statistics,
      queryParameters: filter.toQueryParameters(),
    );
    return StatisticsOverview.fromJson(_data(response.data));
  }

  @override
  Future<PlayerStatistics> getPlayerStatistics(
    String playerId, {
    StatisticsFilter filter = const StatisticsFilter(),
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.playerOverallStatistics(playerId),
      queryParameters: filter.toQueryParameters(),
    );
    return PlayerStatistics.fromJson(_data(response.data));
  }

  @override
  Future<PaginatedResponse<LeaderboardEntry>> getLeaderboard({
    required String metric,
    StatisticsFilter filter = const StatisticsFilter(),
    int page = 1,
    int limit = 20,
  }) async {
    final queryParameters = <String, dynamic>{
      ...filter.toQueryParameters(),
      'metric': metric,
      'page': page,
      'limit': limit,
    };
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.leaderboardByMetric(metric),
      queryParameters: queryParameters,
    );
    return PaginatedResponse.fromJson(
      _envelope(response.data),
      (item) => LeaderboardEntry.fromJson(_map(item)),
    );
  }
}

Map<String, dynamic> _envelope(dynamic value) {
  final map = _map(value);
  if (!map.containsKey('success')) {
    throw const ServerException(message: 'Invalid statistics response received.');
  }
  return map;
}

Map<String, dynamic> _data(dynamic value) {
  final envelope = _envelope(value);
  final data = _map(envelope['data']);
  if (data.isEmpty && envelope['data'] != null) {
    throw const ServerException(message: 'Invalid statistics data received.');
  }
  return data;
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}
