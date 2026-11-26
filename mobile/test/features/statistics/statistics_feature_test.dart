import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/core/models/paginated_response.dart';
import 'package:mobile/features/statistics/domain/entities/leaderboard_entry.dart';
import 'package:mobile/features/statistics/domain/entities/player_statistics.dart';
import 'package:mobile/features/statistics/domain/entities/statistics_filter.dart';
import 'package:mobile/features/statistics/domain/entities/statistics_overview.dart';
import 'package:mobile/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:mobile/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:mobile/features/statistics/presentation/widgets/statistics_entry_tile.dart';

const leaderboardEntryJson = <String, dynamic>{
  'rank': 1,
  'playerId': 'p1',
  'playerName': 'Rohan',
  'playingRole': 'BATSMAN',
  'jerseyNumber': 7,
  'city': 'Mumbai',
  'metric': 'runs',
  'value': 120,
  'stats': <String, dynamic>{
    'batting': <String, dynamic>{
      'innings': 2,
      'runs': 120,
      'balls': 80,
      'average': 120,
      'strikeRate': 150,
      'highestScore': '120',
    },
    'bowling': <String, dynamic>{'wickets': 2, 'economy': 6.5},
    'fielding': <String, dynamic>{'catches': 3},
  },
};

const playerStatisticsJson = <String, dynamic>{
  'playerId': 'p1',
  'filters': <String, dynamic>{'format': 'T20', 'season': 2026},
  'matches': 4,
  'playerOfMatch': 1,
  'batting': <String, dynamic>{
    'innings': 3,
    'runs': 120,
    'balls': 80,
    'fours': 10,
    'sixes': 5,
    'highestScore': '72*',
    'highestScoreRuns': 72,
    'average': 60,
    'strikeRate': 150,
  },
  'bowling': <String, dynamic>{
    'innings': 2,
    'wickets': 5,
    'runsConceded': 60,
    'overs': 10,
    'oversLabel': '10.0',
    'economy': 6,
    'bestBowling': '3/24',
  },
  'fielding': <String, dynamic>{'catches': 4, 'stumpings': 1, 'totalDismissals': 5},
  'recentForm': [
    <String, dynamic>{
      'matchId': 'm1',
      'title': 'Final',
      'batting': <String, dynamic>{'runs': 72},
      'bowling': <String, dynamic>{'wickets': 2},
      'fielding': <String, dynamic>{'catches': 1},
    },
  ],
  'tournamentWise': [
    <String, dynamic>{'key': 't1', 'label': 'Cup', 'matches': 2, 'runs': 80},
  ],
  'seasonWise': [
    <String, dynamic>{'key': '2026', 'label': '2026', 'matches': 4, 'runs': 120},
  ],
  'formatWise': [
    <String, dynamic>{'key': 'T20', 'label': 'T20', 'matches': 4, 'runs': 120},
  ],
};

class FakeStatisticsRepository implements StatisticsRepository {
  StatisticsOverview overview = const StatisticsOverview();
  PlayerStatistics playerStatistics = const PlayerStatistics();
  PaginatedResponse<LeaderboardEntry> leaderboard =
      PaginatedResponse<LeaderboardEntry>.empty();

  StatisticsFilter? lastOverviewFilter;
  StatisticsFilter? lastPlayerFilter;
  String? lastPlayerId;
  String? lastMetric;
  StatisticsFilter? lastLeaderboardFilter;
  int? lastPage;

  @override
  Future<StatisticsOverview> getOverview({
    StatisticsFilter filter = const StatisticsFilter(),
  }) async {
    lastOverviewFilter = filter;
    return overview;
  }

  @override
  Future<PlayerStatistics> getPlayerStatistics(
    String playerId, {
    StatisticsFilter filter = const StatisticsFilter(),
  }) async {
    lastPlayerId = playerId;
    lastPlayerFilter = filter;
    return playerStatistics;
  }

