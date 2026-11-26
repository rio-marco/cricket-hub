import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/auction_remote_datasource.dart';
import '../../data/models/auction_json.dart';
import '../../data/models/auction_state_model.dart';
import '../../data/realtime/auction_realtime_client.dart';
import '../../data/realtime/auction_realtime_event.dart';
import '../../data/repositories/auction_repository_impl.dart';
import '../../domain/entities/auction.dart';
import '../../domain/entities/auction_state.dart';
import '../../domain/repositories/auction_repository.dart';

final Random _auctionRandom = Random.secure();

String newAuctionRequestKey(String action) {
  return '${action.toLowerCase()}-${DateTime.now().microsecondsSinceEpoch}-'
      '${_auctionRandom.nextInt(1 << 30)}';
}

final auctionRemoteDataSourceProvider = Provider<AuctionRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuctionRemoteDataSourceImpl(apiClient.dio);
});

final auctionRepositoryProvider = Provider<AuctionRepository>((ref) {
  final remoteDataSource = ref.watch(auctionRemoteDataSourceProvider);
  return AuctionRepositoryImpl(remoteDataSource: remoteDataSource);
});

sealed class AuctionListState {
  const AuctionListState();
}

class AuctionListLoading extends AuctionListState {
  const AuctionListLoading();
}

class AuctionListLoaded extends AuctionListState {
  final List<Auction> auctions;
  final String status;
  final String search;
  final int page;
  final int total;
  final bool hasNextPage;

  const AuctionListLoaded({
    required this.auctions,
    required this.status,
    required this.search,
    this.page = 1,
    this.total = 0,
    this.hasNextPage = false,
  });
}

class AuctionListEmpty extends AuctionListState {
  final String status;
  final String search;

  const AuctionListEmpty({this.status = 'ALL', this.search = ''});
}

class AuctionListError extends AuctionListState {
  final String message;

  const AuctionListError(this.message);
}

class AuctionsListNotifier extends StateNotifier<AuctionListState> {
  final AuctionRepository _repository;
  String _status = 'ALL';
  String _search = '';
  int _page = 1;

  AuctionsListNotifier(this._repository) : super(const AuctionListLoading()) {
    load();
  }

  String get status => _status;

  String get search => _search;

  Future<void> load({bool refresh = false}) async {
    if (refresh) _page = 1;
    if (state is! AuctionListLoaded || refresh) {
      state = const AuctionListLoading();
    }
    try {
      final response = await _repository.getAuctions(
        page: _page,
        limit: 20,
        status: _status,
        search: _search,
      );
      if (response.items.isEmpty && _page == 1) {
        state = AuctionListEmpty(status: _status, search: _search);
        return;
      }
      state = AuctionListLoaded(
        auctions: response.items,
        status: _status,
        search: _search,
        page: response.page,
        total: response.total,
        hasNextPage: response.hasNextPage,
      );
    } on Failure catch (failure) {
      state = AuctionListError(failure.message);
    } catch (error) {
      state = AuctionListError(error.toString());
    }
  }

  Future<void> setStatus(String status) async {
    _status = status;
    await load(refresh: true);
  }

  Future<void> searchAuctions(String query) async {
    _search = query.trim();
    await load(refresh: true);
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! AuctionListLoaded || !current.hasNextPage) return;
    final nextPage = current.page + 1;
    try {
      final response = await _repository.getAuctions(
        page: nextPage,
        limit: 20,
        status: _status,
        search: _search,
      );
      _page = nextPage;
      state = AuctionListLoaded(
        auctions: [...current.auctions, ...response.items],
        status: _status,
        search: _search,
        page: response.page,
        total: response.total,
        hasNextPage: response.hasNextPage,
      );
    } catch (_) {
      return;
    }
  }
}

final auctionsListProvider =
    StateNotifierProvider<AuctionsListNotifier, AuctionListState>((ref) {
  final repository = ref.watch(auctionRepositoryProvider);
  return AuctionsListNotifier(repository);
});

