import 'package:dio/dio.dart';
import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/core/errors/exceptions.dart';

import '../../domain/entities/scoring.dart';
import '../models/scoring_model.dart';

abstract class ScoringRemoteDataSource {
  Future<ScoringSnapshot> getState(String matchId);

  Future<ScoringSnapshot> startInnings(String matchId, Map<String, dynamic> data);

  Future<ScoringSnapshot> recordBall(String matchId, Map<String, dynamic> data);

  Future<ScoringSnapshot> undo(String matchId, Map<String, dynamic> data);

  Future<ScoringSnapshot> correct(
    String matchId,
    String deliveryId,
    Map<String, dynamic> data,
  );

  Future<ScoringSnapshot> endInnings(String matchId, Map<String, dynamic> data);

  Future<ScoringSnapshot> completeMatch(String matchId, Map<String, dynamic> data);

  Future<List<ScoringDelivery>> getCommentary(String matchId);
}

class ScoringRemoteDataSourceImpl implements ScoringRemoteDataSource {
  final Dio _dio;

  const ScoringRemoteDataSourceImpl(this._dio);

  @override
  Future<ScoringSnapshot> getState(String matchId) async {
    try {
      final response = await _dio.get(ApiEndpoints.scoringState(matchId));
      return _snapshot(response.data);
    } catch (error) {
      _handleError(error);
    }
  }

  @override
  Future<ScoringSnapshot> startInnings(
    String matchId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.scoringStartInnings(matchId),
        data: data,
      );
      return _snapshot(response.data);
    } catch (error) {
      _handleError(error);
    }
  }

  @override
  Future<ScoringSnapshot> recordBall(
    String matchId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.scoringBall(matchId),
        data: data,
      );
      return _snapshot(response.data);
    } catch (error) {
      _handleError(error);
    }
  }

  @override
  Future<ScoringSnapshot> undo(
    String matchId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.scoringUndo(matchId),
        data: data,
      );
      return _snapshot(response.data);
    } catch (error) {
      _handleError(error);
    }
  }

  @override
  Future<ScoringSnapshot> correct(
    String matchId,
    String deliveryId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.scoringCorrect(matchId, deliveryId),
        data: data,
      );
      return _snapshot(response.data);
    } catch (error) {
      _handleError(error);
    }
  }

  @override
  Future<ScoringSnapshot> endInnings(
    String matchId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.scoringInningsEnd(matchId),
        data: data,
      );
      return _snapshot(response.data);
    } catch (error) {
      _handleError(error);
    }
  }

  @override
  Future<ScoringSnapshot> completeMatch(
    String matchId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.scoringComplete(matchId),
        data: data,
      );
      return _snapshot(response.data);
    } catch (error) {
      _handleError(error);
    }
  }

  @override
  Future<List<ScoringDelivery>> getCommentary(String matchId) async {
    try {
      final response = await _dio.get(ApiEndpoints.scoringCommentary(matchId));
      final data = response.data;
      final list = data is Map && data['data'] is List
          ? data['data'] as List
          : data is List
              ? data
              : <dynamic>[];
      return list
          .whereType<Map<String, dynamic>>()
          .map(ScoringDeliveryModel.fromJson)
          .toList();
    } catch (error) {
      _handleError(error);
    }
  }

  ScoringSnapshot _snapshot(dynamic data) {
    if (data is Map<String, dynamic>) {
      return ScoringSnapshotModel.fromJson(data);
    }
    throw const ServerException(message: 'Invalid scoring response format.');
  }

  Never _handleError(dynamic error) {
    if (error is AppException) throw error;
    if (error is DioException) {
      final response = error.response;
      final statusCode = response?.statusCode ?? 500;
      final message = responseMessageFromError(
        response?.data,
        'An unexpected scoring service error occurred.',
      );
      final errors = validationErrorsFromResponse(response?.data);
      if (statusCode == 401) throw UnauthorizedException(message: message);
      if (statusCode == 403) throw ForbiddenException(message: message);
      if (statusCode == 404) throw NotFoundException(message: message);
      if (statusCode == 422 || (statusCode == 400 && errors != null)) {
        throw ValidationException(
          message: message,
          errors: errors ?? {'general': message},
        );
      }
      throw ServerException(
        message: message,
        statusCode: statusCode,
        errors: errors,
      );
    }
    throw ServerException(message: error.toString());
  }
}
