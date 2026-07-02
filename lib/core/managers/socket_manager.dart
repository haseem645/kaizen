import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

enum SocketConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class SocketEventMessage {
  const SocketEventMessage({required this.event, this.data});

  final String event;
  final dynamic data;
}

class SocketManager extends ChangeNotifier {
  SocketManager._();

  static const String _assistantBaseUrl =
      'wss://dev-api.kaizenteams.ai/ws/ai/assistant/';

  static final SocketManager instance = SocketManager._();

  io.Socket? _socket;
  WebSocket? _assistantSocket;
  StreamSubscription<dynamic>? _assistantSubscription;
  final StreamController<SocketEventMessage> _eventController =
      StreamController<SocketEventMessage>.broadcast();
  final StreamController<Object> _errorController =
      StreamController<Object>.broadcast();
  int _assistantSocketGeneration = 0;

  SocketConnectionStatus _status = SocketConnectionStatus.disconnected;
  String? _socketUrl;
  String _path = '/socket.io/';
  List<String> _transports = const <String>['websocket'];
  Map<String, dynamic>? _query;
  Map<String, dynamic>? _headers;
  Map<String, dynamic>? _auth;
  bool _autoReconnect = true;
  int _reconnectionAttempts = 5;
  Duration _reconnectDelay = const Duration(seconds: 3);
  Duration _timeout = const Duration(seconds: 20);
  Object? _lastError;

  SocketConnectionStatus get status => _status;
  bool get isConnected => _status == SocketConnectionStatus.connected;
  bool get isConnecting =>
      _status == SocketConnectionStatus.connecting ||
      _status == SocketConnectionStatus.reconnecting;
  String? get socketUrl => _socketUrl;
  String? get socketId => _socket?.id;
  Object? get lastError => _lastError;
  io.Socket? get socket => _socket;
  WebSocket? get assistantSocket => _assistantSocket;

  Stream<SocketEventMessage> get events => _eventController.stream;
  Stream<Object> get errors => _errorController.stream;

  void _log(String message) {
    debugPrint('[SocketManager] $message');
  }

  String _redactedUri(Uri uri) {
    final queryParameters = Map<String, String>.from(uri.queryParameters);
    final token = queryParameters['token'];
    if (token != null && token.isNotEmpty) {
      queryParameters['token'] =
          '${token.substring(0, token.length.clamp(0, 8))}...';
    }
    return uri.replace(queryParameters: queryParameters).toString();
  }

  Future<void> connectAssistantSocket({
    required String token,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final trimmedToken = token.trim();
    _log(
      'connectAssistantSocket called. tokenEmpty=${trimmedToken.isEmpty}, timeoutMs=${timeout.inMilliseconds}',
    );
    if (trimmedToken.isEmpty) {
      final error = StateError(
        'Cannot connect assistant socket without a token.',
      );
      _log('connectAssistantSocket aborted: missing token');
      _lastError = error;
      _updateStatus(SocketConnectionStatus.error);
      _errorController.add(error);
      throw error;
    }

    final nextSocketUrl = Uri.parse(
      _assistantBaseUrl,
    ).replace(queryParameters: <String, String>{'token': trimmedToken});
    final existingAssistantSocket = _assistantSocket;
    if (existingAssistantSocket != null &&
        _status == SocketConnectionStatus.connected &&
        _socketUrl == nextSocketUrl.toString()) {
      _log(
        'connectAssistantSocket skipped: assistant socket already connected',
      );
      return;
    }

    final generation = ++_assistantSocketGeneration;
    await disconnectAssistantSocket(invalidateGeneration: false);

    final uri = nextSocketUrl;

    _socketUrl = uri.toString();
    _lastError = null;
    _timeout = timeout;
    _log('Connecting assistant socket to ${_redactedUri(uri)}');
    _updateStatus(SocketConnectionStatus.connecting);

    try {
      final webSocket = await WebSocket.connect(
        uri.toString(),
      ).timeout(timeout);
      if (generation != _assistantSocketGeneration) {
        _log('Ignoring stale assistant socket connection result');
        await webSocket.close();
        return;
      }
      _assistantSocket = webSocket;
      _log(
        'Assistant socket connected. readyState=${webSocket.readyState}, protocol=${webSocket.protocol}',
      );
      _updateStatus(SocketConnectionStatus.connected);
      _eventController.add(
        const SocketEventMessage(event: 'assistant_connect'),
      );

      _assistantSubscription = webSocket.listen(
        (dynamic data) {
          if (!_isCurrentAssistantSocket(webSocket, generation)) {
            _log('Ignoring assistant message from stale socket');
            return;
          }
          if (data is String && data.trim().isEmpty) {
            return;
          }
          _eventController.add(
            SocketEventMessage(event: 'assistant_message', data: data),
          );
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!_isCurrentAssistantSocket(webSocket, generation)) {
            _log('Ignoring stale assistant socket error: $error');
            return;
          }
          _log('Assistant socket stream error: $error');
          _lastError = error;
          _updateStatus(SocketConnectionStatus.error);
          _errorController.add(error);
        },
        onDone: () {
          if (!_isCurrentAssistantSocket(webSocket, generation)) {
            _log(
              'Ignoring stale assistant socket done. code=${webSocket.closeCode}, reason=${webSocket.closeReason}',
            );
            return;
          }
          _log(
            'Assistant socket done. code=${webSocket.closeCode}, reason=${webSocket.closeReason}',
          );
          _assistantSubscription = null;
          _assistantSocket = null;
          _updateStatus(SocketConnectionStatus.disconnected);
          _eventController.add(
            SocketEventMessage(
              event: 'assistant_disconnect',
              data: webSocket.closeReason,
            ),
          );
        },
        cancelOnError: false,
      );
    } catch (error) {
      _log('Assistant socket connection failed: $error');
      _lastError = error;
      _assistantSocket = null;
      _assistantSubscription = null;
      _updateStatus(SocketConnectionStatus.error);
      _errorController.add(_lastError!);
      rethrow;
    }
  }

