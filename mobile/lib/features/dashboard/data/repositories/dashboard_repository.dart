import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../teams/data/models/team_model.dart';
import '../../../teams/domain/entities/team.dart';
import '../../domain/entities/dashboard_data.dart';

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository(this._apiClient);

  Future<DashboardData> getDashboardData({String? userId}) async {
    final responses = await Future.wait([
      _apiClient.get(ApiEndpoints.liveMatches),
      _apiClient.get(ApiEndpoints.upcomingMatches),
      _apiClient.get(ApiEndpoints.completedMatches),
      _apiClient.get(ApiEndpoints.matches, queryParameters: {'limit': 1}),
      _apiClient.get(ApiEndpoints.teams, queryParameters: {'limit': 1}),
      _apiClient.get(ApiEndpoints.players, queryParameters: {'limit': 1}),
      _apiClient.get(ApiEndpoints.tournaments, queryParameters: {'limit': 1}),
    ]);

    final live = _matches(responses[0].data);
    final upcoming = _matches(responses[1].data);
    final results = _matches(responses[2].data);

    List<Team> myTeams = [];
    if (userId != null && userId.isNotEmpty) {
      final myTeamsResponse = await _apiClient.get(
        ApiEndpoints.teams,
        queryParameters: {'owner': userId, 'limit': 5},
      );
      myTeams = _items(myTeamsResponse.data)
          .map((item) => TeamModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }

    return DashboardData(
      totalMatches: _total(responses[3].data),
      totalTeams: _total(responses[4].data),
      totalPlayers: _total(responses[5].data),
      totalTournaments: _total(responses[6].data),
      liveMatches: live,
      upcomingMatches: upcoming,
      recentResults: results,
      myTeams: myTeams,
    );
  }

  List<DashboardMatch> _matches(dynamic data) {
    return _items(data)
        .map((item) => DashboardMatch.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  List<dynamic> _items(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final wrapped = data['data'];
      if (wrapped is List) return wrapped;
      if (wrapped is Map && wrapped['items'] is List) {
        return wrapped['items'] as List<dynamic>;
      }
      if (data['items'] is List) return data['items'] as List<dynamic>;
    }
    return const [];
  }

  int _total(dynamic data) {
    if (data is Map) {
      final pagination = data['pagination'];
      if (pagination is Map && pagination['total'] is num) {
        return (pagination['total'] as num).toInt();
      }
      return _items(data).length;
    }
    if (data is List) return data.length;
    return 0;
  }
}
