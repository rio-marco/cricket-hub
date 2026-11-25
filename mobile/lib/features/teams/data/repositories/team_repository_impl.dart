import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/paginated_response.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_invitation.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/repositories/team_repository.dart';
import '../datasources/team_remote_datasource.dart';

/// Concrete implementation of [TeamRepository] managing API communication
/// and error-to-failure domain translation.
class TeamRepositoryImpl implements TeamRepository {
  final TeamRemoteDataSource _remoteDataSource;

  TeamRepositoryImpl({required TeamRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<PaginatedResponse<Team>> getTeams({
    int page = 1,
    int limit = 20,
    String? search,
    String? ownerId,
  }) async {
    try {
      return await _remoteDataSource.getTeams(
        page: page,
        limit: limit,
        search: search,
        ownerId: ownerId,
      );
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<Team> getTeamById(String id) async {
    try {
      return await _remoteDataSource.getTeamById(id);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<Team> createTeam({
    required String name,
    String? description,
    String? location,
    String? logo,
  }) async {
    try {
      return await _remoteDataSource.createTeam(
        name: name,
        description: description,
        location: location,
        logo: logo,
      );
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<Team> updateTeam(String id, Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.updateTeam(id, data);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> deleteTeam(String id) async {
    try {
      await _remoteDataSource.deleteTeam(id);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<List<TeamMember>> getTeamMembers(String teamId) async {
    try {
      return await _remoteDataSource.getTeamMembers(teamId);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<TeamInvitation> invitePlayer({
    required String teamId,
    required String playerId,
    String? message,
  }) async {
    try {
      return await _remoteDataSource.invitePlayer(
        teamId: teamId,
        playerId: playerId,
        message: message,
      );
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<TeamInvitation> requestToJoin(String teamId, {String? message}) async {
    try {
      return await _remoteDataSource.requestToJoin(teamId, message: message);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> respondToInvitation(String invitationId, bool accept) async {
    try {
      await _remoteDataSource.respondToInvitation(invitationId, accept);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<List<TeamInvitation>> getUserInvitations() async {
    try {
      return await _remoteDataSource.getUserInvitations();
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> removePlayer(String teamId, String playerId) async {
    try {
      await _remoteDataSource.removePlayer(teamId, playerId);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> updateMemberRole(
    String teamId,
    String memberId,
    String role,
  ) async {
    try {
      await _remoteDataSource.updateMemberRole(teamId, memberId, role);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> getTeamStats(String teamId) async {
    try {
      return await _remoteDataSource.getTeamStats(teamId);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<List<dynamic>> getTeamMatches(String teamId) async {
    try {
      return await _remoteDataSource.getTeamMatches(teamId);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }
}
