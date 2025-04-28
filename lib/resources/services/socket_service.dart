import 'package:flutter/material.dart';
import 'package:mypsy_app/screens/chat/ConsultationLauncherScreen.dart';
import 'package:mypsy_app/screens/consultation/chatconsultation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:mypsy_app/resources/services/auth_service.dart';

typedef OnMessageReceived = Function(Map<String, dynamic> message);
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  // Callbacks
  OnMessageReceived? onMessage;
  Function(String userId)? onUserOnline;
  Function(String userId)? onUserOffline;
  Function(String userId)? onUserTyping;
  Function(String userId)? onUserStopTyping;
  Function(int messageId)? onMessageRead;
  Function(Map<String, dynamic> data)? onPatientJoined;

  Future<void> connectSocket({OnMessageReceived? onMessageCallback}) async {
    if (_socket != null && _socket!.connected) return;

    final prefs = await AuthService().storage;
    var token = await prefs.read(key: 'token');

    if (token == null || AuthService.isTokenExpired(token)) {
      final newToken = await AuthService.refreshToken();
      if (newToken != null) {
        token = newToken;
      } else {
        print('❌ Échec du refresh token.');
        return;
      }
    }

    _socket = IO.io('http://10.0.2.2:3001', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'auth': {'token': token},
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 1000,
    });

    onMessage = onMessageCallback;

    _socket!.on('connect', (_) async {
      print('🟢 Socket connecté ✅');
      final userId = await AuthService().getUserId();
      if (userId != null) {
        _socket!.emit('online', {'userId': userId});
      }
    });

    // 🔥 Ici la nouvelle version améliorée
    _socket!.on('consultation_started', (data) {
      final context = navigatorKey.currentContext;
      if (context == null) return;

      final mode = data['mode'];
      final peerId = data['from'].toString();
      final peerName = data['fullName'] ?? 'Patient';
      final appointmentId = data['appointmentId'];

      if (mode == 'chat') {
        // 🔔 1. Joue un son discret
        //   FlutterRingtonePlayer.playNotification();

        // 📢 2. Affiche une SnackBar personnalisée
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            backgroundColor: Colors.green,
            content: Row(
              children: [
                const Icon(Icons.campaign, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Consultation en cours avec $peerName",
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );

        // ⏳ 3. Après 2 secondes ➔ navigation automatique
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                peerId: peerId,
                peerName: peerName,
                appointmentId: appointmentId,
              ),
            ),
          );
        });
      }
    });

    _socket!.on('receive_message', (data) {
      print('📩 Message reçu via socket: $data');
      onMessage?.call(data);
    });

    _socket!.on('message_read', (data) {
      final messageId = data['messageId'];
      print('📘 Message lu : messageId = $messageId');
      onMessageRead?.call(messageId);
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

    _socket!.on('join_consultation', (data) {
      print('🚀 Patient a rejoint la consultation : $data');
      onPatientJoined?.call(data);
    });
  }

  void emit(String event, Map<String, dynamic> data) {
    _socket?.emit(event, data);
  }

  void sendMessage(Map<String, dynamic> payload) {
    _socket?.emit('send_message', payload);
  }

  void emitTyping({required int toUserId, required bool isTyping}) {
    _socket?.emit(isTyping ? 'typing' : 'stop_typing', {'to': toUserId});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  bool get isConnected => _socket?.connected ?? false;
}
