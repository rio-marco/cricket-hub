import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/core/errors/exceptions.dart';
import 'package:mobile/features/matches/domain/entities/match.dart';

void main() {
  const teamAId = '507f1f77bcf86cd799439011';
  const teamBId = '507f1f77bcf86cd799439012';

  test('uses real match lifecycle endpoints', () {
    expect(ApiEndpoints.matches, '/matches');
    expect(ApiEndpoints.matchById('m1'), '/matches/m1');
    expect(ApiEndpoints.matchToss('m1'), '/matches/m1/toss');
    expect(ApiEndpoints.matchPlayingXi('m1'), '/matches/m1/playing-xi');
    expect(ApiEndpoints.matchStart('m1'), '/matches/m1/start');
  });

  test('exposes team identifiers from populated backend match payloads', () {
    final match = Match.fromJson({
      '_id': 'm1',
      'teamA': {'_id': teamAId, 'name': 'Team A'},
      'teamB': {'id': teamBId, 'name': 'Team B'},
      'format': 'T20',
      'status': 'UPCOMING',
    });

    expect(match.teamAId, teamAId);
    expect(match.teamBId, teamBId);
  });

  test('maps backend validation error arrays', () {
    final errors = validationErrorsFromResponse({
      'success': false,
      'message': 'Validation failed',
      'error': [
        {'field': 'teamA', 'message': 'teamA must be a string'},
        {'field': 'winner', 'message': 'Invalid identifier'},
      ],
    });

    expect(errors?['teamA'], ['teamA must be a string']);
    expect(errors?['winner'], ['Invalid identifier']);
    expect(
      responseMessageFromError({'message': 'Validation failed'}, 'fallback'),
      'Validation failed',
    );
  });
}
