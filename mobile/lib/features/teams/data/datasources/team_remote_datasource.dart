import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/models/paginated_response.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/team_invitation.dart';
import '../../domain/entities/team_member.dart';
import '../models/team_model.dart';

/// Remote data source contract for team management and roster operations.
abstract class TeamRemoteDataSource {
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
    String? logo,
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
  Future<Map<String, dynamic>> getTeamStats(String teamId);
  Future<List<dynamic>> getTeamMatches(String teamId);
}

/// Implementation of [TeamRemoteDataSource] utilizing Dio HTTP client.
class TeamRemoteDataSourceImpl implements TeamRemoteDataSource {
  final Dio _dio;

  TeamRemoteDataSourceImpl(this._dio);

  @override
  Future<PaginatedResponse<Team>> getTeams({
    int page = 1,
    int limit = 20,
    String? search,
    String? ownerId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (ownerId != null && ownerId.isNotEmpty) {
        queryParams['owner'] = ownerId;
      }

      final response = await _dio.get(
        ApiEndpoints.teams,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return PaginatedResponse<Team>.fromJson(
          data,
          (item) => TeamModel.fromJson(item as Map<String, dynamic>),
        );
      } else if (data is List) {
        final teams = data
            .map((e) => TeamModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return PaginatedResponse<Team>(
          items: teams,
          total: teams.length,
          page: page,
          limit: limit,
          totalPages: 1,
        );
      }

      return PaginatedResponse<Team>.empty();
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<Team> getTeamById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.teamById(id));
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final map = data.containsKey('data') && data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : data;
        return TeamModel.fromJson(map);
      }
      throw const ServerException(message: 'Invalid response format for team detail.');
    } catch (e) {
      _handleError(e);
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
      final response = await _dio.post(
        ApiEndpoints.teams,
        data: {
          'name': name.trim(),
          if (description != null && description.isNotEmpty)
            'description': description.trim(),
          if (location != null && location.isNotEmpty)
            'location': location.trim(),
          if (logo != null && logo.isNotEmpty) 'logo': logo.trim(),
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final map = data.containsKey('data') && data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : data;
        return TeamModel.fromJson(map);
      }
      throw const ServerException(message: 'Invalid response format after creating team.');
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<Team> updateTeam(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.teamById(id),
        data: data,
      );

      final respData = response.data;
      if (respData is Map<String, dynamic>) {
        final map = respData.containsKey('data') && respData['data'] is Map<String, dynamic>
            ? respData['data'] as Map<String, dynamic>
            : respData;
        return TeamModel.fromJson(map);
      }
      throw const ServerException(message: 'Invalid response format updating team.');
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<void> deleteTeam(String id) async {
    try {
      await _dio.delete(ApiEndpoints.teamById(id));
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<List<TeamMember>> getTeamMembers(String teamId) async {
    try {
      final response = await _dio.get(ApiEndpoints.teamMembers(teamId));
      final data = response.data;

      List<dynamic> list = [];
      if (data is Map<String, dynamic>) {
        if (data['data'] is List) {
          list = data['data'] as List<dynamic>;
        } else if (data['members'] is List) {
          list = data['members'] as List<dynamic>;
        }
      } else if (data is List) {
        list = data;
      }

      return list
          .map((item) => TeamMember.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<TeamInvitation> invitePlayer({
    required String teamId,
    required String playerId,
    String? message,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.teamInvite(teamId),
        data: {
          'playerId': playerId,
          if (message != null && message.isNotEmpty) 'message': message,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final map = data.containsKey('data') && data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : data;
        return TeamInvitation.fromJson(map);
      }
      throw const ServerException(message: 'Failed to send invitation.');
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<TeamInvitation> requestToJoin(String teamId, {String? message}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.teamJoin(teamId),
        data: {
          if (message != null && message.isNotEmpty) 'message': message,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final map = data.containsKey('data') && data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : data;
        return TeamInvitation.fromJson(map);
      }
      throw const ServerException(message: 'Failed to submit join request.');
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<void> respondToInvitation(String invitationId, bool accept) async {
    try {
      await _dio.put(
        ApiEndpoints.respondToInvitation(invitationId),
        data: {'status': accept ? 'ACCEPTED' : 'REJECTED'},
      );
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<List<TeamInvitation>> getUserInvitations() async {
    try {
      final response = await _dio.get(ApiEndpoints.userInvitations);
      final data = response.data;

      List<dynamic> list = [];
      if (data is Map<String, dynamic>) {
        if (data['data'] is List) {
          list = data['data'] as List<dynamic>;
        } else if (data['invitations'] is List) {
          list = data['invitations'] as List<dynamic>;
        }
      } else if (data is List) {
        list = data;
      }

      return list
          .map((item) => TeamInvitation.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<void> removePlayer(String teamId, String playerId) async {
    try {
      await _dio.delete(ApiEndpoints.teamMemberById(teamId, playerId));
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<void> updateMemberRole(
    String teamId,
    String memberId,
    String role,
  ) async {
    try {
      await _dio.put(
        ApiEndpoints.teamMemberRole(teamId, memberId),
        data: {'role': role},
      );
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getTeamStats(String teamId) async {
    try {
      final response = await _dio.get(ApiEndpoints.teamStats(teamId));
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final wrapped = data['data'];
        if (wrapped is Map<String, dynamic>) return wrapped;
        return data;
      }
      return <String, dynamic>{};
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<List<dynamic>> getTeamMatches(String teamId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.teamMatches(teamId),
        queryParameters: {'limit': 20},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final wrapped = data['data'];
        if (wrapped is List) return wrapped;
      } else if (data is List) {
        return data;
      }
      return const [];
    } catch (e) {
      _handleError(e);
    }
  }

  Never _handleError(dynamic error) {
    if (error is AppException) throw error;

    if (error is DioException) {
      final response = error.response;
      final statusCode = response?.statusCode ?? 500;
      final responseData = response?.data;

      String message = 'An unexpected error occurred. Please try again.';
      Map<String, dynamic>? errors;

      if (responseData is Map<String, dynamic>) {
        message = responseData['message']?.toString() ??
            responseData['error']?.toString() ??
            message;
        if (responseData['errors'] is Map) {
          errors = Map<String, dynamic>.from(responseData['errors'] as Map);
        } else if (responseData['errors'] is List) {
          final mapped = <String, dynamic>{};
          for (final item in responseData['errors'] as List) {
            if (item is Map) {
              mapped[item['field']?.toString() ?? 'general'] =
                  item['message']?.toString() ?? 'Invalid value';
            }
          }
          if (mapped.isNotEmpty) errors = mapped;
        }
      } else if (responseData is String && responseData.isNotEmpty) {
        message = responseData;
      }

      if (statusCode == 401) {
        throw UnauthorizedException(message: message);
      } else if (statusCode == 403) {
        throw ForbiddenException(message: message);
      } else if (statusCode == 404) {
        throw NotFoundException(message: message);
      } else if (statusCode == 422 || (statusCode == 400 && errors != null)) {
        throw ValidationException(
          errors: errors ?? {'general': message},
          message: message,
        );
      } else {
        throw ServerException(
          message: message,
          statusCode: statusCode,
          errors: errors,
        );
      }
    }

    throw ServerException(message: error.toString());
  }
}
