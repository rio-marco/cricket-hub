import 'leaderboard_entry.dart';
import 'statistics_filter.dart';
import 'statistics_values.dart';

class StatisticsOverview {
  final StatisticsFilter filters;
  final List<LeaderboardEntry> topBatsmen;
  final List<LeaderboardEntry> topBowlers;
  final List<LeaderboardEntry> topFielders;

  const StatisticsOverview({
    this.filters = const StatisticsFilter(),
    this.topBatsmen = const <LeaderboardEntry>[],
    this.topBowlers = const <LeaderboardEntry>[],
    this.topFielders = const <LeaderboardEntry>[],
  });

  factory StatisticsOverview.fromJson(Map<String, dynamic> json) {
    return StatisticsOverview(
      filters: StatisticsFilter.fromJson(mapValue(json['filters'])),
      topBatsmen: listValue(json['topBatsmen'])
          .map((item) => LeaderboardEntry.fromJson(mapValue(item)))
          .toList(),
      topBowlers: listValue(json['topBowlers'])
          .map((item) => LeaderboardEntry.fromJson(mapValue(item)))
          .toList(),
      topFielders: listValue(json['topFielders'])
          .map((item) => LeaderboardEntry.fromJson(mapValue(item)))
          .toList(),
    );
  }

  bool get isEmpty =>
      topBatsmen.isEmpty && topBowlers.isEmpty && topFielders.isEmpty;
}
