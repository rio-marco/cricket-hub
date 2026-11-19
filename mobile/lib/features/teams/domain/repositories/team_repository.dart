import '../../../../core/models/paginated_response.dart';
import '../entities/team.dart';
import '../entities/team_invitation.dart';
import '../entities/team_member.dart';

/// Repository interface for Team domain logic.
abstract class TeamRepository {
  Future<PaginatedResponse<Team>> getTeams({
    int page = 1,
    int limit = 20,
    String? search,
    String? ownerId,
  });

  Future<Team> getTeamById(String id);

  Future<Team> createTeam({
    required String name,
    String? description,
    String? location,
    dynamic logoFile,
  });

  Future<Team> updateTeam(String id, Map<String, dynamic> data);

  Future<void> deleteTeam(String id);

  Future<List<TeamMember>> getTeamMembers(String teamId);

  Future<TeamInvitation> invitePlayer({
    required String teamId,
    required String playerId,
    String? message,
  });

  Future<TeamInvitation> requestToJoin(String teamId, {String? message});

  Future<void> respondToInvitation(String invitationId, bool accept);

  Future<List<TeamInvitation>> getUserInvitations();

  Future<void> removePlayer(String teamId, String playerId);

  Future<void> updateMemberRole(String teamId, String memberId, String role);
}
