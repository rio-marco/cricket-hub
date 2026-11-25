import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/team_remote_datasource.dart';
import '../../data/repositories/team_repository_impl.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_invitation.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/repositories/team_repository.dart';

// =============================================================================
// DEPENDENCY INJECTION PROVIDERS
// =============================================================================

final teamRemoteDataSourceProvider = Provider<TeamRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TeamRemoteDataSourceImpl(apiClient.dio);
});

final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  final remoteDataSource = ref.watch(teamRemoteDataSourceProvider);
  return TeamRepositoryImpl(remoteDataSource: remoteDataSource);
});

// =============================================================================
// TEAMS LIST STATE & NOTIFIER
// =============================================================================

sealed class TeamListState {
  const TeamListState();
}

class TeamListLoading extends TeamListState {
  const TeamListLoading();
}

class TeamListLoaded extends TeamListState {
  final List<Team> teams;
  final bool hasNextPage;
  final int page;
  final int total;

  const TeamListLoaded({
    required this.teams,
    this.hasNextPage = false,
    this.page = 1,
    this.total = 0,
  });
}

class TeamListEmpty extends TeamListState {
  const TeamListEmpty();
}

class TeamListError extends TeamListState {
  final String message;
  const TeamListError(this.message);
}

class TeamsListNotifier extends StateNotifier<TeamListState> {
  final TeamRepository _repository;
  String _currentSearch = '';
  int _currentPage = 1;

  TeamsListNotifier(this._repository) : super(const TeamListLoading()) {
    fetchTeams();
  }

  Future<void> fetchTeams({String? search, bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
    }
    _currentSearch = search ?? _currentSearch;

    if (state is! TeamListLoaded || refresh) {
      state = const TeamListLoading();
    }

    try {
      final response = await _repository.getTeams(
        page: _currentPage,
        limit: 20,
        search: _currentSearch.isNotEmpty ? _currentSearch : null,
      );

      if (response.items.isEmpty && _currentPage == 1) {
        state = const TeamListEmpty();
      } else {
        state = TeamListLoaded(
          teams: response.items,
          hasNextPage: response.hasNextPage,
          page: response.page,
          total: response.total,
        );
      }
    } on Failure catch (f) {
      state = TeamListError(f.message);
    } catch (e) {
      state = TeamListError(e.toString());
    }
  }

  Future<void> search(String query) async {
    _currentSearch = query;
    _currentPage = 1;
    await fetchTeams(search: query, refresh: true);
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! TeamListLoaded || !currentState.hasNextPage) return;

    try {
      final nextPage = currentState.page + 1;
      final response = await _repository.getTeams(
        page: nextPage,
        limit: 20,
        search: _currentSearch.isNotEmpty ? _currentSearch : null,
      );

      _currentPage = nextPage;
      state = TeamListLoaded(
        teams: [...currentState.teams, ...response.items],
        hasNextPage: response.hasNextPage,
        page: response.page,
        total: response.total,
      );
    } catch (_) {
      // Keep existing list on pagination failure
    }
  }
}

final teamsListProvider =
    StateNotifierProvider<TeamsListNotifier, TeamListState>((ref) {
  final repo = ref.watch(teamRepositoryProvider);
  return TeamsListNotifier(repo);
});

// =============================================================================
// MY TEAMS NOTIFIER
// =============================================================================

class MyTeamsNotifier extends StateNotifier<TeamListState> {
  final TeamRepository _repository;
  final String? _userId;

  MyTeamsNotifier(this._repository, this._userId)
      : super(const TeamListLoading()) {
    fetchMyTeams();
  }

  Future<void> fetchMyTeams() async {
    state = const TeamListLoading();
    try {
      final response = await _repository.getTeams(
        page: 1,
        limit: 50,
        ownerId: _userId,
      );

      if (response.items.isEmpty) {
        state = const TeamListEmpty();
      } else {
        state = TeamListLoaded(
          teams: response.items,
          total: response.items.length,
        );
      }
    } on Failure catch (f) {
      state = TeamListError(f.message);
    } catch (e) {
      state = TeamListError(e.toString());
    }
  }
}

