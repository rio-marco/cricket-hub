import '../../domain/entities/auction_player.dart';
import 'auction_json.dart';

class AuctionPlayerModel extends AuctionPlayer {
  const AuctionPlayerModel({
    required super.id,
    required super.auctionId,
    required super.playerId,
    super.playerName,
    required super.basePrice,
    super.soldPrice,
    super.soldTo,
    super.soldToName,
    super.soldAt,
    super.status,
    super.available,
    super.category,
    super.setNumber,
    super.order,
    super.currentBid,
    super.highestBidder,
    super.highestBidderName,
    super.bidCount,
    super.lastSequence,
    super.decision,
    super.version,
  });

  factory AuctionPlayerModel.fromJson(Map<String, dynamic> json) {
    final auctionRef = auctionId(json['auction']);
    final playerRef = auctionId(json['player'], auctionId(json['playerId']));
    final soldToId = json['soldTo'] == null ? null : auctionId(json['soldTo']);
    final highestBidderId = json['highestBidder'] == null
        ? null
        : auctionId(json['highestBidder']);

    return AuctionPlayerModel(
      id: auctionId(json['_id'], auctionString(json['id']) ?? ''),
      auctionId: auctionRef,
      playerId: playerRef,
      playerName: auctionName(json['player']) ?? auctionString(json['playerName']),
      basePrice: auctionDouble(json['basePrice']),
      soldPrice: json['soldPrice'] == null ? null : auctionDouble(json['soldPrice']),
      soldTo: soldToId == null || soldToId.isEmpty ? null : soldToId,
      soldToName: json['soldTo'] == null ? null : auctionName(json['soldTo']),
      soldAt: auctionDate(json['soldAt']),
      status: auctionString(json['status']) ?? 'AVAILABLE',
      available: auctionBool(json['available'], true),
      category: auctionString(json['category']),
      setNumber: json['set'] == null ? null : auctionInt(json['set']),
      order: json['order'] == null ? null : auctionInt(json['order']),
      currentBid: auctionDouble(json['currentBid']),
      highestBidder:
          highestBidderId == null || highestBidderId.isEmpty ? null : highestBidderId,
      highestBidderName: json['highestBidder'] == null
          ? null
          : auctionName(json['highestBidder']),
      bidCount: auctionInt(json['bidCount']),
      lastSequence: auctionInt(json['lastSequence']),
      decision: auctionString(json['decision']) ?? 'PENDING',
      version: auctionInt(json['version']),
    );
  }
}
