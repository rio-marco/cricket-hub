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

typedef NotificationSocketBuilder = io.Socket Function(
  String url,
  String token,
);

io.Socket _defaultNotificationSocketBuilder(String url, String token) {
  return io.io(
    url,
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
}

class SocketIONotificationRealtimeClient implements NotificationRealtimeClient {
  static const _serverEvents = <String>[
    'notification:new',
    'notification:read',
    'notification:unread-count',
  ];

  final String _url;
  final NotificationRealtimeTokenProvider _tokenProvider;
  final NotificationSocketBuilder _socketBuilder;
  final StreamController<NotificationRealtimeEvent> _events =
      StreamController<NotificationRealtimeEvent>.broadcast();

  io.Socket? _socket;
  String? _token;
  Future<void>? _connecting;
  bool _connectingIntent = false;
  String? _tokenError;

  SocketIONotificationRealtimeClient({
    required String url,
    required NotificationRealtimeTokenProvider tokenProvider,
    NotificationSocketBuilder? socketBuilder,
  }) : _url = url,
       _tokenProvider = tokenProvider,
       _socketBuilder = socketBuilder ?? _defaultNotificationSocketBuilder;

  @override
  Stream<NotificationRealtimeEvent> get events => _events.stream;

  @override
  bool get isConnected => _socket?.connected ?? false;

  @override
  Future<void> connect() async {
    _connectingIntent = true;
    _tokenError = null;
    await _ensureConnected();
  }

  @override
  void disconnect() {
    _connectingIntent = false;
    _tokenError = null;
    _teardownSocket();
  }

  @override
  Future<void> dispose() async {
    disconnect();
    await _events.close();
  }

  Future<void> _ensureConnected() async {
    if (!_connectingIntent) return;
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
    final socket = _socketBuilder(_url, token);
    _socket = socket;

    socket.onConnect((_) {
      _tokenError = null;
      _push('notification:connection', <String, dynamic>{
        'connected': true,
        'at': DateTime.now().toIso8601String(),
      });
    });
    socket.onDisconnect((reason) {
      _push('notification:connection', <String, dynamic>{
        'connected': false,
        'reason': reason?.toString(),
        'at': DateTime.now().toIso8601String(),
      });
    });
    socket.onConnectError((error) => _handleConnectError(error));
    try {
      socket.onError((error) => _handleConnectError(error));
    } catch (_) {}

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

  void _handleConnectError(dynamic error) {
    final normalized = normalizeMapOrNull(error);
    final message =
        normalized?['message']?.toString() ?? error?.toString() ?? '';
    final data = normalizeMapOrNull(normalized?['data']);
    final code = data?['code']?.toString() ?? normalized?['code']?.toString();

    if (code == 'TOKEN_EXPIRED' || code == 'INVALID_TOKEN') {
      if (_tokenError == code) return;
      _tokenError = code;
      unawaited(_refreshTokenAndReconnect(code: code!, message: message));
      return;
    }
    _pushError(code ?? 'connect_error', message.isEmpty ? error : message);
  }

  Future<void> _refreshTokenAndReconnect({
    required String code,
    String? message,
  }) async {
    final refreshedToken = await _tokenProvider.getToken();
    final currentToken = _token;
    if (refreshedToken == null || refreshedToken.isEmpty) {
      _pushError(code, message ?? 'Realtime authentication failed.');
      disconnect();
      return;
    }

    if (currentToken != null && refreshedToken != currentToken) {
      _teardownSocket();
      if (_connectingIntent) {
        await _ensureConnected();
      }
      return;
    }

    _pushError(code, message ?? 'Realtime authentication failed.');
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
