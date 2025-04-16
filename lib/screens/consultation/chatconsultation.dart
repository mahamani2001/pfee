// 📁 lib/screens/chat/chat_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/resources/services/crypto_service.dart';
import 'package:mypsy_app/resources/services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;
  final int appointmentId;
  const ChatScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    required this.appointmentId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late IO.Socket socket;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> messages = [];

  late String peerId;
  late String peerName;
  late int appointmentId;
  late int myUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      peerId = widget.peerId;
      peerName = widget.peerName;
      appointmentId = widget.appointmentId;
      myUserId = await AuthService().getUserId() ?? 0;
      await initSocket();
      await loadMessages();
    });
  }

  Future<void> initSocket() async {
    final prefs = await AuthService().storage;
    final token = await prefs.read(key: 'token');

    socket = IO.io('http://10.0.2.2:3001', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
    });

    socket.connect();
    socket.on('connect', (_) => print('🟢 Connecté'));

    socket.on('receive_message', (data) async {
      final peerPublicKey =
          await AuthService().fetchPeerPublicKey(data['from']);
      final decrypted = await CryptoService().decryptMessage(
        cipherTextBase64: data['cipherText'],
        nonceBase64: data['nonce'],
        macBase64: data['tag'],
        peerPublicKeyBase64: peerPublicKey,
      );

      setState(() {
        messages.add({'text': decrypted, 'fromMe': false});
      });
    });
  }

  Future<void> loadMessages() async {
    final peerPublicKey = await AuthService().fetchPeerPublicKey(peerId);
    final data = await ChatService().getMessages(appointmentId);

    for (final msg in data) {
      final decrypted = await CryptoService().decryptMessage(
        cipherTextBase64: msg['ciphertext'],
        nonceBase64: msg['iv'],
        macBase64: msg['tag'],
        peerPublicKeyBase64: peerPublicKey,
      );
      setState(() {
        messages.add({
          'text': decrypted,
          'fromMe': msg['sender_id'] == myUserId,
        });
      });
    }
  }

  Future<void> sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final peerPublicKey = await AuthService().fetchPeerPublicKey(peerId);
    final encrypted = await CryptoService().encryptMessage(text, peerPublicKey);

    socket.emit('send_message', {
      'to': peerId,
      'cipherText': encrypted['cipherText'],
      'nonce': encrypted['nonce'],
    });

    await ChatService().saveMessage(
      appointmentId: appointmentId,
      iv: encrypted['nonce'],
      ciphertext: encrypted['cipherText'],
      tag: encrypted['mac'],
    );

    setState(() {
      messages.add({'text': text, 'fromMe': true});
      _messageController.clear();
    });
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text("Consultation avec $peerName")),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (_, index) {
                  final msg = messages[index];
                  return Align(
                    alignment: msg['fromMe']
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: msg['fromMe'] ? Colors.blue : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        msg['text'],
                        style: TextStyle(
                          color: msg['fromMe'] ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(hintText: "Message..."),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: sendMessage,
                  ),
                ],
              ),
            )
          ],
        ),
      );
}
