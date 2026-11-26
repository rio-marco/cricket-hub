import '../../domain/entities/auction_player.dart';
import '../../domain/entities/auction_state.dart';
import 'auction_bid_model.dart';
import 'auction_json.dart';
import 'auction_model.dart';
import 'auction_player_model.dart';
import 'auction_team_model.dart';

class AuctionStateModel extends AuctionStateSnapshot {
  const AuctionStateModel({
    required super.auction,
    super.currentPlayer,
    super.players,
    super.bids,
    super.teams,
    super.counts,
    super.results,
    super.stateVersion,
    super.permissions,
  });

  factory AuctionStateModel.fromJson(Map<String, dynamic> json) {
    final auctionMap = normalizeAuctionMapOrNull(json['auction']) ?? json;
    final auction = AuctionModel.fromJson(auctionMap);
    final players = normalizeAuctionList(json['players'])
        .map((item) => AuctionPlayerModel.fromJson(normalizeAuctionMap(item)))
        .toList(growable: false);
    final bids = normalizeAuctionList(json['bids'])
        .map((item) => AuctionBidModel.fromJson(normalizeAuctionMap(item)))
        .toList(growable: false);
    final teams = normalizeAuctionList(json['teams'])
        .map((item) => AuctionTeamModel.fromJson(normalizeAuctionMap(item)))
        .toList(growable: false);

    AuctionPlayer? current;
    final currentMap = normalizeAuctionMapOrNull(json['currentPlayer']);
    if (currentMap != null) {
      current = AuctionPlayerModel.fromJson(currentMap);
    }
    if ((current == null || current.playerName == null) &&
        auction.currentPlayerId != null) {
      for (final player in players) {
        if (player.id == auction.currentPlayerId) {
          if (current == null || current.playerName == null) {
            current = player;
          }
          break;
        }
      }
    }

    final countsMap = normalizeAuctionMapOrNull(json['counts']) ??
        <String, dynamic>{};
    final counts = AuctionCounts(
      totalPlayers: auctionInt(countsMap['totalPlayers'], players.length),
      availablePlayers: auctionInt(countsMap['availablePlayers']),
      soldPlayers: auctionInt(countsMap['soldPlayers']),
      unsoldPlayers: auctionInt(countsMap['unsoldPlayers']),
      totalBids: auctionInt(countsMap['totalBids'], bids.length),
    );

    final resultsMap = normalizeAuctionMapOrNull(json['results']);
    final sold = resultsMap == null
        ? players.where((player) => player.isSold).toList(growable: false)
        : normalizeAuctionList(resultsMap['sold'])
            .map((item) => AuctionPlayerModel.fromJson(normalizeAuctionMap(item)))
            .toList(growable: false);
    final unsold = resultsMap == null
        ? players.where((player) => player.isUnsold).toList(growable: false)
        : normalizeAuctionList(resultsMap['unsold'])
            .map((item) => AuctionPlayerModel.fromJson(normalizeAuctionMap(item)))
            .toList(growable: false);

    final permissionsMap =
        normalizeAuctionMapOrNull(json['permissions']) ?? <String, dynamic>{};
    final permissions = AuctionPermissions(
      canView: auctionBool(permissionsMap['canView'], true),
      canManage: auctionBool(permissionsMap['canManage']),
      canBid: auctionBool(permissionsMap['canBid']),
      ownedTeamIds: auctionIdList(permissionsMap['ownedTeamIds']),
    );

    return AuctionStateModel(
      auction: auction,
      currentPlayer: current,
      players: players,
      bids: bids,
      teams: teams,
      counts: counts,
      results: AuctionResults(sold: sold, unsold: unsold, teams: teams),
      stateVersion: auctionInt(json['stateVersion'], auction.stateVersion),
      permissions: permissions,
    );
  }
}
