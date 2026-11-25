import 'package:mobile/core/errors/exceptions.dart';
import 'package:mobile/core/errors/failures.dart';

import '../../domain/entities/scoring.dart';
import '../datasources/scoring_remote_datasource.dart';

abstract class ScoringRepository {
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

class ScoringRepositoryImpl implements ScoringRepository {
  final ScoringRemoteDataSource remoteDataSource;

  const ScoringRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ScoringSnapshot> getState(String matchId) =>
      _execute(() => remoteDataSource.getState(matchId));

  @override
  Future<ScoringSnapshot> startInnings(String matchId, Map<String, dynamic> data) =>
      _execute(() => remoteDataSource.startInnings(matchId, data));

  @override
  Future<ScoringSnapshot> recordBall(String matchId, Map<String, dynamic> data) =>
      _execute(() => remoteDataSource.recordBall(matchId, data));

  @override
  Future<ScoringSnapshot> undo(String matchId, Map<String, dynamic> data) =>
      _execute(() => remoteDataSource.undo(matchId, data));

  @override
  Future<ScoringSnapshot> correct(
    String matchId,
    String deliveryId,
    Map<String, dynamic> data,
  ) =>
      _execute(() => remoteDataSource.correct(matchId, deliveryId, data));

  @override
  Future<ScoringSnapshot> endInnings(String matchId, Map<String, dynamic> data) =>
      _execute(() => remoteDataSource.endInnings(matchId, data));

  @override
  Future<ScoringSnapshot> completeMatch(String matchId, Map<String, dynamic> data) =>
      _execute(() => remoteDataSource.completeMatch(matchId, data));

  @override
  Future<List<ScoringDelivery>> getCommentary(String matchId) =>
      _execute(() => remoteDataSource.getCommentary(matchId));

  Future<T> _execute<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException catch (error) {
      throw Failure.fromException(error);
    } catch (error) {
      throw ServerFailure(message: error.toString());
    }
  }
}
