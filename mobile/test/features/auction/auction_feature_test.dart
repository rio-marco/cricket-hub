import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/core/models/paginated_response.dart';
import 'package:mobile/features/auction/data/models/auction_json.dart';
import 'package:mobile/features/auction/data/models/auction_state_model.dart';
import 'package:mobile/features/auction/data/realtime/auction_realtime_event.dart';
import 'package:mobile/features/auction/domain/entities/auction.dart';
import 'package:mobile/features/auction/domain/entities/auction_bid.dart';
import 'package:mobile/features/auction/domain/entities/auction_player.dart';
import 'package:mobile/features/auction/domain/entities/auction_state.dart';
import 'package:mobile/features/auction/domain/entities/auction_team.dart';
import 'package:mobile/features/auction/domain/repositories/auction_repository.dart';
import 'package:mobile/features/auction/presentation/providers/auction_provider.dart';

const _auctionId = 'auction-1';
const _teamId = 'team-1';
const _auctionPlayerId = 'auction-player-1';
const _playerId = 'player-1';
const _bidId = 'bid-1';

Map<String, dynamic> auctionStatePayload({
  int stateVersion = 1,
  int nextSequence = 3,
  double bidAmount = 150000,
}) {
  return <String, dynamic>{
    'auction': <String, dynamic>{
      '_id': _auctionId,
      'name': 'Premier Auction',
      'status': 'LIVE',
      'stateVersion': stateVersion,
      'nextSequence': nextSequence,
      'purseAmount': 10000000,
      'basePrice': 100000,
      'minBidIncrement': 50000,
      'teams': [
        {'_id': _teamId, 'name': 'Team A'},
      ],
    },
    'currentPlayer': <String, dynamic>{
      '_id': _auctionPlayerId,
      'auction': _auctionId,
      'player': {
        '_id': _playerId,
        'user': {'name': 'Star Player'},
      },
      'basePrice': 100000,
      'status': 'AVAILABLE',
      'available': true,
    },
    'players': <dynamic>[
      <String, dynamic>{
        '_id': _auctionPlayerId,
        'auction': _auctionId,
        'player': {
          '_id': _playerId,
          'user': {'name': 'Star Player'},
        },
        'basePrice': 100000,
        'currentBid': bidAmount,
        'highestBidder': {'_id': _teamId, 'name': 'Team A'},
        'bidCount': 1,
        'lastSequence': nextSequence - 1,
        'status': 'AVAILABLE',
        'available': true,
      },
    ],
    'bids': <dynamic>[
      <String, dynamic>{
        '_id': _bidId,
        'auction': _auctionId,
        'auctionPlayer': _auctionPlayerId,
        'team': {'_id': _teamId, 'name': 'Team A'},
        'amount': bidAmount,
        'sequenceNumber': nextSequence - 1,
        'decision': 'ACCEPTED',
      },
    ],
    'teams': <dynamic>[
      <String, dynamic>{
        '_id': 'auction-team-1',
        'auction': _auctionId,
        'team': {
          '_id': _teamId,
          'name': 'Team A',
          'owner': {'_id': 'owner-1'},
        },
        'initialBudget': 10000000,
        'spent': bidAmount,
        'pendingCommitment': 200000,
        'remainingBudget': 10000000 - bidAmount,
        'availableBudget': 10000000 - bidAmount - 200000,
        'maxAffordableBid': 10000000 - bidAmount - 200000,
        'playersPurchased': 0,
      },
    ],
    'counts': <String, dynamic>{
      'totalPlayers': 1,
      'availablePlayers': 1,
      'soldPlayers': 0,
      'unsoldPlayers': 0,
      'totalBids': 1,
    },
    'results': <String, dynamic>{
      'sold': <dynamic>[],
      'unsold': <dynamic>[],
      'teams': <dynamic>[],
    },
    'stateVersion': stateVersion,
    'permissions': <String, dynamic>{
      'canView': true,
      'canManage': false,
      'canBid': true,
      'ownedTeamIds': [_teamId],
    },
  };
}

class FakeAuctionRepository implements AuctionRepository {
  FakeAuctionRepository(this.snapshot);

  AuctionStateSnapshot snapshot;

  @override
  Future<AuctionStateSnapshot> getState(String auctionId) async => snapshot;

  @override
  Future<PaginatedResponse<Auction>> getAuctions({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  }) =>
      throw UnimplementedError();

