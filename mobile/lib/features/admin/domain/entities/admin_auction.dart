import 'admin_json.dart';

class AdminAuction {
  final String id;
  final String name;
  final String status;
  final String tournamentName;
  final double purseAmount;
  final int teamCount;
  final int playerCount;
  final int stateVersion;
  final Map<String, dynamic> raw;

  const AdminAuction({
    required this.id,
    required this.name,
    this.status = '',
    this.tournamentName = '',
    this.purseAmount = 0,
    this.teamCount = 0,
    this.playerCount = 0,
    this.stateVersion = 0,
    this.raw = const <String, dynamic>{},
  });

  factory AdminAuction.fromJson(dynamic json) {
    final data = AdminJson.entity(json, const <String>['auction']);
    final tournament = AdminJson.map(data['tournament']);
    final teams = data['teams'];
    final players = data['players'];
    final counts = AdminJson.map(data['counts']);
    return AdminAuction(
      id: AdminJson.entityId(data),
      name: AdminJson.string(data['name'], 'Unknown auction'),
      status: AdminJson.string(data['status']),
      tournamentName: AdminJson.string(
        tournament['name'] ?? data['tournamentName'],
      ),
      purseAmount: AdminJson.number(data['purseAmount'] ?? data['totalPurse']),
      teamCount: teams is List
          ? teams.length
          : AdminJson.integer(
              counts['totalTeams'] ?? data['teamCount'] ?? data['teamsCount'],
            ),
      playerCount: players is List
          ? players.length
          : AdminJson.integer(
              counts['totalPlayers'] ??
                  data['playerCount'] ??
                  data['playersCount'],
            ),
      stateVersion: AdminJson.integer(
        data['stateVersion'] ?? counts['stateVersion'],
      ),
      raw: AdminJson.map(data),
    );
  }
}
