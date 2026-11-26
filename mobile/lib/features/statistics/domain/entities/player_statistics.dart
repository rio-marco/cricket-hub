import 'batting_summary.dart';
import 'bowling_summary.dart';
import 'fielding_summary.dart';
import 'statistics_filter.dart';
import 'statistics_values.dart';

class RecentPerformance {
  final String matchId;
  final String title;
  final DateTime? matchDate;
  final String format;
  final String result;
  final BattingSummary batting;
  final BowlingSummary bowling;
  final FieldingSummary fielding;

  const RecentPerformance({
    this.matchId = '',
    this.title = 'Match',
    this.matchDate,
    this.format = '',
    this.result = '',
    this.batting = const BattingSummary(),
    this.bowling = const BowlingSummary(),
    this.fielding = const FieldingSummary(),
  });

  factory RecentPerformance.fromJson(Map<String, dynamic> json) {
    return RecentPerformance(
      matchId: stringValue(json['matchId']),
      title: stringValue(json['title'], 'Match'),
      matchDate: DateTime.tryParse(stringValue(json['matchDate'])),
      format: stringValue(json['format']),
      result: stringValue(json['result']),
      batting: BattingSummary.fromJson(mapValue(json['batting'])),
      bowling: BowlingSummary.fromJson(mapValue(json['bowling'])),
      fielding: FieldingSummary.fromJson(mapValue(json['fielding'])),
    );
  }
}

class StatisticsGroup {
  final String key;
  final String label;
  final int matches;
  final int runs;
  final int balls;
  final int wickets;
  final double economy;
  final int catches;

  const StatisticsGroup({
    this.key = '',
    this.label = '',
    this.matches = 0,
    this.runs = 0,
    this.balls = 0,
    this.wickets = 0,
    this.economy = 0,
    this.catches = 0,
  });

  factory StatisticsGroup.fromJson(Map<String, dynamic> json) {
    return StatisticsGroup(
      key: stringValue(json['key']),
      label: stringValue(json['label']),
      matches: intValue(json['matches']),
      runs: intValue(json['runs']),
      balls: intValue(json['balls']),
      wickets: intValue(json['wickets']),
      economy: doubleValue(json['economy']),
      catches: intValue(json['catches']),
    );
  }
}

class PlayerStatistics {
  final String playerId;
  final StatisticsFilter filters;
  final int matches;
  final int playerOfMatch;
  final BattingSummary batting;
  final BowlingSummary bowling;
  final FieldingSummary fielding;
  final List<RecentPerformance> recentForm;
  final List<StatisticsGroup> tournamentWise;
  final List<StatisticsGroup> seasonWise;
  final List<StatisticsGroup> formatWise;

  const PlayerStatistics({
    this.playerId = '',
    this.filters = const StatisticsFilter(),
    this.matches = 0,
    this.playerOfMatch = 0,
    this.batting = const BattingSummary(),
    this.bowling = const BowlingSummary(),
    this.fielding = const FieldingSummary(),
    this.recentForm = const <RecentPerformance>[],
    this.tournamentWise = const <StatisticsGroup>[],
    this.seasonWise = const <StatisticsGroup>[],
    this.formatWise = const <StatisticsGroup>[],
  });

  factory PlayerStatistics.fromJson(Map<String, dynamic> json) {
    return PlayerStatistics(
      playerId: stringValue(json['playerId']),
      filters: StatisticsFilter.fromJson(mapValue(json['filters'])),
      matches: intValue(json['matches']),
      playerOfMatch: intValue(json['playerOfMatch']),
      batting: BattingSummary.fromJson(mapValue(json['batting'])),
      bowling: BowlingSummary.fromJson(mapValue(json['bowling'])),
      fielding: FieldingSummary.fromJson(mapValue(json['fielding'])),
      recentForm: listValue(json['recentForm'])
          .map((item) => RecentPerformance.fromJson(mapValue(item)))
          .toList(),
      tournamentWise: listValue(json['tournamentWise'])
          .map((item) => StatisticsGroup.fromJson(mapValue(item)))
          .toList(),
      seasonWise: listValue(json['seasonWise'])
          .map((item) => StatisticsGroup.fromJson(mapValue(item)))
          .toList(),
      formatWise: listValue(json['formatWise'])
          .map((item) => StatisticsGroup.fromJson(mapValue(item)))
          .toList(),
    );
  }
}
