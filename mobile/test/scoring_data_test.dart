import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/features/matches/data/models/scoring_model.dart';
import 'package:mobile/features/matches/domain/entities/scoring.dart';

void main() {
  const matchId = '507f1f77bcf86cd799439011';
  const teamAId = '507f1f77bcf86cd799439012';
  const teamBId = '507f1f77bcf86cd799439013';
  const batterId = '507f1f77bcf86cd799439014';
  const bowlerId = '507f1f77bcf86cd799439015';

  test('uses real scoring endpoints', () {
    expect(ApiEndpoints.scoringState(matchId), '/scoring/$matchId/state');
    expect(ApiEndpoints.scoringBall(matchId), '/scoring/$matchId/ball');
    expect(ApiEndpoints.scoringUndo(matchId), '/scoring/$matchId/undo');
    expect(
      ApiEndpoints.scoringCorrect(matchId, 'd1'),
      '/scoring/$matchId/ball/d1/correct',
    );
    expect(ApiEndpoints.scoringComplete(matchId), '/scoring/$matchId/complete');
  });

  test('parses backend scoring state into typed entities', () {
    final snapshot = ScoringSnapshotModel.fromJson({
      'success': true,
      'data': {
        'match': {
          '_id': matchId,
          'teamA': {'_id': teamAId, 'name': 'Team A'},
          'teamB': {'_id': teamBId, 'name': 'Team B'},
          'status': 'LIVE',
          'format': 'T20',
          'totalOvers': 20,
          'ballsPerOver': 6,
          'venue': 'Test Ground',
          'playingXI_A': [batterId],
          'playingXI_B': [bowlerId],
        },
        'innings': [
          {
            'inningsNumber': 1,
            'totalRuns': 6,
            'totalWickets': 0,
            'totalBalls': 1,
            'stateVersion': 2,
            'status': 'IN_PROGRESS',
          },
        ],
        'activeInnings': {
          'inningsNumber': 1,
          'totalRuns': 6,
          'stateVersion': 2,
        },
        'deliveries': [
          {
            '_id': '507f1f77bcf86cd799439016',
            'innings': '507f1f77bcf86cd799439017',
            'match': matchId,
            'overNumber': 0,
            'ballNumber': 1,
            'sequenceNumber': 1,
            'batter': {'_id': batterId, 'user': {'name': 'Batter One'}},
            'bowler': {'_id': bowlerId, 'name': 'Bowler One'},
            'runs': {'batter': 6, 'extras': 0, 'total': 6},
            'extras': {'type': 'NONE', 'runs': 0},
            'isLegal': true,
            'isWicket': false,
            'isBoundary': false,
            'isSix': true,
            'commentary': 'Batter One: 6 runs off the bat off Bowler One.',
          },
        ],
      },
    });

    expect(snapshot.match?.id, matchId);
    expect(snapshot.match?.teamAName, 'Team A');
    expect(snapshot.match?.venue, 'Test Ground');
    expect(snapshot.match?.ballsPerOver, 6);
    expect(snapshot.deliveries, hasLength(1));
    expect(snapshot.deliveries.first.totalRuns, 6);
    expect(snapshot.deliveries.first.isSix, isTrue);
    expect(snapshot.deliveries.first.overLabel, '0.1');
    expect(snapshot.activeInnings?['stateVersion'], 2);
    expect(entityName(snapshot.deliveries.first.batter), 'Batter One');
    expect(entityId(snapshot.deliveries.first.bowler), bowlerId);
  });
}
