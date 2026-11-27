import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/entities/user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/features/auction/data/realtime/auction_realtime_client.dart'
    as auction_rt;
import 'package:mobile/features/auction/data/realtime/auction_realtime_event.dart';
import 'package:mobile/features/matches/data/realtime/match_realtime_client.dart'
    as match_rt;
import 'package:mobile/features/matches/data/realtime/match_realtime_event.dart';
import 'package:mobile/features/matches/presentation/providers/realtime_provider.dart';
import 'package:mobile/features/matches/presentation/providers/scoring_provider.dart';
import 'package:mobile/features/auction/presentation/providers/auction_provider.dart';
import 'package:mobile/features/auction/domain/entities/auction_state.dart';
import 'package:mobile/features/auction/data/models/auction_state_model.dart';
import 'package:mobile/features/matches/domain/entities/scoring.dart';
import 'package:mobile/features/matches/data/repositories/scoring_repository_impl.dart';
import 'package:mobile/core/models/paginated_response.dart';
import 'package:mobile/features/auction/domain/entities/auction.dart';
import 'package:mobile/features/auction/domain/entities/auction_bid.dart';
import 'package:mobile/features/auction/domain/entities/auction_player.dart';
import 'package:mobile/features/auction/domain/entities/auction_team.dart';
import 'package:mobile/features/auction/domain/repositories/auction_repository.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class FakeTokenProvider implements match_rt.RealtimeTokenProvider {
  FakeTokenProvider(this.token);
  String? token;
  int calls = 0;
  @override
  Future<String?> getToken() async {
    calls++;
    return token;
  }
}

class FakeAuctionTokenProvider implements auction_rt.RealtimeTokenProvider {
  FakeAuctionTokenProvider(this.token);
  String? token;
  int calls = 0;
  @override
  Future<String?> getToken() async {
    calls++;
    return token;
  }
}

class FakeMatchRealtimeClient implements match_rt.MatchRealtimeClient {
  final StreamController<MatchRealtimeEvent> _controller =
      StreamController<MatchRealtimeEvent>.broadcast();
  final List<String> joins = [];
  final List<String> leaves = [];
  final List<String> syncs = [];
  int connectCalls = 0;
  int disconnectCalls = 0;
  int disposeCalls = 0;
  bool connected = false;
  final Set<String> _joinedRooms = <String>{};

  @override
  Stream<MatchRealtimeEvent> get events => _controller.stream;

  @override
  bool get isConnected => connected;

  @override
  Set<String> get joinedRooms => Set<String>.unmodifiable(_joinedRooms);

  @override
  Future<void> connect() async {
    connectCalls++;
  }

  @override
  void disconnect() {
    disconnectCalls++;
    connected = false;
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
    await _controller.close();
  }

  @override
  Future<void> joinMatch(String matchId) async {
    joins.add(matchId);
    _joinedRooms.add(matchId);
  }

  @override
  void leaveMatch(String matchId) {
    leaves.add(matchId);
    _joinedRooms.remove(matchId);
  }

  @override
  Future<Map<String, dynamic>?> syncMatch(String matchId) async {
    syncs.add(matchId);
    return {
      'ok': true,
      'matchId': matchId,
      'stateVersion': 99,
      'state': {
        'activeInnings': {
          'stateVersion': 99,
          'inningsNumber': 1,
          'totalRuns': 10,
          'totalBalls': 6,
          'totalWickets': 0,
          'status': 'IN_PROGRESS',
        },
      },
    };
  }

  void emit(MatchRealtimeEvent event) => _controller.add(event);
}

class FakeAuctionRealtimeClient implements auction_rt.AuctionRealtimeClient {
  final StreamController<AuctionRealtimeEvent> _controller =
      StreamController<AuctionRealtimeEvent>.broadcast();
  final List<String> joins = [];
  final List<String> leaves = [];
  final List<String> syncs = [];
  int connectCalls = 0;
  int disconnectCalls = 0;
  int disposeCalls = 0;
  bool connected = false;
  final Set<String> _joinedRooms = <String>{};

  @override
  Stream<AuctionRealtimeEvent> get events => _controller.stream;

  @override
  bool get isConnected => connected;

  @override
  Set<String> get joinedRooms => Set<String>.unmodifiable(_joinedRooms);

  @override
  Future<void> connect() async {
    connectCalls++;
  }

  @override
  void disconnect() {
    disconnectCalls++;
    connected = false;
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
    await _controller.close();
  }

