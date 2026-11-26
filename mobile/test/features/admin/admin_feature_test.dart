import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/core/models/paginated_response.dart';
import 'package:mobile/core/routing/app_router.dart';
import 'package:mobile/features/admin/domain/entities/admin_audit_log.dart';
import 'package:mobile/features/admin/domain/entities/admin_dashboard_stats.dart';
import 'package:mobile/features/admin/domain/entities/admin_match.dart';
import 'package:mobile/features/admin/domain/entities/admin_user.dart';
import 'package:mobile/features/admin/domain/repositories/admin_repository.dart';
import 'package:mobile/features/admin/presentation/providers/admin_provider.dart';
import 'package:mobile/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:mobile/features/admin/presentation/screens/admin_matches_screen.dart';
import 'package:mobile/features/auth/domain/entities/user.dart';

final _dashboardStats = AdminDashboardStats.fromJson(<String, dynamic>{
  'data': <String, dynamic>{
    'counts': <String, dynamic>{
      'totalUsers': 42,
      'totalTeams': 12,
      'totalPlayers': 88,
      'totalTournaments': 5,
      'totalMatches': 31,
      'liveMatches': 2,
      'activeAuctions': 1,
      'totalReports': 3,
    },
  },
});

final _adminUser = AdminUser.fromJson(<String, dynamic>{
  'data': <String, dynamic>{
    'user': <String, dynamic>{
      '_id': 'u1',
      'name': 'Ada Admin',
      'email': 'ada@example.com',
      'role': 'ADMIN',
      'isBlocked': false,
      'isVerified': true,
    },
  },
});

final _match = AdminMatch.fromJson(<String, dynamic>{
  'data': <String, dynamic>{
    '_id': 'm1',
    'status': 'COMPLETED',
    'teamA': {'name': 'India'},
    'teamB': {'name': 'Australia'},
  },
});

class FakeAdminRepository extends AdminRepository {
  String? lastUserSearch;
  String? lastUserStatus;
  String? lastUserRole;
  String? lastMatchStatus;
  String? lastCorrectionId;
  String? lastCorrectionReason;
  Map<String, dynamic>? lastCorrections;
  String? lastTeamDecision;

  @override
  Future<AdminDashboardStats> getDashboard() async => _dashboardStats;

  @override
  Future<PaginatedResponse<AdminUser>> getUsers({
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
    String? status,
  }) async {
    lastUserSearch = search;
    lastUserStatus = status;
    return PaginatedResponse<AdminUser>(
      items: <AdminUser>[_adminUser],
      total: 1,
    );
  }

