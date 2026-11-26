import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/paginated_response.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/entities/admin_auction.dart';
import '../../domain/entities/admin_audit_log.dart';
import '../../domain/entities/admin_dashboard_stats.dart';
import '../../domain/entities/admin_match.dart';
import '../../domain/entities/admin_notification_delivery.dart';
import '../../domain/entities/admin_player.dart';
import '../../domain/entities/admin_report_entry.dart';
import '../../domain/entities/admin_team.dart';
import '../../domain/entities/admin_tournament.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/repositories/admin_repository.dart';

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  return AdminRemoteDataSourceImpl(ref.watch(apiClientProvider));
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(
    remoteDataSource: ref.watch(adminRemoteDataSourceProvider),
  );
});

class AdminDashboardState {
  final AdminDashboardStats? stats;
  final bool isLoading;
  final String? errorMessage;

  const AdminDashboardState({
    this.stats,
    this.isLoading = false,
    this.errorMessage,
  });

  AdminDashboardState copyWith({
    AdminDashboardStats? stats,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdminDashboardState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AdminDashboardNotifier extends StateNotifier<AdminDashboardState> {
  final AdminRepository _repository;

  AdminDashboardNotifier(this._repository)
    : super(const AdminDashboardState(isLoading: true)) {
    load();
  }

  Future<void> load({bool refresh = false}) async {
    if (!refresh && state.isLoading && state.stats != null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final stats = await _repository.getDashboard();
      state = state.copyWith(stats: stats, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: _message(error));
    }
  }
}

final adminDashboardProvider =
    StateNotifierProvider<AdminDashboardNotifier, AdminDashboardState>((ref) {
      return AdminDashboardNotifier(ref.watch(adminRepositoryProvider));
    });

class AdminListState<T> {
  final List<T> items;
  final String search;
  final String status;
  final int page;
  final int total;
  final bool hasNextPage;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  AdminListState({
    List<T>? items,
    this.search = '',
    this.status = '',
    this.page = 1,
    this.total = 0,
    this.hasNextPage = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  }) : items = items ?? <T>[];

  AdminListState<T> copyWith({
    List<T>? items,
    String? search,
    String? status,
    int? page,
    int? total,
    bool? hasNextPage,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AdminListState<T>(
      items: items ?? this.items,
      search: search ?? this.search,
      status: status ?? this.status,
      page: page ?? this.page,
      total: total ?? this.total,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

typedef AdminPageLoader<T> = Future<PaginatedResponse<T>> Function({
  required int page,
  required int limit,
  required String search,
  required String status,
});

class AdminListNotifier<T> extends StateNotifier<AdminListState<T>> {
  final AdminPageLoader<T> _loader;

  AdminListNotifier(this._loader) : super(AdminListState<T>(isLoading: true)) {
    load();
  }

  Future<void> load({bool refresh = false}) async {
    if (!refresh && state.isLoading && state.items.isNotEmpty) return;
    state = state.copyWith(
      isLoading: refresh || state.items.isEmpty,
      isLoadingMore: !refresh && state.items.isNotEmpty,
      clearError: true,
    );
    try {
      final result = await _loader(
        page: 1,
        limit: 20,
        search: state.search,
        status: state.status,
      );
      state = state.copyWith(
        items: result.items,
        page: result.page,
        total: result.total,
        hasNextPage: result.hasNextPage,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        errorMessage: _message(error),
      );
    }
  }

  Future<void> setSearch(String search) async {
    final value = search.trim();
    if (state.search == value) return;
    state = state.copyWith(search: value, items: <T>[]);
    await load(refresh: true);
  }

  Future<void> setStatus(String status) async {
    if (state.status == status) return;
    state = state.copyWith(status: status, items: <T>[]);
    await load(refresh: true);
  }

  Future<void> loadMore() async {
    if (!state.hasNextPage || state.isLoadingMore) return;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await _loader(
        page: nextPage,
        limit: 20,
        search: state.search,
        status: state.status,
      );
      state = state.copyWith(
        items: <T>[...state.items, ...result.items],
        page: result.page,
        total: result.total,
        hasNextPage: result.hasNextPage,
        isLoadingMore: false,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }
}

final adminUsersProvider =
    StateNotifierProvider<
      AdminListNotifier<AdminUser>,
      AdminListState<AdminUser>
    >((ref) {
      final repository = ref.watch(adminRepositoryProvider);
      return AdminListNotifier<AdminUser>(({
        required page,
        required limit,
        required search,
        required status,
      }) {
        return repository.getUsers(
          page: page,
          limit: limit,
          search: search.isEmpty ? null : search,
          status: status.isEmpty ? null : status,
        );
      });
    });

final adminTeamsProvider =
    StateNotifierProvider<
      AdminListNotifier<AdminTeam>,
      AdminListState<AdminTeam>
    >((ref) {
      final repository = ref.watch(adminRepositoryProvider);
      return AdminListNotifier<AdminTeam>(({
        required page,
        required limit,
        required search,
        required status,
      }) {
        return repository.getTeams(
          page: page,
          limit: limit,
          search: search.isEmpty ? null : search,
          status: status.isEmpty ? null : status,
        );
      });
    });

final adminPlayersProvider =
    StateNotifierProvider<
      AdminListNotifier<AdminPlayer>,
      AdminListState<AdminPlayer>
    >((ref) {
      final repository = ref.watch(adminRepositoryProvider);
      return AdminListNotifier<AdminPlayer>(({
        required page,
        required limit,
        required search,
        required status,
      }) {
        return repository.getPlayers(
          page: page,
          limit: limit,
          search: search.isEmpty ? null : search,
          role: status.isEmpty ? null : status,
        );
      });
    });

final adminTournamentsProvider =
    StateNotifierProvider<
      AdminListNotifier<AdminTournament>,
      AdminListState<AdminTournament>
    >((ref) {
      final repository = ref.watch(adminRepositoryProvider);
      return AdminListNotifier<AdminTournament>(({
        required page,
        required limit,
        required search,
        required status,
      }) {
        return repository.getTournaments(
          page: page,
          limit: limit,
          search: search.isEmpty ? null : search,
          status: status.isEmpty ? null : status,
        );
      });
    });

final adminMatchesProvider =
    StateNotifierProvider<
      AdminListNotifier<AdminMatch>,
      AdminListState<AdminMatch>
    >((ref) {
      final repository = ref.watch(adminRepositoryProvider);
      return AdminListNotifier<AdminMatch>(({
        required page,
        required limit,
        required search,
        required status,
      }) {
        return repository.getMatches(
          page: page,
          limit: limit,
          search: search.isEmpty ? null : search,
          status: status.isEmpty ? null : status,
        );
      });
    });

final adminAuctionsProvider =
    StateNotifierProvider<
      AdminListNotifier<AdminAuction>,
      AdminListState<AdminAuction>
    >((ref) {
      final repository = ref.watch(adminRepositoryProvider);
      return AdminListNotifier<AdminAuction>(({
        required page,
        required limit,
        required search,
        required status,
      }) {
        return repository.getAuctions(
          page: page,
          limit: limit,
          search: search.isEmpty ? null : search,
          status: status.isEmpty ? null : status,
        );
      });
    });

final adminNotificationDeliveriesProvider =
    StateNotifierProvider<
      AdminListNotifier<AdminNotificationDelivery>,
      AdminListState<AdminNotificationDelivery>
    >((ref) {
      final repository = ref.watch(adminRepositoryProvider);
      return AdminListNotifier<AdminNotificationDelivery>(({
        required page,
        required limit,
        required search,
        required status,
      }) {
        return repository.getNotificationDeliveries(
          page: page,
          limit: limit,
          search: search.isEmpty ? null : search,
          status: status.isEmpty ? null : status,
        );
      });
    });

final adminReportsProvider =
    StateNotifierProvider<
      AdminListNotifier<AdminReportEntry>,
      AdminListState<AdminReportEntry>
    >((ref) {
      final repository = ref.watch(adminRepositoryProvider);
      return AdminListNotifier<AdminReportEntry>(({
        required page,
        required limit,
        required search,
        required status,
      }) {
        return repository.getReports(
          page: page,
          limit: limit,
          search: search.isEmpty ? null : search,
          status: status.isEmpty ? null : status,
        );
      });
    });

final adminAuditsProvider =
    StateNotifierProvider<
      AdminListNotifier<AdminAuditLog>,
      AdminListState<AdminAuditLog>
    >((ref) {
      final repository = ref.watch(adminRepositoryProvider);
      return AdminListNotifier<AdminAuditLog>(({
        required page,
        required limit,
        required search,
        required status,
      }) {
        return repository.getAudits(
          page: page,
          limit: limit,
          search: search.isEmpty ? null : search,
          category: status.isEmpty ? null : status,
        );
      });
    });

final adminScoringAuditsProvider =
    StateNotifierProvider<
      AdminListNotifier<AdminAuditLog>,
      AdminListState<AdminAuditLog>
    >((ref) {
      final repository = ref.watch(adminRepositoryProvider);
      return AdminListNotifier<AdminAuditLog>(({
        required page,
        required limit,
        required search,
        required status,
      }) {
        return repository.getScoringAudits(
          page: page,
          limit: limit,
          search: search.isEmpty ? null : search,
        );
      });
    });

final adminAuctionAuditsProvider =
    StateNotifierProvider<
      AdminListNotifier<AdminAuditLog>,
      AdminListState<AdminAuditLog>
    >((ref) {
      final repository = ref.watch(adminRepositoryProvider);
      return AdminListNotifier<AdminAuditLog>(({
        required page,
        required limit,
        required search,
        required status,
      }) {
        return repository.getAuctionAudits(
          page: page,
          limit: limit,
          search: search.isEmpty ? null : search,
        );
      });
    });

final adminUserDetailProvider = FutureProvider.family<AdminUser, String>((
  ref,
  id,
) {
  return ref.watch(adminRepositoryProvider).getUser(id);
});

final adminTeamDetailProvider = FutureProvider.family<AdminTeam, String>((
  ref,
  id,
) {
  return ref.watch(adminRepositoryProvider).getTeam(id);
});

final adminPlayerDetailProvider = FutureProvider.family<AdminPlayer, String>((
  ref,
  id,
) {
  return ref.watch(adminRepositoryProvider).getPlayer(id);
});

final adminTournamentDetailProvider =
    FutureProvider.family<AdminTournament, String>((ref, id) {
      return ref.watch(adminRepositoryProvider).getTournament(id);
    });

final adminMatchDetailProvider = FutureProvider.family<AdminMatch, String>((
  ref,
  id,
) {
  return ref.watch(adminRepositoryProvider).getMatch(id);
});

final adminMatchScorecardProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) {
      return ref.watch(adminRepositoryProvider).getMatchScorecard(id);
    });

final adminMatchEventsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, id) {
      return ref.watch(adminRepositoryProvider).getMatchEvents(id);
    });

final adminAuctionDetailProvider = FutureProvider.family<AdminAuction, String>((
  ref,
  id,
) {
  return ref.watch(adminRepositoryProvider).getAuction(id);
});

final adminAuctionBidsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, id) {
      return ref.watch(adminRepositoryProvider).getAuctionBids(id);
    });

final adminAuctionAuditProvider =
    FutureProvider.family<List<AdminAuditLog>, String>((ref, id) {
      return ref.watch(adminRepositoryProvider).getAuctionAudit(id);
    });

final adminAuctionSuspiciousProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, id) {
      return ref
          .watch(adminRepositoryProvider)
          .getSuspiciousAuctionActivity(id);
    });

