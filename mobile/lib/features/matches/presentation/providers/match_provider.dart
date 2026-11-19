import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/errors/failures.dart';
import '../../data/datasources/match_remote_datasource.dart';
import '../../data/repositories/match_repository_impl.dart';
import '../../domain/entities/innings.dart';
import '../../domain/entities/match.dart';
import '../../domain/repositories/match_repository.dart';

// =============================================================================
// MATCH LIST STATE
// =============================================================================

class MatchListState {
  final List<Match> matches;
  final bool isLoading;
  final String? errorMessage;
  final String selectedTab; // 'LIVE', 'UPCOMING', 'COMPLETED'
  final String searchQuery;

  const MatchListState({
    this.matches = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedTab = 'LIVE',
    this.searchQuery = '',
  });

  MatchListState copyWith({
    List<Match>? matches,
    bool? isLoading,
    String? errorMessage,
    String? selectedTab,
    String? searchQuery,
  }) {
    return MatchListState(
      matches: matches ?? this.matches,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedTab: selectedTab ?? this.selectedTab,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// =============================================================================
// MATCH LIST NOTIFIER
// =============================================================================

class MatchListNotifier extends StateNotifier<MatchListState> {
  final MatchRepository _repository;

  MatchListNotifier(this._repository) : super(const MatchListState()) {
    loadMatches();
  }

  /// Loads matches according to current tab (LIVE, UPCOMING, COMPLETED)
  Future<void> loadMatches({bool refresh = false}) async {
    if (!refresh && state.matches.isNotEmpty && state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      List<Match> results;
      switch (state.selectedTab) {
        case 'LIVE':
          results = await _repository.getLiveMatches();
          break;
        case 'UPCOMING':
          results = await _repository.getUpcomingMatches();
          break;
        case 'COMPLETED':
          results = await _repository.getCompletedMatches();
          break;
        default:
          results = await _repository.getMatches(
            status: state.selectedTab == 'ALL' ? null : state.selectedTab,
            search: state.searchQuery.isEmpty ? null : state.searchQuery,
          );
      }

      // Filter by search query if present
      if (state.searchQuery.trim().isNotEmpty) {
        final q = state.searchQuery.toLowerCase();
        results = results.where((m) {
          return m.teamAName.toLowerCase().contains(q) ||
              m.teamBName.toLowerCase().contains(q) ||
              (m.venue != null && m.venue!.toLowerCase().contains(q)) ||
              (m.tournamentName != null && m.tournamentName!.toLowerCase().contains(q));
        }).toList();
      }

      state = state.copyWith(
        matches: results,
        isLoading: false,
        errorMessage: null,
      );
    } on Failure catch (f) {
      state = state.copyWith(isLoading: false, errorMessage: f.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Switches tab selection
  void setSelectedTab(String tab) {
    if (state.selectedTab == tab) return;
    state = state.copyWith(selectedTab: tab);
    loadMatches();
  }

  /// Updates keyword query
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadMatches();
  }

  /// Resets search
  void clearSearch() {
    state = state.copyWith(searchQuery: '');
    loadMatches();
  }
}

// =============================================================================
// MATCH ACTION STATE & NOTIFIER (Create Match, Record Toss, Live Scorer)
// =============================================================================

class MatchActionState {
  final bool isLoading;
  final String? successMessage;
  final String? errorMessage;

  const MatchActionState({
    this.isLoading = false,
    this.successMessage,
    this.errorMessage,
  });
}

class MatchActionNotifier extends StateNotifier<MatchActionState> {
  final MatchRepository _repository;

  MatchActionNotifier(this._repository) : super(const MatchActionState());

  /// Creates a new match
  Future<Match?> createMatch(Map<String, dynamic> data) async {
    state = const MatchActionState(isLoading: true);
    try {
      final match = await _repository.createMatch(data);
      state = const MatchActionState(
        isLoading: false,
        successMessage: 'Match fixture created successfully!',
      );
      return match;
    } on Failure catch (f) {
      state = MatchActionState(isLoading: false, errorMessage: f.message);
      return null;
    } catch (e) {
      state = MatchActionState(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Records toss decision
  Future<Match?> recordToss({
    required String matchId,
    required String winnerTeamId,
    required String decision,
  }) async {
    state = const MatchActionState(isLoading: true);
    try {
      final updated = await _repository.recordToss(matchId, winnerTeamId, decision);
      state = const MatchActionState(
        isLoading: false,
        successMessage: 'Toss outcome recorded successfully!',
      );
      return updated;
    } on Failure catch (f) {
      state = MatchActionState(isLoading: false, errorMessage: f.message);
      return null;
    } catch (e) {
      state = MatchActionState(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }
}

// =============================================================================
// RIVERPOD PROVIDERS
// =============================================================================

/// Match remote datasource provider
final matchRemoteDataSourceProvider = Provider<MatchRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MatchRemoteDataSourceImpl(apiClient.dio);
});

/// Match repository provider
final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  final remoteDataSource = ref.watch(matchRemoteDataSourceProvider);
  return MatchRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// Main match list provider with tab control
final matchesListProvider =
    StateNotifierProvider<MatchListNotifier, MatchListState>((ref) {
  final repository = ref.watch(matchRepositoryProvider);
  return MatchListNotifier(repository);
});

/// Live matches stream/polling provider
final liveMatchesProvider = FutureProvider<List<Match>>((ref) async {
  final repository = ref.watch(matchRepositoryProvider);
  return repository.getLiveMatches();
});

/// Upcoming matches provider
final upcomingMatchesProvider = FutureProvider<List<Match>>((ref) async {
  final repository = ref.watch(matchRepositoryProvider);
  return repository.getUpcomingMatches();
});

/// Completed matches provider
final completedMatchesProvider = FutureProvider<List<Match>>((ref) async {
  final repository = ref.watch(matchRepositoryProvider);
  return repository.getCompletedMatches();
});

/// Match detail provider by ID
final matchDetailProvider =
    FutureProvider.family<Match, String>((ref, id) async {
  final repository = ref.watch(matchRepositoryProvider);
  return repository.getMatchById(id);
});

/// Innings scorecard provider
final matchInningsProvider =
    FutureProvider.family<Innings, (String, int)>((ref, args) async {
  final (matchId, inningsNum) = args;
  final repository = ref.watch(matchRepositoryProvider);
  return repository.getInnings(matchId, inningsNum);
});

/// Complete Scorecard provider
final matchScorecardProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, matchId) async {
  final repository = ref.watch(matchRepositoryProvider);
  return repository.getScorecard(matchId);
});

/// Ball-by-ball commentary provider
final matchCommentaryProvider =
    FutureProvider.family<List<dynamic>, String>((ref, matchId) async {
  final repository = ref.watch(matchRepositoryProvider);
  return repository.getCommentary(matchId);
});

/// Match action notifier provider
final matchActionProvider =
    StateNotifierProvider<MatchActionNotifier, MatchActionState>((ref) {
  final repository = ref.watch(matchRepositoryProvider);
  return MatchActionNotifier(repository);
});