  @override
  Future<void> joinAuction(String auctionId) async {
    joins.add(auctionId);
    _joinedRooms.add(auctionId);
  }

  @override
  void leaveAuction(String auctionId) {
    leaves.add(auctionId);
    _joinedRooms.remove(auctionId);
  }

  @override
  Future<AuctionRealtimeEvent?> syncAuction(String auctionId) async {
    syncs.add(auctionId);
    return AuctionRealtimeEvent.from('auction:state', {
      'ok': true,
      'auctionId': auctionId,
      'stateVersion': 99,
      'state': {
        'stateVersion': 99,
        'auction': {'_id': auctionId, 'status': 'LIVE', 'stateVersion': 99},
        'teams': [],
        'players': [],
        'bids': [],
      },
    });
  }

  void emit(AuctionRealtimeEvent event) => _controller.add(event);
}

class _StaticAuthNotifier extends AuthNotifier {
  _StaticAuthNotifier(AuthState initial)
      : super(_NoopAuthRepository()) {
    state = initial;
  }

  @override
  Future<void> checkAuth() async {}

  @override
  Future<bool> login({
    required String emailOrPhone,
    required String password,
  }) async =>
      false;

  @override
  Future<String?> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async =>
      null;

  @override
  Future<bool> verifyOTP({required String userId, required String otp}) async =>
      false;

  @override
  Future<bool> resendOTP({required String userId}) async => false;

  @override
  Future<String?> forgotPassword({required String emailOrPhone}) async => null;

  @override
  Future<bool> resetPassword({
    required String userId,
    required String otp,
    required String newPassword,
  }) async =>
      false;

  @override
  Future<void> logout({String? fcmToken}) async {
    state = const AuthState.unauthenticated();
  }
}

class _NoopAuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

User testUser(String id) {
  return User(
    id: id,
    name: 'User $id',
    email: '$id@example.com',
    phone: '1234567890',
    role: 'user',
  );
}

class FakeSocket extends Fake implements io.Socket {
  final Map<String, List<Function(dynamic)>> handlers = {};
  final List<Map<String, dynamic>> emits = [];
  final List<Map<String, dynamic>> ackEmits = [];
  bool connectedValue = false;
  bool disposed = false;
  int connectCalls = 0;
  int disconnectCalls = 0;
  String? idValue = 'socket-1';
  final String token;

  FakeSocket(this.token);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #io) {
      throw UnimplementedError('io');
    }
    return super.noSuchMethod(invocation);
  }

  dynamic Function() onConnect(dynamic Function(dynamic) handler) =>
      on('connect', handler);

  dynamic Function() onDisconnect(dynamic Function(dynamic) handler) =>
      on('disconnect', handler);

  dynamic Function() onConnectError(dynamic Function(dynamic) handler) =>
      on('connect_error', handler);

  dynamic Function() onError(dynamic Function(dynamic) handler) =>
      on('error', handler);

  @override
  bool get connected => connectedValue;

  @override
  String? get id => idValue;

  @override
  @override
  dynamic Function() on(String event, dynamic Function(dynamic) handler) {
    handlers.putIfAbsent(event, () => []).add(handler);
    return () => off(event, handler);
  }

  @override
  @override
  void off(String event, [dynamic handler]) {
    if (handler == null) {
      handlers.remove(event);
    } else {
      handlers[event]?.remove(handler);
    }
  }

  @override
  @override
  void emit(String event, [dynamic data]) {
    emits.add({'event': event, 'data': data});
  }

  @override
  @override
  void emitWithAck(
    String event,
    dynamic data, {
    Function? ack,
    bool binary = false,
  }) {
    ackEmits.add({'event': event, 'data': data, 'ack': ack});
  }

  @override
  @override
  io.Socket connect() {
    connectCalls++;
    return this;
  }

  @override
  @override
  io.Socket disconnect() {
    disconnectCalls++;
    connectedValue = false;
    return this;
  }

  @override
  void dispose() {
    disposed = true;
  }

  @override
  void destroy() {
    disposed = true;
  }

  void fire(String event, [dynamic data]) {
    final list = List<Function(dynamic)>.from(handlers[event] ?? const []);
    for (final h in list) {
      h(data);
    }
  }

  void fireConnect() {
    connectedValue = true;
    fire('connect');
  }

  void fireDisconnect([dynamic reason]) {
    connectedValue = false;
    fire('disconnect', reason);
  }

  void fireConnectError(dynamic err) {
    fire('connect_error', err);
  }
}

