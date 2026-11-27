import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/errors/failures.dart';

import '../../data/datasources/scoring_remote_datasource.dart';
import '../../data/models/scoring_model.dart';
import '../../data/realtime/match_realtime_event.dart';
import '../../data/repositories/scoring_repository_impl.dart';
import '../../domain/entities/scoring.dart';

class ScoringUiState {
  final String matchId;
  final ScoringSnapshot snapshot;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const ScoringUiState({
    required this.matchId,
    this.snapshot = const ScoringSnapshot(),
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  Map<String, dynamic>? get activeInnings {
    final innings = snapshot.activeInnings;
    if (innings is Map<String, dynamic>) return innings;
    if (innings is Map) return Map<String, dynamic>.from(innings);
    return null;
  }

  ScoringUiState copyWith({
    ScoringSnapshot? snapshot,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return ScoringUiState(
      matchId: matchId,
      snapshot: snapshot ?? this.snapshot,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      successMessage: clearSuccessMessage
          ? null
          : successMessage ?? this.successMessage,
    );
  }
}

class ScoringNotifier extends StateNotifier<ScoringUiState> {
  final ScoringRepository _repository;
  int _requestCounter = 0;
  final Set<String> _seenEventIds = <String>{};

  ScoringNotifier(this._repository, String matchId)
    : super(ScoringUiState(matchId: matchId)) {
    load();
  }

  Map<String, dynamic>? get activeInnings => state.activeInnings;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final snapshot = await _repository.getState(state.matchId);
      state = state.copyWith(snapshot: snapshot, isLoading: false);
    } on Failure catch (failure) {
      state = state.copyWith(isLoading: false, errorMessage: failure.message);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  void applyState(
    Map<String, dynamic> incomingState, {
    String message = 'Live score updated.',
  }) {
    final incomingInnings = _inningsNumberOf(incomingState);
    final currentInnings = _inningsNumberOf(state.snapshot.activeInnings);
    final incomingVersion = _versionOf(incomingState);
    final currentVersion = _versionOf(state.snapshot.activeInnings);

    final sameInnings =
        incomingInnings == null ||
        currentInnings == null ||
        incomingInnings == currentInnings;
    if (sameInnings &&
        incomingVersion != null &&
        currentVersion != null &&
        incomingVersion < currentVersion) {
      return;
    }

    state = state.copyWith(
      snapshot: ScoringSnapshotModel.fromJson({'data': incomingState}),
      isSaving: false,
      successMessage: message,
      clearErrorMessage: true,
    );
  }

  void applyRealtimeEvent(MatchRealtimeEvent event) {
    if (event.matchId != null && event.matchId != state.matchId) return;

    if (event.name == 'match:error') {
      final message = event.errorMessage;
      if (message != null) {
        state = state.copyWith(isSaving: false, errorMessage: message);
      }
      return;
    }

    final eventId = event.eventId;
    if (eventId != null && eventId.isNotEmpty) {
      if (_seenEventIds.contains(eventId)) return;
      if (_seenEventIds.length >= 200) {
        _seenEventIds.remove(_seenEventIds.first);
      }
      _seenEventIds.add(eventId);
    }

    final incoming = event.state;
    if (incoming != null) {
      applyState(incoming);
      return;
    }
    if (event.name == 'connection:status') return;
    unawaited(load());
  }

  int? _versionOf(dynamic value) {
    final map = normalizeMapOrNull(value);
    final innings = normalizeMapOrNull(map?['activeInnings'] ?? map);
    final version = innings?['stateVersion'];
    if (version is num) return version.toInt();
    return null;
  }

  int? _inningsNumberOf(dynamic value) {
    final map = normalizeMapOrNull(value);
    final innings = normalizeMapOrNull(map?['activeInnings'] ?? map);
    final number = innings?['inningsNumber'];
    if (number is num) return number.toInt();
    if (number is String) return int.tryParse(number);
    return null;
  }

  Future<bool> startInnings({
    required String striker,
    required String nonStriker,
    required String bowler,
  }) async {
    return _run(
      successMessage: 'Innings started.',
      action: () => _repository.startInnings(
        state.matchId,
        _payload({
          'striker': striker,
          'nonStriker': nonStriker,
          'bowler': bowler,
          'inningsNumber': _activeInningsNumber(),
        }),
      ),
    );
  }

  Future<bool> recordRuns(int runs, {String? bowler}) async {
    return _run(
      successMessage: '$runs run${runs == 1 ? '' : 's'} recorded.',
      action: () => _repository.recordBall(
        state.matchId,
        _payload({'runs': runs, if (bowler != null) 'bowler': bowler}),
      ),
    );
  }

  Future<bool> recordExtra(
    String extraType, {
    int extraRuns = 1,
    String? bowler,
  }) async {
    return _run(
      successMessage: '$extraType recorded.',
      action: () => _repository.recordBall(
        state.matchId,
        _payload({
          'runs': 0,
          'extraType': extraType,
          'extraRuns': extraRuns,
          if (bowler != null) 'bowler': bowler,
        }),
      ),
    );
  }

  Future<bool> recordWicket({
    required String type,
    required String dismissedPlayerId,
    String? fielderId,
    String? bowler,
  }) async {
    return _run(
      successMessage: 'Wicket recorded.',
      action: () => _repository.recordBall(
        state.matchId,
        _payload({
          'runs': 0,
          if (bowler != null) 'bowler': bowler,
          'wicket': {
            'type': type,
            'batter': dismissedPlayerId,
            if (fielderId != null && fielderId.isNotEmpty) 'fielder': fielderId,
          },
        }),
      ),
    );
  }

  Future<bool> undoLastBall() async {
    return _run(
      successMessage: 'Last delivery undone.',
      action: () => _repository.undo(state.matchId, _payload({})),
    );
  }

  Future<bool> correctDelivery(
    String deliveryId, {
    int runs = 0,
    String extraType = 'NONE',
    int extraRuns = 0,
  }) async {
    return _run(
      successMessage: 'Delivery corrected.',
      action: () => _repository.correct(
        state.matchId,
        deliveryId,
        _payload({
          'runs': runs,
          'extraType': extraType,
          'extraRuns': extraRuns,
        }),
      ),
    );
  }

  Future<bool> endInnings() async {
    return _run(
      successMessage: 'Innings completed.',
      action: () => _repository.endInnings(
        state.matchId,
        _payload({
          'inningsNumber': _activeInningsNumber(),
          'status': 'COMPLETED',
        }),
      ),
    );
  }

  Future<bool> completeMatch() async {
    return _run(
      successMessage: 'Match result recorded.',
      action: () => _repository.completeMatch(state.matchId, _payload({})),
    );
  }

  int _activeInningsNumber() {
    final innings = activeInnings;
    if (innings == null) return state.snapshot.match?.currentInnings ?? 1;
    final value = innings['inningsNumber'];
    return value is num ? value.toInt() : 1;
  }

  Map<String, dynamic> _payload(Map<String, dynamic> data) {
    final innings = activeInnings;
    final version = innings?['stateVersion'];
    _requestCounter += 1;
    return {
      ...data,
      if (version is num) 'expectedVersion': version.toInt(),
      'idempotencyKey':
          'flutter-${DateTime.now().microsecondsSinceEpoch}-$_requestCounter',
    };
  }

  Future<bool> _run({
    required Future<ScoringSnapshot> Function() action,
    required String successMessage,
  }) async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearErrorMessage: true);
    try {
      final snapshot = await action();
      final incomingVersion = _versionOf(snapshot.activeInnings);
      final currentVersion = _versionOf(activeInnings);
      if (incomingVersion == null ||
          currentVersion == null ||
          incomingVersion >= currentVersion) {
        state = state.copyWith(
          snapshot: snapshot,
          isSaving: false,
          successMessage: successMessage,
        );
      } else {
        state = state.copyWith(isSaving: false, successMessage: successMessage);
      }
      return true;
    } on Failure catch (failure) {
      final message = failure is ValidationFailure
          ? failure.firstError ?? failure.message
          : failure.message;
      state = state.copyWith(isSaving: false, errorMessage: message);
      return false;
    } catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.toString());
      return false;
    }
  }
}

final scoringRemoteDataSourceProvider = Provider<ScoringRemoteDataSource>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return ScoringRemoteDataSourceImpl(apiClient.dio);
});

final scoringRepositoryProvider = Provider<ScoringRepository>((ref) {
  return ScoringRepositoryImpl(
    remoteDataSource: ref.watch(scoringRemoteDataSourceProvider),
  );
});

final scoringControllerProvider =
    StateNotifierProvider.family<ScoringNotifier, ScoringUiState, String>((
      ref,
      matchId,
    ) {
      return ScoringNotifier(ref.watch(scoringRepositoryProvider), matchId);
    });
