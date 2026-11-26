import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/core/models/paginated_response.dart';

import '../../domain/entities/admin_auction.dart';
import '../../domain/entities/admin_audit_log.dart';
import '../../domain/entities/admin_dashboard_stats.dart';
import '../../domain/entities/admin_json.dart';
import '../../domain/entities/admin_match.dart';
import '../../domain/entities/admin_notification_delivery.dart';
import '../../domain/entities/admin_player.dart';
import '../../domain/entities/admin_report_entry.dart';
import '../../domain/entities/admin_team.dart';
import '../../domain/entities/admin_tournament.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/repositories/admin_repository.dart';

abstract class AdminRemoteDataSource implements AdminRepository {}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final ApiClient _apiClient;

  const AdminRemoteDataSourceImpl(this._apiClient);

  @override
  Future<AdminDashboardStats> getDashboard() async {
    final response = await _apiClient.get<dynamic>(ApiEndpoints.adminDashboard);
    return AdminDashboardStats.fromJson(response.data);
  }

  @override
  Future<PaginatedResponse<AdminUser>> getUsers({
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
    String? status,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.adminUsers,
      queryParameters: _query(
        page: page,
        limit: limit,
        search: search,
        role: role,
        status: status,
      ),
    );
    return _paginated<AdminUser>(
      response.data,
      AdminUser.fromJson,
      const <String>['users'],
    );
  }

  @override
  Future<AdminUser> getUser(String id) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.adminUserById(id),
    );
    return AdminUser.fromJson(response.data);
  }

  @override
  Future<AdminUser> updateUserStatus(String id, String status) async {
    final response = await _apiClient.patch<dynamic>(
      ApiEndpoints.adminUserStatus(id),
      data: <String, dynamic>{'status': status},
    );
    return AdminUser.fromJson(response.data);
  }

  @override
  Future<AdminUser> updateUserRole(String id, String role) async {
    final response = await _apiClient.patch<dynamic>(
      ApiEndpoints.adminUserRole(id),
      data: <String, dynamic>{'role': role},
    );
    return AdminUser.fromJson(response.data);
  }

  @override
  Future<PaginatedResponse<AdminTeam>> getTeams({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.adminTeams,
      queryParameters: _query(
        page: page,
        limit: limit,
        search: search,
        status: status,
      ),
    );
    return _paginated<AdminTeam>(
      response.data,
      AdminTeam.fromJson,
      const <String>['teams'],
    );
  }

  @override
  Future<AdminTeam> getTeam(String id) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.adminTeamById(id),
    );
    return AdminTeam.fromJson(response.data);
  }

  @override
  Future<AdminTeam> updateTeamStatus(String id, String status) async {
    final response = await _apiClient.patch<dynamic>(
      ApiEndpoints.adminTeamStatus(id),
      data: <String, dynamic>{'status': status},
    );
    return AdminTeam.fromJson(response.data);
  }

  @override
  Future<PaginatedResponse<AdminPlayer>> getPlayers({
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.adminPlayers,
      queryParameters: _query(
        page: page,
        limit: limit,
        search: search,
        role: role,
      ),
    );
    return _paginated<AdminPlayer>(
      response.data,
      AdminPlayer.fromJson,
      const <String>['players'],
    );
  }

  @override
  Future<AdminPlayer> getPlayer(String id) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.adminPlayerById(id),
    );
    return AdminPlayer.fromJson(response.data);
  }

  @override
  Future<PaginatedResponse<AdminTournament>> getTournaments({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.adminTournaments,
      queryParameters: _query(
        page: page,
        limit: limit,
        search: search,
        status: status,
      ),
    );
    return _paginated<AdminTournament>(
      response.data,
      AdminTournament.fromJson,
      const <String>['tournaments'],
    );
  }

  @override
  Future<AdminTournament> getTournament(String id) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.adminTournamentById(id),
    );
    return AdminTournament.fromJson(response.data);
  }

  @override
  Future<AdminTournament> updateTournamentStatus(
    String id,
    String status,
  ) async {
    final response = await _apiClient.patch<dynamic>(
      ApiEndpoints.adminTournamentStatus(id),
      data: <String, dynamic>{'status': status},
    );
    return AdminTournament.fromJson(response.data);
  }

  @override
  Future<Map<String, dynamic>> decideTournamentTeam(
    String tournamentId,
    String teamId,
    String decision, {
    String? reason,
  }) async {
    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.adminTournamentTeamDecision(tournamentId, teamId),
      data: <String, dynamic>{
        'decision': decision,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return _result(response.data);
  }

  @override
  Future<PaginatedResponse<AdminMatch>> getMatches({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.adminMatches,
      queryParameters: _query(
        page: page,
        limit: limit,
        search: search,
        status: status,
      ),
    );
    return _paginated<AdminMatch>(
      response.data,
      AdminMatch.fromJson,
      const <String>['matches'],
    );
  }

  @override
  Future<AdminMatch> getMatch(String id) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.adminMatchById(id),
    );
    return AdminMatch.fromJson(response.data);
  }

  @override
  Future<Map<String, dynamic>> getMatchScorecard(String id) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.adminMatchScorecard(id),
    );
    return _result(response.data);
  }

  @override
  Future<List<Map<String, dynamic>>> getMatchEvents(String id) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.adminMatchEvents(id),
    );
    return _maps(response.data, const <String>['events', 'commentary']);
  }

  @override
  Future<AdminMatch> updateMatchStatus(String id, String status) async {
    final response = await _apiClient.patch<dynamic>(
      ApiEndpoints.adminMatchStatus(id),
      data: <String, dynamic>{'status': status},
    );
    return AdminMatch.fromJson(response.data);
  }

  @override
  Future<Map<String, dynamic>> correctMatch(
    String id, {
    required String reason,
    required Map<String, dynamic> corrections,
  }) async {
    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.adminMatchCorrections(id),
      data: <String, dynamic>{
        ...corrections,
        'corrections': corrections,
        'reason': reason.trim(),
      },
    );
    return _result(response.data);
  }

  @override
  Future<PaginatedResponse<AdminAuction>> getAuctions({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.adminAuctions,
      queryParameters: _query(
        page: page,
        limit: limit,
        search: search,
        status: status,
      ),
    );
    return _paginated<AdminAuction>(
      response.data,
      AdminAuction.fromJson,
      const <String>['auctions'],
    );
  }

  @override
  Future<AdminAuction> getAuction(String id) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.adminAuctionById(id),
    );
    return AdminAuction.fromJson(response.data);
  }

  @override
  Future<List<Map<String, dynamic>>> getAuctionBids(String id) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.adminAuctionBids(id),
    );
    return _maps(response.data, const <String>['bids']);
  }

  @override
  Future<List<AdminAuditLog>> getAuctionAudit(String id) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.adminAuctionAudit(id),
    );
    return AdminJson.list(response.data, const <String>[
      'audit',
      'audits',
      'logs',
    ]).map((item) => AdminAuditLog.fromJson(item)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getSuspiciousAuctionActivity(
    String id,
  ) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.adminAuctionSuspicious(id),
    );
    return _maps(response.data, const <String>[
      'suspicious',
      'suspiciousBids',
      'activities',
    ]);
  }

  @override
  Future<Map<String, dynamic>> broadcastNotification({
    required String title,
    required String body,
    String? audience,
    Map<String, dynamic>? data,
  }) async {
    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.adminNotificationBroadcast,
      data: <String, dynamic>{
        'title': title.trim(),
        'body': body.trim(),
        if (audience != null && audience.trim().isNotEmpty)
          'audience': audience.trim(),
        if (data != null) 'data': data,
      },
    );
    return _result(response.data);
  }

  @override
  Future<Map<String, dynamic>> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final response = await _apiClient.post<dynamic>(
      ApiEndpoints.adminNotificationUsers,
      data: <String, dynamic>{
        'userIds': userIds,
        'title': title.trim(),
        'body': body.trim(),
        if (data != null) 'data': data,
      },
    );
    return _result(response.data);
  }

  @override
  Future<PaginatedResponse<AdminNotificationDelivery>>
  getNotificationDeliveries({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.adminNotificationDeliveries,
      queryParameters: _query(
        page: page,
        limit: limit,
        search: search,
        status: status,
      ),
    );
    return _paginated<AdminNotificationDelivery>(
      response.data,
      AdminNotificationDelivery.fromJson,
      const <String>['deliveries'],
    );
  }

  @override
  Future<PaginatedResponse<AdminReportEntry>> getReports({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.adminReports,
      queryParameters: _query(
        page: page,
        limit: limit,
        search: search,
        status: status,
      ),
    );
    return _paginated<AdminReportEntry>(
      response.data,
      AdminReportEntry.fromJson,
      const <String>['reports'],
    );
  }

  @override
  Future<Map<String, dynamic>> exportReports({
    String? format,
    String? status,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.adminReportsExport,
      queryParameters: _query(format: format, status: status),
    );
    return _result(response.data);
  }

  @override
  Future<PaginatedResponse<AdminAuditLog>> getAudits({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.adminAudits,
      queryParameters: _query(
        page: page,
        limit: limit,
        search: search,
        category: category,
      ),
    );
    return _paginated<AdminAuditLog>(
      response.data,
      AdminAuditLog.fromJson,
      const <String>['audits', 'logs'],
    );
  }

  @override
  Future<PaginatedResponse<AdminAuditLog>> getScoringAudits({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.adminAuditsScoring,
      queryParameters: _query(page: page, limit: limit, search: search),
    );
    return _paginated<AdminAuditLog>(
      response.data,
      AdminAuditLog.fromJson,
      const <String>['audits', 'logs'],
    );
  }

  @override
  Future<PaginatedResponse<AdminAuditLog>> getAuctionAudits({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.adminAuditsAuction,
      queryParameters: _query(page: page, limit: limit, search: search),
    );
    return _paginated<AdminAuditLog>(
      response.data,
      AdminAuditLog.fromJson,
      const <String>['audits', 'logs'],
    );
  }

  Map<String, dynamic> _query({
    int? page,
    int? limit,
    String? search,
    String? role,
    String? status,
    String? category,
    String? format,
  }) {
    return <String, dynamic>{
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (role != null && role.trim().isNotEmpty) 'role': role.trim(),
      if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      if (category != null && category.trim().isNotEmpty)
        'category': category.trim(),
      if (format != null && format.trim().isNotEmpty) 'format': format.trim(),
    };
  }

  PaginatedResponse<T> _paginated<T>(
    dynamic value,
    T Function(dynamic) fromJson,
    List<String> keys,
  ) {
    return PaginatedResponse<T>.fromJson(
      AdminJson.listEnvelope(value, keys),
      fromJson,
    );
  }

  List<Map<String, dynamic>> _maps(dynamic value, List<String> keys) {
    return AdminJson.list(
      value,
      keys,
    ).whereType<Map>().map((item) => AdminJson.map(item)).toList();
  }

  Map<String, dynamic> _result(dynamic value) {
    final data = AdminJson.payload(value);
    if (data.isNotEmpty) return data;
    if (value is String && value.trim().isNotEmpty) {
      return <String, dynamic>{'content': value.trim()};
    }
    if (value != null) return <String, dynamic>{'data': value};
    return <String, dynamic>{};
  }
}
