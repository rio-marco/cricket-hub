import 'admin_json.dart';

class AdminMatch {
  final String id;
  final String status;
  final String format;
  final String teamAName;
  final String teamBName;
  final String tournamentName;
  final String venue;
  final DateTime? startTime;
  final String scoreSummary;
  final Map<String, dynamic> raw;

  const AdminMatch({
    required this.id,
    this.status = '',
    this.format = '',
    this.teamAName = 'Team A',
    this.teamBName = 'Team B',
    this.tournamentName = '',
    this.venue = '',
    this.startTime,
    this.scoreSummary = '',
    this.raw = const <String, dynamic>{},
  });

  factory AdminMatch.fromJson(dynamic json) {
    final data = AdminJson.entity(json, const <String>['match']);
    final teamA = AdminJson.map(data['teamA']);
    final teamB = AdminJson.map(data['teamB']);
    final tournament = AdminJson.map(data['tournament']);
    final result = AdminJson.map(data['result']);
    return AdminMatch(
      id: AdminJson.entityId(data),
      status: AdminJson.string(data['status']),
      format: AdminJson.string(data['format']),
      teamAName: AdminJson.string(teamA['name'] ?? data['teamAName'], 'Team A'),
      teamBName: AdminJson.string(teamB['name'] ?? data['teamBName'], 'Team B'),
      tournamentName: AdminJson.string(
        tournament['name'] ?? data['tournamentName'],
      ),
      venue: AdminJson.string(data['venue']),
      startTime: AdminJson.date(
        data['startTime'] ?? data['matchDate'] ?? data['scheduledAt'],
      ),
      scoreSummary: AdminJson.string(
        result['description'] ?? result['summary'] ?? data['scoreSummary'],
      ),
      raw: AdminJson.map(data),
    );
  }
}
