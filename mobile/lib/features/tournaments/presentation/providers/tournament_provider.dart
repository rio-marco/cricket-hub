import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/errors/failures.dart';
import '../../data/datasources/tournament_remote_datasource.dart';
import '../../data/repositories/tournament_repository_impl.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_team.dart';
import '../../domain/repositories/tournament_repository.dart';

class TournamentListState {
  final List<Tournament> tournaments;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final String selectedStatus;
  final String searchQuery;
  final int page;
  final bool hasNextPage;

  const TournamentListState({
    this.tournaments = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.selectedStatus = 'ALL',
    this.searchQuery = '',
    this.page = 1,
    this.hasNextPage = true,
  });

  TournamentListState copyWith({
    List<Tournament>? tournaments,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? selectedStatus,
    String? searchQuery,
    int? page,
    bool? hasNextPage,
  }) {
    return TournamentListState(
      tournaments: tournaments ?? this.tournaments,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      page: page ?? this.page,
      hasNextPage: hasNextPage ?? this.hasNextPage,
    );
  }
}

class TournamentListNotifier extends StateNotifier<TournamentListState> {
  static const int _pageSize = 20;

  final TournamentRepository _repository;

  TournamentListNotifier(this._repository) : super(const TournamentListState()) {
    loadTournaments();
  }

  Future<void> loadTournaments({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      clearErrorMessage: true,
    );

    try {
      final list = await _repository.getTournaments(
        page: 1,
        limit: _pageSize,
        status: state.selectedStatus == 'ALL' ? null : state.selectedStatus,
        search: state.searchQuery.trim().isEmpty ? null : state.searchQuery.trim(),
      );
      state = state.copyWith(
        tournaments: list,
        page: 1,
        hasNextPage: list.length == _pageSize,
        isLoading: false,
        clearErrorMessage: true,
      );
    } on Failure catch (f) {
      state = state.copyWith(isLoading: false, errorMessage: f.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasNextPage) return;

    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, clearErrorMessage: true);

    try {
      final list = await _repository.getTournaments(
        page: nextPage,
        limit: _pageSize,
        status: state.selectedStatus == 'ALL' ? null : state.selectedStatus,
        search: state.searchQuery.trim().isEmpty ? null : state.searchQuery.trim(),
      );
      state = state.copyWith(
        tournaments: [...state.tournaments, ...list],
        page: nextPage,
        hasNextPage: list.length == _pageSize,
        isLoadingMore: false,
        clearErrorMessage: true,
      );
    } on Failure catch (f) {
      state = state.copyWith(isLoadingMore: false, errorMessage: f.message);
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, errorMessage: e.toString());
    }
  }

  void setStatusFilter(String status) {
    if (state.selectedStatus == status) return;
    state = state.copyWith(selectedStatus: status);
    loadTournaments(refresh: true);
  }

  void setSearchQuery(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query);
    loadTournaments(refresh: true);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
    loadTournaments(refresh: true);
  }
}

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

  Future<Tournament?> createTournament(
    Map<String, dynamic> data, {
    bool openRegistration = false,
  }) async {
    state = const TournamentActionState(isLoading: true);
    try {
      final tournament = await _repository.createTournament(data);
      final result = openRegistration
          ? await _repository.updateTournamentStatus(tournament.id, 'REGISTRATION_OPEN')
          : tournament;
      state = const TournamentActionState(
        isLoading: false,
        successMessage: 'Tournament created successfully!',
      );
      return result;
    } on Failure catch (f) {
      state = TournamentActionState(isLoading: false, errorMessage: f.message);
      return null;
    } catch (e) {
      state = TournamentActionState(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<Tournament?> updateTournament(String id, Map<String, dynamic> data) async {
    state = const TournamentActionState(isLoading: true);
    try {
      final tournament = await _repository.updateTournament(id, data);
      state = const TournamentActionState(
        isLoading: false,
        successMessage: 'Tournament updated successfully!',
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

  Future<bool> deleteTournament(String id) async {
    state = const TournamentActionState(isLoading: true);
    try {
      await _repository.deleteTournament(id);
      state = const TournamentActionState(
        isLoading: false,
        successMessage: 'Tournament deleted successfully!',
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

  Future<bool> updateStatus(String id, String status) async {
    state = const TournamentActionState(isLoading: true);
    try {
      await _repository.updateTournamentStatus(id, status);
      state = TournamentActionState(
        isLoading: false,
        successMessage: 'Tournament status updated to ${status.replaceAll('_', ' ').toLowerCase()}.',
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

  Future<bool> registerTeam(String tournamentId, String teamId) async {
    state = const TournamentActionState(isLoading: true);
    try {
      await _repository.registerTeam(tournamentId, teamId);
      state = const TournamentActionState(
        isLoading: false,
        successMessage: 'Team registration request submitted!',
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

  Future<bool> approveTeam(String tournamentId, String tournamentTeamId) async {
    state = const TournamentActionState(isLoading: true);
    try {
      await _repository.approveTeam(tournamentId, tournamentTeamId);
      state = const TournamentActionState(
        isLoading: false,
        successMessage: 'Team approved successfully!',
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

  Future<bool> rejectTeam(String tournamentId, String tournamentTeamId) async {
    state = const TournamentActionState(isLoading: true);
    try {
      await _repository.rejectTeam(tournamentId, tournamentTeamId);
      state = const TournamentActionState(
        isLoading: false,
        successMessage: 'Team registration rejected.',
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

final tournamentRemoteDataSourceProvider = Provider<TournamentRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TournamentRemoteDataSourceImpl(apiClient.dio);
});

final tournamentRepositoryProvider = Provider<TournamentRepository>((ref) {
  final remoteDataSource = ref.watch(tournamentRemoteDataSourceProvider);
  return TournamentRepositoryImpl(remoteDataSource: remoteDataSource);
});

final tournamentsListProvider =
    StateNotifierProvider<TournamentListNotifier, TournamentListState>((ref) {
  final repository = ref.watch(tournamentRepositoryProvider);
  return TournamentListNotifier(repository);
});

final tournamentDetailProvider =
    FutureProvider.family<Tournament, String>((ref, id) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.getTournamentById(id);
});

final pointsTableProvider =
    FutureProvider.family<List<TournamentTeam>, String>((ref, tournamentId) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.getPointsTable(tournamentId);
});

final tournamentFixturesProvider =
    FutureProvider.family<List<dynamic>, String>((ref, tournamentId) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.getFixtures(tournamentId);
});

final tournamentTeamsProvider =
    FutureProvider.family<List<TournamentTeam>, String>((ref, tournamentId) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.getRegisteredTeams(tournamentId);
});

final tournamentActionProvider =
    StateNotifierProvider<TournamentActionNotifier, TournamentActionState>((ref) {
  final repository = ref.watch(tournamentRepositoryProvider);
  return TournamentActionNotifier(repository);
});