  void sendAssistantMessage(dynamic data) {
    final activeSocket = _assistantSocket;
    if (activeSocket == null) {
      _log('sendAssistantMessage failed: assistant socket is null');
      throw StateError('Assistant socket is not connected.');
    }

    if (data is Uint8List) {
      _log('Sending assistant socket byte message. length=${data.length}');
      activeSocket.add(data);
      return;
    }

    if (data is List<int>) {
      _log('Sending assistant socket byte-list message. length=${data.length}');
      activeSocket.add(Uint8List.fromList(data));
      return;
    }

    if (data is String) {
      _log('Sending assistant socket string message: $data');
      activeSocket.add(data);
      return;
    }

    final encoded = jsonEncode(data);
    _log('Sending assistant socket json message: $encoded');
    activeSocket.add(encoded);
  }

  Future<void> connect({
    required String url,
    String path = '/socket.io/',
    List<String> transports = const <String>['websocket'],
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? auth,
    bool autoReconnect = true,
    int reconnectionAttempts = 5,
    Duration reconnectDelay = const Duration(seconds: 3),
    Duration timeout = const Duration(seconds: 20),
  }) async {
    _socketUrl = url;
    _path = path;
    _transports = List<String>.from(transports);
    _query = query == null ? null : Map<String, dynamic>.from(query);
    _headers = headers == null ? null : Map<String, dynamic>.from(headers);
    _auth = auth == null ? null : Map<String, dynamic>.from(auth);
    _autoReconnect = autoReconnect;
    _reconnectionAttempts = reconnectionAttempts;
    _reconnectDelay = reconnectDelay;
    _timeout = timeout;
    _lastError = null;

    await disconnect();

    _updateStatus(SocketConnectionStatus.connecting);

    final options = io.OptionBuilder()
        .setTransports(_transports)
        .setPath(_path)
        .setTimeout(_timeout.inMilliseconds)
        .setReconnectionAttempts(_reconnectionAttempts)
        .setReconnectionDelay(_reconnectDelay.inMilliseconds)
        .disableAutoConnect();

    if (_autoReconnect) {
      options.enableReconnection();
    } else {
      options.disableReconnection();
    }

    if (_query != null && _query!.isNotEmpty) {
      options.setQuery(_query!);
    }
    if (_headers != null && _headers!.isNotEmpty) {
      options.setExtraHeaders(_headers!);
    }
    if (_auth != null && _auth!.isNotEmpty) {
      options.setAuth(_auth!);
    }

    final socket = io.io(url, options.build());
    _socket = socket;
    _registerCoreListeners(socket);
    socket.connect();
  }

  Future<void> reconnect() async {
    final activeSocket = _socket;
    if (activeSocket != null) {
      _updateStatus(SocketConnectionStatus.reconnecting);
      activeSocket.disconnect();
      activeSocket.connect();
      return;
    }

    final url = _socketUrl;
    if (url == null || url.isEmpty) {
      return;
    }

    await connect(
      url: url,
      path: _path,
      transports: _transports,
      query: _query,
      headers: _headers,
      auth: _auth,
      autoReconnect: _autoReconnect,
      reconnectionAttempts: _reconnectionAttempts,
      reconnectDelay: _reconnectDelay,
      timeout: _timeout,
    );
  }