  @override
  Future<PaginatedResponse<AdminMatch>> getMatches({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    return PaginatedResponse<AdminMatch>(items: <AdminMatch>[_match], total: 1);
  }

  @override
  Future<AdminUser> updateUserStatus(String id, String status) async {
    lastUserRole = null;
    return _adminUser;
  }

  @override
  Future<AdminUser> updateUserRole(String id, String role) async {
    lastUserRole = role;
    return _adminUser;
  }

  @override
  Future<AdminMatch> updateMatchStatus(String id, String status) async {
    lastMatchStatus = status;
    return _match;
  }

  @override
  Future<Map<String, dynamic>> correctMatch(
    String id, {
    required String reason,
    required Map<String, dynamic> corrections,
  }) async {
    lastCorrectionId = id;
    lastCorrectionReason = reason;
    lastCorrections = corrections;
    return <String, dynamic>{'ok': true};
  }

  @override
  Future<Map<String, dynamic>> decideTournamentTeam(
    String tournamentId,
    String teamId,
    String decision, {
    String? reason,
  }) async {
    lastTeamDecision = decision;
    return <String, dynamic>{'ok': true};
  }
}

ProviderContainer _container(FakeAdminRepository repository) {
  return ProviderContainer(
    overrides: <Override>[
      adminRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

void main() {
  test('exposes all admin endpoints and routes', () {
    expect(ApiEndpoints.adminDashboard, '/admin/dashboard');
    expect(ApiEndpoints.adminUsers, '/admin/users');
    expect(ApiEndpoints.adminUserStatus('u1'), '/admin/users/u1/status');
    expect(ApiEndpoints.adminTeams, '/admin/teams');
    expect(ApiEndpoints.adminPlayers, '/admin/players');
    expect(ApiEndpoints.adminTournaments, '/admin/tournaments');
    expect(
      ApiEndpoints.adminTournamentTeamDecision('t1', 'team1'),
      '/admin/tournaments/t1/teams/team1/decision',
    );
    expect(ApiEndpoints.adminMatches, '/admin/matches');
    expect(
      ApiEndpoints.adminMatchScorecard('m1'),
      '/admin/matches/m1/scorecard',
    );
    expect(
      ApiEndpoints.adminMatchCorrections('m1'),
      '/admin/matches/m1/corrections',
    );
    expect(ApiEndpoints.adminAuctions, '/admin/auctions');
    expect(
      ApiEndpoints.adminAuctionSuspicious('a1'),
      '/admin/auctions/a1/suspicious',
    );
    expect(
      ApiEndpoints.adminNotificationBroadcast,
      '/admin/notifications/broadcast',
    );
    expect(ApiEndpoints.adminNotificationUsers, '/admin/notifications/users');
    expect(ApiEndpoints.adminReportsExport, '/admin/reports/export');
    expect(ApiEndpoints.adminAuditsScoring, '/admin/audits/scoring');
    expect(ApiEndpoints.adminAuditsAuction, '/admin/audits/auction');

    expect(AppRoutes.adminShell, '/admin');
    expect(AppRoutes.adminDashboard, '/admin/dashboard');
    expect(AppRoutes.adminUsers, '/admin/users');
    expect(AppRoutes.adminAudits, '/admin/audits');
  });

  test('normalizes admin role variants and blocked flags', () {
    expect(
      const User(id: '1', name: 'A', email: 'a@b.c', role: 'admin').isAdmin,
      isTrue,
    );
    expect(
      const User(
        id: '1',
        name: 'A',
        email: 'a@b.c',
        role: 'role-admin',
      ).isAdmin,
      isTrue,
    );
    expect(
      const User(
        id: '1',
        name: 'A',
        email: 'a@b.c',
        role: 'super admin',
      ).isAdmin,
      isTrue,
    );
    expect(
      const User(
        id: '1',
        name: 'A',
        email: 'a@b.c',
        role: 'NORMAL_USER',
      ).isAdmin,
      isFalse,
    );

    final user = User.fromJson(<String, dynamic>{
      'id': 'u1',
      'name': 'Blocked',
      'email': 'blocked@example.com',
      'role': 'NORMAL_USER',
      'isBlocked': 'true',
    });
    expect(user.isBlocked, isTrue);
    expect(user.toJson()['isBlocked'], isTrue);
  });

  test('parses nested admin payloads without client-side derivation', () {
    expect(_dashboardStats.totalUsers, 42);
    expect(_dashboardStats.liveMatches, 2);
    expect(_dashboardStats.metrics['totalTeams'], 12);

    expect(_adminUser.id, 'u1');
    expect(_adminUser.email, 'ada@example.com');
    expect(_adminUser.isBlocked, isFalse);

    final audit = AdminAuditLog.fromJson(<String, dynamic>{
      'data': <String, dynamic>{
        'audit': <String, dynamic>{
          '_id': 'audit1',
          'action': 'MATCH_CORRECTED',
          'actor': {'name': 'Ada Admin'},
          'severity': 'HIGH',
          'reason': 'Scoring error',
          'changes': {'runs': 104},
        },
      },
    });
    expect(audit.action, 'MATCH_CORRECTED');
    expect(audit.actorName, 'Ada Admin');
    expect(audit.severity, 'HIGH');
    expect(audit.details['runs'], 104);
  });

  test('list notifier forwards filters to the backend repository', () async {
    final repository = FakeAdminRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final notifier = container.read(adminUsersProvider.notifier);
    await notifier.load(refresh: true);
    await notifier.setSearch('Ada');
    await notifier.setStatus('ACTIVE');

    expect(repository.lastUserSearch, 'Ada');
    expect(repository.lastUserStatus, 'ACTIVE');
    expect(notifier.state.items.single.name, 'Ada Admin');
  });

  test(
    'action notifier sends explicit correction reason and audited changes',
    () async {
      final repository = FakeAdminRepository();
      final container = _container(repository);
      addTearDown(container.dispose);

      final success = await container
          .read(adminActionProvider.notifier)
          .correctMatch(
            'm1',
            reason: 'Scoring error confirmed by scorecard',
            corrections: <String, dynamic>{'runs': 104, 'wickets': 2},
          );

      expect(success, isTrue);
      expect(repository.lastCorrectionId, 'm1');
      expect(
        repository.lastCorrectionReason,
        'Scoring error confirmed by scorecard',
      );
      expect(repository.lastCorrections?['runs'], 104);
      expect(repository.lastCorrections?['wickets'], 2);
    },
  );

  testWidgets('admin dashboard renders backend metrics', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          adminRepositoryProvider.overrideWithValue(FakeAdminRepository()),
        ],
        child: const MaterialApp(home: AdminDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Admin Dashboard'), findsOneWidget);
    expect(find.text('Users'), findsNWidgets(2));
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('match screen shows the correction audit warning', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          adminRepositoryProvider.overrideWithValue(FakeAdminRepository()),
        ],
        child: const MaterialApp(home: AdminMatchesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Score corrections require an explicit reason. Corrections are audited.',
      ),
      findsOneWidget,
    );
  });
}
