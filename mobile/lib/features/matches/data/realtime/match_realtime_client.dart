import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/storage/secure_storage.dart';
import 'match_realtime_event.dart';

abstract class RealtimeTokenProvider {
  Future<String?> getToken();
}

class SecureStorageRealtimeTokenProvider implements RealtimeTokenProvider {
  final SecureStorage _storage;

  const SecureStorageRealtimeTokenProvider(this._storage);

  @override
  Future<String?> getToken() => _storage.getToken();
}

abstract class MatchRealtimeClient {
  Stream<MatchRealtimeEvent> get events;
  Set<String> get joinedRooms;
  bool get isConnected;

  Future<void> connect();
  Future<void> joinMatch(String matchId);
  void leaveMatch(String matchId);
  Future<Map<String, dynamic>?> syncMatch(String matchId);
  void disconnect();
  Future<void> dispose();
}

class SocketIOMatchRealtimeClient implements MatchRealtimeClient {
  static const _serverEvents = <String>[
    'connection:status',
    'match:state',
    'score:delivery',
    'wicket:recorded',
    'score:corrected',
    'score:undone',
    'match:over-completed',
    'match:innings-started',
    'match:innings-ended',
    'match:completed',
    'match:error',
  ];

  final String _url;
  final RealtimeTokenProvider _tokenProvider;
  final StreamController<MatchRealtimeEvent> _events =
      StreamController<MatchRealtimeEvent>.broadcast();
  final Set<String> _rooms = <String>{};
  final Set<String> _joinedRooms = <String>{};

  io.Socket? _socket;
  String? _token;
  Future<void>? _connecting;

  SocketIOMatchRealtimeClient({
    required this._url,
    required this._tokenProvider,
  });

  @override
  Stream<MatchRealtimeEvent> get events => _events.stream;

  @override
  Set<String> get joinedRooms => Set<String>.unmodifiable(_joinedRooms);

  @override
  bool get isConnected => _socket?.connected ?? false;

  @override
  Future<void> connect() => _ensureConnected();

  @override
  Future<void> joinMatch(String matchId) async {
    if (!_rooms.add(matchId)) return;
    await _ensureConnected();
    await _joinCurrentRoom(matchId);
  }

  @override
  void leaveMatch(String matchId) {
    _rooms.remove(matchId);
    _joinedRooms.remove(matchId);
    if (isConnected) {
      _socket!.emit('match:leave', {'matchId': matchId});
    }
  }

  @override
  Future<Map<String, dynamic>?> syncMatch(String matchId) {
    return _ack('match:sync', {'matchId': matchId});
  }

  @override
  void disconnect() {
    _rooms.clear();
    _joinedRooms.clear();
    _teardownSocket();
  }

  @override
  Future<void> dispose() async {
    disconnect();
    await _events.close();
  }

  Future<void> _ensureConnected() async {
    final token = await _tokenProvider.getToken();
    if (token == null || token.isEmpty) return;

    if (_socket != null && _token == token) {
      if (!_socket!.connected) _socket!.connect();
      return;
    }

    final pending = _connecting;
    if (pending != null && _token == token) {
      await pending;
      return;
    }

    _teardownSocket();
    _token = token;
    final connecting = _createSocket(token);
    _connecting = connecting;
    try {
      await connecting;
    } finally {
      if (identical(_connecting, connecting)) _connecting = null;
    }
  }

  Future<void> _createSocket(String token) async {
    final socket = io.io(
      _url,
      io.OptionBuilder()
        .enableForceNew()
        .setTransports(['websocket', 'polling'])
        .enableAutoConnect()
        .enableReconnection()
        .setReconnectionAttempts(8)
        .setReconnectionDelay(1000)
        .setReconnectionDelayMax(10000)
        .setAuth({'token': token})
        .setExtraHeaders({'Authorization': 'Bearer $token'})
        .build(),
    );
    _socket = socket;

    socket.onConnect((_) {
      _joinedRooms.clear();
      for (final matchId in _rooms.toList()) {
        unawaited(_joinCurrentRoom(matchId));
      }
    });
    socket.onDisconnect((_) {
      _joinedRooms.clear();
    });
    socket.onConnectError((error) {
      _pushError('connect_error', error);
    });
    socket.onError((error) {
      _pushError('socket_error', error);
    });
    for (final event in _serverEvents) {
      socket.on(event, (data) => _push(event, data));
    }
  }

  Future<void> _joinCurrentRoom(String matchId) async {
    if (!isConnected || !_joinedRooms.add(matchId)) return;
    final ack = await _ack('match:join', {'matchId': matchId});
    if (ack != null) _push('match:state', ack);
  }

  Future<Map<String, dynamic>?> _ack(
    String event,
    Map<String, dynamic> payload,
  ) async {
    final socket = _socket;
    if (socket == null || !socket.connected) return null;

    final completer = Completer<Map<String, dynamic>?>();
    socket.emitWithAck(
      event,
      payload,
      ack: (dynamic response) {
        if (completer.isCompleted) return;
        final normalized = normalizeMapOrNull(response);
        completer.complete(normalized);
      },
    );
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => null,
    );
  }

  void _push(String name, dynamic value) {
    if (_events.isClosed) return;
    final normalized = normalizeMapOrNull(value);
    _events.add(
      MatchRealtimeEvent(
        name: name,
        data: normalized ?? <String, dynamic>{'value': value},
      ),
    );
  }

  void _pushError(String code, dynamic error) {
    _push('match:error', {
      'error': {
        'code': code,
        'message': error?.toString() ?? 'Realtime connection failed.',
      },
    });
  }

  void _teardownSocket() {
    final socket = _socket;
    _socket = null;
    _token = null;
    _joinedRooms.clear();
    if (socket == null) return;
    socket.disconnect();
    socket.destroy();
  }
}
