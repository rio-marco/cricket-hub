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
    // Determine Team A info
    String teamAName = 'Team A';
    String? teamALogo;
    if (json['teamA'] is Map) {
      teamAName = (json['teamA'] as Map)['name']?.toString() ?? 'Team A';
      teamALogo = (json['teamA'] as Map)['logo']?.toString();
    } else if (json['teamAName'] != null) {
      teamAName = json['teamAName'].toString();
      teamALogo = json['teamALogo']?.toString();
    }

    // Determine Team B info
    String teamBName = 'Team B';
    String? teamBLogo;
    if (json['teamB'] is Map) {
      teamBName = (json['teamB'] as Map)['name']?.toString() ?? 'Team B';
      teamBLogo = (json['teamB'] as Map)['logo']?.toString();
    } else if (json['teamBName'] != null) {
      teamBName = json['teamBName'].toString();
      teamBLogo = json['teamBLogo']?.toString();
    }

    // Score details
    int aRuns = json['teamARuns'] as int? ?? 0;
    int aWickets = json['teamAWickets'] as int? ?? 0;
    double aOvers = (json['teamAOvers'] as num?)?.toDouble() ?? 0.0;
    int bRuns = json['teamBRuns'] as int? ?? 0;
    int bWickets = json['teamBWickets'] as int? ?? 0;
    double bOvers = (json['teamBOvers'] as num?)?.toDouble() ?? 0.0;

    // Handle innings if available
    if (json['innings'] is List && (json['innings'] as List).isNotEmpty) {
      final inngs = json['innings'] as List;
      if (inngs.isNotEmpty && inngs[0] is Map) {
        aRuns = inngs[0]['totalRuns'] as int? ?? aRuns;
        aWickets = inngs[0]['totalWickets'] as int? ?? aWickets;
        aOvers = (inngs[0]['overs'] as num?)?.toDouble() ?? aOvers;
      }
      if (inngs.length > 1 && inngs[1] is Map) {
        bRuns = inngs[1]['totalRuns'] as int? ?? bRuns;
        bWickets = inngs[1]['totalWickets'] as int? ?? bWickets;
        bOvers = (inngs[1]['overs'] as num?)?.toDouble() ?? bOvers;
      }
    }

    return DashboardMatch(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
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
      status: (json['status'] as String? ?? 'LIVE').toUpperCase(),
      statusText: json['statusText'] as String? ??
          json['summary'] as String? ??
          'Match in progress',
      tournamentName: json['tournament'] is Map
          ? (json['tournament'] as Map)['name']?.toString()
          : json['tournamentName']?.toString(),
      venue: json['venue']?.toString(),
      format: json['format']?.toString() ?? 'T20',
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'].toString())
          : null,
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
