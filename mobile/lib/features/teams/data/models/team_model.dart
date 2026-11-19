import '../../domain/entities/team.dart';

/// Team data model extending domain [Team] entity with serialization.
class TeamModel extends Team {
  const TeamModel({
    required super.id,
    required super.name,
    super.logo,
    super.description,
    super.location,
    required super.owner,
    super.ownerName,
    super.captain,
    super.captainName,
    super.viceCaptain,
    super.viceCaptainName,
    super.wicketkeeper,
    super.wicketkeeperName,
    super.isActive = true,
    super.memberCount = 0,
    super.totalMatches = 0,
    super.wonMatches = 0,
    super.lostMatches = 0,
    super.createdAt,
  });

  /// Factory constructor to parse [TeamModel] from API JSON map
  factory TeamModel.fromJson(Map<String, dynamic> json) {
    // Check if nested in 'team'
    final map = json.containsKey('team') && json['team'] is Map<String, dynamic>
        ? json['team'] as Map<String, dynamic>
        : json;

    final baseTeam = Team.fromJson(map);

    return TeamModel(
      id: baseTeam.id,
      name: baseTeam.name,
      logo: baseTeam.logo,
      description: baseTeam.description,
      location: baseTeam.location,
      owner: baseTeam.owner,
      ownerName: baseTeam.ownerName,
      captain: baseTeam.captain,
      captainName: baseTeam.captainName,
      viceCaptain: baseTeam.viceCaptain,
      viceCaptainName: baseTeam.viceCaptainName,
      wicketkeeper: baseTeam.wicketkeeper,
      wicketkeeperName: baseTeam.wicketkeeperName,
      isActive: baseTeam.isActive,
      memberCount: baseTeam.memberCount,
      totalMatches: baseTeam.totalMatches,
      wonMatches: baseTeam.wonMatches,
      lostMatches: baseTeam.lostMatches,
      createdAt: baseTeam.createdAt,
    );
  }

  /// Factory constructor to convert domain [Team] to [TeamModel]
  factory TeamModel.fromEntity(Team entity) {
    return TeamModel(
      id: entity.id,
      name: entity.name,
      logo: entity.logo,
      description: entity.description,
      location: entity.location,
      owner: entity.owner,
      ownerName: entity.ownerName,
      captain: entity.captain,
      captainName: entity.captainName,
      viceCaptain: entity.viceCaptain,
      viceCaptainName: entity.viceCaptainName,
      wicketkeeper: entity.wicketkeeper,
      wicketkeeperName: entity.wicketkeeperName,
      isActive: entity.isActive,
      memberCount: entity.memberCount,
      totalMatches: entity.totalMatches,
      wonMatches: entity.wonMatches,
      lostMatches: entity.lostMatches,
      createdAt: entity.createdAt,
    );
  }

  /// Returns domain [Team] instance
  Team toEntity() {
    return Team(
      id: id,
      name: name,
      logo: logo,
      description: description,
      location: location,
      owner: owner,
      ownerName: ownerName,
      captain: captain,
      captainName: captainName,
      viceCaptain: viceCaptain,
      viceCaptainName: viceCaptainName,
      wicketkeeper: wicketkeeper,
      wicketkeeperName: wicketkeeperName,
      isActive: isActive,
      memberCount: memberCount,
      totalMatches: totalMatches,
      wonMatches: wonMatches,
      lostMatches: lostMatches,
      createdAt: createdAt,
    );
  }

  @override
  TeamModel copyWith({
    String? id,
    String? name,
    String? logo,
    String? description,
    String? location,
    String? owner,
    String? ownerName,
    String? captain,
    String? captainName,
    String? viceCaptain,
    String? viceCaptainName,
    String? wicketkeeper,
    String? wicketkeeperName,
    bool? isActive,
    int? memberCount,
    int? totalMatches,
    int? wonMatches,
    int? lostMatches,
    DateTime? createdAt,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      description: description ?? this.description,
      location: location ?? this.location,
      owner: owner ?? this.owner,
      ownerName: ownerName ?? this.ownerName,
      captain: captain ?? this.captain,
      captainName: captainName ?? this.captainName,
      viceCaptain: viceCaptain ?? this.viceCaptain,
      viceCaptainName: viceCaptainName ?? this.viceCaptainName,
      wicketkeeper: wicketkeeper ?? this.wicketkeeper,
      wicketkeeperName: wicketkeeperName ?? this.wicketkeeperName,
      isActive: isActive ?? this.isActive,
      memberCount: memberCount ?? this.memberCount,
      totalMatches: totalMatches ?? this.totalMatches,
      wonMatches: wonMatches ?? this.wonMatches,
      lostMatches: lostMatches ?? this.lostMatches,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
