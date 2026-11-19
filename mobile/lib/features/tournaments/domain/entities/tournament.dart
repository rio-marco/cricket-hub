import 'package:flutter/material.dart';

/// Tournament domain entity representing a cricket competition.
class Tournament {
  final String id;
  final String name;
  final String? description;
  final String? logo;
  final String? banner;
  final dynamic organizer;
  final String format; // LEAGUE, KNOCKOUT, LEAGUE_KNOCKOUT
  final String ballType; // TENNIS, RED, WHITE
  final String matchFormat; // T10, T20, ODI, CUSTOM
  final int? customOvers;
  final List<String> venues;
  final String? city;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? registrationStartDate;
  final DateTime? registrationEndDate;
  final int maxTeams;
  final int maxPlayersPerTeam;
  final String? rules;
  final double registrationFee;
  final String status; // DRAFT, REGISTRATION_OPEN, REGISTRATION_CLOSED, IN_PROGRESS, COMPLETED, CANCELLED
  final int teamsCount;
  final DateTime? createdAt;

  const Tournament({
    required this.id,
    required this.name,
    this.description,
    this.logo,
    this.banner,
    this.organizer,
    this.format = 'LEAGUE',
    this.ballType = 'TENNIS',
    this.matchFormat = 'T20',
    this.customOvers,
    this.venues = const [],
    this.city,
    required this.startDate,
    required this.endDate,
    this.registrationStartDate,
    this.registrationEndDate,
    this.maxTeams = 8,
    this.maxPlayersPerTeam = 15,
    this.rules,
    this.registrationFee = 0.0,
    this.status = 'DRAFT',
    this.teamsCount = 0,
    this.createdAt,
  });

