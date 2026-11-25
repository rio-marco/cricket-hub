import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../domain/entities/dashboard_data.dart';

// =============================================================================
// REPOSITORY PROVIDER
// =============================================================================

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardRepository(apiClient);
});

// =============================================================================
// DASHBOARD STATE
// =============================================================================

sealed class DashboardState {
  const DashboardState();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardData data;
  const DashboardLoaded(this.data);
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
}

// =============================================================================
// DASHBOARD NOTIFIER
// =============================================================================

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;
  final String? _userId;

  DashboardNotifier(this._repository, this._userId)
      : super(const DashboardLoading()) {
    loadDashboard();
  }

  Future<void> loadDashboard({bool isRefresh = false}) async {
    if (!isRefresh && state is! DashboardLoaded) {
      state = const DashboardLoading();
    }

    try {
      final data = await _repository.getDashboardData(userId: _userId);
      state = DashboardLoaded(data);
    } on AppException catch (e) {
      state = DashboardError(Failure.fromException(e).message);
    } catch (e) {
      state = DashboardError(e.toString());
    }
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final repo = ref.watch(dashboardRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  return DashboardNotifier(repo, user?.id);
});
