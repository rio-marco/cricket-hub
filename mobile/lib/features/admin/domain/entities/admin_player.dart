import 'admin_json.dart';

class AdminPlayer {
  final String id;
  final String name;
  final String role;
  final String teamName;
  final String userId;
  final int matchesPlayed;
  final int runs;
  final int wickets;
  final Map<String, dynamic> raw;

  const AdminPlayer({
    required this.id,
    required this.name,
    this.role = '',
    this.teamName = '',
    this.userId = '',
    this.matchesPlayed = 0,
    this.runs = 0,
    this.wickets = 0,
    this.raw = const <String, dynamic>{},
  });

  factory AdminPlayer.fromJson(dynamic json) {
    final data = AdminJson.entity(json, const <String>['player']);
    final user = AdminJson.map(data['user']);
    final team = AdminJson.map(data['team']);
    final stats = AdminJson.map(data['stats'] ?? data['statistics']);
    return AdminPlayer(
      id: AdminJson.entityId(data),
      name: AdminJson.string(
        user['name'] ?? data['name'] ?? data['playerName'],
        'Unknown player',
      ),
      role: AdminJson.string(data['role'] ?? data['playerRole']),
      teamName: AdminJson.string(team['name'] ?? data['teamName']),
      userId: AdminJson.entityId(user) == ''
          ? AdminJson.string(data['userId'])
          : AdminJson.entityId(user),
      matchesPlayed: AdminJson.integer(
        stats['matches'] ?? stats['matchesPlayed'] ?? data['matchesPlayed'],
      ),
      runs: AdminJson.integer(stats['runs'] ?? data['runs']),
      wickets: AdminJson.integer(stats['wickets'] ?? data['wickets']),
      raw: AdminJson.map(data),
    );
  }
}
