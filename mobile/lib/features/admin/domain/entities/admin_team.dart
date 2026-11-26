import 'admin_json.dart';

class AdminTeam {
  final String id;
  final String name;
  final String shortName;
  final String status;
  final String ownerName;
  final int memberCount;
  final String tournamentName;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;

  const AdminTeam({
    required this.id,
    required this.name,
    this.shortName = '',
    this.status = '',
    this.ownerName = '',
    this.memberCount = 0,
    this.tournamentName = '',
    this.createdAt,
    this.raw = const <String, dynamic>{},
  });

  factory AdminTeam.fromJson(dynamic json) {
    final data = AdminJson.entity(json, const <String>['team']);
    final owner = AdminJson.map(data['owner']);
    final tournament = AdminJson.map(data['tournament']);
    final members = data['members'];
    return AdminTeam(
      id: AdminJson.entityId(data),
      name: AdminJson.string(data['name'], 'Unknown team'),
      shortName: AdminJson.string(data['shortName'] ?? data['short_name']),
      status: AdminJson.string(data['status']),
      ownerName: AdminJson.string(owner['name'] ?? data['ownerName']),
      memberCount: members is List
          ? members.length
          : AdminJson.integer(data['memberCount'] ?? data['membersCount']),
      tournamentName: AdminJson.string(
        tournament['name'] ?? data['tournamentName'],
      ),
      createdAt: AdminJson.date(data['createdAt'] ?? data['created_at']),
      raw: AdminJson.map(data),
    );
  }
}
