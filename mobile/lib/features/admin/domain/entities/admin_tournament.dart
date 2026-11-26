import 'admin_json.dart';

class AdminTournament {
  final String id;
  final String name;
  final String status;
  final String format;
  final int teamCount;
  final int matchCount;
  final String organizerName;
  final DateTime? startDate;
  final Map<String, dynamic> raw;

  const AdminTournament({
    required this.id,
    required this.name,
    this.status = '',
    this.format = '',
    this.teamCount = 0,
    this.matchCount = 0,
    this.organizerName = '',
    this.startDate,
    this.raw = const <String, dynamic>{},
  });

  factory AdminTournament.fromJson(dynamic json) {
    final data = AdminJson.entity(json, const <String>['tournament']);
    final organizer = AdminJson.map(data['organizer']);
    final teams = data['teams'];
    final matches = data['matches'];
    return AdminTournament(
      id: AdminJson.entityId(data),
      name: AdminJson.string(data['name'], 'Unknown tournament'),
      status: AdminJson.string(data['status']),
      format: AdminJson.string(data['format']),
      teamCount: teams is List
          ? teams.length
          : AdminJson.integer(data['teamCount'] ?? data['teamsCount']),
      matchCount: matches is List
          ? matches.length
          : AdminJson.integer(data['matchCount'] ?? data['matchesCount']),
      organizerName: AdminJson.string(
        organizer['name'] ?? data['organizerName'],
      ),
      startDate: AdminJson.date(data['startDate'] ?? data['startsAt']),
      raw: AdminJson.map(data),
    );
  }
}
