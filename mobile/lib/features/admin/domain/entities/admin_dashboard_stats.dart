import 'admin_json.dart';

class AdminDashboardStats {
  final int totalUsers;
  final int totalTeams;
  final int totalPlayers;
  final int totalTournaments;
  final int totalMatches;
  final int liveMatches;
  final int completedMatches;
  final int activeAuctions;
  final int blockedUsers;
  final int totalReports;
  final Map<String, int> metrics;
  final List<Map<String, dynamic>> highlights;
  final Map<String, dynamic> raw;

  const AdminDashboardStats({
    this.totalUsers = 0,
    this.totalTeams = 0,
    this.totalPlayers = 0,
    this.totalTournaments = 0,
    this.totalMatches = 0,
    this.liveMatches = 0,
    this.completedMatches = 0,
    this.activeAuctions = 0,
    this.blockedUsers = 0,
    this.totalReports = 0,
    this.metrics = const <String, int>{},
    this.highlights = const <Map<String, dynamic>>[],
    this.raw = const <String, dynamic>{},
  });

  factory AdminDashboardStats.fromJson(dynamic json) {
    final data = AdminJson.entity(json, const <String>['stats', 'dashboard']);
    final counts = AdminJson.map(data['counts'] ?? data['statistics']);
    final source = <String, dynamic>{...data, ...counts};

    int count(List<String> keys) {
      for (final key in keys) {
        if (source.containsKey(key)) return AdminJson.integer(source[key]);
      }
      return 0;
    }

    final metrics = <String, int>{};
    for (final entry in counts.entries) {
      if (entry.value is num)
        metrics[entry.key] = AdminJson.integer(entry.value);
    }
    for (final key in source.keys) {
      if (source[key] is num && !metrics.containsKey(key)) {
        metrics[key] = AdminJson.integer(source[key]);
      }
    }

    return AdminDashboardStats(
      totalUsers: count(const <String>['totalUsers', 'users', 'userCount']),
      totalTeams: count(const <String>['totalTeams', 'teams', 'teamCount']),
      totalPlayers: count(const <String>[
        'totalPlayers',
        'players',
        'playerCount',
      ]),
      totalTournaments: count(const <String>[
        'totalTournaments',
        'tournaments',
        'tournamentCount',
      ]),
      totalMatches: count(const <String>[
        'totalMatches',
        'matches',
        'matchCount',
      ]),
      liveMatches: count(const <String>[
        'liveMatches',
        'live',
        'activeMatches',
      ]),
      completedMatches: count(const <String>[
        'completedMatches',
        'completed',
        'finishedMatches',
      ]),
      activeAuctions: count(const <String>[
        'activeAuctions',
        'liveAuctions',
        'auctions',
      ]),
      blockedUsers: count(const <String>['blockedUsers', 'blocked']),
      totalReports: count(const <String>[
        'totalReports',
        'reports',
        'openReports',
      ]),
      metrics: metrics,
      highlights: AdminJson.list(data, const <String>[
        'highlights',
        'recentActivity',
        'activity',
        'recent',
      ]).whereType<Map>().map((item) => AdminJson.map(item)).toList(),
      raw: AdminJson.map(data),
    );
  }
}
