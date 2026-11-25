import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/storage/secure_storage.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/realtime/match_realtime_client.dart';
import 'match_provider.dart';
import 'scoring_provider.dart';

const _scoreEventNames = <String>{
  'match:state',
  'score:delivery',
  'wicket:recorded',
  'score:corrected',
  'score:undone',
  'match:over-completed',
  'match:innings-started',
  'match:innings-ended',
  'match:completed',
};

final matchRealtimeClientProvider = Provider<MatchRealtimeClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final storage = ref.watch(secureStorageProvider);
  final client = SocketIOMatchRealtimeClient(
    url: config.socketUrl,
    tokenProvider: SecureStorageRealtimeTokenProvider(storage),
  );

  ref.keepAlive();
  ref.onDispose(() => unawaited(client.dispose()));

  final currentAuth = ref.read(authStateProvider);
  if (currentAuth is Authenticated) unawaited(client.connect());

  ref.listen<AuthState>(authStateProvider, (_, auth) {
    if (auth is Authenticated) {
      unawaited(client.connect());
    } else {
      client.disconnect();
    }
  });

  return client;
});

final matchRoomProvider = Provider.family<bool, String>((ref, matchId) {
  final client = ref.watch(matchRealtimeClientProvider);
  final auth = ref.watch(authStateProvider);
  if (auth is! Authenticated) return false;

  unawaited(client.joinMatch(matchId));

  final subscription = client.events.listen((event) {
    if (event.matchId != null && event.matchId != matchId) return;
    ref
        .read(scoringControllerProvider(matchId).notifier)
        .applyRealtimeEvent(event);

    if (_scoreEventNames.contains(event.name)) {
      ref.invalidate(matchDetailProvider(matchId));
      ref.invalidate(matchScorecardProvider(matchId));
      ref.invalidate(matchCommentaryProvider(matchId));
      ref.invalidate(matchInningsProvider((matchId, 1)));
      ref.invalidate(matchInningsProvider((matchId, 2)));
    }
  });

  ref.onDispose(() {
    subscription.cancel();
    client.leaveMatch(matchId);
  });

  return true;
});
