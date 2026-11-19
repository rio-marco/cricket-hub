import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/errors/failures.dart';
import '../../data/datasources/tournament_remote_datasource.dart';
import '../../data/repositories/tournament_repository_impl.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_team.dart';
import '../../domain/repositories/tournament_repository.dart';

// =============================================================================
// TOURNAMENT LIST STATE
// =============================================================================

class TournamentListState {
  final List<Tournament> tournaments;
  final bool isLoading;
  final String? errorMessage;
  final String selectedStatus; // 'ALL', 'IN_PROGRESS', 'REGISTRATION_OPEN', 'COMPLETED'
  final String searchQuery;

  const TournamentListState({
    this.tournaments = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedStatus = 'ALL',
    this.searchQuery = '',
  });

  TournamentListState copyWith({
    List<Tournament>? tournaments,
    bool? isLoading,
    String? errorMessage,
    String? selectedStatus,
    String? searchQuery,
  }) {
    return TournamentListState(
      tournaments: tournaments ?? this.tournaments,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// =============================================================================
// TOURNAMENT LIST NOTIFIER
// =============================================================================

class TournamentListNotifier extends StateNotifier<TournamentListState> {
  final TournamentRepository _repository;

  TournamentListNotifier(this._repository) : super(const TournamentListState()) {
    loadTournaments();
  }

  /// Fetches tournaments matching current status tab and search query
  Future<void> loadTournaments({bool refresh = false}) async {
    if (!refresh && state.tournaments.isNotEmpty && state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final list = await _repository.getTournaments(
        status: state.selectedStatus == 'ALL' ? null : state.selectedStatus,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
      );
      state = state.copyWith(
        tournaments: list,
        isLoading: false,
        errorMessage: null,
      );
    } on Failure catch (f) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: f.message,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Switches status filter tab (ALL, IN_PROGRESS, REGISTRATION_OPEN, COMPLETED)
  void setStatusFilter(String status) {
    if (state.selectedStatus == status) return;
    state = state.copyWith(selectedStatus: status);
    loadTournaments();
  }

  /// Updates search keyword and refreshes query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadTournaments();
  }

  /// Clears active search
  void clearSearch() {
    state = state.copyWith(searchQuery: '');
    loadTournaments();
  }
}

// =============================================================================
// TOURNAMENT ACTION NOTIFIER (Create, Update, Register Team, Generate Fixtures)
// =============================================================================

class TournamentActionState {
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;

  const TournamentActionState({
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
  });
}

class TournamentActionNotifier extends StateNotifier<TournamentActionState> {
  final TournamentRepository _repository;

  TournamentActionNotifier(this._repository) : super(const TournamentActionState());

  /// Creates a new tournament
  Future<Tournament?> createTournament(Map<String, dynamic> data) async {
    state = const TournamentActionState(isLoading: true);
    try {
      final tournament = await _repository.createTournament(data);
      state = const TournamentActionState(
        isLoading: false,
        successMessage: 'Tournament created successfully!',
      );
      return tournament;
    } on Failure catch (f) {
      state = TournamentActionState(isLoading: false, errorMessage: f.message);
      return null;
    } catch (e) {
      state = TournamentActionState(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Registers a team
  Future<bool> registerTeam(String tournamentId, String teamId) async {
    state = const TournamentActionState(isLoading: true);
    try {
      await _repository.registerTeam(tournamentId, teamId);
      state = const TournamentActionState(
        isLoading: false,
        successMessage: 'Team registered for tournament!',
      );
      return true;
    } on Failure catch (f) {
      state = TournamentActionState(isLoading: false, errorMessage: f.message);
      return false;
    } catch (e) {
      state = TournamentActionState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Generates tournament match fixtures
  Future<bool> generateFixtures(String tournamentId) async {
    state = const TournamentActionState(isLoading: true);
    try {
      await _repository.generateFixtures(tournamentId);
      state = const TournamentActionState(
        isLoading: false,
        successMessage: 'Fixtures generated successfully!',
      );
      return true;
    } on Failure catch (f) {
      state = TournamentActionState(isLoading: false, errorMessage: f.message);
      return false;
    } catch (e) {
      state = TournamentActionState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

// =============================================================================
// RIVERPOD PROVIDERS
// =============================================================================

/// Remote data source provider
final tournamentRemoteDataSourceProvider = Provider<TournamentRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TournamentRemoteDataSourceImpl(apiClient.dio);
});

/// Tournament repository provider
final tournamentRepositoryProvider = Provider<TournamentRepository>((ref) {
  final remoteDataSource = ref.watch(tournamentRemoteDataSourceProvider);
  return TournamentRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// Main Tournament List provider
final tournamentsListProvider =
    StateNotifierProvider<TournamentListNotifier, TournamentListState>((ref) {
  final repository = ref.watch(tournamentRepositoryProvider);
  return TournamentListNotifier(repository);
});

/// Tournament Detail provider by ID
final tournamentDetailProvider =
    FutureProvider.family<Tournament, String>((ref, id) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.getTournamentById(id);
});

/// Standings / Points Table provider for a tournament
final pointsTableProvider =
    FutureProvider.family<List<TournamentTeam>, String>((ref, tournamentId) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.getPointsTable(tournamentId);
});

/// Tournament Fixtures provider
final tournamentFixturesProvider =
    FutureProvider.family<List<dynamic>, String>((ref, tournamentId) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.getFixtures(tournamentId);
});

/// Registered teams provider
final tournamentTeamsProvider =
    FutureProvider.family<List<TournamentTeam>, String>((ref, tournamentId) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.getRegisteredTeams(tournamentId);
});

/// Tournament actions provider (create, register, fixtures)
final tournamentActionProvider =
    StateNotifierProvider<TournamentActionNotifier, TournamentActionState>((ref) {
  final repository = ref.watch(tournamentRepositoryProvider);
  return TournamentActionNotifier(repository);
});