class AdminActionState {
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final Map<String, dynamic>? lastResult;

  const AdminActionState({
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.lastResult,
  });

  AdminActionState copyWith({
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    Map<String, dynamic>? lastResult,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearResult = false,
  }) {
    return AdminActionState(
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess
          ? null
          : successMessage ?? this.successMessage,
      lastResult: clearResult ? null : lastResult ?? this.lastResult,
    );
  }
}

class AdminActionNotifier extends StateNotifier<AdminActionState> {
  final AdminRepository _repository;
  final Ref _ref;

  AdminActionNotifier(this._repository, this._ref)
    : super(const AdminActionState());

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  Future<bool> setUserStatus(String id, String status) {
    return _run(
      () => _repository.updateUserStatus(id, status),
      successMessage: 'User status updated.',
      onSuccess: () {
        _ref.invalidate(adminUsersProvider);
        _ref.invalidate(adminUserDetailProvider(id));
      },
    );
  }

  Future<bool> setUserRole(String id, String role) {
    return _run(
      () => _repository.updateUserRole(id, role),
      successMessage: 'User role updated.',
      onSuccess: () {
        _ref.invalidate(adminUsersProvider);
        _ref.invalidate(adminUserDetailProvider(id));
      },
    );
  }

  Future<bool> setTeamStatus(String id, String status) {
    return _run(
      () => _repository.updateTeamStatus(id, status),
      successMessage: 'Team status updated.',
      onSuccess: () {
        _ref.invalidate(adminTeamsProvider);
        _ref.invalidate(adminTeamDetailProvider(id));
      },
    );
  }

