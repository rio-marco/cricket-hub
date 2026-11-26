class AuctionTeam {
  final String id;
  final String auctionId;
  final String teamId;
  final String? teamName;
  final String? ownerId;
  final double initialBudget;
  final double spent;
  final double pendingCommitment;
  final int playersPurchased;
  final double remainingBudget;
  final double availableBudget;
  final double maxAffordableBid;

  const AuctionTeam({
    required this.id,
    required this.auctionId,
    required this.teamId,
    this.teamName,
    this.ownerId,
    required this.initialBudget,
    this.spent = 0,
    this.pendingCommitment = 0,
    this.playersPurchased = 0,
    this.remainingBudget = 0,
    this.availableBudget = 0,
    this.maxAffordableBid = 0,
  });

  String get displayName {
    final name = teamName?.trim();
    return name == null || name.isEmpty ? 'Team' : name;
  }
}
