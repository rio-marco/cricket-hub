import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/player_remote_datasource.dart';
import '../../data/repositories/player_repository_impl.dart';
import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';

// =============================================================================
// DEPENDENCY INJECTION PROVIDERS
// =============================================================================

final playerRemoteDataSourceProvider = Provider<PlayerRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PlayerRemoteDataSourceImpl(apiClient.dio);
});

final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  final remote = ref.watch(playerRemoteDataSourceProvider);
  return PlayerRepositoryImpl(remoteDataSource: remote);
});

// =============================================================================
// PLAYERS LIST STATE & NOTIFIER
// =============================================================================

sealed class PlayerListState {
  const PlayerListState();
}

class PlayerListLoading extends PlayerListState {
  const PlayerListLoading();
}

class PlayerListLoaded extends PlayerListState {
  final List<Player> players;
  final String activeRole;
  final bool hasNextPage;
  final int page;
  final int total;

  const PlayerListLoaded({
    required this.players,
    this.activeRole = 'ALL',
    this.hasNextPage = false,
    this.page = 1,
    this.total = 0,
  });
}

class PlayerListEmpty extends PlayerListState {
  const PlayerListEmpty();
}

class PlayerListError extends PlayerListState {
  final String message;
  const PlayerListError(this.message);
}

class PlayerListNotifier extends StateNotifier<PlayerListState> {
  final PlayerRepository _repository;
  String _currentSearch = '';
  String _currentRole = 'ALL';
  int _currentPage = 1;

  PlayerListNotifier(this._repository) : super(const PlayerListLoading()) {
    fetchPlayers();
  }

  Future<void> fetchPlayers({
    String? search,
    String? role,
    bool refresh = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
    }
    _currentSearch = search ?? _currentSearch;
    _currentRole = role ?? _currentRole;

    if (state is! PlayerListLoaded || refresh) {
      state = const PlayerListLoading();
    }

    try {
      final response = await _repository.getPlayers(
        page: _currentPage,
        limit: 20,
        search: _currentSearch.isNotEmpty ? _currentSearch : null,
        role: _currentRole != 'ALL' ? _currentRole : null,
      );

      if (response.items.isEmpty && _currentPage == 1) {
        state = const PlayerListEmpty();
      } else {
        state = PlayerListLoaded(
          players: response.items,
          activeRole: _currentRole,
          hasNextPage: response.hasNextPage,
          page: response.page,
          total: response.total,
        );
      }
    } on Failure catch (f) {
      state = PlayerListError(f.message);
    } catch (e) {
      state = PlayerListError(e.toString());
    }
  }

  Future<void> filterByRole(String role) async {
    _currentRole = role;
    _currentPage = 1;
    await fetchPlayers(role: role, refresh: true);
  }

  Future<void> search(String query) async {
    _currentSearch = query;
    _currentPage = 1;
    await fetchPlayers(search: query, refresh: true);
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! PlayerListLoaded || !currentState.hasNextPage) return;

    try {
      final nextPage = currentState.page + 1;
      final response = await _repository.getPlayers(
        page: nextPage,
        limit: 20,
        search: _currentSearch.isNotEmpty ? _currentSearch : null,
        role: _currentRole != 'ALL' ? _currentRole : null,
      );

      _currentPage = nextPage;
      state = PlayerListLoaded(
        players: [...currentState.players, ...response.items],
        activeRole: _currentRole,
        hasNextPage: response.hasNextPage,
        page: response.page,
        total: response.total,
      );
    } catch (_) {
      // Keep existing list on failure
    }
  }
}

final playerListProvider =
    StateNotifierProvider<PlayerListNotifier, PlayerListState>((ref) {
  final repo = ref.watch(playerRepositoryProvider);
  return PlayerListNotifier(repo);
});

// =============================================================================
// PLAYER DETAIL STATE & NOTIFIER
// =============================================================================

sealed class PlayerDetailState {
  const PlayerDetailState();
}

class PlayerDetailLoading extends PlayerDetailState {
  const PlayerDetailLoading();
}

class PlayerDetailLoaded extends PlayerDetailState {
  final Player player;
  final Map<String, dynamic> stats;
  final List<dynamic> matchHistory;

  const PlayerDetailLoaded({
    required this.player,
    this.stats = const {},
    this.matchHistory = const [],
  });
}

class PlayerDetailError extends PlayerDetailState {
  final String message;
  const PlayerDetailError(this.message);
}

class PlayerDetailNotifier extends StateNotifier<PlayerDetailState> {
  final PlayerRepository _repository;
  final String _playerId;

  PlayerDetailNotifier(this._repository, this._playerId)
      : super(const PlayerDetailLoading()) {
    loadPlayerDetail();
  }

  Future<void> loadPlayerDetail() async {
    state = const PlayerDetailLoading();
    try {
      final results = await Future.wait([
        _repository.getPlayerById(_playerId),
        _repository.getPlayerStats(_playerId),
        _repository.getPlayerMatches(_playerId),
      ]);
      final player = results[0] as Player;
      final stats = results[1] as Map<String, dynamic>;
      final matches = results[2] as List<dynamic>;

      state = PlayerDetailLoaded(
        player: Player.applyCareerStats(player, stats),
        stats: stats,
        matchHistory: matches,
      );
    } on Failure catch (f) {
      state = PlayerDetailError(f.message);
    } catch (e) {
      state = PlayerDetailError(e.toString());
    }
  }
}

final playerDetailProvider = StateNotifierProvider.family<PlayerDetailNotifier,
    PlayerDetailState, String>((ref, playerId) {
  final repo = ref.watch(playerRepositoryProvider);
  return PlayerDetailNotifier(repo, playerId);
});

// =============================================================================
// CURRENT LOGGED IN USER PLAYER PROFILE PROVIDER
// =============================================================================

final myPlayerProfileProvider = FutureProvider<Player?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final repo = ref.watch(playerRepositoryProvider);
  return await repo.getPlayerByUserId(user.id, searchName: user.name);
});

// =============================================================================
// CREATE / EDIT PLAYER CONTROLLER
// =============================================================================

class CreatePlayerNotifier extends StateNotifier<AsyncValue<Player?>> {
  final PlayerRepository _repository;

  CreatePlayerNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<Player?> createPlayer(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final player = await _repository.createPlayer(data);
      state = AsyncValue.data(player);
      return player;
    } on Failure catch (f) {
      state = AsyncValue.error(f.message, StackTrace.current);
      return null;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return null;
    }
  }

  Future<Player?> updatePlayer(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final player = await _repository.updatePlayer(id, data);
      state = AsyncValue.data(player);
      return player;
    } on Failure catch (f) {
      state = AsyncValue.error(f.message, StackTrace.current);
      return null;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return null;
    }
  }
}

final createPlayerProvider =
    StateNotifierProvider<CreatePlayerNotifier, AsyncValue<Player?>>((ref) {
  final repo = ref.watch(playerRepositoryProvider);
  return CreatePlayerNotifier(repo);
});
