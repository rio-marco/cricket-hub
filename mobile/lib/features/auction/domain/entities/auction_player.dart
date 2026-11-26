class AuctionPlayer {
  final String id;
  final String auctionId;
  final String playerId;
  final String? playerName;
  final double basePrice;
  final double? soldPrice;
  final String? soldTo;
  final String? soldToName;
  final DateTime? soldAt;
  final String status;
  final bool available;
  final String? category;
  final int? setNumber;
  final int? order;
  final double currentBid;
  final String? highestBidder;
  final String? highestBidderName;
  final int bidCount;
  final int lastSequence;
  final String decision;
  final int version;

  const AuctionPlayer({
    required this.id,
    required this.auctionId,
    required this.playerId,
    this.playerName,
    required this.basePrice,
    this.soldPrice,
    this.soldTo,
    this.soldToName,
    this.soldAt,
    this.status = 'AVAILABLE',
    this.available = true,
    this.category,
    this.setNumber,
    this.order,
    this.currentBid = 0,
    this.highestBidder,
    this.highestBidderName,
    this.bidCount = 0,
    this.lastSequence = 0,
    this.decision = 'PENDING',
    this.version = 0,
  });

  String get displayName {
    final name = playerName?.trim();
    return name == null || name.isEmpty ? 'Player' : name;
  }

  bool get isSold => status == 'SOLD';

  bool get isUnsold => status == 'UNSOLD';

  bool get isAvailable => status == 'AVAILABLE' && available;
}
