import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/http_service.dart';
import 'package:mypsy_app/resources/services/socket_service.dart';
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
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> messages = [];
  bool isPeerOnline = false;
  bool isPeerTyping = false;
  late String peerId;
  late String peerName;
  late int appointmentId;
  late int myUserId;
  bool _isChatScreenActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      peerId = widget.peerId;
      peerName = widget.peerName;
      appointmentId = widget.appointmentId;
      myUserId = await AuthService().getUserId() ?? 0;
      SocketService().onMessage = handleIncomingMessage;
      await SocketService()
          .connectSocket(onMessageCallback: handleIncomingMessage);

      SocketService().onUserOnline = (userId) {
        if (userId == peerId) {
          setState(() {
            isPeerOnline = true;
          });
        }
      };

      SocketService().onUserOffline = (userId) {
        if (userId == peerId) {
          setState(() {
            isPeerOnline = false;
          });
        }
      };
      SocketService().onMessageRead = (messageId) {
        setState(() {
          for (var msg in messages) {
            if (msg['id'] == messageId && msg['fromMe']) {
              msg['status'] = 'read';
            }
          }
        });
      };
      await loadMessages();
    });

    SocketService().onUserTyping = (userId) {
      if (userId == peerId) {
        setState(() {
          isPeerTyping = true;
        });
      }
    };

    SocketService().onUserStopTyping = (userId) {
      if (userId == peerId) {
        setState(() {
          isPeerTyping = false;
        });
      }
    };
  }

  void handleIncomingMessage(Map<String, dynamic> data) async {
    print("📩 handleIncomingMessage appelé !");
    print("Données socket = $data");

    final fromId = data['from'].toString();
    if (fromId != peerId) return;

    final peerPublicKey = await AuthService().fetchPeerPublicKey(fromId);
    final decrypted = await CryptoService().decryptMessage(
      cipherTextBase64: data['cipherText'],
      nonceBase64: data['nonce'],
      macBase64: data['tag'],
      peerPublicKeyBase64: peerPublicKey,
    );

    if (!mounted) return; // 🔥 Protège ici
    setState(() {
      messages.add({
        'text': decrypted,
        'fromMe': false,
        'status': data['status'] ?? 'sent',
        'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
      });
    });

    await HttpService().request(
      url: 'http://10.0.2.2:3001/api/messages/$appointmentId/read',
      method: 'PUT',
      body: {},
    );
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    final date = DateTime.tryParse(iso);
    if (date == null) return '';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> loadMessages() async {
    final peerPublicKey = await AuthService().fetchPeerPublicKey(peerId);
    final data = await ChatService().getMessages(appointmentId);
    await HttpService().request(
      url: 'http://10.0.2.2:3001/api/messages/${widget.appointmentId}/read',
      method: 'PUT',
      body: {},
    );

    setState(() {
      messages.clear();
    });

    for (final msg in data) {
      final from = msg['sender_id'].toString();
      final to = msg['receiver_id'].toString();

      if (!(from == peerId || to == peerId)) continue;

      try {
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
            'status': msg['status'] ?? 'sent',
            'createdAt': msg['created_at'] ?? DateTime.now().toIso8601String(),
          });
        });
      } catch (e) {
        print("❌ Erreur de décryptage : $e");
      }
    }
  }

  Future<void> sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final peerPublicKey = await AuthService().fetchPeerPublicKey(peerId);
    final encrypted = await CryptoService().encryptMessage(text, peerPublicKey);
    print('📤 Envoi message vers $peerId (type: ${peerId.runtimeType})');

    SocketService().sendMessage({
      'to': int.parse(peerId),
      'cipherText': encrypted['cipherText'],
      'nonce': encrypted['nonce'],
      'tag': encrypted['mac'],
      'appointmentId': appointmentId,
    });

    await ChatService().saveMessage(
      appointmentId: appointmentId,
      iv: encrypted['nonce'],
      ciphertext: encrypted['cipherText'],
      tag: encrypted['mac'],
      receiverId: int.parse(peerId),
    );

    setState(() {
      messages.add({
        'text': text,
        'fromMe': true,
        'status': 'sent',
        'createdAt': DateTime.now().toIso8601String(),
      });
      _messageController.clear();
    });
  }

  @override
  void dispose() {
    _isChatScreenActive = false;
    SocketService().onMessage = null;
    SocketService().onMessageRead = null;
    super.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF075E54),
          title: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage('assets/images/doctor_avatar.png'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.peerName,
                      style: const TextStyle(fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isPeerOnline ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isPeerOnline ? "En ligne" : "Hors ligne",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.call), onPressed: () {}),
            IconButton(icon: const Icon(Icons.videocam), onPressed: () {}),
            const SizedBox(width: 5),
          ],
        ),
        backgroundColor: const Color(0xFFEDEDED),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                itemCount: messages.length + (isPeerTyping ? 1 : 0),
                itemBuilder: (_, index) {
                  if (isPeerTyping && index == messages.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        constraints: const BoxConstraints(maxWidth: 300),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          "$peerName est en train d’écrire...",
                          style: const TextStyle(
                              fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  final msg = messages[index];
                  final fromMe = msg['fromMe'] ?? false;

                  return Align(
                    alignment:
                        fromMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      constraints: const BoxConstraints(maxWidth: 300),
                      decoration: BoxDecoration(
                        color: fromMe ? const Color(0xFFDCF8C6) : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(fromMe ? 18 : 0),
                          bottomRight: Radius.circular(fromMe ? 0 : 18),
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 3),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              msg['text'],
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatTime(msg['createdAt']),
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey),
                              ),
                              if (fromMe)
                                Icon(
                                  msg['status'] == 'read'
                                      ? Icons.done_all
                                      : Icons.check,
                                  size: 16,
                                  color: msg['status'] == 'read'
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                      icon: const Icon(Icons.attach_file, color: Colors.grey),
                      onPressed: () {}),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        onChanged: (text) {
                          SocketService().emitTyping(
                            toUserId: int.parse(peerId),
                            isTyping: text.isNotEmpty,
                          );
                        },
                        decoration: const InputDecoration(
                          hintText: "Écrire un message...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                      icon: const Icon(Icons.mic, color: Colors.grey),
                      onPressed: () {}),
                  GestureDetector(
                    onTap: sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF128C7E),
                      ),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