class FakeScoringRepository implements ScoringRepository {
  FakeScoringRepository(this.snapshot);
  ScoringSnapshot snapshot;
  int getStateCalls = 0;

  @override
  Future<ScoringSnapshot> getState(String matchId) async {
    getStateCalls++;
    return snapshot;
  }

  @override
  Future<ScoringSnapshot> startInnings(
    String matchId,
    Map<String, dynamic> data,
  ) async => snapshot;
  @override
  Future<ScoringSnapshot> recordBall(
    String matchId,
    Map<String, dynamic> data,
  ) async => snapshot;
  @override
  Future<ScoringSnapshot> undo(
    String matchId,
    Map<String, dynamic> data,
  ) async => snapshot;
  @override
  Future<ScoringSnapshot> correct(
    String matchId,
    String deliveryId,
    Map<String, dynamic> data,
  ) async => snapshot;
  @override
  Future<ScoringSnapshot> endInnings(
    String matchId,
    Map<String, dynamic> data,
  ) async => snapshot;
  @override
  Future<ScoringSnapshot> completeMatch(
    String matchId,
    Map<String, dynamic> data,
  ) async => snapshot;
  @override
  Future<List<ScoringDelivery>> getCommentary(String matchId) async => const [];
}

ScoringSnapshot snapshotWithVersion(
  int version, {
  int innings = 1,
  int runs = 0,
}) {
  return ScoringSnapshot(
    activeInnings: <String, dynamic>{
      'stateVersion': version,
      'inningsNumber': innings,
      'totalRuns': runs == 0 ? version : runs,
      'totalWickets': 0,
      'totalBalls': version,
      'status': 'IN_PROGRESS',
    },
    deliveries: const [],
  );
}

class FakeAuctionRepository implements AuctionRepository {
  FakeAuctionRepository(this.snapshot);
  AuctionStateSnapshot snapshot;
  int getStateCalls = 0;

  @override
  Future<AuctionStateSnapshot> getState(String auctionId) async {
    getStateCalls++;
    return snapshot;
  }

  @override
  Future<PaginatedResponse<Auction>> getAuctions({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  }) => throw UnimplementedError();
  @override
  Future<PaginatedResponse<AuctionPlayer>> getPlayers(
    String auctionId, {
    int page = 1,
    int limit = 20,
    String? status,
    String? category,
    bool? available,
    String? search,
  }) => throw UnimplementedError();
  @override
  Future<List<AuctionBid>> getBidHistory(
    String auctionId, {
    int limit = 100,
    String? decision,
  }) => throw UnimplementedError();
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
  }) => throw UnimplementedError();
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
  }) => throw UnimplementedError();
  @override
  Future<void> deleteAuction(String auctionId) => throw UnimplementedError();
  @override
  Future<AuctionStateSnapshot> registerPlayers(
    String auctionId, {
    required List<Map<String, dynamic>> players,
    String? idempotencyKey,
  }) => throw UnimplementedError();
  @override
  Future<AuctionStateSnapshot> removePlayer(
    String auctionId,
    String auctionPlayerId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) => throw UnimplementedError();
  @override
  Future<AuctionStateSnapshot> setPlayerAvailability(
    String auctionId,
    String auctionPlayerId, {
    required bool available,
    int? expectedVersion,
    String? idempotencyKey,
  }) => throw UnimplementedError();
  @override
  Future<AuctionStateSnapshot> bringPlayerForward(
    String auctionId,
    String auctionPlayerId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) => throw UnimplementedError();
  @override
  Future<AuctionStateSnapshot> addTeam(
    String auctionId, {
    required String teamId,
  }) => throw UnimplementedError();
  @override
  Future<AuctionStateSnapshot> removeTeam(
    String auctionId,
    String teamId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) => throw UnimplementedError();
  @override
  Future<AuctionStateSnapshot> startAuction(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) => throw UnimplementedError();
  @override
  Future<AuctionStateSnapshot> pauseAuction(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) => throw UnimplementedError();
  @override
  Future<AuctionStateSnapshot> resumeAuction(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) => throw UnimplementedError();
  @override
  Future<AuctionStateSnapshot> completeAuction(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) => throw UnimplementedError();
  @override
  Future<AuctionStateSnapshot> placeBid(
    String auctionId, {
    required String teamId,
    double? amount,
    int? expectedVersion,
    String? idempotencyKey,
  }) => throw UnimplementedError();
  @override
  Future<AuctionStateSnapshot> decideBid(
    String auctionId,
    String bidId, {
    required bool accept,
    String? reason,
    int? expectedVersion,
    String? idempotencyKey,
  }) => throw UnimplementedError();
  @override
  Future<AuctionStateSnapshot> markSold(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) => throw UnimplementedError();
  @override
  Future<AuctionStateSnapshot> markUnsold(
    String auctionId, {
    String? reason,
    int? expectedVersion,
    String? idempotencyKey,
  }) => throw UnimplementedError();
  @override
  Future<AuctionStateSnapshot> nextPlayer(
    String auctionId, {
    int? expectedVersion,
    String? idempotencyKey,
  }) => throw UnimplementedError();
}

