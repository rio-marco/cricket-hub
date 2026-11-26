import 'statistics_values.dart';

class BattingSummary {
  final int innings;
  final int runs;
  final int balls;
  final int fours;
  final int sixes;
  final int notOuts;
  final int dismissals;
  final String highestScore;
  final int highestScoreRuns;
  final int highestNotOut;
  final int thirties;
  final int fifties;
  final int hundreds;
  final int ducks;
  final double average;
  final double strikeRate;

  const BattingSummary({
    this.innings = 0,
    this.runs = 0,
    this.balls = 0,
    this.fours = 0,
    this.sixes = 0,
    this.notOuts = 0,
    this.dismissals = 0,
    this.highestScore = '-',
    this.highestScoreRuns = 0,
    this.highestNotOut = 0,
    this.thirties = 0,
    this.fifties = 0,
    this.hundreds = 0,
    this.ducks = 0,
    this.average = 0,
    this.strikeRate = 0,
  });

  factory BattingSummary.fromJson(Map<String, dynamic> json) {
    return BattingSummary(
      innings: intValue(json['innings']),
      runs: intValue(json['runs']),
      balls: intValue(json['balls']),
      fours: intValue(json['fours']),
      sixes: intValue(json['sixes']),
      notOuts: intValue(json['notOuts']),
      dismissals: intValue(json['dismissals']),
      highestScore: stringValue(json['highestScore'], '-'),
      highestScoreRuns: intValue(json['highestScoreRuns']),
      highestNotOut: intValue(json['highestNotOut']),
      thirties: intValue(json['thirties']),
      fifties: intValue(json['fifties']),
      hundreds: intValue(json['hundreds']),
      ducks: intValue(json['ducks']),
      average: doubleValue(json['average']),
      strikeRate: doubleValue(json['strikeRate']),
    );
  }
}
