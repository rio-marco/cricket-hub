import 'package:mobile/core/errors/exceptions.dart';
import 'package:mobile/core/errors/failures.dart';

import '../../domain/entities/innings.dart';
import '../../domain/entities/match.dart';
import '../../domain/repositories/match_repository.dart';
import '../datasources/match_remote_datasource.dart';

class MatchRepositoryImpl implements MatchRepository {
  final MatchRemoteDataSource remoteDataSource;

  const MatchRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Match>> getMatches({
    int page = 1,
    int limit = 20,
    String? status,
    String? tournamentId,
    String? teamId,
    String? search,
  }) {
    return _execute(
      () => remoteDataSource.getMatches(
        page: page,
        limit: limit,
        status: status,
        tournamentId: tournamentId,
        teamId: teamId,
        search: search,
      ),
    );
  }

  @override
  Future<List<Match>> getLiveMatches() {
    return _execute(() => remoteDataSource.getLiveMatches());
  }

  @override
  Future<List<Match>> getUpcomingMatches() {
    return _execute(() => remoteDataSource.getUpcomingMatches());
  }

  @override
  Future<List<Match>> getCompletedMatches() {
    return _execute(() => remoteDataSource.getCompletedMatches());
  }

  @override
  Future<Match> getMatchById(String id) {
    return _execute(() => remoteDataSource.getMatchById(id));
  }

  @override
  Future<Match> createMatch(Map<String, dynamic> data) {
    return _execute(() => remoteDataSource.createMatch(data));
  }

  @override
  Future<Match> updateMatch(String id, Map<String, dynamic> data) {
    return _execute(() => remoteDataSource.updateMatch(id, data));
  }

  @override
  Future<Match> recordToss(
    String matchId,
    String winnerTeamId,
    String decision,
  ) {
    return _execute(
      () => remoteDataSource.recordToss(matchId, winnerTeamId, decision),
    );
  }

  @override
  Future<Innings> getInnings(String matchId, int inningsNumber) {
    return _execute(() => remoteDataSource.getInnings(matchId, inningsNumber));
  }

  @override
  Future<Map<String, dynamic>> getScorecard(String matchId) {
    return _execute(() => remoteDataSource.getScorecard(matchId));
  }

  @override
  Future<List<dynamic>> getCommentary(String matchId) {
    return _execute(() => remoteDataSource.getCommentary(matchId));
  }

  Future<T> _execute<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }
}
