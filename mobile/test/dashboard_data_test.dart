import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/dashboard/domain/entities/dashboard_data.dart';

void main() {
  test('parses populated teams and maps innings scores to the batting team', () {
    final match = DashboardMatch.fromJson({
      '_id': 'm1',
      'teamA': {'_id': 't1', 'name': 'India', 'logo': 'https://img/in.png'},
      'teamB': {'_id': 't2', 'name': 'Australia', 'logo': 'https://img/au.png'},
      'innings': [
        {
          'battingTeam': {'_id': 't2', 'name': 'Australia'},
          'totalRuns': 156,
          'totalWickets': 7,
          'totalOvers': 20,
        },
        {
          'battingTeam': {'_id': 't1', 'name': 'India'},
          'totalRuns': 182,
          'totalWickets': 4,
          'totalOvers': 20,
        },
      ],
      'status': 'LIVE',
      'venue': 'Wankhede',
      'tournament': {'name': 'Test Series'},
    });

    expect(match.id, 'm1');
    expect(match.teamAName, 'India');
    expect(match.teamBName, 'Australia');
    expect(match.teamARuns, 182);
    expect(match.teamAWickets, 4);
    expect(match.teamBRuns, 156);
    expect(match.teamBWickets, 7);
    expect(match.tournamentName, 'Test Series');
    expect(match.venue, 'Wankhede');
  });

  test('parses completed result text and falls back to startTime', () {
    final match = DashboardMatch.fromJson({
      'id': 'm2',
      'teamAName': 'Team A',
      'teamBName': 'Team B',
      'status': 'COMPLETED',
      'result': {
        'winner': {'name': 'Team A'},
        'margin': '32 runs',
      },
      'startTime': '2026-11-18T10:00:00.000Z',
      'format': 'T20',
    });

    expect(match.statusText, 'Team A won by 32 runs');
    expect(match.startTime, DateTime.parse('2026-11-18T10:00:00.000Z'));
    expect(match.format, 'T20');
  });
}
