import 'package:flutter/material.dart';

/// Toss result information
class TossInfo {
  final dynamic winner; // Team ID or Team Map
  final String? decision; // BAT, BOWL

  const TossInfo({this.winner, this.decision});

  factory TossInfo.fromJson(Map<String, dynamic> json) {
    return TossInfo(
      winner: json['winner'],
      decision: json['decision']?.toString().toUpperCase(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'winner': winner is Map ? (winner as Map)['id'] ?? (winner as Map)['_id'] : winner,
      'decision': decision,
    };
  }

  String get winnerName {
    if (winner is Map) {
      return (winner as Map)['name']?.toString() ?? 'Toss Winner';
    }
    return winner?.toString() ?? '';
  }

  String get summary {
    if (decision == null) return 'Toss completed';
    final choice = decision == 'BAT' ? 'bat first' : 'bowl first';
    return '$winnerName won the toss and elected to $choice';
  }
}

/// Match conclusion outcome
class MatchResultInfo {
  final dynamic winner;
  final String? resultType; // RUNS, WICKETS, TIE, DRAW, NO_RESULT, ABANDONED
  final int? margin;
  final String? description;

  const MatchResultInfo({
    this.winner,
    this.resultType,
    this.margin,
    this.description,
  });

  factory MatchResultInfo.fromJson(Map<String, dynamic> json) {
    return MatchResultInfo(
      winner: json['winner'],
      resultType: json['resultType']?.toString().toUpperCase(),
      margin: json['margin'] is num ? (json['margin'] as num).toInt() : null,
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'winner': winner is Map ? (winner as Map)['id'] ?? (winner as Map)['_id'] : winner,
      if (resultType != null) 'resultType': resultType,
      if (margin != null) 'margin': margin,
      if (description != null) 'description': description,
    };
  }

  String get winnerName {
    if (winner is Map) {
      return (winner as Map)['name']?.toString() ?? 'Winner';
    }
    return winner?.toString() ?? '';
  }
}

/// Match domain entity representing a cricket fixture between two teams.
class Match {
  final String id;
  final String? title;
  final dynamic tournament;
  final dynamic teamA;
  final dynamic teamB;
  final String format; // T10, T20, ODI, CUSTOM
  final int totalOvers;
  final String? ballType; // TENNIS, RED, WHITE
  final String? venue;
  final String? city;
  final DateTime? matchDate;
  final TossInfo? toss;
  final dynamic scorer;
  final String status; // UPCOMING, TOSS, LIVE, COMPLETED, ABANDONED, CANCELLED
  final MatchResultInfo? result;
  final dynamic playerOfMatch;
  final int currentInnings;
  final String? teamAScore; // e.g. "182/4 (20.0)"
  final String? teamBScore; // e.g. "156/9 (18.2)"
  final DateTime? createdAt;

  const Match({
    required this.id,
    this.title,
    this.tournament,
    required this.teamA,
    required this.teamB,
    this.format = 'T20',
    this.totalOvers = 20,
    this.ballType = 'WHITE',
    this.venue,
    this.city,
    this.matchDate,
    this.toss,
    this.scorer,
    this.status = 'UPCOMING',
    this.result,
    this.playerOfMatch,
    this.currentInnings = 1,
    this.teamAScore,
    this.teamBScore,
    this.createdAt,
  });

  /// Factory constructor to parse Match from JSON map.
  factory Match.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    TossInfo? tossInfo;
    if (json['toss'] is Map<String, dynamic>) {
      tossInfo = TossInfo.fromJson(json['toss'] as Map<String, dynamic>);
    }

    MatchResultInfo? resultInfo;
    if (json['result'] is Map<String, dynamic>) {
      resultInfo = MatchResultInfo.fromJson(json['result'] as Map<String, dynamic>);
    }

    return Match(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      title: json['title'] as String?,
      tournament: json['tournament'],
      teamA: json['teamA'],
      teamB: json['teamB'],
      format: (json['format'] as String? ?? 'T20').toUpperCase(),
      totalOvers: json['totalOvers'] is num ? (json['totalOvers'] as num).toInt() : 20,
      ballType: json['ballType']?.toString().toUpperCase(),
      venue: json['venue'] as String?,
      city: json['city'] as String?,
      matchDate: parseDate(json['matchDate'] ?? json['date']),
      toss: tossInfo,
      scorer: json['scorer'],
      status: (json['status'] as String? ?? 'UPCOMING').toUpperCase(),
      result: resultInfo,
      playerOfMatch: json['playerOfMatch'],
      currentInnings: json['currentInnings'] is num ? (json['currentInnings'] as num).toInt() : 1,
      teamAScore: json['teamAScore'] as String? ?? json['scoreA'] as String?,
      teamBScore: json['teamBScore'] as String? ?? json['scoreB'] as String?,
      createdAt: parseDate(json['createdAt']),
    );
  }

