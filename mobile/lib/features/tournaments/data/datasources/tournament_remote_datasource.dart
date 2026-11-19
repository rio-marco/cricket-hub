import 'package:dio/dio.dart';
import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/core/errors/exceptions.dart';
import '../models/tournament_model.dart';
import '../models/tournament_team_model.dart';

/// Remote data source interface for tournament operations.
abstract class TournamentRemoteDataSource {
  Future<List<TournamentModel>> getTournaments({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  });

  Future<TournamentModel> getTournamentById(String id);

  Future<TournamentModel> createTournament(Map<String, dynamic> data);

  Future<TournamentModel> updateTournament(String id, Map<String, dynamic> data);

  Future<void> deleteTournament(String id);

  Future<TournamentTeamModel> registerTeam(String tournamentId, String teamId);

  Future<List<TournamentTeamModel>> getRegisteredTeams(String tournamentId);

  Future<List<dynamic>> getFixtures(String tournamentId);

  Future<List<dynamic>> generateFixtures(String tournamentId);

  Future<List<TournamentTeamModel>> getPointsTable(String tournamentId);
}

/// Implementation of [TournamentRemoteDataSource] using Dio HTTP client.
class TournamentRemoteDataSourceImpl implements TournamentRemoteDataSource {
  final Dio _dio;

  TournamentRemoteDataSourceImpl(this._dio);

  @override
  Future<List<TournamentModel>> getTournaments({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (status != null && status.isNotEmpty && status != 'ALL') 'status': status,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      };

      final response = await _dio.get(
        ApiEndpoints.tournaments,
        queryParameters: queryParams,
      );

      final data = response.data;
      List<dynamic> list = [];
      if (data is Map<String, dynamic>) {
        if (data['data'] is List) {
          list = data['data'] as List;
        } else if (data['tournaments'] is List) {
          list = data['tournaments'] as List;
        } else if (data['items'] is List) {
          list = data['items'] as List;
        }
      } else if (data is List) {
        list = data;
      }

      return list
          .whereType<Map<String, dynamic>>()
          .map((item) => TournamentModel.fromJson(item))
          .toList();
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<TournamentModel> getTournamentById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.tournamentById(id));
      final data = response.data;

      if (data is Map<String, dynamic>) {
        final map = data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : (data['tournament'] is Map<String, dynamic>
                ? data['tournament'] as Map<String, dynamic>
                : data);
        return TournamentModel.fromJson(map);
      }
      throw const ServerException(message: 'Invalid tournament data received.');
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<TournamentModel> createTournament(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.tournaments,
        data: data,
      );

      final resData = response.data;
      if (resData is Map<String, dynamic>) {
        final map = resData['data'] is Map<String, dynamic>
            ? resData['data'] as Map<String, dynamic>
            : (resData['tournament'] is Map<String, dynamic>
                ? resData['tournament'] as Map<String, dynamic>
                : resData);
        return TournamentModel.fromJson(map);
      }
      throw const ServerException(message: 'Failed to create tournament.');
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<TournamentModel> updateTournament(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.tournamentById(id),
        data: data,
      );

      final resData = response.data;
      if (resData is Map<String, dynamic>) {
        final map = resData['data'] is Map<String, dynamic>
            ? resData['data'] as Map<String, dynamic>
            : (resData['tournament'] is Map<String, dynamic>
                ? resData['tournament'] as Map<String, dynamic>
                : resData);
        return TournamentModel.fromJson(map);
      }
      throw const ServerException(message: 'Failed to update tournament.');
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<void> deleteTournament(String id) async {
    try {
      await _dio.delete(ApiEndpoints.tournamentById(id));
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<TournamentTeamModel> registerTeam(String tournamentId, String teamId) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.tournamentTeams(tournamentId),
        data: {'teamId': teamId},
      );

      final resData = response.data;
      if (resData is Map<String, dynamic>) {
        final map = resData['data'] is Map<String, dynamic>
            ? resData['data'] as Map<String, dynamic>
            : resData;
        return TournamentTeamModel.fromJson(map);
      }
      throw const ServerException(message: 'Failed to register team for tournament.');
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<List<TournamentTeamModel>> getRegisteredTeams(String tournamentId) async {
    try {
      final response = await _dio.get(ApiEndpoints.tournamentTeams(tournamentId));
      final data = response.data;

      List<dynamic> list = [];
      if (data is Map<String, dynamic>) {
        if (data['data'] is List) {
          list = data['data'] as List;
        } else if (data['teams'] is List) {
          list = data['teams'] as List;
        }
      } else if (data is List) {
        list = data;
      }

      return list
          .whereType<Map<String, dynamic>>()
          .map((item) => TournamentTeamModel.fromJson(item))
          .toList();
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<List<dynamic>> getFixtures(String tournamentId) async {
    try {
      final response = await _dio.get(ApiEndpoints.tournamentFixtures(tournamentId));
      final data = response.data;

      if (data is Map<String, dynamic>) {
        if (data['data'] is List) return data['data'] as List;
        if (data['fixtures'] is List) return data['fixtures'] as List;
        if (data['matches'] is List) return data['matches'] as List;
      } else if (data is List) {
        return data;
      }
      return [];
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<List<dynamic>> generateFixtures(String tournamentId) async {
    try {
      final response = await _dio.post('${ApiEndpoints.tournamentFixtures(tournamentId)}/generate');
      final data = response.data;

      if (data is Map<String, dynamic>) {
        if (data['data'] is List) return data['data'] as List;
        if (data['fixtures'] is List) return data['fixtures'] as List;
      } else if (data is List) {
        return data;
      }
      return [];
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<List<TournamentTeamModel>> getPointsTable(String tournamentId) async {
    try {
      final response = await _dio.get(ApiEndpoints.tournamentStandings(tournamentId));
      final data = response.data;

      List<dynamic> list = [];
      if (data is Map<String, dynamic>) {
        if (data['data'] is List) {
          list = data['data'] as List;
        } else if (data['standings'] is List) {
          list = data['standings'] as List;
        } else if (data['teams'] is List) {
          list = data['teams'] as List;
        }
      } else if (data is List) {
        list = data;
      }

      return list
          .whereType<Map<String, dynamic>>()
          .map((item) => TournamentTeamModel.fromJson(item))
          .toList();
    } catch (e) {
      _handleError(e);
    }
  }

  /// Error mapping matching project conventions
  Never _handleError(dynamic error) {
    if (error is AppException) throw error;

    if (error is DioException) {
      final response = error.response;
      final statusCode = response?.statusCode ?? 500;
      final responseData = response?.data;

      String message = 'An unexpected tournament service error occurred.';
      Map<String, dynamic>? errors;

      if (responseData is Map<String, dynamic>) {
        message = responseData['message']?.toString() ??
            responseData['error']?.toString() ??
            message;
        if (responseData['errors'] is Map) {
          errors = Map<String, dynamic>.from(responseData['errors'] as Map);
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
