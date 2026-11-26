import '../../../../core/models/paginated_response.dart';
import '../entities/admin_auction.dart';
import '../entities/admin_audit_log.dart';
import '../entities/admin_dashboard_stats.dart';
import '../entities/admin_match.dart';
import '../entities/admin_notification_delivery.dart';
import '../entities/admin_player.dart';
import '../entities/admin_report_entry.dart';
import '../entities/admin_team.dart';
import '../entities/admin_tournament.dart';
import '../entities/admin_user.dart';

abstract class AdminRepository {
  Future<AdminDashboardStats> getDashboard() {
    throw UnimplementedError();
  }

  Future<PaginatedResponse<AdminUser>> getUsers({
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
    String? status,
  }) {
    throw UnimplementedError();
  }

  Future<AdminUser> getUser(String id) {
    throw UnimplementedError();
  }

  Future<AdminUser> updateUserStatus(String id, String status) {
    throw UnimplementedError();
  }

  Future<AdminUser> updateUserRole(String id, String role) {
    throw UnimplementedError();
  }

  Future<PaginatedResponse<AdminTeam>> getTeams({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) {
    throw UnimplementedError();
  }

  Future<AdminTeam> getTeam(String id) {
    throw UnimplementedError();
  }

  Future<AdminTeam> updateTeamStatus(String id, String status) {
    throw UnimplementedError();
  }

  Future<PaginatedResponse<AdminPlayer>> getPlayers({
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
  }) {
    throw UnimplementedError();
  }

  Future<AdminPlayer> getPlayer(String id) {
    throw UnimplementedError();
  }

  Future<PaginatedResponse<AdminTournament>> getTournaments({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) {
    throw UnimplementedError();
  }

  Future<AdminTournament> getTournament(String id) {
    throw UnimplementedError();
  }

  Future<AdminTournament> updateTournamentStatus(String id, String status) {
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>> decideTournamentTeam(
    String tournamentId,
    String teamId,
    String decision, {
    String? reason,
  }) {
    throw UnimplementedError();
  }

  Future<PaginatedResponse<AdminMatch>> getMatches({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) {
    throw UnimplementedError();
  }

  Future<AdminMatch> getMatch(String id) {
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>> getMatchScorecard(String id) {
    throw UnimplementedError();
  }

  Future<List<Map<String, dynamic>>> getMatchEvents(String id) {
    throw UnimplementedError();
  }

  Future<AdminMatch> updateMatchStatus(String id, String status) {
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>> correctMatch(
    String id, {
    required String reason,
    required Map<String, dynamic> corrections,
  }) {
    throw UnimplementedError();
  }

  Future<PaginatedResponse<AdminAuction>> getAuctions({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) {
    throw UnimplementedError();
  }

  Future<AdminAuction> getAuction(String id) {
    throw UnimplementedError();
  }

  Future<List<Map<String, dynamic>>> getAuctionBids(String id) {
    throw UnimplementedError();
  }

  Future<List<AdminAuditLog>> getAuctionAudit(String id) {
    throw UnimplementedError();
  }

  Future<List<Map<String, dynamic>>> getSuspiciousAuctionActivity(String id) {
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>> broadcastNotification({
    required String title,
    required String body,
    String? audience,
    Map<String, dynamic>? data,
  }) {
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    throw UnimplementedError();
  }

  Future<PaginatedResponse<AdminNotificationDelivery>>
  getNotificationDeliveries({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) {
    throw UnimplementedError();
  }

  Future<PaginatedResponse<AdminReportEntry>> getReports({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) {
    throw UnimplementedError();
  }

  Future<Map<String, dynamic>> exportReports({String? format, String? status}) {
    throw UnimplementedError();
  }

  Future<PaginatedResponse<AdminAuditLog>> getAudits({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
  }) {
    throw UnimplementedError();
  }

  Future<PaginatedResponse<AdminAuditLog>> getScoringAudits({
    int page = 1,
    int limit = 20,
    String? search,
  }) {
    throw UnimplementedError();
  }

  Future<PaginatedResponse<AdminAuditLog>> getAuctionAudits({
    int page = 1,
    int limit = 20,
    String? search,
  }) {
    throw UnimplementedError();
  }
}
