import 'auction.dart';
import 'auction_bid.dart';
import 'auction_player.dart';
import 'auction_team.dart';

class AuctionCounts {
  final int totalPlayers;
  final int availablePlayers;
  final int soldPlayers;
  final int unsoldPlayers;
  final int totalBids;

  const AuctionCounts({
    this.totalPlayers = 0,
    this.availablePlayers = 0,
    this.soldPlayers = 0,
    this.unsoldPlayers = 0,
    this.totalBids = 0,
  });
}

class AuctionPermissions {
  final bool canView;
  final bool canManage;
  final bool canBid;
  final List<String> ownedTeamIds;

  const AuctionPermissions({
    this.canView = true,
    this.canManage = false,
    this.canBid = false,
    this.ownedTeamIds = const [],
  });

  bool canBidFor(String teamId) => ownedTeamIds.contains(teamId);
}

class AuctionResults {
  final List<AuctionPlayer> sold;
  final List<AuctionPlayer> unsold;
  final List<AuctionTeam> teams;

  const AuctionResults({
    this.sold = const [],
    this.unsold = const [],
    this.teams = const [],
  });
}

class AuctionStateSnapshot {
  final Auction auction;
  final AuctionPlayer? currentPlayer;
  final List<AuctionPlayer> players;
  final List<AuctionBid> bids;
  final List<AuctionTeam> teams;
  final AuctionCounts counts;
  final AuctionResults results;
  final int stateVersion;
  final AuctionPermissions permissions;

  const AuctionStateSnapshot({
    required this.auction,
    this.currentPlayer,
    this.players = const [],
    this.bids = const [],
    this.teams = const [],
    this.counts = const AuctionCounts(),
    this.results = const AuctionResults(),
    this.stateVersion = 0,
    this.permissions = const AuctionPermissions(),
  });

  AuctionTeam? teamById(String teamId) {
    for (final team in teams) {
      if (team.teamId == teamId) return team;
    }
    return null;
  }

  List<AuctionTeam> get biddableTeams {
    return teams
        .where((team) => permissions.canBidFor(team.teamId))
        .toList(growable: false);
  }
}