class AuctionLiveState {
  final String auctionId;
  final AuctionStateSnapshot? snapshot;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const AuctionLiveState({
    required this.auctionId,
    this.snapshot,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  AuctionLiveState copyWith({
    AuctionStateSnapshot? snapshot,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearErrorMessage = false,
    bool clearSuccessMessage = false,
  }) {
    return AuctionLiveState(
      auctionId: auctionId,
      snapshot: snapshot ?? this.snapshot,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      successMessage:
          clearSuccessMessage ? null : successMessage ?? this.successMessage,
    );
  }
}

class AuctionLiveController extends StateNotifier<AuctionLiveState> {
  final AuctionRepository _repository;
  final Set<String> _seenEventIds = <String>{};

  AuctionLiveController(this._repository, String auctionId)
      : super(AuctionLiveState(auctionId: auctionId)) {
    load();
  }

  String get auctionId => state.auctionId;

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );
    try {
      final snapshot = await _repository.getState(state.auctionId);
      state = state.copyWith(snapshot: snapshot, isLoading: false);
    } on Failure catch (failure) {
      state = state.copyWith(isLoading: false, errorMessage: failure.message);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  void applyState(
    Map<String, dynamic> incomingState, {
    String message = 'Auction updated.',
  }) {
    final incomingVersion = auctionInt(incomingState['stateVersion']);
    final currentVersion = state.snapshot?.stateVersion ?? 0;
    if (incomingVersion < currentVersion) return;
    final snapshot = AuctionStateModel.fromJson(incomingState);
    state = state.copyWith(
      snapshot: snapshot,
      isSaving: false,
      successMessage: message,
      clearErrorMessage: true,
    );
  }

  void applyRealtimeEvent(AuctionRealtimeEvent event) {
    final eventAuctionId = event.auctionId;
    if (eventAuctionId != null && eventAuctionId != state.auctionId) return;

    if (event.name == 'auction:error') {
      final message = event.errorMessage;
      if (message != null && message.isNotEmpty) {
        state = state.copyWith(isSaving: false, errorMessage: message);
      }
      return;
    }

    final eventId = event.eventId;
    if (eventId != null && eventId.isNotEmpty) {
      if (_seenEventIds.contains(eventId)) return;
      if (_seenEventIds.length >= 200) {
        _seenEventIds.remove(_seenEventIds.first);
      }
      _seenEventIds.add(eventId);
    }

    final incoming = event.state;
    if (incoming != null) {
      applyState(incoming, message: _messageFor(event));
      return;
    }
    if (event.name == 'connection:status') return;
    unawaited(load());
  }

  String _messageFor(AuctionRealtimeEvent event) {
    switch (event.name) {
      case 'auction:bid_placed':
        return 'Bid accepted.';
      case 'auction:bid_rejected':
        return 'Bid rejected.';
      case 'auction:player_sold':
        return 'Player sold.';
      case 'auction:player_unsold':
        return 'Player marked unsold.';
      case 'auction:player_changed':
        return 'Next player is up for bidding.';
      case 'auction:completed':
        return 'Auction completed.';
      default:
        return 'Auction updated.';
    }
  }

  Future<bool> placeBid({
    required String teamId,
    double? amount,
  }) {
    return _runAction(
      () => _repository.placeBid(
        state.auctionId,
        teamId: teamId,
        amount: amount,
        expectedVersion: state.snapshot?.stateVersion,
        idempotencyKey: newAuctionRequestKey('bid'),
      ),
      successMessage: 'Bid placed.',
    );
  }

  Future<bool> start() {
    return _runAction(() => _repository.startAuction(
          state.auctionId,
          expectedVersion: state.snapshot?.stateVersion,
          idempotencyKey: newAuctionRequestKey('start'),
        ), successMessage: 'Auction started.');
  }

  Future<bool> pause() {
    return _runAction(() => _repository.pauseAuction(
          state.auctionId,
          expectedVersion: state.snapshot?.stateVersion,
          idempotencyKey: newAuctionRequestKey('pause'),
        ), successMessage: 'Auction paused.');
  }

  Future<bool> resume() {
    return _runAction(() => _repository.resumeAuction(
          state.auctionId,
          expectedVersion: state.snapshot?.stateVersion,
          idempotencyKey: newAuctionRequestKey('resume'),
        ), successMessage: 'Auction resumed.');
  }

  Future<bool> complete() {
    return _runAction(() => _repository.completeAuction(
          state.auctionId,
          expectedVersion: state.snapshot?.stateVersion,
          idempotencyKey: newAuctionRequestKey('complete'),
        ), successMessage: 'Auction completed.');
  }

  Future<bool> markSold() {
    return _runAction(() => _repository.markSold(
          state.auctionId,
          expectedVersion: state.snapshot?.stateVersion,
          idempotencyKey: newAuctionRequestKey('sold'),
        ), successMessage: 'Player sold.');
  }

  Future<bool> markUnsold({String? reason}) {
    return _runAction(() => _repository.markUnsold(
          state.auctionId,
          reason: reason,
          expectedVersion: state.snapshot?.stateVersion,
          idempotencyKey: newAuctionRequestKey('unsold'),
        ), successMessage: 'Player marked unsold.');
  }

  Future<bool> next() {
    return _runAction(() => _repository.nextPlayer(
          state.auctionId,
          expectedVersion: state.snapshot?.stateVersion,
          idempotencyKey: newAuctionRequestKey('next'),
        ), successMessage: 'Next player is up for bidding.');
  }

  Future<bool> bringForward(String auctionPlayerId) {
    return _runAction(
      () => _repository.bringPlayerForward(
        state.auctionId,
        auctionPlayerId,
        expectedVersion: state.snapshot?.stateVersion,
        idempotencyKey: newAuctionRequestKey('forward'),
      ),
      successMessage: 'Player brought forward.',
    );
  }

  Future<bool> _runAction(
    Future<AuctionStateSnapshot> Function() action, {
    required String successMessage,
  }) async {
    state = state.copyWith(
      isSaving: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );
    try {
      final snapshot = await action();
      state = state.copyWith(
        snapshot: snapshot,
        isSaving: false,
        successMessage: successMessage,
      );
      return true;
    } on Failure catch (failure) {
      state = state.copyWith(isSaving: false, errorMessage: failure.message);
      return false;
    } catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.toString());
      return false;
    }
  }
}

