import '../../domain/entities/auction.dart';
import 'auction_json.dart';

class AuctionModel extends Auction {
  const AuctionModel({
    required super.id,
    required super.name,
    super.tournamentId,
    super.tournamentName,
    super.teams,
    super.teamNames,
    super.purseAmount = 0,
    super.basePrice,
    super.minBidIncrement,
    super.maxSquadSize,
    super.minSquadSize,
    super.playerCategories,
    super.status,
    super.currentPlayerId,
    super.stateVersion,
    super.nextSequence,
    super.startedAt,
    super.endedAt,
    super.createdAt,
    super.playerCount,
    super.soldCount,
  });

  factory AuctionModel.fromJson(Map<String, dynamic> json) {
    final tournament = normalizeAuctionMapOrNull(json['tournament']);
    final currentPlayerId = json['currentPlayerId'] != null
        ? auctionId(json['currentPlayerId'])
        : json['currentPlayer'] != null
            ? auctionId(json['currentPlayer'])
            : null;
    final teams = auctionIdList(json['teams']);
    final teamNames = auctionNameList(json['teams']);
    final categories = normalizeAuctionList(json['playerCategories'])
        .map((item) => auctionString(item) ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    return AuctionModel(
      id: auctionId(json['_id'], auctionString(json['id']) ?? ''),
      name: auctionString(json['name']) ?? '',
      tournamentId: tournament != null ? auctionId(tournament) : null,
      tournamentName: tournament != null ? auctionName(tournament) : null,
      teams: teams,
      teamNames: teamNames,
      purseAmount: json['purseAmount'] == null ? 0 : auctionDouble(json['purseAmount']),
      basePrice: json['basePrice'] == null ? 0 : auctionDouble(json['basePrice']),
      minBidIncrement: json['minBidIncrement'] == null ? 0 : auctionInt(json['minBidIncrement']),
      maxSquadSize: auctionInt(json['maxSquadSize']),
      minSquadSize: auctionInt(json['minSquadSize']),
      playerCategories: categories,
      status: auctionString(json['status']) ?? 'DRAFT',
      currentPlayerId: currentPlayerId == null || currentPlayerId.isEmpty
          ? null
          : currentPlayerId,
      stateVersion: auctionInt(json['stateVersion']),
      nextSequence: auctionInt(json['nextSequence'], 1),
      startedAt: auctionDate(json['startedAt']),
      endedAt: auctionDate(json['endedAt']),
      createdAt: auctionDate(json['createdAt']),
      playerCount: auctionInt(json['playerCount']),
      soldCount: auctionInt(json['soldCount']),
    );
  }
}