  @override
  Future<PaginatedResponse<LeaderboardEntry>> getLeaderboard({
    required String metric,
    StatisticsFilter filter = const StatisticsFilter(),
    int page = 1,
    int limit = 20,
  }) async {
    lastMetric = metric;
    lastLeaderboardFilter = filter;
    lastPage = page;
    return leaderboard;
  }
}

void main() {
  test('parses leaderboard entries and formats metric values', () {
    final entry = LeaderboardEntry.fromJson(leaderboardEntryJson);

    expect(entry.rank, 1);
    expect(entry.playerId, 'p1');
    expect(entry.jerseyNumber, 7);
    expect(entry.batting.runs, 120);
    expect(entry.bowling.economy, 6.5);
    expect(entry.fielding.catches, 3);
    expect(entry.valueDisplay, '120');
  });

  test('parses authoritative player statistics payload', () {
    final stats = PlayerStatistics.fromJson(playerStatisticsJson);

    expect(stats.playerId, 'p1');
    expect(stats.matches, 4);
    expect(stats.batting.highestScore, '72*');
    expect(stats.batting.strikeRate, 150);
    expect(stats.bowling.bestBowling, '3/24');
    expect(stats.fielding.totalDismissals, 5);
    expect(stats.recentForm.single.title, 'Final');
    expect(stats.tournamentWise.single.label, 'Cup');
    expect(stats.seasonWise.single.key, '2026');
    expect(stats.formatWise.single.key, 'T20');
  });

  test('builds filter query parameters for the backend', () {
    final filter = StatisticsFilter(
      tournamentId: '64b7f5c2a1b2c3d4e5f60718',
      season: 2026,
      format: 'T20',
      from: DateTime.utc(2026, 1, 1),
      to: DateTime.utc(2026, 12, 31),
    );

    final query = filter.toQueryParameters();

    expect(query['tournament'], '64b7f5c2a1b2c3d4e5f60718');
    expect(query['season'], 2026);
    expect(query['format'], 'T20');
    expect(query['from'], '2026-01-01T00:00:00.000Z');
    expect(query['to'], '2026-12-31T00:00:00.000Z');
  });

  test('exposes backend statistic and leaderboard endpoints', () {
    expect(ApiEndpoints.playerOverallStatistics('p1'), '/statistics/players/p1/overall');
    expect(ApiEndpoints.playerBattingStatistics('p1'), '/statistics/players/p1/batting');
    expect(ApiEndpoints.playerBowlingStatistics('p1'), '/statistics/players/p1/bowling');
    expect(ApiEndpoints.playerFieldingStatistics('p1'), '/statistics/players/p1/fielding');
    expect(ApiEndpoints.leaderboardByMetric('battingAverage'), '/leaderboards/battingAverage');
  });

  test('overview notifier forwards filters to the repository', () async {
    final repository = FakeStatisticsRepository();
    repository.overview = StatisticsOverview(
      topBatsmen: [LeaderboardEntry.fromJson(leaderboardEntryJson)],
    );
    final notifier = StatisticsOverviewNotifier(repository);
    addTearDown(notifier.dispose);

    const filter = StatisticsFilter(format: 'T20', season: 2026);
    await notifier.setFilter(filter);

    expect(repository.lastOverviewFilter, filter);
    expect(notifier.state.filter, filter);
    expect(notifier.state.overview?.topBatsmen.single.playerName, 'Rohan');
  });

  test('leaderboard notifier switches metric and reloads from page one', () async {
    final repository = FakeStatisticsRepository();
    final notifier = LeaderboardNotifier(repository);
    addTearDown(notifier.dispose);

    await notifier.setMetric('wickets');

    expect(repository.lastMetric, 'wickets');
    expect(repository.lastPage, 1);
    expect(notifier.state.metric, 'wickets');
  });

  testWidgets('statistics entry tile renders rank and value', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatisticsEntryTile(
            entry: LeaderboardEntry.fromJson(leaderboardEntryJson),
          ),
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text('Rohan'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
  });
}
