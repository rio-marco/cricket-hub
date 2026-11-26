import 'batting_summary.dart';
import 'bowling_summary.dart';
import 'fielding_summary.dart';
import 'statistics_values.dart';

const List<String> leaderboardMetrics = <String>[
  'runs',
  'wickets',
  'battingAverage',
  'battingStrikeRate',
  'bowlingEconomy',
  'bowlingAverage',
  'sixes',
  'fours',
  'catches',
];

String leaderboardMetricLabel(String metric) {
  const labels = <String, String>{
    'runs': 'Most Runs',
    'wickets': 'Most Wickets',
    'battingAverage': 'Batting Average',
    'battingStrikeRate': 'Strike Rate',
    'bowlingEconomy': 'Economy',
    'bowlingAverage': 'Bowling Average',
    'sixes': 'Most Sixes',
    'fours': 'Most Fours',
    'catches': 'Most Catches',
  };
  return labels[metric] ?? 'Leaderboard';
}

class LeaderboardEntry {
  final int rank;
  final String playerId;
  final String playerName;
  final String playingRole;
  final int? jerseyNumber;
  final String city;
  final String metric;
  final double value;
  final BattingSummary batting;
  final BowlingSummary bowling;
  final FieldingSummary fielding;

  const LeaderboardEntry({
    this.rank = 0,
    this.playerId = '',
    this.playerName = 'Player',
    this.playingRole = '',
    this.jerseyNumber,
    this.city = '',
    this.metric = 'runs',
    this.value = 0,
    this.batting = const BattingSummary(),
    this.bowling = const BowlingSummary(),
    this.fielding = const FieldingSummary(),
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: intValue(json['rank']),
      playerId: stringValue(json['playerId']),
      playerName: stringValue(json['playerName'], 'Player'),
      playingRole: stringValue(json['playingRole']),
      jerseyNumber: intOrNull(json['jerseyNumber']),
      city: stringValue(json['city']),
      metric: stringValue(json['metric'], 'runs'),
      value: doubleValue(json['value']),
      batting: BattingSummary.fromJson(mapValue(mapValue(json['stats'])['batting'])),
      bowling: BowlingSummary.fromJson(mapValue(mapValue(json['stats'])['bowling'])),
      fielding: FieldingSummary.fromJson(mapValue(mapValue(json['stats'])['fielding'])),
    );
  }

  String get valueDisplay {
    if (metric == 'battingAverage' ||
        metric == 'battingStrikeRate' ||
        metric == 'bowlingEconomy' ||
        metric == 'bowlingAverage') {
      return value.toStringAsFixed(2);
    }
    return intValue(value).toString();
  }
}
