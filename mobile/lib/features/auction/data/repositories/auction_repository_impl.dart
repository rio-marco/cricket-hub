import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/paginated_response.dart';
import '../datasources/auction_remote_datasource.dart';
import '../../domain/entities/auction.dart';
import '../../domain/entities/auction_bid.dart';
import '../../domain/entities/auction_player.dart';
import '../../domain/entities/auction_state.dart';
import '../../domain/entities/auction_team.dart';
import '../../domain/repositories/auction_repository.dart';

class AuctionRepositoryImpl implements AuctionRepository {
  final AuctionRemoteDataSource _remoteDataSource;

  const AuctionRepositoryImpl({required AuctionRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<PaginatedResponse<Auction>> getAuctions({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  }) {
    return _guard(() => _remoteDataSource.getAuctions(
          page: page,
          limit: limit,
          status: status,
          search: search,
        ));
  }

  @override
  Future<AuctionStateSnapshot> getState(String auctionId) {
    return _guard(() => _remoteDataSource.getState(auctionId));
  }

  @override
  Future<PaginatedResponse<AuctionPlayer>> getPlayers(
    String auctionId, {
    int page = 1,
    int limit = 20,
    String? status,
    String? category,
    bool? available,
    String? search,
  }) {
    return _guard(() => _remoteDataSource.getPlayers(
          auctionId,
          page: page,
          limit: limit,
          status: status,
          category: category,
          available: available,
          search: search,
        ));
  }

  @override
  Future<List<AuctionBid>> getBidHistory(
    String auctionId, {
    int limit = 100,
    String? decision,
  }) {
    return _guard(() => _remoteDataSource.getBidHistory(
          auctionId,
          limit: limit,
          decision: decision,
        ));
  }

  @override
  Future<AuctionResults> getResults(String auctionId) {
    return _guard(() => _remoteDataSource.getResults(auctionId));
  }

  @override
  Future<AuctionTeam> getTeamPurse(String auctionId, String teamId) {
    return _guard(() => _remoteDataSource.getTeamPurse(auctionId, teamId));
  }

  @override
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
  }) {
    return _guard(() => _remoteDataSource.createAuction(
          name: name,
          teams: teams,
          purseAmount: purseAmount,
          tournamentId: tournamentId,
          basePrice: basePrice,
          minBidIncrement: minBidIncrement,
          maxSquadSize: maxSquadSize,
          minSquadSize: minSquadSize,
          playerCategories: playerCategories,
          status: status,
          idempotencyKey: idempotencyKey,
        ));
  }

