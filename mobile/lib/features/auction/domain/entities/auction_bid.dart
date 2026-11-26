class AuctionBid {
  final String id;
  final String auctionId;
  final String auctionPlayerId;
  final String teamId;
  final String? teamName;
  final double amount;
  final String? bidById;
  final String? bidderName;
  final int sequenceNumber;
  final String decision;
  final String? rejectionReason;
  final DateTime? createdAt;

  const AuctionBid({
    required this.id,
    required this.auctionId,
    required this.auctionPlayerId,
    required this.teamId,
    this.teamName,
    required this.amount,
    this.bidById,
    this.bidderName,
    this.sequenceNumber = 0,
    this.decision = 'PENDING',
    this.rejectionReason,
    this.createdAt,
  });

  bool get isPending => decision == 'PENDING';

  bool get isAccepted => decision == 'ACCEPTED';

  bool get isRejected => decision == 'REJECTED';
}
