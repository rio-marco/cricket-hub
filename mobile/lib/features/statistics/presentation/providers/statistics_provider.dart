import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/errors/failures.dart';
import '../../data/datasources/statistics_remote_datasource.dart';
import '../../data/repositories/statistics_repository_impl.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/player_statistics.dart';
import '../../domain/entities/statistics_filter.dart';
import '../../domain/entities/statistics_overview.dart';
import '../../domain/repositories/statistics_repository.dart';

final statisticsRemoteDataSourceProvider = Provider<StatisticsRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StatisticsRemoteDataSource(apiClient);
});

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  final remoteDataSource = ref.watch(statisticsRemoteDataSourceProvider);
  return StatisticsRepositoryImpl(remoteDataSource: remoteDataSource);
});

class StatisticsOverviewState {
  final StatisticsOverview? overview;
  final StatisticsFilter filter;
  final bool isLoading;
  final String? errorMessage;

  const StatisticsOverviewState({
    this.overview,
    this.filter = const StatisticsFilter(),
    this.isLoading = false,
    this.errorMessage,
  });

  StatisticsOverviewState copyWith({
    StatisticsOverview? overview,
    StatisticsFilter? filter,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StatisticsOverviewState(
      overview: overview ?? this.overview,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class StatisticsOverviewNotifier extends StateNotifier<StatisticsOverviewState> {
  final StatisticsRepository _repository;

  StatisticsOverviewNotifier(this._repository)
      : super(const StatisticsOverviewState(isLoading: true)) {
    load();
  }

  Future<void> load({bool refresh = false}) async {
    final current = state;
    if (current.isLoading && !refresh) return;

    state = current.copyWith(isLoading: true, clearError: true);
    try {
      final overview = await _repository.getOverview(filter: current.filter);
      state = state.copyWith(overview: overview, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _message(error),
      );
    }
  }

  Future<void> setFilter(StatisticsFilter filter) async {
    state = state.copyWith(
      filter: filter,
      isLoading: true,
      clearError: true,
    );
    await load(refresh: true);
  }
}

final statisticsOverviewProvider =
    StateNotifierProvider<StatisticsOverviewNotifier, StatisticsOverviewState>((ref) {
  final repository = ref.watch(statisticsRepositoryProvider);
  return StatisticsOverviewNotifier(repository);
});

class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final String metric;
  final StatisticsFilter filter;
  final int page;
  final int total;
  final bool hasNextPage;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  const LeaderboardState({
    this.entries = const <LeaderboardEntry>[],
    this.metric = 'runs',
    this.filter = const StatisticsFilter(),
    this.page = 1,
    this.total = 0,
    this.hasNextPage = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  bool get hasMore => hasNextPage || entries.length < total;

  LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    String? metric,
    StatisticsFilter? filter,
    int? page,
    int? total,
    bool? hasNextPage,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      metric: metric ?? this.metric,
      filter: filter ?? this.filter,
      page: page ?? this.page,
      total: total ?? this.total,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final StatisticsRepository _repository;

  LeaderboardNotifier(this._repository)
      : super(const LeaderboardState(isLoading: true)) {
    load();
  }

  Future<void> load({bool refresh = false}) async {
    final current = state;
    if (!refresh && current.isLoading) return;
    if (!refresh && !current.hasMore) return;

    final page = refresh ? 1 : current.page + 1;
    state = current.copyWith(
      page: page,
      isLoading: refresh,
      isLoadingMore: !refresh,
      clearError: true,
    );

    try {
      final result = await _repository.getLeaderboard(
        metric: current.metric,
        filter: current.filter,
        page: page,
        limit: 20,
      );
      final entries = refresh
          ? result.items
          : <LeaderboardEntry>[...current.entries, ...result.items];
      state = state.copyWith(
        entries: entries,
        page: result.page,
        total: result.total,
        hasNextPage: result.hasNextPage,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (error) {
      state = state.copyWith(
        page: refresh ? 1 : current.page,
        isLoading: false,
        isLoadingMore: false,
        errorMessage: _message(error),
      );
    }
  }

  Future<void> setMetric(String metric) async {
    if (state.metric == metric) return;
    state = state.copyWith(
      entries: const <LeaderboardEntry>[],
      metric: metric,
      page: 1,
      total: 0,
      hasNextPage: false,
      clearError: true,
    );
    await load(refresh: true);
  }

  Future<void> setFilter(StatisticsFilter filter) async {
    if (state.filter == filter) return;
    state = state.copyWith(
      entries: const <LeaderboardEntry>[],
      filter: filter,
      page: 1,
      total: 0,
      hasNextPage: false,
      clearError: true,
    );
    await load(refresh: true);
  }
}

final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  final repository = ref.watch(statisticsRepositoryProvider);
  return LeaderboardNotifier(repository);
});

final playerStatisticsProvider =
    FutureProvider.family<PlayerStatistics, String>((ref, playerId) async {
  final repository = ref.watch(statisticsRepositoryProvider);
  return repository.getPlayerStatistics(playerId);
});

String _message(Object error) {
  if (error is Failure) return error.message;
  return error.toString();
}
