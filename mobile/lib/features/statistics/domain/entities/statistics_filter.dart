import 'statistics_values.dart';

class StatisticsFilter {
  final String? tournamentId;
  final int? season;
  final String? format;
  final DateTime? from;
  final DateTime? to;

  const StatisticsFilter({
    this.tournamentId,
    this.season,
    this.format,
    this.from,
    this.to,
  });

  factory StatisticsFilter.fromJson(Map<String, dynamic> json) {
    return StatisticsFilter(
      tournamentId: stringOrNull(json['tournament']),
      season: intOrNull(json['season']),
      format: stringOrNull(json['format']),
      from: DateTime.tryParse(stringValue(json['from'])),
      to: DateTime.tryParse(stringValue(json['to'])),
    );
  }

  StatisticsFilter copyWith({
    String? tournamentId,
    bool clearTournament = false,
    int? season,
    bool clearSeason = false,
    String? format,
    bool clearFormat = false,
    DateTime? from,
    bool clearFrom = false,
    DateTime? to,
    bool clearTo = false,
  }) {
    return StatisticsFilter(
      tournamentId: clearTournament ? null : tournamentId ?? this.tournamentId,
      season: clearSeason ? null : season ?? this.season,
      format: clearFormat ? null : format ?? this.format,
      from: clearFrom ? null : from ?? this.from,
      to: clearTo ? null : to ?? this.to,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    return <String, dynamic>{
      if (tournamentId != null && tournamentId!.isNotEmpty) 'tournament': tournamentId,
      if (season != null) 'season': season,
      if (format != null && format!.isNotEmpty) 'format': format,
      if (from != null) 'from': from!.toIso8601String(),
      if (to != null) 'to': to!.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatisticsFilter &&
          tournamentId == other.tournamentId &&
          season == other.season &&
          format == other.format &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => Object.hash(tournamentId, season, format, from, to);
}