  @override
  Future<PaginatedResponse<AuctionPlayer>> getPlayers(
    String auctionId, {
    int page = 1,
    int limit = 20,
    String? status,
    String? category,
    bool? available,
    String? search,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<AuctionBid>> getBidHistory(
    String auctionId, {
    int limit = 100,
    String? decision,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuctionResults> getResults(String auctionId) =>
      throw UnimplementedError();

  @override
  Future<AuctionTeam> getTeamPurse(String auctionId, String teamId) =>
      throw UnimplementedError();

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
  }) =>
      throw UnimplementedError();

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
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteAuction(String auctionId) => throw UnimplementedError();

  @override
  Future<AuctionStateSnapshot> registerPlayers(
    String auctionId, {
    required List<Map<String, dynamic>> players,
    String? idempotencyKey,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuctionStateSnapshot> removePlayer(
    String auctionId,
    String auctionPlayerId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuctionStateSnapshot> setPlayerAvailability(
    String auctionId,
    String auctionPlayerId, {
    required bool available,
    int? expectedVersion,
    String? idempotencyKey,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuctionStateSnapshot> bringPlayerForward(
    String auctionId,
    String auctionPlayerId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuctionStateSnapshot> addTeam(
    String auctionId, {
    required String teamId,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuctionStateSnapshot> removeTeam(
    String auctionId,
    String teamId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuctionStateSnapshot> startAuction(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuctionStateSnapshot> pauseAuction(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuctionStateSnapshot> resumeAuction(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuctionStateSnapshot> completeAuction(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuctionStateSnapshot> placeBid(
    String auctionId, {
    required String teamId,
    double? amount,
    int? expectedVersion,
    String? idempotencyKey,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuctionStateSnapshot> decideBid(
    String auctionId,
    String bidId, {
    required bool accept,
    String? reason,
    int? expectedVersion,
    String? idempotencyKey,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuctionStateSnapshot> markSold(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuctionStateSnapshot> markUnsold(
    String auctionId, {
    String? reason,
    int? expectedVersion,
    String? idempotencyKey,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuctionStateSnapshot> nextPlayer(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) =>
      throw UnimplementedError();
}

AuctionRealtimeEvent bidEvent({
  required String eventId,
  int stateVersion = 2,
  double amount = 200000,
}) {
  return AuctionRealtimeEvent.from('auction:bid_placed', {
    'eventId': eventId,
    'auctionId': _auctionId,
    'action': 'BID_PLACED',
    'stateVersion': stateVersion,
    'state': auctionStatePayload(
      stateVersion: stateVersion,
      nextSequence: stateVersion + 1,
      bidAmount: amount,
    ),
  });
}

void main() {
  test('uses real auction REST endpoints', () {
    expect(ApiEndpoints.auctions, '/auctions');
    expect(ApiEndpoints.auctionState(_auctionId), '/auctions/$_auctionId/state');
    expect(ApiEndpoints.auctionBid(_auctionId), '/auctions/$_auctionId/bid');
    expect(
      ApiEndpoints.auctionBidDecision(_auctionId, _bidId),
      '/auctions/$_auctionId/bids/$_bidId/decision',
    );
    expect(
      ApiEndpoints.auctionTeamPurse(_auctionId, _teamId),
      '/auctions/$_auctionId/teams/$_teamId/purse',
    );
    expect(ApiEndpoints.auctionNext(_auctionId), '/auctions/$_auctionId/next');
    expect(ApiEndpoints.auctionComplete(_auctionId), '/auctions/$_auctionId/complete');
  });

  test('parses authoritative auction state without deriving budgets locally', () {
    final snapshot = AuctionStateModel.fromJson(auctionStatePayload());

    expect(snapshot.auction.id, _auctionId);
    expect(snapshot.auction.nextSequence, 3);
    expect(snapshot.currentPlayer?.displayName, 'Star Player');
    expect(snapshot.bids.single.sequenceNumber, 2);
    expect(snapshot.bids.single.amount, 150000);
    expect(snapshot.teams.single.initialBudget, 10000000);
    expect(snapshot.teams.single.availableBudget, 9650000);
    expect(snapshot.counts.totalBids, 1);
    expect(snapshot.permissions.canBidFor(_teamId), isTrue);
    expect(snapshot.biddableTeams, hasLength(1));
  });

  test('normalizes nested response envelopes and realtime events', () {
    final envelope = auctionResponseData({
      'success': true,
      'data': {'stateVersion': 7},
    });
    expect(envelope['stateVersion'], 7);

    final event = AuctionRealtimeEvent.from('auction:bid_rejected', {
      'eventId': '$_auctionId:bid:7',
      'auctionId': _auctionId,
      'stateVersion': 7,
      'error': {'code': 403, 'message': 'Bid below minimum'},
      'state': {'stateVersion': 7},
    });

    expect(event.eventId, '$_auctionId:bid:7');
    expect(event.auctionId, _auctionId);
    expect(event.errorCode, 403);
    expect(event.errorMessage, 'Bid below minimum');
    expect(event.state?['stateVersion'], 7);
  });

  test('live controller applies newer state and rejects stale or duplicate events',
      () async {
    final repository = FakeAuctionRepository(
      AuctionStateModel.fromJson(auctionStatePayload()),
    );
    final notifier = AuctionLiveController(repository, _auctionId);
    addTearDown(notifier.dispose);
    await notifier.load();

    expect(notifier.state.snapshot?.stateVersion, 1);

    notifier.applyRealtimeEvent(bidEvent(eventId: 'event-2'));
    expect(notifier.state.snapshot?.stateVersion, 2);
    expect(notifier.state.snapshot?.bids.single.amount, 200000);
    expect(notifier.state.successMessage, 'Bid accepted.');

    notifier.applyRealtimeEvent(
      bidEvent(eventId: 'event-stale', stateVersion: 1, amount: 999999),
    );
    expect(notifier.state.snapshot?.stateVersion, 2);
    expect(notifier.state.snapshot?.bids.single.amount, 200000);

    notifier.applyRealtimeEvent(
      bidEvent(eventId: 'event-2', amount: 888888),
    );
    expect(notifier.state.snapshot?.bids.single.amount, 200000);
  });

  test('live controller surfaces realtime errors', () async {
    final repository = FakeAuctionRepository(
      AuctionStateModel.fromJson(auctionStatePayload()),
    );
    final notifier = AuctionLiveController(repository, _auctionId);
    addTearDown(notifier.dispose);
    await notifier.load();

    notifier.applyRealtimeEvent(
      AuctionRealtimeEvent.from('auction:error', {
        'auctionId': _auctionId,
        'error': {'code': 'BID_REJECTED', 'message': 'Insufficient purse'},
      }),
    );

    expect(notifier.state.errorMessage, 'Insufficient purse');
    expect(notifier.state.isSaving, isFalse);
  });
}
