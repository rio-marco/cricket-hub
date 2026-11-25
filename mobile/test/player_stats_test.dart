import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/players/domain/entities/player.dart';

void main() {
  const backendStats = <String, dynamic>{
    'matches': 12,
    'playerOfMatch': 2,
    'batting': <String, dynamic>{
      'runs': 350,
      'balls': 240,
      'highestScore': '87*',
      'average': 35.0,
      'strikeRate': 145.83,
    },
    'bowling': <String, dynamic>{
      'wickets': 15,
      'overs': 24,
      'runsConceded': 180,
      'average': 12.0,
      'economy': 7.5,
      'bestBowling': '4/21',
    },
    'fielding': <String, dynamic>{
      'catches': 6,
      'stumpings': 2,
    },
  };

  test('parses backend nested career stats', () {
    final player = Player.fromJson({
      '_id': 'p1',
      'user': {'_id': 'u1', 'name': 'Rohan'},
      'playingRole': 'ALL_ROUNDER',
      'stats': backendStats,
    });

    expect(player.id, 'p1');
    expect(player.user, 'u1');
    expect(player.name, 'Rohan');
    expect(player.matchesCount, 12);
    expect(player.runs, 350);
    expect(player.highestScore, 87);
    expect(player.strikeRate, 145.83);
    expect(player.wickets, 15);
    expect(player.oversBowled, 24);
    expect(player.bestBowling, '4/21');
    expect(player.catches, 6);
    expect(player.stumpings, 2);
  });

  test('merges stats endpoint payload into an existing player', () {
    const base = Player(
      id: 'p1',
      user: 'u1',
      name: 'Rohan',
      playingRole: 'ALL_ROUNDER',
    );

    final updated = Player.applyCareerStats(base, backendStats);

    expect(updated.runs, 350);
    expect(updated.bowlingAverage, 12.0);
    expect(updated.economyRate, 7.5);
    expect(updated.name, 'Rohan');
  });
}
