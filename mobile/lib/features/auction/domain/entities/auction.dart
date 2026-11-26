class Auction {
  final String id;
  final String name;
  final String? tournamentId;
  final String? tournamentName;
  final List<String> teams;
  final List<String> teamNames;
  final double purseAmount;
  final double basePrice;
  final int minBidIncrement;
  final int maxSquadSize;
  final int minSquadSize;
  final List<String> playerCategories;
  final String status;
  final String? currentPlayerId;
  final int stateVersion;
  final int nextSequence;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? createdAt;
  final int playerCount;
  final int soldCount;

  const Auction({
    required this.id,
    required this.name,
    this.tournamentId,
    this.tournamentName,
    this.teams = const [],
    this.teamNames = const [],
    required this.purseAmount,
    this.basePrice = 0,
    this.minBidIncrement = 0,
    this.maxSquadSize = 0,
    this.minSquadSize = 0,
    this.playerCategories = const [],
    this.status = 'DRAFT',
    this.currentPlayerId,
    this.stateVersion = 0,
    this.nextSequence = 1,
    this.startedAt,
    this.endedAt,
    this.createdAt,
    this.playerCount = 0,
    this.soldCount = 0,
  });

  bool get isLive => status == 'LIVE';

  bool get isPaused => status == 'PAUSED';

  bool get isCompleted => status == 'COMPLETED';

  bool get canAcceptBids => isLive;

  String get statusLabel {
    final normalized = status.toLowerCase();
    if (normalized.isEmpty) return 'DRAFT';
    return normalized[0].toUpperCase() + normalized.substring(1);
  }
}
