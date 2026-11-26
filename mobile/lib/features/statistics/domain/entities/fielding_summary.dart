import 'statistics_values.dart';

class FieldingSummary {
  final int catches;
  final int runOuts;
  final int stumpings;
  final int totalDismissals;

  const FieldingSummary({
    this.catches = 0,
    this.runOuts = 0,
    this.stumpings = 0,
    this.totalDismissals = 0,
  });

  factory FieldingSummary.fromJson(Map<String, dynamic> json) {
    return FieldingSummary(
      catches: intValue(json['catches']),
      runOuts: intValue(json['runOuts']),
      stumpings: intValue(json['stumpings']),
      totalDismissals: intValue(json['totalDismissals']),
    );
  }
}
