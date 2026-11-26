import 'statistics_values.dart';

class BowlingSummary {
  final int innings;
  final int balls;
  final double overs;
  final String oversLabel;
  final int maidens;
  final int runsConceded;
  final int wickets;
  final int dotBalls;
  final int wides;
  final int noBalls;
  final String bestBowling;
  final int bestBowlingWickets;
  final int bestBowlingRuns;
  final int fourWicketHauls;
  final int fiveWicketHauls;
  final double average;
  final double economy;
  final double strikeRate;

  const BowlingSummary({
    this.innings = 0,
    this.balls = 0,
    this.overs = 0,
    this.oversLabel = '0.0',
    this.maidens = 0,
    this.runsConceded = 0,
    this.wickets = 0,
    this.dotBalls = 0,
    this.wides = 0,
    this.noBalls = 0,
    this.bestBowling = '-',
    this.bestBowlingWickets = 0,
    this.bestBowlingRuns = 0,
    this.fourWicketHauls = 0,
    this.fiveWicketHauls = 0,
    this.average = 0,
    this.economy = 0,
    this.strikeRate = 0,
  });

  factory BowlingSummary.fromJson(Map<String, dynamic> json) {
    return BowlingSummary(
      innings: intValue(json['innings']),
      balls: intValue(json['balls']),
      overs: doubleValue(json['overs']),
      oversLabel: stringValue(json['oversLabel'], '0.0'),
      maidens: intValue(json['maidens']),
      runsConceded: intValue(json['runsConceded']),
      wickets: intValue(json['wickets']),
      dotBalls: intValue(json['dotBalls']),
      wides: intValue(json['wides']),
      noBalls: intValue(json['noBalls']),
      bestBowling: stringValue(json['bestBowling'], '-'),
      bestBowlingWickets: intValue(json['bestBowlingWickets']),
      bestBowlingRuns: intValue(json['bestBowlingRuns']),
      fourWicketHauls: intValue(json['fourWicketHauls']),
      fiveWicketHauls: intValue(json['fiveWicketHauls']),
      average: doubleValue(json['average']),
      economy: doubleValue(json['economy']),
      strikeRate: doubleValue(json['strikeRate']),
    );
  }
}
