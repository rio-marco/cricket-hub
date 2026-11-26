import '../../domain/entities/auction_team.dart';
import 'auction_json.dart';

class AuctionTeamModel extends AuctionTeam {
  const AuctionTeamModel({
    required super.id,
    required super.auctionId,
    required super.teamId,
    super.teamName,
    super.ownerId,
    required super.initialBudget,
    super.spent,
    super.pendingCommitment,
    super.playersPurchased,
    super.remainingBudget,
    super.availableBudget,
    super.maxAffordableBid,
  });

  factory AuctionTeamModel.fromJson(Map<String, dynamic> json) {
    final teamRef = normalizeAuctionMapOrNull(json['team']);
    final initialBudget = auctionDouble(json['initialBudget']);
    final spent = auctionDouble(json['spent']);
    final pendingCommitment = auctionDouble(json['pendingCommitment']);
    final remainingBudget = json['remainingBudget'] == null
        ? initialBudget - spent
        : auctionDouble(json['remainingBudget']);
    final availableBudget = json['availableBudget'] == null
        ? (initialBudget - spent - pendingCommitment) > 0
            ? initialBudget - spent - pendingCommitment
            : 0.0
        : auctionDouble(json['availableBudget']);

    return AuctionTeamModel(
      id: auctionId(json['_id'], auctionString(json['id']) ?? ''),
      auctionId: auctionId(json['auction']),
      teamId: teamRef != null
          ? auctionId(teamRef, auctionId(json['team'], auctionId(json['teamId'])))
          : auctionId(json['team'], auctionId(json['teamId'])),
      teamName: teamRef != null ? auctionName(teamRef) : auctionName(json['team']),
      ownerId: teamRef == null ? null : auctionId(teamRef['owner']),
      initialBudget: initialBudget,
      spent: spent,
      pendingCommitment: pendingCommitment,
      playersPurchased: auctionInt(json['playersPurchased']),
      remainingBudget: remainingBudget,
      availableBudget: availableBudget,
      maxAffordableBid: json['maxAffordableBid'] == null
          ? availableBudget
          : auctionDouble(json['maxAffordableBid']),
    );
  }
}
