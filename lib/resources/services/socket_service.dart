import 'package:flutter/material.dart';
import 'package:mypsy_app/screens/consultation/ConsultationLauncherScreen.dart';
import 'package:mypsy_app/screens/consultation/chatconsultation.dart';
import 'package:mypsy_app/screens/consultation/video_call_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:mypsy_app/resources/services/auth_service.dart';

typedef OnMessageReceived = Function(Map<String, dynamic> message);
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  String? get socketId => _socket?.id;

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
    if (_socket != null && _socket!.connected) {
      print('🟢 Socket déjà connecté.');
      return;
    }

    var token = await AuthService().getJwtToken();

    if (token == null || AuthService.isTokenExpired(token)) {
      print('🔁 Token expiré. Tentative de refresh...');
      final refreshedToken = await AuthService.refreshToken();
      if (refreshedToken != null) {
        token = refreshedToken;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt', refreshedToken);
        print('✅ Token rafraîchi avec succès pour le socket');
      } else {
        print('❌ Impossible de rafraîchir le token. Déconnexion forcée.');
        return;
      }
    }

    print('📥 Token final utilisé pour le socket : $token');

    _socket = IO.io('http://192.168.1.2:3001', {
      'transports': ['websocket'],
      'auth': {'token': token},
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 1000,
    });
    onMessage = onMessageCallback;

    _socket!.on('connect', (_) async {
      print('🟢 Socket connecté avec succès ✅');
      final userId = await AuthService().getUserId();
      if (userId != null) {
        _socket!.emit('online', {'userId': userId});
        print('📡 Emit "online" avec userId : $userId');
      }
    });
    // 🔔 ÉCOUTE de l'appel entrant juste après connexion
    _socket!.on('incoming_call', (data) {
      final roomId = 'room-${data['appointmentId']}';
      final callerName = data['callerName'];
      final appointmentId = data['appointmentId'];

      navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (_) => VideoCallScreen(
          roomId: roomId,
          peerName: callerName,
          appointmentId: appointmentId,
          isCaller: false,
        ),
      ));
    });

    _socket!.on('connect_error', (err) async {
      print('🔴 Erreur de connexion socket : $err');

      if (err.toString().contains('jwt expired') ||
          err.toString().contains('Unauthorized')) {
        navigatorKey.currentState
            ?.pushNamedAndRemoveUntil('/login', (route) => false);
        disconnect(); // ferme le socket
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

  void sendMessage(Map<String, dynamic> payload) {
    _socket?.emit('send_message', payload);
  }

  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  void emit(String event, Map<String, dynamic> data) {
    _socket?.emit(event, data);
  }

  void emitTyping({required int toUserId, required bool isTyping}) {
    _socket?.emit(isTyping ? 'typing' : 'stop_typing', {'to': toUserId});
  }

  void off(String event) {
    _socket?.off(event);
  }

  void reconnect() async {
    if (_socket == null || !_socket!.connected) {
      print('🔄 Tentative de reconnexion au socket...');
      await connectSocket();
    }
  }

  void sendVoiceMessage({
    required int toUserId,
    required String fileName,
    required List<int> audioBytes,
    required int appointmentId,
    required int durationSeconds,
  }) {
    _socket?.emit('send_voice', {
      'to': toUserId,
      'fileName': fileName,
      'audio': audioBytes,
      'appointmentId': appointmentId,
      'duration': durationSeconds,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  bool get isConnected => _socket?.connected ?? false;
  IO.Socket? get socket => _socket;
}
