import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/matches/data/repositories/scoring_repository_impl.dart';
import 'package:mobile/features/matches/data/realtime/match_realtime_event.dart';
import 'package:mobile/features/matches/domain/entities/scoring.dart';
import 'package:mobile/features/matches/presentation/providers/scoring_provider.dart';

class FakeScoringRepository implements ScoringRepository {
  FakeScoringRepository(this.snapshot);

  ScoringSnapshot snapshot;

  @override
  Future<ScoringSnapshot> getState(String matchId) async => snapshot;

  @override
  Future<ScoringSnapshot> startInnings(
    String matchId,
    Map<String, dynamic> data,
  ) async => snapshot;

  @override
  Future<ScoringSnapshot> recordBall(
    String matchId,
    Map<String, dynamic> data,
  ) async => snapshot;

  @override
  Future<ScoringSnapshot> undo(
    String matchId,
    Map<String, dynamic> data,
  ) async => snapshot;

  @override
  Future<ScoringSnapshot> correct(
    String matchId,
    String deliveryId,
    Map<String, dynamic> data,
  ) async => snapshot;

  @override
  Future<ScoringSnapshot> endInnings(
    String matchId,
    Map<String, dynamic> data,
  ) async => snapshot;

  @override
  Future<ScoringSnapshot> completeMatch(
    String matchId,
    Map<String, dynamic> data,
  ) async => snapshot;

  @override
  Future<List<ScoringDelivery>> getCommentary(String matchId) async => const [];
}

class SlowScoringRepository extends FakeScoringRepository {
  SlowScoringRepository(super.snapshot);
  int recordBallCalls = 0;
  final Completer<ScoringSnapshot> _completer = Completer<ScoringSnapshot>();

  @override
  Future<ScoringSnapshot> recordBall(
    String matchId,
    Map<String, dynamic> data,
  ) {
    recordBallCalls++;
    return _completer.future;
  }

  void complete() {
    if (!_completer.isCompleted) _completer.complete(snapshot);
  }
}

ScoringSnapshot snapshotWithVersion(int version) {
  return ScoringSnapshot(
    activeInnings: <String, dynamic>{
      'stateVersion': version,
      'totalRuns': version * 4,
      'totalWickets': 0,
      'totalBalls': version,
      'status': 'IN_PROGRESS',
    },
    deliveries: const [],
  );
}

MatchRealtimeEvent stateEvent({
  required String eventId,
  required String matchId,
  required int version,
  int totalRuns = 0,
}) {
  return MatchRealtimeEvent.from('match:state', {
    'eventId': eventId,
    'matchId': matchId,
    'action': 'BALL',
    'stateVersion': version,
    'state': {
      'activeInnings': {
        'stateVersion': version,
        'totalRuns': totalRuns == 0 ? version * 4 : totalRuns,
        'totalWickets': 0,
        'totalBalls': version,
        'status': 'IN_PROGRESS',
      },
      'deliveries': [],
    },
  });
}

void main() {
  test('real-time event normalizes nested payload maps', () {
    final event = MatchRealtimeEvent.from('score:delivery', {
      'eventId': 'm1:key:BALL',
      'matchId': 'm1',
      'action': 'BALL',
      'stateVersion': 7,
      'delivery': {
        'runs': {'batter': 4, 'total': 4},
      },
      'state': {
        'activeInnings': {'stateVersion': 7},
      },
    });

    expect(event.eventId, 'm1:key:BALL');
    expect(event.matchId, 'm1');
    expect(event.action, 'BALL');
    expect(event.stateVersion, 7);
    expect(event.state?['activeInnings']?['stateVersion'], 7);
    expect(event.data['delivery']?['runs']?['batter'], 4);
  });

  test(
    'scoring state applies newer socket updates and rejects stale ones',
    () async {
      final repository = FakeScoringRepository(snapshotWithVersion(1));
      final notifier = ScoringNotifier(repository, 'm1');
      await notifier.load();

      notifier.applyRealtimeEvent(
        stateEvent(eventId: 'm1:key-2:BALL', matchId: 'm1', version: 2),
      );
      expect(notifier.state.activeInnings?['stateVersion'], 2);
      expect(notifier.state.activeInnings?['totalRuns'], 8);

      notifier.applyRealtimeEvent(
        stateEvent(eventId: 'm1:key-3:BALL', matchId: 'm1', version: 1),
      );
      expect(notifier.state.activeInnings?['stateVersion'], 2);

      notifier.applyRealtimeEvent(
        stateEvent(
          eventId: 'm1:key-2:BALL',
          matchId: 'm1',
          version: 2,
          totalRuns: 99,
        ),
      );
      expect(notifier.state.activeInnings?['totalRuns'], 8);
    },
  );

  test('socket errors are surfaced in scoring UI state', () async {
    final repository = FakeScoringRepository(snapshotWithVersion(1));
    final notifier = ScoringNotifier(repository, 'm1');
    await notifier.load();

    notifier.applyRealtimeEvent(
      MatchRealtimeEvent.from('match:error', {
        'matchId': 'm1',
        'error': {'code': 'MATCH_ACCESS_DENIED', 'message': 'Access denied'},
      }),
    );

    expect(notifier.state.errorMessage, 'Access denied');
  });

  test('duplicate save requests are guarded while saving', () async {
    final repository = SlowScoringRepository(snapshotWithVersion(1));
    final notifier = ScoringNotifier(repository, 'm1');
    await notifier.load();

    final first = notifier.recordRuns(1);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final second = await notifier.recordRuns(2);
    expect(second, isFalse);
    repository.complete();
    expect(await first, isTrue);
    expect(repository.recordBallCalls, 1);
  });
}