  void emit(String event, [dynamic data]) {
    final activeSocket = _socket;
    if (activeSocket == null) {
      throw StateError('Socket is not initialized.');
    }

    activeSocket.emit(event, data);
  }

  Future<dynamic> emitWithAck(
    String event, [
    dynamic data,
    Duration timeout = const Duration(seconds: 10),
  ]) async {
    final activeSocket = _socket;
    if (activeSocket == null) {
      throw StateError('Socket is not initialized.');
    }

    final completer = Completer<dynamic>();
    Timer? timer;

    timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException('Socket ack timed out for event "$event".'),
        );
      }
    });

    activeSocket.emitWithAck(
      event,
      data,
      ack: (response) {
        timer?.cancel();
        if (!completer.isCompleted) {
          completer.complete(response);
        }
      },
    );

    return completer.future;
  }

  void on(String event, void Function(dynamic data) handler) {
    _socket?.on(event, handler);
  }

  void off(String event, [void Function(dynamic data)? handler]) {
    if (handler != null) {
      _socket?.off(event, handler);
      return;
    }

    _socket?.off(event);
  }

  Future<void> disconnect() async {
    _log('disconnect called');
    await disconnectAssistantSocket();

    final activeSocket = _socket;
    _socket = null;

    if (activeSocket == null) {
      _log('disconnect finished: no socket.io socket to close');
      _updateStatus(SocketConnectionStatus.disconnected);
      return;
    }

    activeSocket.offAny();
    activeSocket.dispose();
    _log('socket.io socket disposed');
    _updateStatus(SocketConnectionStatus.disconnected);
  }

  Future<void> disconnectAssistantSocket({
    bool invalidateGeneration = true,
  }) async {
    _log('disconnectAssistantSocket called');
    if (invalidateGeneration) {
      _assistantSocketGeneration++;
    }
    final activeSocket = _assistantSocket;
    final subscription = _assistantSubscription;
    _assistantSocket = null;
    _assistantSubscription = null;

    await subscription?.cancel();
    if (subscription != null) {
      _log('Assistant socket subscription cancelled');
    }

    if (activeSocket == null) {
      _log('disconnectAssistantSocket finished: no active assistant socket');
      return;
    }

    try {
      _log(
        'Closing assistant socket. code=${activeSocket.closeCode}, reason=${activeSocket.closeReason}',
      );
      await activeSocket.close();
      _log('Assistant socket close requested');
    } catch (_) {
      _log('Assistant socket close threw but was ignored');
      // Keep cleanup resilient.
    }
  }

  bool _isCurrentAssistantSocket(WebSocket socket, int generation) {
    return generation == _assistantSocketGeneration &&
        identical(_assistantSocket, socket);
  }

  void _registerCoreListeners(io.Socket socket) {
    socket.onConnect((_) {
      _lastError = null;
      _updateStatus(SocketConnectionStatus.connected);
      _eventController.add(const SocketEventMessage(event: 'connect'));
    });

    socket.onDisconnect((reason) {
      _updateStatus(SocketConnectionStatus.disconnected);
      _eventController.add(
        SocketEventMessage(event: 'disconnect', data: reason),
      );
    });

    socket.onConnectError((error) {
      _lastError = error;
      _updateStatus(SocketConnectionStatus.error);
      _errorController.add(error is Object ? error : Exception('$error'));
    });

    socket.onError((error) {
      _lastError = error;
      _updateStatus(SocketConnectionStatus.error);
      _errorController.add(error is Object ? error : Exception('$error'));
    });

    socket.onReconnectAttempt((attempt) {
      _updateStatus(SocketConnectionStatus.reconnecting);
      _eventController.add(
        SocketEventMessage(event: 'reconnect_attempt', data: attempt),
      );
    });

    socket.onReconnect((attempt) {
      _updateStatus(SocketConnectionStatus.connected);
      _eventController.add(
        SocketEventMessage(event: 'reconnect', data: attempt),
      );
    });

    socket.onReconnectError((error) {
      _lastError = error;
      _updateStatus(SocketConnectionStatus.error);
      _errorController.add(error is Object ? error : Exception('$error'));
    });

    socket.onReconnectFailed((error) {
      _lastError = error;
      _updateStatus(SocketConnectionStatus.error);
      _errorController.add(error is Object ? error : Exception('$error'));
    });

    socket.onAny((event, data) {
      _eventController.add(SocketEventMessage(event: event, data: data));
    });
  }

  void _updateStatus(SocketConnectionStatus nextStatus) {
    if (_status == nextStatus) {
      return;
    }

    _log('Status changed: $_status -> $nextStatus');
    _status = nextStatus;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(disconnect());
    unawaited(_eventController.close());
    unawaited(_errorController.close());
    super.dispose();
  }
}
