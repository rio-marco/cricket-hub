import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/models/paginated_response.dart';
import '../../domain/entities/player.dart';
import '../../domain/repositories/player_repository.dart';
import '../datasources/player_remote_datasource.dart';

/// Implementation of [PlayerRepository] handling network calls and error mapping.
class PlayerRepositoryImpl implements PlayerRepository {
  final PlayerRemoteDataSource _remoteDataSource;

  PlayerRepositoryImpl({required PlayerRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<PaginatedResponse<Player>> getPlayers({
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
  }) async {
    try {
      return await _remoteDataSource.getPlayers(
        page: page,
        limit: limit,
        search: search,
        role: role,
      );
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<Player> getPlayerById(String id) async {
    try {
      return await _remoteDataSource.getPlayerById(id);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<Player?> getPlayerByUserId(
    String userId, {
    String? searchName,
  }) async {
    try {
      return await _remoteDataSource.getPlayerByUserId(
        userId,
        searchName: searchName,
      );
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<Player> createPlayer(Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.createPlayer(data);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<Player> updatePlayer(String id, Map<String, dynamic> data) async {
    try {
      return await _remoteDataSource.updatePlayer(id, data);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> getPlayerStats(String id) async {
    try {
      return await _remoteDataSource.getPlayerStats(id);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<List<dynamic>> getPlayerMatches(String id) async {
    try {
      return await _remoteDataSource.getPlayerMatches(id);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }
}
