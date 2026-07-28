import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_client.dart';
import 'api_config.dart';
import 'repository.dart';

/// Thin wrapper over the socket.io connection to the NestJS ChatGateway.
///
/// Connects once (authenticated with the stored JWT), exposes a broadcast
/// stream of every incoming message, and sends over the socket with a REST
/// fallback. The server echoes each sent message back to the sender too, so
/// screens dedupe by message `_id` rather than optimistically inserting.
class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  io.Socket? _socket;
  // The token the current socket was authenticated with. If ApiAuth.token later
  // differs (the user switched accounts / re-logged in), the socket must be
  // rebuilt — otherwise it keeps sending as the PREVIOUS user, which the server
  // rejects as "you cannot message yourself" when you open that user's chat.
  String? _socketToken;
  final _incoming = StreamController<Map<String, dynamic>>.broadcast();

  /// Every `message:new` pushed by the server (both mine and the other party's).
  Stream<Map<String, dynamic>> get onMessage => _incoming.stream;

  bool get connected => _socket?.connected ?? false;

  /// Open the socket (or reopen it if the logged-in user changed), using the
  /// current bearer token. Safe to call repeatedly (e.g. from each chat screen's
  /// initState).
  void ensureConnected() {
    final token = ApiAuth.token;
    if (token == null || token.isEmpty) return; // not logged in yet

    // Already connected as the SAME user — nothing to do.
    if (_socket != null && _socketToken == token) return;

    // Token changed (account switch) or a stale socket exists → rebuild it so
    // the socket's identity matches the current session.
    _socket?.dispose();

    final socket = io.io(
      ApiConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setAuth({'token': token})
          .build(),
    );
    socket.on('message:new', (data) {
      if (data is Map) {
        _incoming.add(Map<String, dynamic>.from(data));
      }
    });
    socket.connect();
    _socket = socket;
    _socketToken = token;
  }

  /// Send a message. Uses the socket when connected (with an ack that returns
  /// the saved message), otherwise falls back to REST — both broadcast live.
  Future<Map<String, dynamic>> send(String toUserId, String text) {
    final socket = _socket;
    if (socket != null && socket.connected) {
      final completer = Completer<Map<String, dynamic>>();
      socket.emitWithAck(
        'message:send',
        {'toUserId': toUserId, 'text': text},
        ack: (res) {
          if (res is Map &&
              res['ok'] == true &&
              res['message'] is Map &&
              !completer.isCompleted) {
            completer.complete(Map<String, dynamic>.from(res['message'] as Map));
          } else if (!completer.isCompleted) {
            final err =
                (res is Map ? res['error'] : null)?.toString() ?? 'Send failed';
            completer.completeError(ApiException(err));
          }
        },
      );
      // If the ack never lands, fall back to REST so the message isn't lost.
      return completer.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () => Repository.instance.sendMessage(toUserId, text),
      );
    }
    return Repository.instance.sendMessage(toUserId, text);
  }

  /// Drop the socket (e.g. on logout).
  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _socketToken = null;
  }
}
