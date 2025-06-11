import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/screens/consultation/chatconsultation.dart';

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
    if (_socket != null && _socket!.connected) {
      print('🟢 Socket déjà connecté.');
      return;
    }

    var token = await AuthService().getJwtToken();
    if (token == null || AuthService.isTokenExpired(token)) {
      print('🔁 Token expiré. Tentative de refresh...');
      final refreshedToken = await AuthService().refreshToken();
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
      print('🟢 Socket connecté ✅');
      final userId = await AuthService().getUserId();
      if (userId != null) {
        _socket!.emit('online', {'userId': userId});
        print('📡 Emit "online" avec userId : $userId');
      }
    });

    _socket!.on('connect_error', (err) async {
      print('🔴 Erreur de connexion socket : $err');
      if (err.toString().contains('jwt expired') ||
          err.toString().contains('Unauthorized')) {
        navigatorKey.currentState
            ?.pushNamedAndRemoveUntil('/login', (route) => false);
        disconnect();
      }
    });

    _socket!.on('consultation_started', (data) {
      final context = navigatorKey.currentContext;
      if (context == null) return;

      final mode = data['mode'];
      final peerId = data['from'].toString();
      final peerName = data['fullName'] ?? 'Patient';
      final appointmentId = data['appointmentId'];
      final consultationId = data['consultationId'];
      final roomId = 'consultation_$consultationId';

      if (mode == 'chat') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Consultation en cours avec $peerName"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                peerId: peerId,
                peerName: peerName,
                appointmentId: appointmentId,
                consultationId: consultationId,
                roomId: roomId,
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
      onMessageRead?.call(messageId);
    });

    _socket!.on('user_online', (data) {
      final userId = data['userId'].toString();
      onUserOnline?.call(userId);
    });

    _socket!.on('user_offline', (data) {
      final userId = data['userId'].toString();
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
    if (!isConnected) {
      print("❌ Impossible d'envoyer le message : socket non connecté");
      return;
    }
    print('📤 Envoi message via socket : $payload'); // 👈 Ajoute cette ligne
    _socket?.emit('send_message', payload);
  }

  void sendVoiceMessage({
    required String roomId,
    required String senderId,
    required String recipientId,
    required String audioUrl,
  }) {
    if (!isConnected) {
      print("❌ Impossible d'envoyer le message vocal : socket non connecté");
      return;
    }

    final payload = {
      'consultationId': roomId,
      'from': senderId,
      'to': recipientId,
      'audioUrl': audioUrl,
      'type': 'voice',
      'timestamp': DateTime.now().toIso8601String(),
    };

    _socket?.emit('send_message', payload);
  }

  void emitTyping({required int toUserId, required bool isTyping}) {
    if (!isConnected) {
      print("❌ Impossible d'émettre l'état de frappe : socket non connecté");
      return;
    }
    _socket?.emit(isTyping ? 'typing' : 'stop_typing', {'to': toUserId});
  }

  void joinRoom(String roomId) {
    if (!isConnected) return;
    _socket?.emit('join_room', {'roomId': roomId});
  }

  void on(String event, Function(dynamic) handler) {
    if (!isConnected) {
      print(
          '⚠️ Tentative d’écouter un événement sans socket connecté : $event');
      return;
    }
    _socket?.on(event, handler);
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  Future<void> waitForConnection({int maxTries = 10}) async {
    int attempt = 0;
    while (!isConnected && attempt < maxTries) {
      print("🕒 Attente connexion socket... ($attempt)");
      await Future.delayed(const Duration(milliseconds: 500));
      attempt++;
    }

    if (!isConnected) {
      print("❌ Connexion socket échouée après $maxTries tentatives");
    } else {
      print("✅ Socket connecté après $attempt tentatives");
    }
  }

  bool get isConnected => _socket?.connected ?? false;
  IO.Socket? get socket => _socket;
}
