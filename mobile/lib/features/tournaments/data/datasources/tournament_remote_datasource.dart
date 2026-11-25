import 'package:dio/dio.dart';
import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/core/errors/exceptions.dart';
import '../models/tournament_model.dart';
import '../models/tournament_team_model.dart';

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

  Future<TournamentModel> updateTournamentStatus(String id, String status);

  Future<void> deleteTournament(String id);

  Future<TournamentTeamModel> registerTeam(String tournamentId, String teamId);

  Future<TournamentTeamModel> approveTeam(String tournamentId, String tournamentTeamId);

  Future<TournamentTeamModel> rejectTeam(String tournamentId, String tournamentTeamId);

  Future<List<TournamentTeamModel>> getRegisteredTeams(String tournamentId);

  Future<List<dynamic>> getFixtures(String tournamentId);

  Future<List<dynamic>> generateFixtures(String tournamentId);

  Future<List<TournamentTeamModel>> getPointsTable(String tournamentId);
}

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
      final response = await _dio.get(
        ApiEndpoints.tournaments,
        queryParameters: <String, dynamic>{
          'page': page,
          'limit': limit,
          if (status != null && status.isNotEmpty && status != 'ALL') 'status': status,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
      );

      return _extractList(response.data, const ['data', 'tournaments', 'items'])
          .whereType<Map>()
          .map((item) => TournamentModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<TournamentModel> getTournamentById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.tournamentById(id));
      return TournamentModel.fromJson(_extractMap(response.data, 'Invalid tournament data received.'));
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<TournamentModel> createTournament(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(ApiEndpoints.tournaments, data: data);
      return TournamentModel.fromJson(_extractMap(response.data, 'Failed to create tournament.'));
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<TournamentModel> updateTournament(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(ApiEndpoints.tournamentById(id), data: data);
      return TournamentModel.fromJson(_extractMap(response.data, 'Failed to update tournament.'));
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<TournamentModel> updateTournamentStatus(String id, String status) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.tournamentStatus(id),
        data: {'status': status},
      );
      return TournamentModel.fromJson(_extractMap(response.data, 'Failed to update tournament status.'));
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
      return TournamentTeamModel.fromJson(
        _extractMap(response.data, 'Failed to register team for tournament.'),
      );
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<TournamentTeamModel> approveTeam(String tournamentId, String tournamentTeamId) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.tournamentTeamApprove(tournamentId, tournamentTeamId),
      );
      return TournamentTeamModel.fromJson(
        _extractMap(response.data, 'Failed to approve team.'),
      );
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<TournamentTeamModel> rejectTeam(String tournamentId, String tournamentTeamId) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.tournamentTeamReject(tournamentId, tournamentTeamId),
      );
      return TournamentTeamModel.fromJson(
        _extractMap(response.data, 'Failed to reject team.'),
      );
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<List<TournamentTeamModel>> getRegisteredTeams(String tournamentId) async {
    try {
      final response = await _dio.get(ApiEndpoints.tournamentTeams(tournamentId));
      return _extractList(response.data, const ['data', 'teams'])
          .whereType<Map>()
          .map((item) => TournamentTeamModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<List<dynamic>> getFixtures(String tournamentId) async {
    try {
      final response = await _dio.get(ApiEndpoints.tournamentFixtures(tournamentId));
      return _extractList(response.data, const ['data', 'fixtures', 'matches']);
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<List<dynamic>> generateFixtures(String tournamentId) async {
    try {
      final response = await _dio.post(ApiEndpoints.tournamentFixtures(tournamentId));
      return _extractList(response.data, const ['data', 'fixtures', 'matches']);
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<List<TournamentTeamModel>> getPointsTable(String tournamentId) async {
    try {
      final response = await _dio.get(ApiEndpoints.tournamentStandings(tournamentId));
      return _extractList(response.data, const ['data', 'standings', 'teams'])
          .whereType<Map>()
          .map((item) => TournamentTeamModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      _handleError(e);
    }
  }

  List<dynamic> _extractList(dynamic data, List<String> keys) {
    if (data is List) return data;
    final map = _asMap(data);
    if (map == null) return const [];
    for (final key in keys) {
      final value = map[key];
      if (value is List) return value;
    }
    return const [];
  }

  Map<String, dynamic> _extractMap(dynamic data, String errorMessage) {
    final map = _asMap(data);
    if (map == null) throw ServerException(message: errorMessage);

    final nested = map['data'] ?? map['tournament'];
    final result = _asMap(nested);
    return result ?? map;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  Map<String, dynamic>? _extractErrors(dynamic value) {
    final map = _asMap(value);
    if (map != null) return map;
    if (value is! List) return null;

    final errors = <String, dynamic>{};
    for (final item in value) {
      final error = _asMap(item);
      if (error == null) continue;
      final field = error['field']?.toString() ??
          error['param']?.toString() ??
          'general_${errors.length}';
      errors[field] = error['message']?.toString() ?? 'Invalid value';
    }
    return errors.isEmpty ? null : errors;
  }

  Never _handleError(dynamic error) {
    if (error is AppException) throw error;

    if (error is DioException) {
      final response = error.response;
      final statusCode = response?.statusCode ?? 500;
      final responseData = _asMap(response?.data);

      String message = 'An unexpected tournament service error occurred.';
      Map<String, dynamic>? errors;

      if (responseData != null) {
        final errorValue = responseData['error'];
        final errorList = errorValue is List;
        message = responseData['message']?.toString() ??
            (!errorList && errorValue != null ? errorValue.toString() : null) ??
            message;
        errors = _extractErrors(responseData['errors']) ?? _extractErrors(errorValue);
      } else if (response?.data is String && (response!.data as String).isNotEmpty) {
        message = response.data as String;
      }

      if (statusCode == 401) {
        throw UnauthorizedException(message: message);
      } else if (statusCode == 403) {
        throw ForbiddenException(message: message);
      } else if (statusCode == 404) {
        throw NotFoundException(message: message);
      } else if (statusCode == 422 ||
          (statusCode == 400 && errors != null) ||
          statusCode == 409) {
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
