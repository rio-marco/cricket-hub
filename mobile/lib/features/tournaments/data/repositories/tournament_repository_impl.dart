import 'package:mobile/core/errors/exceptions.dart';
import 'package:mobile/core/errors/failures.dart';
import '../../domain/entities/tournament.dart';
import '../../domain/entities/tournament_team.dart';
import '../../domain/repositories/tournament_repository.dart';
import '../datasources/tournament_remote_datasource.dart';

class TournamentRepositoryImpl implements TournamentRepository {
  final TournamentRemoteDataSource remoteDataSource;

  TournamentRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<List<Tournament>> getTournaments({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
  }) async {
    try {
      return await remoteDataSource.getTournaments(
        page: page,
        limit: limit,
        status: status,
        search: search,
      );
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<Tournament> getTournamentById(String id) async {
    try {
      return await remoteDataSource.getTournamentById(id);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<Tournament> createTournament(Map<String, dynamic> data) async {
    try {
      return await remoteDataSource.createTournament(data);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<Tournament> updateTournament(String id, Map<String, dynamic> data) async {
    try {
      return await remoteDataSource.updateTournament(id, data);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<Tournament> updateTournamentStatus(String id, String status) async {
    try {
      return await remoteDataSource.updateTournamentStatus(id, status);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<void> deleteTournament(String id) async {
    try {
      await remoteDataSource.deleteTournament(id);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<TournamentTeam> registerTeam(String tournamentId, String teamId) async {
    try {
      return await remoteDataSource.registerTeam(tournamentId, teamId);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<TournamentTeam> approveTeam(String tournamentId, String tournamentTeamId) async {
    try {
      return await remoteDataSource.approveTeam(tournamentId, tournamentTeamId);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<TournamentTeam> rejectTeam(String tournamentId, String tournamentTeamId) async {
    try {
      return await remoteDataSource.rejectTeam(tournamentId, tournamentTeamId);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<List<TournamentTeam>> getRegisteredTeams(String tournamentId) async {
    try {
      return await remoteDataSource.getRegisteredTeams(tournamentId);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<List<dynamic>> getFixtures(String tournamentId) async {
    try {
      return await remoteDataSource.getFixtures(tournamentId);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<List<dynamic>> generateFixtures(String tournamentId) async {
    try {
      return await remoteDataSource.generateFixtures(tournamentId);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }

  @override
  Future<List<TournamentTeam>> getPointsTable(String tournamentId) async {
    try {
      return await remoteDataSource.getPointsTable(tournamentId);
    } on AppException catch (e) {
      throw Failure.fromException(e);
    } catch (e) {
      throw ServerFailure(message: e.toString());
    }
  }
}
