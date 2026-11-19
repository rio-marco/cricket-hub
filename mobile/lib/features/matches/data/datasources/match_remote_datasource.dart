import 'package:dio/dio.dart';
import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/core/errors/exceptions.dart';
import '../models/innings_model.dart';
import '../models/match_model.dart';

/// Remote data source interface for cricket matches and live scorecards.
abstract class MatchRemoteDataSource {
  Future<List<MatchModel>> getMatches({
    int page = 1,
    int limit = 20,
    String? status,
    String? tournamentId,
    String? teamId,
    String? search,
  });

  Future<List<MatchModel>> getLiveMatches();

  Future<List<MatchModel>> getUpcomingMatches();

  Future<List<MatchModel>> getCompletedMatches();

  Future<MatchModel> getMatchById(String id);

  Future<MatchModel> createMatch(Map<String, dynamic> data);

  Future<MatchModel> updateMatch(String id, Map<String, dynamic> data);

  Future<MatchModel> recordToss(String matchId, String winnerTeamId, String decision);

  Future<InningsModel> getInnings(String matchId, int inningsNumber);

  Future<Map<String, dynamic>> getScorecard(String matchId);

  Future<List<dynamic>> getCommentary(String matchId);
}

/// Remote data source implementation using Dio HTTP client.
class MatchRemoteDataSourceImpl implements MatchRemoteDataSource {
  final Dio _dio;

  MatchRemoteDataSourceImpl(this._dio);

  @override
  Future<List<MatchModel>> getMatches({
    int page = 1,
    int limit = 20,
    String? status,
    String? tournamentId,
    String? teamId,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (status != null && status.isNotEmpty && status != 'ALL') 'status': status,
        if (tournamentId != null && tournamentId.isNotEmpty) 'tournament': tournamentId,
        if (teamId != null && teamId.isNotEmpty) 'team': teamId,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      };

      final response = await _dio.get(
        ApiEndpoints.matches,
        queryParameters: queryParams,
      );

      return _extractMatchList(response.data);
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<List<MatchModel>> getLiveMatches() async {
    try {
      final response = await _dio.get(ApiEndpoints.liveMatches);
      return _extractMatchList(response.data);
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<List<MatchModel>> getUpcomingMatches() async {
    try {
      final response = await _dio.get(ApiEndpoints.upcomingMatches);
      return _extractMatchList(response.data);
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<List<MatchModel>> getCompletedMatches() async {
    try {
      final response = await _dio.get(ApiEndpoints.completedMatches);
      return _extractMatchList(response.data);
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<MatchModel> getMatchById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.matchById(id));
      final data = response.data;

      if (data is Map<String, dynamic>) {
        final map = data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : (data['match'] is Map<String, dynamic>
                ? data['match'] as Map<String, dynamic>
                : data);
        return MatchModel.fromJson(map);
      }
      throw const ServerException(message: 'Invalid match response format.');
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<MatchModel> createMatch(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.matches,
        data: data,
      );

      final resData = response.data;
      if (resData is Map<String, dynamic>) {
        final map = resData['data'] is Map<String, dynamic>
            ? resData['data'] as Map<String, dynamic>
            : (resData['match'] is Map<String, dynamic>
                ? resData['match'] as Map<String, dynamic>
                : resData);
        return MatchModel.fromJson(map);
      }
      throw const ServerException(message: 'Failed to create match fixture.');
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<MatchModel> updateMatch(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.matchById(id),
        data: data,
      );

      final resData = response.data;
      if (resData is Map<String, dynamic>) {
        final map = resData['data'] is Map<String, dynamic>
            ? resData['data'] as Map<String, dynamic>
            : (resData['match'] is Map<String, dynamic>
                ? resData['match'] as Map<String, dynamic>
                : resData);
        return MatchModel.fromJson(map);
      }
      throw const ServerException(message: 'Failed to update match.');
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<MatchModel> recordToss(
    String matchId,
    String winnerTeamId,
    String decision,
  ) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.matchToss(matchId),
        data: {
          'winner': winnerTeamId,
          'decision': decision,
        },
      );

      final resData = response.data;
      if (resData is Map<String, dynamic>) {
        final map = resData['data'] is Map<String, dynamic>
            ? resData['data'] as Map<String, dynamic>
            : (resData['match'] is Map<String, dynamic>
                ? resData['match'] as Map<String, dynamic>
                : resData);
        return MatchModel.fromJson(map);
      }
      throw const ServerException(message: 'Failed to record toss decision.');
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<InningsModel> getInnings(String matchId, int inningsNumber) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.matchById(matchId)}/innings/$inningsNumber',
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final map = data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : (data['innings'] is Map<String, dynamic>
                ? data['innings'] as Map<String, dynamic>
                : data);
        return InningsModel.fromJson(map);
      }
      throw const ServerException(message: 'Failed to load innings.');
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getScorecard(String matchId) async {
    try {
      final response = await _dio.get(ApiEndpoints.scorecardByMatchId(matchId));
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<List<dynamic>> getCommentary(String matchId) async {
    try {
      final response = await _dio.get(ApiEndpoints.commentaryByMatchId(matchId));
      final data = response.data;

      if (data is Map<String, dynamic>) {
        if (data['data'] is List) return data['data'] as List;
        if (data['commentary'] is List) return data['commentary'] as List;
        if (data['deliveries'] is List) return data['deliveries'] as List;
      } else if (data is List) {
        return data;
      }
      return [];
    } catch (e) {
      _handleError(e);
    }
  }

  List<MatchModel> _extractMatchList(dynamic data) {
    List<dynamic> list = [];
    if (data is Map<String, dynamic>) {
      if (data['data'] is List) {
        list = data['data'] as List;
      } else if (data['matches'] is List) {
        list = data['matches'] as List;
      } else if (data['items'] is List) {
        list = data['items'] as List;
      }
    } else if (data is List) {
      list = data;
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map((item) => MatchModel.fromJson(item))
        .toList();
  }

  Never _handleError(dynamic error) {
    if (error is AppException) throw error;

    if (error is DioException) {
      final response = error.response;
      final statusCode = response?.statusCode ?? 500;
      final responseData = response?.data;

      String message = 'An unexpected match service error occurred.';
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
