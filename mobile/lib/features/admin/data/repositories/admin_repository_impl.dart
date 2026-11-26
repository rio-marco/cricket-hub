import 'package:mobile/core/errors/exceptions.dart';
import 'package:mobile/core/errors/failures.dart';
import 'package:mobile/core/models/paginated_response.dart';

import '../../domain/entities/admin_auction.dart';
import '../../domain/entities/admin_audit_log.dart';
import '../../domain/entities/admin_dashboard_stats.dart';
import '../../domain/entities/admin_match.dart';
import '../../domain/entities/admin_notification_delivery.dart';
import '../../domain/entities/admin_player.dart';
import '../../domain/entities/admin_report_entry.dart';
import '../../domain/entities/admin_team.dart';
import '../../domain/entities/admin_tournament.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRepository remoteDataSource;

  const AdminRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AdminDashboardStats> getDashboard() {
    return _run(() => remoteDataSource.getDashboard());
  }

  @override
  Future<PaginatedResponse<AdminUser>> getUsers({
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
    String? status,
  }) {
    return _run(
      () => remoteDataSource.getUsers(
        page: page,
        limit: limit,
        search: search,
        role: role,
        status: status,
      ),
    );
  }

  @override
  Future<AdminUser> getUser(String id) {
    return _run(() => remoteDataSource.getUser(id));
  }

  @override
  Future<AdminUser> updateUserStatus(String id, String status) {
    return _run(() => remoteDataSource.updateUserStatus(id, status));
  }

  @override
  Future<AdminUser> updateUserRole(String id, String role) {
    return _run(() => remoteDataSource.updateUserRole(id, role));
  }

  @override
  Future<PaginatedResponse<AdminTeam>> getTeams({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) {
    return _run(
      () => remoteDataSource.getTeams(
        page: page,
        limit: limit,
        search: search,
        status: status,
      ),
    );
  }

  @override
  Future<AdminTeam> getTeam(String id) {
    return _run(() => remoteDataSource.getTeam(id));
  }

  @override
  Future<AdminTeam> updateTeamStatus(String id, String status) {
    return _run(() => remoteDataSource.updateTeamStatus(id, status));
  }

  @override
  Future<PaginatedResponse<AdminPlayer>> getPlayers({
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
  }) {
    return _run(
      () => remoteDataSource.getPlayers(
        page: page,
        limit: limit,
        search: search,
        role: role,
      ),
    );
  }

  @override
  Future<AdminPlayer> getPlayer(String id) {
    return _run(() => remoteDataSource.getPlayer(id));
  }

  @override
  Future<PaginatedResponse<AdminTournament>> getTournaments({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) {
    return _run(
      () => remoteDataSource.getTournaments(
        page: page,
        limit: limit,
        search: search,
        status: status,
      ),
    );
  }

  @override
  Future<AdminTournament> getTournament(String id) {
    return _run(() => remoteDataSource.getTournament(id));
  }

  @override
  Future<AdminTournament> updateTournamentStatus(String id, String status) {
    return _run(() => remoteDataSource.updateTournamentStatus(id, status));
  }

  @override
  Future<Map<String, dynamic>> decideTournamentTeam(
    String tournamentId,
    String teamId,
    String decision, {
    String? reason,
  }) {
    return _run(
      () => remoteDataSource.decideTournamentTeam(
        tournamentId,
        teamId,
        decision,
        reason: reason,
      ),
    );
  }

  @override
  Future<PaginatedResponse<AdminMatch>> getMatches({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) {
    return _run(
      () => remoteDataSource.getMatches(
        page: page,
        limit: limit,
        search: search,
        status: status,
      ),
    );
  }

  @override
  Future<AdminMatch> getMatch(String id) {
    return _run(() => remoteDataSource.getMatch(id));
  }

  @override
  Future<Map<String, dynamic>> getMatchScorecard(String id) {
    return _run(() => remoteDataSource.getMatchScorecard(id));
  }

  @override
  Future<List<Map<String, dynamic>>> getMatchEvents(String id) {
    return _run(() => remoteDataSource.getMatchEvents(id));
  }

  @override
  Future<AdminMatch> updateMatchStatus(String id, String status) {
    return _run(() => remoteDataSource.updateMatchStatus(id, status));
  }

  @override
  Future<Map<String, dynamic>> correctMatch(
    String id, {
    required String reason,
    required Map<String, dynamic> corrections,
  }) {
    return _run(
      () => remoteDataSource.correctMatch(
        id,
        reason: reason,
        corrections: corrections,
      ),
    );
  }

  @override
  Future<PaginatedResponse<AdminAuction>> getAuctions({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) {
    return _run(
      () => remoteDataSource.getAuctions(
        page: page,
        limit: limit,
        search: search,
        status: status,
      ),
    );
  }

  @override
  Future<AdminAuction> getAuction(String id) {
    return _run(() => remoteDataSource.getAuction(id));
  }

  @override
  Future<List<Map<String, dynamic>>> getAuctionBids(String id) {
    return _run(() => remoteDataSource.getAuctionBids(id));
  }

  @override
  Future<List<AdminAuditLog>> getAuctionAudit(String id) {
    return _run(() => remoteDataSource.getAuctionAudit(id));
  }

  @override
  Future<List<Map<String, dynamic>>> getSuspiciousAuctionActivity(String id) {
    return _run(() => remoteDataSource.getSuspiciousAuctionActivity(id));
  }

  @override
  Future<Map<String, dynamic>> broadcastNotification({
    required String title,
    required String body,
    String? audience,
    Map<String, dynamic>? data,
  }) {
    return _run(
      () => remoteDataSource.broadcastNotification(
        title: title,
        body: body,
        audience: audience,
        data: data,
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    return _run(
      () => remoteDataSource.sendNotificationToUsers(
        userIds: userIds,
        title: title,
        body: body,
        data: data,
      ),
    );
  }

  @override
  Future<PaginatedResponse<AdminNotificationDelivery>>
  getNotificationDeliveries({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) {
    return _run(
      () => remoteDataSource.getNotificationDeliveries(
        page: page,
        limit: limit,
        search: search,
        status: status,
      ),
    );
  }

  @override
  Future<PaginatedResponse<AdminReportEntry>> getReports({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) {
    return _run(
      () => remoteDataSource.getReports(
        page: page,
        limit: limit,
        search: search,
        status: status,
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> exportReports({String? format, String? status}) {
    return _run(
      () => remoteDataSource.exportReports(format: format, status: status),
    );
  }

  @override
  Future<PaginatedResponse<AdminAuditLog>> getAudits({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
  }) {
    return _run(
      () => remoteDataSource.getAudits(
        page: page,
        limit: limit,
        search: search,
        category: category,
      ),
    );
  }

  @override
  Future<PaginatedResponse<AdminAuditLog>> getScoringAudits({
    int page = 1,
    int limit = 20,
    String? search,
  }) {
    return _run(
      () => remoteDataSource.getScoringAudits(
        page: page,
        limit: limit,
        search: search,
      ),
    );
  }

  @override
  Future<PaginatedResponse<AdminAuditLog>> getAuctionAudits({
    int page = 1,
    int limit = 20,
    String? search,
  }) {
    return _run(
      () => remoteDataSource.getAuctionAudits(
        page: page,
        limit: limit,
        search: search,
      ),
    );
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException catch (error) {
      throw Failure.fromException(error);
    } catch (error) {
      throw ServerFailure(message: error.toString());
    }
  }
}