  Future<bool> setTournamentStatus(String id, String status) {
    return _run(
      () => _repository.updateTournamentStatus(id, status),
      successMessage: 'Tournament status updated.',
      onSuccess: () {
        _ref.invalidate(adminTournamentsProvider);
        _ref.invalidate(adminTournamentDetailProvider(id));
      },
    );
  }

  Future<bool> decideTournamentTeam(
    String tournamentId,
    String teamId,
    String decision, {
    String? reason,
  }) {
    return _run(
      () => _repository.decideTournamentTeam(
        tournamentId,
        teamId,
        decision,
        reason: reason,
      ),
      successMessage: 'Tournament team decision recorded.',
      onSuccess: () {
        _ref.invalidate(adminTournamentDetailProvider(tournamentId));
      },
    );
  }

  Future<bool> setMatchStatus(String id, String status) {
    return _run(
      () => _repository.updateMatchStatus(id, status),
      successMessage: 'Match status updated.',
      onSuccess: () {
        _ref.invalidate(adminMatchesProvider);
        _ref.invalidate(adminMatchDetailProvider(id));
      },
    );
  }

  Future<bool> correctMatch(
    String id, {
    required String reason,
    required Map<String, dynamic> corrections,
  }) {
    return _run(
      () => _repository.correctMatch(
        id,
        reason: reason,
        corrections: corrections,
      ),
      successMessage: 'Correction recorded in the audit trail.',
      onSuccess: () {
        _ref.invalidate(adminMatchDetailProvider(id));
        _ref.invalidate(adminMatchScorecardProvider(id));
        _ref.invalidate(adminAuditsProvider);
      },
    );
  }

