import '../../domain/entities/tournament.dart';

/// Tournament data model extending domain [Tournament] entity with JSON serialization.
class TournamentModel extends Tournament {
  const TournamentModel({
    required super.id,
    required super.name,
    super.description,
    super.logo,
    super.banner,
    super.organizer,
    super.format = 'LEAGUE',
    super.ballType = 'TENNIS',
    super.matchFormat = 'T20',
    super.customOvers,
    super.venues = const [],
    super.city,
    required super.startDate,
    required super.endDate,
    super.registrationStartDate,
    super.registrationEndDate,
    super.maxTeams = 8,
    super.maxPlayersPerTeam = 15,
    super.rules,
    super.registrationFee = 0.0,
    super.status = 'DRAFT',
    super.teamsCount = 0,
    super.createdAt,
  });

  /// Factory constructor to parse [TournamentModel] from API JSON map.
  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    // Handle unwrapping if nested inside a "tournament" or "data" key
    final map = json.containsKey('tournament') && json['tournament'] is Map<String, dynamic>
        ? json['tournament'] as Map<String, dynamic>
        : (json.containsKey('data') && json['data'] is Map<String, dynamic> && !json.containsKey('name')
            ? json['data'] as Map<String, dynamic>
            : json);

    // Parse venues
    List<String> venuesList = [];
    if (map['venues'] is List) {
      venuesList = (map['venues'] as List).map((v) => v.toString()).toList();
    } else if (map['venue'] != null && map['venue'].toString().isNotEmpty) {
      venuesList = [map['venue'].toString()];
    }

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

    return TournamentModel(
      id: map['id'] as String? ?? map['_id'] as String? ?? '',
      name: map['name'] as String? ?? 'Cricket Tournament',
      description: map['description'] as String?,
      logo: map['logo'] as String?,
      banner: map['banner'] as String?,
      organizer: map['organizer'],
      format: (map['format'] as String? ?? 'LEAGUE').toUpperCase(),
      ballType: (map['ballType'] as String? ?? 'TENNIS').toUpperCase(),
      matchFormat: (map['matchFormat'] as String? ?? 'T20').toUpperCase(),
      customOvers: map['customOvers'] is num ? (map['customOvers'] as num).toInt() : null,
      venues: venuesList,
      city: map['city'] as String?,
      startDate: parseDate(map['startDate'], now),
      endDate: parseDate(map['endDate'], now.add(const Duration(days: 7))),
      registrationStartDate: parseNullableDate(map['registrationStartDate']),
      registrationEndDate: parseNullableDate(map['registrationEndDate']),
      maxTeams: map['maxTeams'] is num ? (map['maxTeams'] as num).toInt() : 8,
      maxPlayersPerTeam: map['maxPlayersPerTeam'] is num ? (map['maxPlayersPerTeam'] as num).toInt() : 15,
      rules: map['rules'] as String?,
      registrationFee: map['registrationFee'] is num ? (map['registrationFee'] as num).toDouble() : 0.0,
      status: (map['status'] as String? ?? 'DRAFT').toUpperCase(),
      teamsCount: map['teamsCount'] is num
          ? (map['teamsCount'] as num).toInt()
          : (map['totalRegisteredTeams'] is num
              ? (map['totalRegisteredTeams'] as num).toInt()
              : (map['approvedTeamsCount'] is num
                  ? (map['approvedTeamsCount'] as num).toInt()
                  : (map['teams'] is List ? (map['teams'] as List).length : 0))),
      createdAt: parseNullableDate(map['createdAt']),
    );
  }

  /// Factory constructor to convert domain [Tournament] entity to [TournamentModel].
  factory TournamentModel.fromEntity(Tournament entity) {
    return TournamentModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      logo: entity.logo,
      banner: entity.banner,
      organizer: entity.organizer,
      format: entity.format,
      ballType: entity.ballType,
      matchFormat: entity.matchFormat,
      customOvers: entity.customOvers,
      venues: entity.venues,
      city: entity.city,
      startDate: entity.startDate,
      endDate: entity.endDate,
      registrationStartDate: entity.registrationStartDate,
      registrationEndDate: entity.registrationEndDate,
      maxTeams: entity.maxTeams,
      maxPlayersPerTeam: entity.maxPlayersPerTeam,
      rules: entity.rules,
      registrationFee: entity.registrationFee,
      status: entity.status,
      teamsCount: entity.teamsCount,
      createdAt: entity.createdAt,
    );
  }

  /// Converts model back to domain [Tournament] entity.
  Tournament toEntity() => this;

  @override
  TournamentModel copyWith({
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
    return TournamentModel(
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
}
