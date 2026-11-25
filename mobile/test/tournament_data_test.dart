import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/features/tournaments/data/models/tournament_model.dart';
import 'package:mobile/features/tournaments/data/models/tournament_team_model.dart';

void main() {
  test('uses real tournament management endpoints', () {
    expect(ApiEndpoints.tournamentFixtures('t1'), '/tournaments/t1/fixtures');
    expect(ApiEndpoints.tournamentStatus('t1'), '/tournaments/t1/status');
    expect(
      ApiEndpoints.tournamentTeamApprove('t1', 'tt1'),
      '/tournaments/t1/teams/tt1/approve',
    );
    expect(
      ApiEndpoints.tournamentTeamReject('t1', 'tt1'),
      '/tournaments/t1/teams/tt1/reject',
    );
  });

  test('parses backend tournament team counts', () {
    final tournament = TournamentModel.fromJson({
      '_id': 't1',
      'name': 'Mumbai Cup',
      'format': 'LEAGUE',
      'ballType': 'WHITE',
      'matchFormat': 'T20',
      'startDate': '2026-12-01T00:00:00.000Z',
      'endDate': '2026-12-10T00:00:00.000Z',
      'maxTeams': 8,
      'status': 'REGISTRATION_OPEN',
      'totalRegisteredTeams': 6,
      'approvedTeamsCount': 5,
    });

    expect(tournament.id, 't1');
    expect(tournament.status, 'REGISTRATION_OPEN');
    expect(tournament.teamsCount, 6);
  });

  test('parses backend standings rank', () {
    final team = TournamentTeamModel.fromJson({
      '_id': 'tt1',
      'tournament': 't1',
      'team': {'_id': 'team1', 'name': 'Mumbai Strikers', 'shortName': 'MS'},
      'status': 'APPROVED',
      'rank': 2,
      'played': 4,
      'points': 8,
      'netRunRate': 0.75,
    });

    expect(team.rank, 2);
    expect(team.teamId, 'team1');
    expect(team.teamShortName, 'MS');
    expect(team.points, 8);
    expect(team.netRunRate, 0.75);
  });
}
