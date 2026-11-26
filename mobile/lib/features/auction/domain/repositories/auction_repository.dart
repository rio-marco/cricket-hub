import '../../../../core/models/paginated_response.dart';
import '../entities/auction.dart';
import '../entities/auction_bid.dart';
import '../entities/auction_player.dart';
import '../entities/auction_state.dart';
import '../entities/auction_team.dart';

abstract class AuctionRepository {
  Future<PaginatedResponse<Auction>> getAuctions({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  });

  Future<AuctionStateSnapshot> getState(String auctionId);

  Future<PaginatedResponse<AuctionPlayer>> getPlayers(
    String auctionId, {
    int page = 1,
    int limit = 20,
    String? status,
    String? category,
    bool? available,
    String? search,
  });

  Future<List<AuctionBid>> getBidHistory(
    String auctionId, {
    int limit = 100,
    String? decision,
  });

  Future<AuctionResults> getResults(String auctionId);

  Future<AuctionTeam> getTeamPurse(String auctionId, String teamId);

  Future<AuctionStateSnapshot> createAuction({
    required String name,
    required List<String> teams,
    required double purseAmount,
    String? tournamentId,
    double? basePrice,
    int? minBidIncrement,
    int? maxSquadSize,
    int? minSquadSize,
    List<String>? playerCategories,
    String? status,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> updateAuction(
    String auctionId, {
    String? name,
    String? tournamentId,
    List<String>? teams,
    double? purseAmount,
    double? basePrice,
    int? minBidIncrement,
    int? maxSquadSize,
    int? minSquadSize,
    List<String>? playerCategories,
    String? status,
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<void> deleteAuction(String auctionId);

  Future<AuctionStateSnapshot> registerPlayers(
    String auctionId, {
    required List<Map<String, dynamic>> players,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> removePlayer(
    String auctionId,
    String auctionPlayerId, {
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> setPlayerAvailability(
    String auctionId,
    String auctionPlayerId, {
    required bool available,
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> bringPlayerForward(
    String auctionId,
    String auctionPlayerId, {
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> addTeam(
    String auctionId, {
    required String teamId,
  });

  Future<AuctionStateSnapshot> removeTeam(
    String auctionId,
    String teamId, {
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> startAuction(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> pauseAuction(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> resumeAuction(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> completeAuction(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> placeBid(
    String auctionId, {
    required String teamId,
    double? amount,
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> decideBid(
    String auctionId,
    String bidId, {
    required bool accept,
    String? reason,
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> markSold(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> markUnsold(
    String auctionId, {
    String? reason,
    int? expectedVersion,
    String? idempotencyKey,
  });

  Future<AuctionStateSnapshot> nextPlayer(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  });
}