  /// Factory constructor to parse tournament from JSON map.
  factory Tournament.fromJson(Map<String, dynamic> json) {
    // Parse venues list
    List<String> venuesList = [];
    if (json['venues'] is List) {
      venuesList = (json['venues'] as List).map((v) => v.toString()).toList();
    } else if (json['venue'] != null && json['venue'].toString().isNotEmpty) {
      venuesList = [json['venue'].toString()];
    }

    // Helper for DateTime parsing
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val == null) return fallback;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString()) ?? fallback;
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    final now = DateTime.now();

    return Tournament(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Tournament',
      description: json['description'] as String?,
      logo: json['logo'] as String?,
      banner: json['banner'] as String?,
      organizer: json['organizer'],
      format: (json['format'] as String? ?? 'LEAGUE').toUpperCase(),
      ballType: (json['ballType'] as String? ?? 'TENNIS').toUpperCase(),
      matchFormat: (json['matchFormat'] as String? ?? 'T20').toUpperCase(),
      customOvers: json['customOvers'] is num ? (json['customOvers'] as num).toInt() : null,
      venues: venuesList,
      city: json['city'] as String?,
      startDate: parseDate(json['startDate'], now),
      endDate: parseDate(json['endDate'], now.add(const Duration(days: 7))),
      registrationStartDate: parseNullableDate(json['registrationStartDate']),
      registrationEndDate: parseNullableDate(json['registrationEndDate']),
      maxTeams: json['maxTeams'] is num ? (json['maxTeams'] as num).toInt() : 8,
      maxPlayersPerTeam: json['maxPlayersPerTeam'] is num ? (json['maxPlayersPerTeam'] as num).toInt() : 15,
      rules: json['rules'] as String?,
      registrationFee: json['registrationFee'] is num ? (json['registrationFee'] as num).toDouble() : 0.0,
      status: (json['status'] as String? ?? 'DRAFT').toUpperCase(),
      teamsCount: json['teamsCount'] is num
          ? (json['teamsCount'] as num).toInt()
          : (json['teams'] is List ? (json['teams'] as List).length : 0),
      createdAt: parseNullableDate(json['createdAt']),
    );
  }

  /// Converts tournament instance to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (logo != null) 'logo': logo,
      if (banner != null) 'banner': banner,
      if (organizer != null) 'organizer': organizer,
      'format': format,
      'ballType': ballType,
      'matchFormat': matchFormat,
      if (customOvers != null) 'customOvers': customOvers,
      'venues': venues,
      if (city != null) 'city': city,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      if (registrationStartDate != null)
        'registrationStartDate': registrationStartDate!.toIso8601String(),
      if (registrationEndDate != null)
        'registrationEndDate': registrationEndDate!.toIso8601String(),
      'maxTeams': maxTeams,
      'maxPlayersPerTeam': maxPlayersPerTeam,
      if (rules != null) 'rules': rules,
      'registrationFee': registrationFee,
      'status': status,
      'teamsCount': teamsCount,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  /// Creates a copy of tournament with updated fields.
  Tournament copyWith({
    String? id,
    String? name,
    String? description,
    String? logo,
    String? banner,
    dynamic organizer,
    String? format,
    String? ballType,
    String? matchFormat,
    int? customOvers,
    List<String>? venues,
    String? city,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? registrationStartDate,
    DateTime? registrationEndDate,
    int? maxTeams,
    int? maxPlayersPerTeam,
    String? rules,
    double? registrationFee,
    String? status,
    int? teamsCount,
    DateTime? createdAt,
  }) {
    return Tournament(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logo: logo ?? this.logo,
      banner: banner ?? this.banner,
      organizer: organizer ?? this.organizer,
      format: format ?? this.format,
      ballType: ballType ?? this.ballType,
      matchFormat: matchFormat ?? this.matchFormat,
      customOvers: customOvers ?? this.customOvers,
      venues: venues ?? this.venues,
      city: city ?? this.city,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      registrationStartDate: registrationStartDate ?? this.registrationStartDate,
      registrationEndDate: registrationEndDate ?? this.registrationEndDate,
      maxTeams: maxTeams ?? this.maxTeams,
      maxPlayersPerTeam: maxPlayersPerTeam ?? this.maxPlayersPerTeam,
      rules: rules ?? this.rules,
      registrationFee: registrationFee ?? this.registrationFee,
      status: status ?? this.status,
      teamsCount: teamsCount ?? this.teamsCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Convenience Getters
  // ---------------------------------------------------------------------------

  /// Friendly organizer name helper
  String get organizerName {
    if (organizer == null) return 'Cricket Hub Admin';
    if (organizer is Map) {
      return (organizer as Map)['name']?.toString() ?? 'Cricket Hub Admin';
    }
    return organizer.toString();
  }

  /// Whether tournament is currently in progress
  bool get isInProgress => status == 'IN_PROGRESS';

  /// Whether registration is open
  bool get isRegistrationOpen => status == 'REGISTRATION_OPEN';

  /// Whether tournament is completed
  bool get isCompleted => status == 'COMPLETED';

  /// Human-friendly display status
  String get statusDisplayName {
    switch (status) {
      case 'REGISTRATION_OPEN':
        return 'Registration Open';
      case 'REGISTRATION_CLOSED':
        return 'Registration Closed';
      case 'IN_PROGRESS':
        return 'Live / In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      case 'DRAFT':
      default:
        return 'Upcoming Draft';
    }
  }

  /// Human-friendly format display
  String get formatDisplayName {
    switch (format) {
      case 'LEAGUE':
        return 'Round Robin League';
      case 'KNOCKOUT':
        return 'Single Knockout';
      case 'LEAGUE_KNOCKOUT':
        return 'League + Knockout';
      default:
        return format;
    }
  }

  /// Formatted date range (e.g. "12 Oct - 20 Oct 2026")
  String get dateRangeFormatted {
    final startMonth = _monthName(startDate.month);
    final endMonth = _monthName(endDate.month);
    if (startDate.year == endDate.year) {
      if (startDate.month == endDate.month) {
        return '${startDate.day} - ${endDate.day} $startMonth ${startDate.year}';
      }
      return '${startDate.day} $startMonth - ${endDate.day} $endMonth ${startDate.year}';
    }
    return '${startDate.day} $startMonth ${startDate.year} - ${endDate.day} $endMonth ${endDate.year}';
  }

  static String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  /// Status badge color
  Color get statusColor {
    switch (status) {
      case 'IN_PROGRESS':
        return const Color(0xFFE53935); // Live Red
      case 'REGISTRATION_OPEN':
        return const Color(0xFF43A047); // Success Green
      case 'REGISTRATION_CLOSED':
        return const Color(0xFFFB8C00); // Warning Orange
      case 'COMPLETED':
        return const Color(0xFF1E88E5); // Info Blue
      case 'CANCELLED':
        return const Color(0xFF757575); // Grey
      case 'DRAFT':
      default:
        return const Color(0xFFFF8C00);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tournament &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