  @override
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
  }) {
    return _guard(() => _remoteDataSource.updateAuction(
          auctionId,
          name: name,
          tournamentId: tournamentId,
          teams: teams,
          purseAmount: purseAmount,
          basePrice: basePrice,
          minBidIncrement: minBidIncrement,
          maxSquadSize: maxSquadSize,
          minSquadSize: minSquadSize,
          playerCategories: playerCategories,
          status: status,
          expectedVersion: expectedVersion,
          idempotencyKey: idempotencyKey,
        ));
  }

  @override
  Future<void> deleteAuction(String auctionId) {
    return _guard(() => _remoteDataSource.deleteAuction(auctionId));
  }

  @override
  Future<AuctionStateSnapshot> registerPlayers(
    String auctionId, {
    required List<Map<String, dynamic>> players,
    String? idempotencyKey,
  }) {
    return _guard(() => _remoteDataSource.registerPlayers(
          auctionId,
          players: players,
          idempotencyKey: idempotencyKey,
        ));
  }

  @override
  Future<AuctionStateSnapshot> removePlayer(
    String auctionId,
    String auctionPlayerId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    return _guard(() => _remoteDataSource.removePlayer(
          auctionId,
          auctionPlayerId,
          expectedVersion: expectedVersion,
          idempotencyKey: idempotencyKey,
        ));
  }

  @override
  Future<AuctionStateSnapshot> setPlayerAvailability(
    String auctionId,
    String auctionPlayerId, {
    required bool available,
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    return _guard(() => _remoteDataSource.setPlayerAvailability(
          auctionId,
          auctionPlayerId,
          available: available,
          expectedVersion: expectedVersion,
          idempotencyKey: idempotencyKey,
        ));
  }

  @override
  Future<AuctionStateSnapshot> bringPlayerForward(
    String auctionId,
    String auctionPlayerId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    return _guard(() => _remoteDataSource.bringPlayerForward(
          auctionId,
          auctionPlayerId,
          expectedVersion: expectedVersion,
          idempotencyKey: idempotencyKey,
        ));
  }

  @override
  Future<AuctionStateSnapshot> addTeam(
    String auctionId, {
    required String teamId,
  }) {
    return _guard(() => _remoteDataSource.addTeam(auctionId, teamId: teamId));
  }

  @override
  Future<AuctionStateSnapshot> removeTeam(
    String auctionId,
    String teamId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    return _guard(() => _remoteDataSource.removeTeam(
          auctionId,
          teamId,
          expectedVersion: expectedVersion,
          idempotencyKey: idempotencyKey,
        ));
  }

  @override
  Future<AuctionStateSnapshot> startAuction(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    return _guard(() => _remoteDataSource.startAuction(
          auctionId,
          expectedVersion: expectedVersion,
          idempotencyKey: idempotencyKey,
        ));
  }

  @override
  Future<AuctionStateSnapshot> pauseAuction(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    return _guard(() => _remoteDataSource.pauseAuction(
          auctionId,
          expectedVersion: expectedVersion,
          idempotencyKey: idempotencyKey,
        ));
  }

  @override
  Future<AuctionStateSnapshot> resumeAuction(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    return _guard(() => _remoteDataSource.resumeAuction(
          auctionId,
          expectedVersion: expectedVersion,
          idempotencyKey: idempotencyKey,
        ));
  }

  @override
  Future<AuctionStateSnapshot> completeAuction(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    return _guard(() => _remoteDataSource.completeAuction(
          auctionId,
          expectedVersion: expectedVersion,
          idempotencyKey: idempotencyKey,
        ));
  }

  @override
  Future<AuctionStateSnapshot> placeBid(
    String auctionId, {
    required String teamId,
    double? amount,
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    return _guard(() => _remoteDataSource.placeBid(
          auctionId,
          teamId: teamId,
          amount: amount,
          expectedVersion: expectedVersion,
          idempotencyKey: idempotencyKey,
        ));
  }

  @override
  Future<AuctionStateSnapshot> decideBid(
    String auctionId,
    String bidId, {
    required bool accept,
    String? reason,
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    return _guard(() => _remoteDataSource.decideBid(
          auctionId,
          bidId,
          accept: accept,
          reason: reason,
          expectedVersion: expectedVersion,
          idempotencyKey: idempotencyKey,
        ));
  }

  @override
  Future<AuctionStateSnapshot> markSold(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    return _guard(() => _remoteDataSource.markSold(
          auctionId,
          expectedVersion: expectedVersion,
          idempotencyKey: idempotencyKey,
        ));
  }

  @override
  Future<AuctionStateSnapshot> markUnsold(
    String auctionId, {
    String? reason,
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    return _guard(() => _remoteDataSource.markUnsold(
          auctionId,
          reason: reason,
          expectedVersion: expectedVersion,
          idempotencyKey: idempotencyKey,
        ));
  }

  @override
  Future<AuctionStateSnapshot> nextPlayer(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) {
    return _guard(() => _remoteDataSource.nextPlayer(
          auctionId,
          expectedVersion: expectedVersion,
          idempotencyKey: idempotencyKey,
        ));
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException catch (exception) {
      throw Failure.fromException(exception);
    } catch (error) {
      throw ServerFailure(message: error.toString());
    }
  }
}