final myTeamsProvider =
    StateNotifierProvider<MyTeamsNotifier, TeamListState>((ref) {
  final repo = ref.watch(teamRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  return MyTeamsNotifier(repo, user?.id);
});

// =============================================================================
// TEAM DETAIL STATE & NOTIFIER
// =============================================================================

sealed class TeamDetailState {
  const TeamDetailState();
}

class TeamDetailLoading extends TeamDetailState {
  const TeamDetailLoading();
}

class TeamDetailLoaded extends TeamDetailState {
  final Team team;
  final List<TeamMember> members;
  final Map<String, dynamic> stats;
  final List<dynamic> matches;

  const TeamDetailLoaded({
    required this.team,
    this.members = const [],
    this.stats = const {},
    this.matches = const [],
  });
}

class TeamDetailError extends TeamDetailState {
  final String message;
  const TeamDetailError(this.message);
}

class TeamDetailNotifier extends StateNotifier<TeamDetailState> {
  final TeamRepository _repository;
  final String _teamId;

  TeamDetailNotifier(this._repository, this._teamId)
      : super(const TeamDetailLoading()) {
    loadTeamDetail();
  }

  Future<void> loadTeamDetail() async {
    state = const TeamDetailLoading();
    try {
      final results = await Future.wait([
        _repository.getTeamById(_teamId),
        _repository.getTeamMembers(_teamId),
        _repository.getTeamStats(_teamId),
        _repository.getTeamMatches(_teamId),
      ]);
      state = TeamDetailLoaded(
        team: results[0] as Team,
        members: results[1] as List<TeamMember>,
        stats: results[2] as Map<String, dynamic>,
        matches: results[3] as List<dynamic>,
      );
    } on Failure catch (f) {
      state = TeamDetailError(f.message);
    } catch (e) {
      state = TeamDetailError(e.toString());
    }
  }

  Future<bool> invitePlayer(String playerId, [String? message]) async {
    try {
      await _repository.invitePlayer(
        teamId: _teamId,
        playerId: playerId,
        message: message,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateMemberRole(String memberId, String newRole) async {
    try {
      await _repository.updateMemberRole(_teamId, memberId, newRole);
      await loadTeamDetail();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeMember(String playerId) async {
    try {
      await _repository.removePlayer(_teamId, playerId);
      await loadTeamDetail();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final teamDetailProvider = StateNotifierProvider.family<TeamDetailNotifier,
    TeamDetailState, String>((ref, teamId) {
  final repo = ref.watch(teamRepositoryProvider);
  return TeamDetailNotifier(repo, teamId);
});

// =============================================================================
// TEAM MEMBERS NOTIFIER
// =============================================================================

final teamMembersProvider =
    FutureProvider.family<List<TeamMember>, String>((ref, teamId) async {
  final repo = ref.watch(teamRepositoryProvider);
  return await repo.getTeamMembers(teamId);
});

// =============================================================================
// USER INVITATIONS STATE & NOTIFIER
// =============================================================================

sealed class InvitationsState {
  const InvitationsState();
}

class InvitationsLoading extends InvitationsState {
  const InvitationsLoading();
}

class InvitationsLoaded extends InvitationsState {
  final List<TeamInvitation> invitations;
  const InvitationsLoaded(this.invitations);
}

class InvitationsError extends InvitationsState {
  final String message;
  const InvitationsError(this.message);
}

class UserInvitationsNotifier extends StateNotifier<InvitationsState> {
  final TeamRepository _repository;
  final String? _userId;

  UserInvitationsNotifier(this._repository, this._userId)
      : super(const InvitationsLoading()) {
    fetchInvitations();
  }

  Future<void> fetchInvitations() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      state = const InvitationsLoaded([]);
      return;
    }
    state = const InvitationsLoading();
    try {
      final invitations = await _repository.getUserInvitations();
      state = InvitationsLoaded(invitations);
    } on Failure catch (f) {
      state = InvitationsError(f.message);
    } catch (e) {
      state = InvitationsError(e.toString());
    }
  }

  Future<bool> respond(String invitationId, bool accept) async {
    try {
      await _repository.respondToInvitation(invitationId, accept);
      await fetchInvitations();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final userInvitationsProvider =
    StateNotifierProvider<UserInvitationsNotifier, InvitationsState>((ref) {
  final repo = ref.watch(teamRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  return UserInvitationsNotifier(repo, user?.id);
});

// =============================================================================
// CREATE TEAM CONTROLLER
// =============================================================================

class CreateTeamNotifier extends StateNotifier<AsyncValue<Team?>> {
  final TeamRepository _repository;

  CreateTeamNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<Team?> createTeam({
    required String name,
    String? description,
    String? location,
    String? logo,
  }) async {
    state = const AsyncValue.loading();
    try {
      final newTeam = await _repository.createTeam(
        name: name,
        description: description,
        location: location,
        logo: logo,
      );
      state = AsyncValue.data(newTeam);
      return newTeam;
    } on Failure catch (f) {
      state = AsyncValue.error(f.message, StackTrace.current);
      return null;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return null;
    }
  }
}

final createTeamProvider =
    StateNotifierProvider<CreateTeamNotifier, AsyncValue<Team?>>((ref) {
  final repo = ref.watch(teamRepositoryProvider);
  return CreateTeamNotifier(repo);
});
