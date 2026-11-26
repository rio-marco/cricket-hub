import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/storage/secure_storage.dart';
import '../models/auction_json.dart';
import 'auction_realtime_event.dart';

abstract class RealtimeTokenProvider {
  Future<String?> getToken();
}

class SecureStorageRealtimeTokenProvider implements RealtimeTokenProvider {
  final SecureStorage _storage;

  const SecureStorageRealtimeTokenProvider(this._storage);

  @override
  Future<String?> getToken() => _storage.getToken();
}

abstract class AuctionRealtimeClient {
  Stream<AuctionRealtimeEvent> get events;
  Set<String> get joinedRooms;
  bool get isConnected;

  Future<void> connect();
  Future<void> joinAuction(String auctionId);
  void leaveAuction(String auctionId);
  Future<AuctionRealtimeEvent?> syncAuction(String auctionId);
  void disconnect();
  Future<void> dispose();
}

class SocketIOAuctionRealtimeClient implements AuctionRealtimeClient {
  static const _serverEvents = <String>[
    'connection:status',
    'auction:state',
    'auction:started',
    'auction:player_changed',
    'auction:bid_placed',
    'auction:bid_rejected',
    'auction:player_sold',
    'auction:player_unsold',
    'auction:paused',
    'auction:resumed',
    'auction:completed',
    'auction:error',
  ];

  final String _url;
  final RealtimeTokenProvider _tokenProvider;
  final StreamController<AuctionRealtimeEvent> _events =
      StreamController<AuctionRealtimeEvent>.broadcast();
  final Set<String> _rooms = <String>{};
  final Set<String> _joinedRooms = <String>{};

  io.Socket? _socket;
  String? _token;
  Future<void>? _connecting;

  SocketIOAuctionRealtimeClient({
    required this._url,
    required this._tokenProvider,
  });

  @override
  Stream<AuctionRealtimeEvent> get events => _events.stream;

  @override
  Set<String> get joinedRooms => Set<String>.unmodifiable(_joinedRooms);

  @override
  bool get isConnected => _socket?.connected ?? false;

  @override
  Future<void> connect() => _ensureConnected();

  @override
  Future<void> joinAuction(String auctionId) async {
    if (!_rooms.add(auctionId)) return;
    await _ensureConnected();
    await _joinCurrentRoom(auctionId);
  }

  @override
  void leaveAuction(String auctionId) {
    _rooms.remove(auctionId);
    _joinedRooms.remove(auctionId);
    if (isConnected) {
      _socket!.emit('auction:leave', {'auctionId': auctionId});
    }
  }

  @override
  Future<AuctionRealtimeEvent?> syncAuction(String auctionId) async {
    final ack = await _ack('auction:sync', {'auctionId': auctionId});
    if (ack == null) return null;
    return AuctionRealtimeEvent.from(
      auctionBool(ack['ok']) ? 'auction:state' : 'auction:error',
      ack,
    );
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
      for (final auctionId in _rooms.toList()) {
        unawaited(_joinCurrentRoom(auctionId));
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

  Future<void> _joinCurrentRoom(String auctionId) async {
    if (!isConnected || !_joinedRooms.add(auctionId)) return;
    final ack = await _ack('auction:join', {'auctionId': auctionId});
    if (ack != null) {
      _push('auction:state', ack);
    }
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
        completer.complete(normalizeAuctionMapOrNull(response));
      },
    );
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => null,
    );
  }

  void _push(String name, dynamic value) {
    if (_events.isClosed) return;
    _events.add(AuctionRealtimeEvent.from(name, value));
  }

  void _pushError(String code, dynamic error) {
    _push('auction:error', {
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