  /// Converts match to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (title != null) 'title': title,
      if (tournament != null)
        'tournament': tournament is Map ? (tournament as Map)['id'] ?? (tournament as Map)['_id'] : tournament,
      'teamA': teamA is Map ? (teamA as Map)['id'] ?? (teamA as Map)['_id'] : teamA,
      'teamB': teamB is Map ? (teamB as Map)['id'] ?? (teamB as Map)['_id'] : teamB,
      'format': format,
      'totalOvers': totalOvers,
      if (ballType != null) 'ballType': ballType,
      if (venue != null) 'venue': venue,
      if (city != null) 'city': city,
      if (matchDate != null) 'matchDate': matchDate!.toIso8601String(),
      if (toss != null) 'toss': toss!.toJson(),
      if (scorer != null) 'scorer': scorer,
      'status': status,
      if (result != null) 'result': result!.toJson(),
      if (playerOfMatch != null) 'playerOfMatch': playerOfMatch,
      'currentInnings': currentInnings,
      if (teamAScore != null) 'teamAScore': teamAScore,
      if (teamBScore != null) 'teamBScore': teamBScore,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  /// Creates a copy with updated attributes.
  Match copyWith({
    String? id,
    String? title,
    dynamic tournament,
    dynamic teamA,
    dynamic teamB,
    String? format,
    int? totalOvers,
    String? ballType,
    String? venue,
    String? city,
    DateTime? matchDate,
    TossInfo? toss,
    dynamic scorer,
    String? status,
    MatchResultInfo? result,
    dynamic playerOfMatch,
    int? currentInnings,
    String? teamAScore,
    String? teamBScore,
    DateTime? createdAt,
  }) {
    return Match(
      id: id ?? this.id,
      title: title ?? this.title,
      tournament: tournament ?? this.tournament,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      format: format ?? this.format,
      totalOvers: totalOvers ?? this.totalOvers,
      ballType: ballType ?? this.ballType,
      venue: venue ?? this.venue,
      city: city ?? this.city,
      matchDate: matchDate ?? this.matchDate,
      toss: toss ?? this.toss,
      scorer: scorer ?? this.scorer,
      status: status ?? this.status,
      result: result ?? this.result,
      playerOfMatch: playerOfMatch ?? this.playerOfMatch,
      currentInnings: currentInnings ?? this.currentInnings,
      teamAScore: teamAScore ?? this.teamAScore,
      teamBScore: teamBScore ?? this.teamBScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Convenience Getters
  // ---------------------------------------------------------------------------

  String get teamAName {
    if (teamA is Map) return (teamA as Map)['name']?.toString() ?? 'Team A';
    return teamA?.toString() ?? 'Team A';
  }

  String get teamBName {
    if (teamB is Map) return (teamB as Map)['name']?.toString() ?? 'Team B';
    return teamB?.toString() ?? 'Team B';
  }

  String get teamAShortName {
    if (teamA is Map && (teamA as Map)['shortName'] != null) {
      return (teamA as Map)['shortName'].toString();
    }
    return _generateShortName(teamAName);
  }

  String get teamBShortName {
    if (teamB is Map && (teamB as Map)['shortName'] != null) {
      return (teamB as Map)['shortName'].toString();
    }
    return _generateShortName(teamBName);
  }

  String? get teamALogo {
    if (teamA is Map) return (teamA as Map)['logo']?.toString();
    return null;
  }

  String? get teamBLogo {
    if (teamB is Map) return (teamB as Map)['logo']?.toString();
    return null;
  }

  String? get tournamentName {
    if (tournament is Map) return (tournament as Map)['name']?.toString();
    return null;
  }

  String? get playerOfMatchName {
    if (playerOfMatch is Map) {
      return (playerOfMatch as Map)['name']?.toString() ??
          (playerOfMatch as Map)['playerName']?.toString();
    }
    return playerOfMatch?.toString();
  }

  bool get isLive => status == 'LIVE' || status == 'IN_PROGRESS';
  bool get isUpcoming => status == 'UPCOMING' || status == 'TOSS';
  bool get isCompleted => status == 'COMPLETED';

  Color get statusColor {
    switch (status) {
      case 'LIVE':
      case 'IN_PROGRESS':
        return const Color(0xFFE53935); // Live Red
      case 'TOSS':
        return const Color(0xFFFF8C00); // Amber Orange
      case 'COMPLETED':
        return const Color(0xFF43A047); // Success Green
      case 'CANCELLED':
      case 'ABANDONED':
        return const Color(0xFF757575);
      case 'UPCOMING':
      default:
        return const Color(0xFF1E88E5); // Info Blue
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'LIVE':
      case 'IN_PROGRESS':
        return 'LIVE';
      case 'TOSS':
        return 'TOSS';
      case 'COMPLETED':
        return 'COMPLETED';
      case 'CANCELLED':
        return 'CANCELLED';
      case 'ABANDONED':
        return 'ABANDONED';
      case 'UPCOMING':
      default:
        return 'UPCOMING';
    }
  }

  static String _generateShortName(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length > 1) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name.substring(0, name.length >= 3 ? 3 : name.length).toUpperCase() : 'TM';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Match &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