AuctionStateSnapshot auctionSnapshot({
  int version = 1,
  double currentBid = 100,
  double available = 900,
}) {
  return AuctionStateModel.fromJson({
    'stateVersion': version,
    'auction': {'_id': 'a1', 'status': 'LIVE', 'stateVersion': version},
    'currentPlayer': {
      '_id': 'ap1',
      'auction': 'a1',
      'player': {'_id': 'p1', 'name': 'Player'},
      'basePrice': 50,
      'currentBid': currentBid,
      'status': 'AVAILABLE',
      'available': true,
    },
    'players': [
      {
        '_id': 'ap1',
        'auction': 'a1',
        'player': {'_id': 'p1', 'name': 'Player'},
        'basePrice': 50,
        'currentBid': currentBid,
        'status': 'AVAILABLE',
        'available': true,
      },
    ],
    'teams': [
      {
        '_id': 'at1',
        'auction': 'a1',
        'team': {'_id': 't1', 'name': 'Team 1'},
        'initialBudget': 1000,
        'spent': 1000 - available - currentBid,
        'pendingCommitment': currentBid,
        'remainingBudget': available,
        'availableBudget': available,
        'maxAffordableBid': available,
      },
    ],
    'bids': [],
    'permissions': {
      'canBid': true,
      'canManage': true,
      'ownedTeamIds': ['t1'],
    },
  });
}

