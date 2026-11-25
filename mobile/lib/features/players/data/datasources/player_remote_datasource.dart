import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/models/paginated_response.dart';
import '../../domain/entities/player.dart';
import '../models/player_model.dart';

/// Remote data source contract for player directories and cricket statistics.
abstract class PlayerRemoteDataSource {
  Future<PaginatedResponse<Player>> getPlayers({
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
  });

  Future<Player> getPlayerById(String id);

  Future<Player?> getPlayerByUserId(String userId, {String? searchName});

  Future<Player> createPlayer(Map<String, dynamic> data);

  Future<Player> updatePlayer(String id, Map<String, dynamic> data);

  Future<Map<String, dynamic>> getPlayerStats(String id);

  Future<List<dynamic>> getPlayerMatches(String id);
}

/// Implementation of [PlayerRemoteDataSource] using Dio HTTP client.
class PlayerRemoteDataSourceImpl implements PlayerRemoteDataSource {
  final Dio _dio;

  PlayerRemoteDataSourceImpl(this._dio);

  @override
  Future<PaginatedResponse<Player>> getPlayers({
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (role != null && role.isNotEmpty && role != 'ALL') {
        queryParams['playingRole'] = role;
      }

      final response = await _dio.get(
        ApiEndpoints.players,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return PaginatedResponse<Player>.fromJson(
          data,
          (item) => PlayerModel.fromJson(Map<String, dynamic>.from(item as Map)),
        );
      } else if (data is List) {
        final players = data
            .map((e) => PlayerModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        return PaginatedResponse<Player>(
          items: players,
          total: players.length,
          page: page,
          limit: limit,
          totalPages: 1,
        );
      }

      return PaginatedResponse<Player>.empty();
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<Player> getPlayerById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.playerById(id));
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final map = data.containsKey('data') && data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : data;
        return PlayerModel.fromJson(map);
      }
      throw const ServerException(message: 'Invalid response format for player details.');
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<Player?> getPlayerByUserId(
    String userId, {
    String? searchName,
  }) async {
    try {
      const pageSize = 100;
      for (var page = 1; page <= 10; page++) {
        final response = await _dio.get(
          ApiEndpoints.players,
          queryParameters: {
            'page': page,
            'limit': pageSize,
            if (searchName != null && searchName.trim().isNotEmpty)
              'search': searchName.trim(),
          },
        );

        final data = response.data;
        if (data is! Map<String, dynamic>) break;

        final paginated = PaginatedResponse<Player>.fromJson(
          data,
          (item) => PlayerModel.fromJson(Map<String, dynamic>.from(item as Map)),
        );

        for (final player in paginated.items) {
          if (player.user == userId) return player;
        }

        if (!paginated.hasNextPage) break;
      }
      return null;
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<Player> createPlayer(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.players,
        data: data,
      );

      final respData = response.data;
      if (respData is Map<String, dynamic>) {
        final map = respData.containsKey('data') && respData['data'] is Map<String, dynamic>
            ? respData['data'] as Map<String, dynamic>
            : respData;
        return PlayerModel.fromJson(map);
      }
      throw const ServerException(message: 'Invalid response after creating player profile.');
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<Player> updatePlayer(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.playerById(id),
        data: data,
      );

      final respData = response.data;
      if (respData is Map<String, dynamic>) {
        final map = respData.containsKey('data') && respData['data'] is Map<String, dynamic>
            ? respData['data'] as Map<String, dynamic>
            : respData;
        return PlayerModel.fromJson(map);
      }
      throw const ServerException(message: 'Invalid response updating player.');
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getPlayerStats(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.playerStats(id));
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data.containsKey('data') && data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : data;
      }
      return {};
    } catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<List<dynamic>> getPlayerMatches(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.playerMatches(id));
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final list = data['data'] ?? data['matches'];
        if (list is List) return list;
      } else if (data is List) {
        return data;
      }
      return [];
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
