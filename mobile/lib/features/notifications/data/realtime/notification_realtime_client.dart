import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/storage/secure_storage.dart';
import 'notification_realtime_event.dart';

abstract class NotificationRealtimeTokenProvider {
  Future<String?> getToken();
}

class SecureStorageNotificationRealtimeTokenProvider
    implements NotificationRealtimeTokenProvider {
  final SecureStorage _storage;

  const SecureStorageNotificationRealtimeTokenProvider(this._storage);

  @override
  Future<String?> getToken() => _storage.getToken();
}

abstract class NotificationRealtimeClient {
  Stream<NotificationRealtimeEvent> get events;
  bool get isConnected;

  Future<void> connect();
  void disconnect();
  Future<void> dispose();
}

class SocketIONotificationRealtimeClient
    implements NotificationRealtimeClient {
  static const _serverEvents = <String>[
    'notification:new',
    'notification:read',
    'notification:unread-count',
  ];

  final String _url;
  final NotificationRealtimeTokenProvider _tokenProvider;
  final StreamController<NotificationRealtimeEvent> _events =
      StreamController<NotificationRealtimeEvent>.broadcast();

  io.Socket? _socket;
  String? _token;
  Future<void>? _connecting;

  SocketIONotificationRealtimeClient({
    required this._url,
    required this._tokenProvider,
  });

  @override
  Stream<NotificationRealtimeEvent> get events => _events.stream;

  @override
  bool get isConnected => _socket?.connected ?? false;

  @override
  Future<void> connect() => _ensureConnected();

  @override
  void disconnect() => _teardownSocket();

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

    socket.onConnect((_) {});
    socket.onDisconnect((_) {});
    socket.onConnectError((error) => _pushError('connect_error', error));
    socket.onError((error) => _pushError('socket_error', error));
    for (final event in _serverEvents) {
      socket.on(event, (data) => _push(event, data));
    }
  }

  void _push(String name, dynamic value) {
    if (_events.isClosed) return;
    _events.add(NotificationRealtimeEvent.from(name, value));
  }

  void _pushError(String code, dynamic error) {
    _push('notification:error', <String, dynamic>{
      'eventId': code,
      'message': error?.toString() ?? 'Realtime connection failed.',
    });
  }

  void _teardownSocket() {
    final socket = _socket;
    _socket = null;
    _token = null;
    if (socket == null) return;
    socket.disconnect();
    socket.destroy();
  }
}