void main() {
  group('match realtime client lifecycle', () {
    test(
      'uses current token, rejoins rooms, and handles token refresh rebuild',
      () async {
        final tokenProvider = FakeTokenProvider('token-a');
        final sockets = <FakeSocket>[];
        final client = match_rt.SocketIOMatchRealtimeClient(
          url: 'http://localhost',
          tokenProvider: tokenProvider,
          socketBuilder: (url, token) {
            final s = FakeSocket(token);
            sockets.add(s);
            return s;
          },
        );

        await client.joinMatch('m1');
        expect(sockets, hasLength(1));
        expect(sockets.first.token, 'token-a');

        sockets.first.fireConnect();
        await Future<void>.delayed(Duration.zero);
        expect(
          sockets.first.ackEmits
              .where((e) => e['event'] == 'match:join')
              .length,
          1,
        );

        sockets.first.fireConnectError({
          'data': {'code': 'TOKEN_EXPIRED'},
        });
        await Future<void>.delayed(Duration.zero);
        expect(sockets, hasLength(1)); // same token, no rebuild

        tokenProvider.token = 'token-b';
        sockets.first.fireConnectError({
          'data': {'code': 'INVALID_TOKEN'},
        });
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(sockets.length, greaterThanOrEqualTo(2));
        final rebuilt = sockets.last;
        expect(rebuilt.token, 'token-b');
        rebuilt.fireConnect();
        await Future<void>.delayed(Duration.zero);
        expect(
          rebuilt.ackEmits.where((e) => e['event'] == 'match:join').length,
          1,
        );

        await client.dispose();
      },
    );

    test('missing token does not connect or reconnect', () async {
      final tokenProvider = FakeTokenProvider(null);
      final sockets = <FakeSocket>[];
      final client = match_rt.SocketIOMatchRealtimeClient(
        url: 'http://localhost',
        tokenProvider: tokenProvider,
        socketBuilder: (url, token) {
          final s = FakeSocket(token);
          sockets.add(s);
          return s;
        },
      );

      await client.connect();
      await client.joinMatch('m1');
      expect(sockets, isEmpty);

      tokenProvider.token = 'token-a';
      await client.connect();
      expect(sockets, hasLength(1));

      await client.dispose();
    });
  });

  group('auction realtime client lifecycle', () {
    test(
      'rebuilds socket on changed token after auth error and rejoins room',
      () async {
        final tokenProvider = FakeAuctionTokenProvider('a1');
        final sockets = <FakeSocket>[];
        final client = auction_rt.SocketIOAuctionRealtimeClient(
          url: 'http://localhost',
          tokenProvider: tokenProvider,
          socketBuilder: (url, token) {
            final s = FakeSocket(token);
            sockets.add(s);
            return s;
          },
        );

        await client.joinAuction('auction-1');
        sockets.first.fireConnect();
        await Future<void>.delayed(Duration.zero);
        expect(
          sockets.first.ackEmits
              .where((e) => e['event'] == 'auction:join')
              .length,
          1,
        );

        tokenProvider.token = 'a2';
        sockets.first.fireConnectError({
          'data': {'code': 'TOKEN_EXPIRED'},
        });
        await Future<void>.delayed(const Duration(milliseconds: 10));

        expect(sockets.length, 2);
        sockets.last.fireConnect();
        await Future<void>.delayed(Duration.zero);
        expect(
          sockets.last.ackEmits
              .where((e) => e['event'] == 'auction:join')
              .length,
          1,
        );

        await client.dispose();
      },
    );
  });

  group('match recovery', () {
    test(
      'applies same/unknown innings by version and rejects stale same innings',
      () async {
        final repo = FakeScoringRepository(
          snapshotWithVersion(2, innings: 2, runs: 20),
        );
        final notifier = ScoringNotifier(repo, 'm1');
        await notifier.load();

        notifier.applyRealtimeEvent(
          MatchRealtimeEvent.from('match:state', {
            'matchId': 'm1',
            'state': {
              'activeInnings': {
                'stateVersion': 1,
                'inningsNumber': 2,
                'totalRuns': 5,
                'totalBalls': 1,
              },
            },
          }),
        );
        expect(notifier.state.activeInnings?['stateVersion'], 2);
        expect(notifier.state.activeInnings?['totalRuns'], 20);

        notifier.applyRealtimeEvent(
          MatchRealtimeEvent.from('match:state', {
            'matchId': 'm1',
            'state': {
              'activeInnings': {
                'stateVersion': 1,
                'inningsNumber': 1,
                'totalRuns': 7,
                'totalBalls': 1,
              },
            },
          }),
        );
        expect(notifier.state.activeInnings?['inningsNumber'], 1);
        expect(notifier.state.activeInnings?['totalRuns'], 7);
      },
    );

    test('provider disposal removes room listeners and reconnect recreates subscription', () async {
      final fakeClient = FakeMatchRealtimeClient();
      final container = ProviderContainer(
        overrides: [
          matchRealtimeClientProvider.overrideWithValue(fakeClient),
          authStateProvider.overrideWith(
            (ref) =>
                _StaticAuthNotifier(AuthState.authenticated(testUser('u1'))),
          ),
          scoringControllerProvider.overrideWith(
            (ref, matchId) => ScoringNotifier(
              FakeScoringRepository(snapshotWithVersion(1)),
              matchId,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(matchRoomProvider('m1'), (_, __) {});
      expect(sub.read(), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(fakeClient.joins.where((id) => id == 'm1').length, 1);

      sub.close();
      await Future<void>.delayed(Duration.zero);
      expect(fakeClient.leaves, contains('m1'));

      fakeClient.connected = true;
      fakeClient.emit(
        MatchRealtimeEvent.from('connection:status', {
          'status': 'connected',
          'connected': true,
        }),
      );
      await Future<void>.delayed(Duration.zero);
      expect(fakeClient.syncs, isEmpty);

      final container2 = ProviderContainer(
        overrides: [
          matchRealtimeClientProvider.overrideWithValue(fakeClient),
          authStateProvider.overrideWith(
            (ref) =>
                _StaticAuthNotifier(AuthState.authenticated(testUser('u1'))),
          ),
          scoringControllerProvider.overrideWith(
            (ref, matchId) => ScoringNotifier(
              FakeScoringRepository(snapshotWithVersion(1)),
              matchId,
            ),
          ),
        ],
      );
      addTearDown(container2.dispose);

      final sub2 = container2.listen(matchRoomProvider('m1'), (_, __) {});
      expect(sub2.read(), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(fakeClient.joins.where((id) => id == 'm1').length, 2);
      expect(fakeClient._controller.hasListener, isTrue);

      fakeClient.connected = true;
      fakeClient.emit(
        MatchRealtimeEvent.from('connection:status', {
          'status': 'connected',
          'connected': true,
        }),
      );
      await Future<void>.delayed(Duration.zero);
      expect(fakeClient.joins.where((id) => id == 'm1').length, 3);
      expect(fakeClient.syncs, contains('m1'));
    });
  });

  group('auction recovery', () {
    test('redacted broadcast does not erase known financial fields and stale version rejected', () async {
      final repo = FakeAuctionRepository(
        auctionSnapshot(version: 2, currentBid: 150, available: 850),
      );
      final notifier = AuctionLiveController(repo, 'a1');
      addTearDown(notifier.dispose);
      await notifier.load();

      notifier.applyRealtimeEvent(
        AuctionRealtimeEvent.from('auction:bid_placed', {
          'auctionId': 'a1',
          'stateVersion': 3,
          'state': {
            'stateVersion': 3,
            'auction': {'_id': 'a1', 'status': 'LIVE', 'stateVersion': 3},
            'currentPlayer': {
              '_id': 'ap1',
              'auction': 'a1',
              'player': {'_id': 'p1', 'name': 'Player'},
              'status': 'AVAILABLE',
              'available': true,
              'currentBid': null,
            },
            'teams': [
              {
                '_id': 'at1',
                'auction': 'a1',
                'team': {'_id': 't1', 'name': 'Team 1'},
                'availableBudget': null,
                'remainingBudget': null,
                'spent': null,
              },
            ],
            'players': [],
            'bids': [],
            'permissions': {
              'canBid': true,
              'canManage': true,
              'ownedTeamIds': ['t1'],
            },
          },
        }),
      );

      expect(notifier.state.snapshot?.stateVersion, 3);
      expect(notifier.state.snapshot?.currentPlayer?.currentBid, 150);
      expect(notifier.state.snapshot?.teams.first.availableBudget, 850);
      expect(notifier.state.snapshot?.currentPlayer?.currentBid, isNot(0));

      notifier.applyRealtimeEvent(
        AuctionRealtimeEvent.from('auction:bid_placed', {
          'auctionId': 'a1',
          'stateVersion': 2,
          'state': {
            'stateVersion': 2,
            'auction': {'_id': 'a1', 'stateVersion': 2},
            'teams': [],
            'players': [],
            'bids': [],
          },
        }),
      );
      expect(notifier.state.snapshot?.stateVersion, 3);
    });

    test('provider disposal removes auction room listeners and reconnect recreates subscription', () async {
      final fakeClient = FakeAuctionRealtimeClient();
      final container = ProviderContainer(
        overrides: [
          auctionRealtimeClientProvider.overrideWithValue(fakeClient),
          authStateProvider.overrideWith(
            (ref) =>
                _StaticAuthNotifier(AuthState.authenticated(testUser('u1'))),
          ),
          auctionLiveControllerProvider.overrideWith(
            (ref, auctionId) => AuctionLiveController(
              FakeAuctionRepository(auctionSnapshot(version: 1)),
              auctionId,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(auctionRoomProvider('a1'), (_, __) {});
      expect(sub.read(), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(fakeClient.joins.where((id) => id == 'a1').length, 1);

      sub.close();
      await Future<void>.delayed(Duration.zero);
      expect(fakeClient.leaves, contains('a1'));

      fakeClient.connected = true;
      fakeClient.emit(
        AuctionRealtimeEvent.from('connection:status', {
          'status': 'connected',
          'connected': true,
        }),
      );
      await Future<void>.delayed(Duration.zero);
      expect(fakeClient.syncs, isEmpty);

      final container2 = ProviderContainer(
        overrides: [
          auctionRealtimeClientProvider.overrideWithValue(fakeClient),
          authStateProvider.overrideWith(
            (ref) =>
                _StaticAuthNotifier(AuthState.authenticated(testUser('u1'))),
          ),
          auctionLiveControllerProvider.overrideWith(
            (ref, auctionId) => AuctionLiveController(
              FakeAuctionRepository(auctionSnapshot(version: 1)),
              auctionId,
            ),
          ),
        ],
      );
      addTearDown(container2.dispose);

      final sub2 = container2.listen(auctionRoomProvider('a1'), (_, __) {});
      expect(sub2.read(), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(fakeClient.joins.where((id) => id == 'a1').length, 2);

      fakeClient.connected = true;
      fakeClient.emit(
        AuctionRealtimeEvent.from('connection:status', {
          'status': 'connected',
          'connected': true,
        }),
      );
      await Future<void>.delayed(Duration.zero);
      expect(fakeClient.joins.where((id) => id == 'a1').length, 3);
      expect(fakeClient.syncs, contains('a1'));
    });
  });
}
