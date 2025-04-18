import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:mypsy_app/resources/services/auth_service.dart';

typedef OnMessageReceived = Function(Map<String, dynamic> message);

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  OnMessageReceived? onMessage;
  Function(String userId)? onUserOnline;
  Function(String userId)? onUserOffline;

  Function(String userId)? onUserTyping;
  Function(String userId)? onUserStopTyping;

  Future<void> connectSocket() async {
    if (_socket != null && _socket!.connected) return;

    final prefs = await AuthService().storage;
    final token = await prefs.read(key: 'token');

    _socket = IO.io('http://10.0.2.2:3001', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'auth': {'token': token},
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 1000,
    });

    _socket!.on('connect', (_) async {
      print('🟢 Socket connecté ✅');
      print('🟢 Socket connecté ✅');
      final userId = await AuthService().getUserId();
      if (userId != null) {
        _socket!.emit('online', {'userId': userId});
      }
    });

    _socket!.on('disconnect', (_) {
      print('🔌 Déconnecté du socket');
    });

    _socket!.on('receive_message', (data) {
      print('📩 Message reçu via socket: $data');
      if (onMessage != null) {
        onMessage!(data);
      }
    });
    _socket!.on('user_online', (data) {
      final userId = data['userId'].toString();
      print('🔵 Utilisateur en ligne : $userId');
      onUserOnline?.call(userId);
    });

    _socket!.on('user_offline', (data) {
      final userId = data['userId'].toString();
      print('⚪ Utilisateur hors ligne : $userId');
      onUserOffline?.call(userId);
    });

    _socket!.on('typing', (data) {
      final userId = data['userId'].toString();
      onUserTyping?.call(userId);
    });

    _socket!.on('stop_typing', (data) {
      final userId = data['userId'].toString();
      onUserStopTyping?.call(userId);
    });
  }

  void emitTyping({required int toUserId, required bool isTyping}) {
    _socket?.emit(isTyping ? 'typing' : 'stop_typing', {
      'to': toUserId,
    });
  }

  void sendMessage(Map<String, dynamic> payload) {
    _socket?.emit('send_message', payload);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  bool get isConnected => _socket?.connected ?? false;
}