final auctionLiveControllerProvider = StateNotifierProvider.family<
    AuctionLiveController, AuctionLiveState, String>((ref, auctionId) {
  final repository = ref.watch(auctionRepositoryProvider);
  return AuctionLiveController(repository, auctionId);
});

final auctionRealtimeClientProvider = Provider<AuctionRealtimeClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final storage = ref.watch(secureStorageProvider);
  final client = SocketIOAuctionRealtimeClient(
    url: config.socketUrl,
    tokenProvider: SecureStorageRealtimeTokenProvider(storage),
  );

  ref.keepAlive();
  ref.onDispose(() => unawaited(client.dispose()));

  final currentAuth = ref.read(authStateProvider);
  if (currentAuth is Authenticated) unawaited(client.connect());

  ref.listen<AuthState>(authStateProvider, (_, auth) {
    if (auth is Authenticated) {
      unawaited(client.connect());
    } else {
      client.disconnect();
    }
  });

  return client;
});

const _auctionStateEventNames = <String>{
  'auction:state',
  'auction:started',
  'auction:player_changed',
  'auction:bid_placed',
  'auction:player_sold',
  'auction:player_unsold',
  'auction:paused',
  'auction:resumed',
  'auction:completed',
};

final auctionRoomProvider = Provider.family<bool, String>((ref, auctionId) {
  final client = ref.watch(auctionRealtimeClientProvider);
  final auth = ref.watch(authStateProvider);
  if (auth is! Authenticated) return false;

  unawaited(client.joinAuction(auctionId));

  final subscription = client.events.listen((event) {
    if (event.auctionId != null && event.auctionId != auctionId) return;
    ref.read(auctionLiveControllerProvider(auctionId).notifier)
        .applyRealtimeEvent(event);

    if (_auctionStateEventNames.contains(event.name)) {
      ref.invalidate(auctionsListProvider);
    }
  });

  ref.onDispose(() {
    subscription.cancel();
    client.leaveAuction(auctionId);
  });

  return true;
});
