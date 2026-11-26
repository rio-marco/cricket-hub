import '../../domain/entities/auction_bid.dart';
import 'auction_json.dart';

class AuctionBidModel extends AuctionBid {
  const AuctionBidModel({
    required super.id,
    required super.auctionId,
    required super.auctionPlayerId,
    required super.teamId,
    super.teamName,
    required super.amount,
    super.bidById,
    super.bidderName,
    super.sequenceNumber,
    super.decision,
    super.rejectionReason,
    super.createdAt,
  });

  factory AuctionBidModel.fromJson(Map<String, dynamic> json) {
    final teamId = auctionId(json['team'], auctionId(json['teamId']));
    final bidById = json['bidBy'] == null ? null : auctionId(json['bidBy']);

    return AuctionBidModel(
      id: auctionId(json['_id'], auctionString(json['id']) ?? ''),
      auctionId: auctionId(json['auction']),
      auctionPlayerId: auctionId(json['auctionPlayer']),
      teamId: teamId,
      teamName: auctionName(json['team']),
      amount: auctionDouble(json['amount']),
      bidById: bidById == null || bidById.isEmpty ? null : bidById,
      bidderName: json['bidBy'] == null ? null : auctionName(json['bidBy']),
      sequenceNumber: auctionInt(json['sequenceNumber']),
      decision: auctionString(json['decision']) ?? 'PENDING',
      rejectionReason: auctionString(json['rejectionReason']),
      createdAt: auctionDate(json['createdAt']),
    );
  }
}
