import '../../../teams/domain/entities/team.dart';

/// Lightweight match representation for live feeds, dashboard, and match preview cards.
class DashboardMatch {
  final String id;
  final String teamAName;
  final String? teamALogo;
  final String teamBName;
  final String? teamBLogo;
  final int teamARuns;
  final int teamAWickets;
  final double teamAOvers;
  final int teamBRuns;
  final int teamBWickets;
  final double teamBOvers;
  final String status; // 'LIVE', 'UPCOMING', 'COMPLETED'
  final String statusText;
  final String? tournamentName;
  final String? venue;
  final String format; // 'T20', 'T10', 'ODI'
  final DateTime? startTime;

  const DashboardMatch({
    required this.id,
    required this.teamAName,
    this.teamALogo,
    required this.teamBName,
    this.teamBLogo,
    this.teamARuns = 0,
    this.teamAWickets = 0,
    this.teamAOvers = 0.0,
    this.teamBRuns = 0,
    this.teamBWickets = 0,
    this.teamBOvers = 0.0,
    this.status = 'LIVE',
    required this.statusText,
    this.tournamentName,
    this.venue,
    this.format = 'T20',
    this.startTime,
  });

  factory DashboardMatch.fromJson(Map<String, dynamic> json) {
    String teamAName = 'Team A';
    String? teamALogo;
    String? teamAId;
    if (json['teamA'] is Map) {
      final teamA = json['teamA'] as Map;
      teamAName = teamA['name']?.toString() ?? 'Team A';
      teamALogo = teamA['logo']?.toString();
      teamAId = teamA['_id']?.toString() ?? teamA['id']?.toString();
    } else if (json['teamAName'] != null) {
      teamAName = json['teamAName'].toString();
      teamALogo = json['teamALogo']?.toString();
    }

    String teamBName = 'Team B';
    String? teamBLogo;
    String? teamBId;
    if (json['teamB'] is Map) {
      final teamB = json['teamB'] as Map;
      teamBName = teamB['name']?.toString() ?? 'Team B';
      teamBLogo = teamB['logo']?.toString();
      teamBId = teamB['_id']?.toString() ?? teamB['id']?.toString();
    } else if (json['teamBName'] != null) {
      teamBName = json['teamBName'].toString();
      teamBLogo = json['teamBLogo']?.toString();
    }

    int aRuns = json['teamARuns'] as int? ?? 0;
    int aWickets = json['teamAWickets'] as int? ?? 0;
    double aOvers = (json['teamAOvers'] as num?)?.toDouble() ?? 0.0;
    int bRuns = json['teamBRuns'] as int? ?? 0;
    int bWickets = json['teamBWickets'] as int? ?? 0;
    double bOvers = (json['teamBOvers'] as num?)?.toDouble() ?? 0.0;

    final rawInnings = json['innings'] is List
        ? json['innings'] as List
        : (json['activeInnings'] is Map ? [json['activeInnings']] : const []);
    for (var index = 0; index < rawInnings.length; index++) {
      final entry = rawInnings[index];
      if (entry is! Map) continue;
      final battingTeam = entry['battingTeam'];
      final battingId = battingTeam is Map
          ? battingTeam['_id']?.toString() ?? battingTeam['id']?.toString()
          : null;
      final battingName =
          battingTeam is Map ? battingTeam['name']?.toString() : null;
      final belongsToA = battingId != null && teamAId != null
          ? battingId == teamAId
          : (battingName != null ? battingName == teamAName : index == 0);
      final belongsToB = battingId != null && teamBId != null
          ? battingId == teamBId
          : !belongsToA;

      final runs = (entry['totalRuns'] as num?)?.toInt() ?? 0;
      final wickets = (entry['totalWickets'] as num?)?.toInt() ?? 0;
      final overs =
          ((entry['totalOvers'] ?? entry['overs']) as num?)?.toDouble() ?? 0.0;
      if (belongsToA && !belongsToB) {
        aRuns = runs;
        aWickets = wickets;
        aOvers = overs;
      } else {
        bRuns = runs;
        bWickets = wickets;
        bOvers = overs;
      }
    }

    final status = (json['status'] as String? ?? 'UPCOMING').toUpperCase();
    final result = json['result'] is Map ? json['result'] as Map : null;
    final winner = result?['winner'];
    final winnerName = winner is Map ? winner['name']?.toString() : null;
    final margin = result?['margin'];
    String statusText;
    if (status == 'COMPLETED') {
      final description = result?['description']?.toString();
      if (description != null && description.isNotEmpty) {
        statusText = description;
      } else if (winnerName != null) {
        statusText = margin != null
            ? '$winnerName won by $margin'
            : '$winnerName won';
      } else {
        statusText = 'Match completed';
      }
    } else if (status == 'UPCOMING') {
      statusText = 'Scheduled';
    } else {
      statusText = 'Match in progress';
    }

    return DashboardMatch(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      teamAName: teamAName,
      teamALogo: teamALogo,
      teamBName: teamBName,
      teamBLogo: teamBLogo,
      teamARuns: aRuns,
      teamAWickets: aWickets,
      teamAOvers: aOvers,
      teamBRuns: bRuns,
      teamBWickets: bWickets,
      teamBOvers: bOvers,
      status: status,
      statusText: statusText,
      tournamentName: json['tournament'] is Map
          ? (json['tournament'] as Map)['name']?.toString()
          : json['tournamentName']?.toString(),
      venue: json['venue']?.toString(),
      format: json['format']?.toString() ?? 'T20',
      startTime: json['matchDate'] != null
          ? DateTime.tryParse(json['matchDate'].toString())
          : (json['startTime'] != null
              ? DateTime.tryParse(json['startTime'].toString())
              : null),
    );
  }

  bool get isLive => status == 'LIVE';
  bool get isUpcoming => status == 'UPCOMING';
  bool get isCompleted => status == 'COMPLETED';
}

/// Aggregated dashboard statistics and highlights payload.
class DashboardData {
  final int totalMatches;
  final int totalTeams;
  final int totalTournaments;
  final int totalPlayers;
  final List<DashboardMatch> liveMatches;
  final List<DashboardMatch> upcomingMatches;
  final List<DashboardMatch> recentResults;
  final List<Team> myTeams;

  const DashboardData({
    this.totalMatches = 0,
    this.totalTeams = 0,
    this.totalTournaments = 0,
    this.totalPlayers = 0,
    this.liveMatches = const [],
    this.upcomingMatches = const [],
    this.recentResults = const [],
    this.myTeams = const [],
  });
}