  Future<bool> broadcast({
    required String title,
    required String body,
    String? audience,
  }) {
    return _run(
      () => _repository.broadcastNotification(
        title: title,
        body: body,
        audience: audience,
      ),
      successMessage: 'Broadcast request accepted.',
      onSuccess: () => _ref.invalidate(adminNotificationDeliveriesProvider),
    );
  }

  Future<bool> sendToUsers({
    required List<String> userIds,
    required String title,
    required String body,
  }) {
    return _run(
      () => _repository.sendNotificationToUsers(
        userIds: userIds,
        title: title,
        body: body,
      ),
      successMessage: 'Notification request accepted.',
      onSuccess: () => _ref.invalidate(adminNotificationDeliveriesProvider),
    );
  }

  Future<bool> exportReports({String? format, String? status}) {
    return _run(
      () => _repository.exportReports(format: format, status: status),
      successMessage: 'Report export is ready.',
      storeResult: true,
    );
  }

  Future<bool> _run<T>(
    Future<T> Function() action, {
    required String successMessage,
    void Function()? onSuccess,
    bool storeResult = false,
  }) async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearSuccess: true,
      clearResult: !storeResult,
    );
    try {
      final result = await action();
      onSuccess?.call();
      state = state.copyWith(
        isSaving: false,
        successMessage: successMessage,
        lastResult: storeResult && result is Map
            ? Map<String, dynamic>.from(result as Map)
            : null,
      );
      return true;
    } catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: _message(error));
      return false;
    }
  }
}

final adminActionProvider =
    StateNotifierProvider<AdminActionNotifier, AdminActionState>((ref) {
      return AdminActionNotifier(ref.watch(adminRepositoryProvider), ref);
    });

String _message(Object error) {
  if (error is Failure) return error.message;
  return error.toString();
}
