import 'dart:async'; // ← important pour Timer
import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/appointment_service.dart';
import 'package:mypsy_app/resources/services/http_service.dart';
import 'package:mypsy_app/resources/services/socket_service.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/resources/services/crypto_service.dart';
import 'package:mypsy_app/resources/services/chat_service.dart';
import 'package:mypsy_app/screens/consultation/ConsultationEndedScreen.dart';

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
  bool isPsychiatrist = false;
  bool isLoadingConsultation = true;
  late DateTime startTime;
  Duration remainingTime = Duration.zero; // ✅ pour affichage dans le build

  Timer? _timer;
  Duration consultationDuration = const Duration(minutes: 30); // 🔥 initial
  Duration elapsedTime = Duration.zero;
  bool isConsultationEnded = false;
  Future<void> initConsultationTiming() async {
    print("🚀 initConsultationTiming lancé");
    final data = await AppointmentService().getAppointmentById(appointmentId);

    if (data != null) {
      try {
        final dateStr = data['date']; // ex: "2025-04-30"
        final timeStr = data['start_time']; // ex: "23:15:00"

        final dateParts = dateStr.split('-');
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);

        final timeParts = timeStr.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        // ⚠️ Ne pas utiliser .toLocal() si tout est déjà en heure locale
        final start = DateTime(year, month, day, hour, minute);
        final duration = Duration(minutes: data['duration_minutes']);
        final end = start.add(duration);
        final now = DateTime.now();

        if (!mounted) return;

        setState(() {
          startTime = start;
          consultationDuration = duration;

          if (now.isBefore(start)) {
            remainingTime = duration;
          } else if (now.isBefore(end)) {
            remainingTime = end.difference(now);
          } else {
            remainingTime = Duration.zero;
            isConsultationEnded = true;
          }
        });

        if (!isConsultationEnded) {
          startConsultationTimer();
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ConsultationEndedScreen(
                peerName: peerName,
                startTime: start,
                duration: duration,
              ),
            ),
          );
        }
      } catch (e) {
        print("❌ Erreur parsing date/heure : $e");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      peerId = widget.peerId;
      peerName = widget.peerName;
      appointmentId = widget.appointmentId;
      myUserId = await AuthService().getUserId() ?? 0;
      isPsychiatrist = (await AuthService().getUserRole()) == 'psychiatrist';

      SocketService().onMessage = handleIncomingMessage;
      await SocketService()
          .connectSocket(onMessageCallback: handleIncomingMessage);
      SocketService().socket?.on('duration_extended', (data) async {
        print("📲 reçu duration_extended côté Flutter : $data");
        final int receivedAppointmentId = data['appointmentId'];
        final int extraMinutes = data['extraMinutes'];

        if (receivedAppointmentId == appointmentId) {
          if (!mounted) return;

          final updated =
              await AppointmentService().getAppointmentById(appointmentId);
          if (updated != null) {
            final updatedDuration =
                Duration(minutes: updated['duration_minutes']);
            final now = DateTime.now();
            final end = startTime.add(updatedDuration);

            setState(() {
              consultationDuration = updatedDuration;
              elapsedTime = now.isAfter(startTime)
                  ? now.difference(startTime)
                  : Duration.zero;
              isConsultationEnded = now.isAfter(end);
            });

            _timer?.cancel();
            startConsultationTimer(); // 🔁 relance le timer
          }
        }
      });

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
      await initConsultationTiming();
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

  void startConsultationTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      final now = DateTime.now();
      final endTime = startTime.add(consultationDuration);
      final remaining = endTime.difference(now);

      if (remaining <= Duration.zero) {
        _timer?.cancel();
        setState(() => isConsultationEnded = true);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ConsultationEndedScreen(
              peerName: peerName,
              startTime: startTime,
              duration: consultationDuration,
            ),
          ),
        );
      } else {
        setState(() {
          elapsedTime = now.difference(startTime);
          remainingTime = remaining; // ✅ ici on le met à jour
        });
      }
    });
  }

  void extendConsultation() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '⏱️ Prolonger la consultation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 1),
            for (int minutes in [5, 10, 15])
              ListTile(
                leading: const Icon(Icons.access_time, color: Colors.teal),
                title: Text(
                  'Ajouter $minutes minutes',
                  style: const TextStyle(fontSize: 16),
                ),
                onTap: () async {
                  await AppointmentService().extendAppointment(
                    appointmentId: appointmentId,
                    extraMinutes: minutes,
                  );
                  setState(() {
                    consultationDuration += Duration(minutes: minutes);
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('✅ Consultation prolongée de $minutes minutes.'),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void handleIncomingMessage(Map<String, dynamic> data) async {
    final fromId = data['from'].toString();
    if (fromId != peerId) return;

    final peerPublicKey = await AuthService().fetchPeerPublicKey(fromId);
    final decrypted = await CryptoService().decryptMessage(
      cipherTextBase64: data['cipherText'],
      nonceBase64: data['nonce'],
      macBase64: data['tag'],
      peerPublicKeyBase64: peerPublicKey,
    );

    if (!mounted) return;
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
      body: {
        'extraMinutes': 15,
      },
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

  // 🕒 Ajoute ici la fonction pour formater la durée
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> loadMessages() async {
    final peerPublicKey = await AuthService().fetchPeerPublicKey(peerId);
    final data = await ChatService().getMessages(appointmentId);
    await HttpService().request(
      url: 'http://10.0.2.2:3001/api/messages/$appointmentId/read',
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
    if (isConsultationEnded) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // 👉 Stop typing avant d’envoyer
    SocketService().emitTyping(toUserId: int.parse(peerId), isTyping: false);

    final peerPublicKey = await AuthService().fetchPeerPublicKey(peerId);
    final encrypted = await CryptoService().encryptMessage(text, peerPublicKey);

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
    _timer?.cancel();
    SocketService().onMessage = null;
    SocketService().onMessageRead = null;
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
                    Text(widget.peerName,
                        style: const TextStyle(fontSize: 18),
                        overflow: TextOverflow.ellipsis),
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
            // 🔥 Seulement si psy
            IconButton(
              icon: const Icon(Icons.call, color: Colors.white),
              onPressed: () {
                // TODO: logiques d’appel audio ici
                print('📞 Appel audio');
              },
            ),
            IconButton(
              icon: const Icon(Icons.videocam, color: Colors.white),
              onPressed: () {
                // TODO: logiques d’appel vidéo ici
                print('🎥 Appel vidéo');
              },
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEDEDED),
        body: Column(
          children: [
            if (!isConsultationEnded)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.hourglass_bottom,
                            color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          _formatDuration(remainingTime),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: remainingTime.inMinutes <= 5
                                ? Colors.red
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    if (isPsychiatrist)
                      ElevatedButton.icon(
                        onPressed: extendConsultation,
                        icon: const Icon(Icons.add_alarm, size: 18),
                        label: const Text('Prolonger'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            if (isConsultationEnded)
              const Center(
                child: Text(
                  "⏰ La consultation est terminée",
                  style: TextStyle(color: Colors.red, fontSize: 18),
                ),
              ),
            Expanded(
              child: isConsultationEnded
                  ? const Center()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      itemCount: messages.length + (isPeerTyping ? 1 : 0),
                      itemBuilder: (_, index) {
                        if (isPeerTyping && index == messages.length) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                "$peerName est en train d’écrire...",
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey),
                              ),
                            ),
                          );
                        }

                        final msg = messages[index];
                        final fromMe = msg['fromMe'] ?? false;

                        return Align(
                          alignment: fromMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: fromMe
                                  ? const Color(0xFFDCF8C6)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(msg['text'],
                                style: const TextStyle(fontSize: 16)),
                          ),
                        );
                      },
                    ),
            ),
            if (!isConsultationEnded) _buildMessageInput(),
          ],
        ),
      );

  Widget _buildMessageInput() {
    final isDisabled = isConsultationEnded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.grey),
            onPressed: isDisabled ? null : () {},
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !isDisabled,
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
          GestureDetector(
            onTap: isDisabled ? null : sendMessage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDisabled ? Colors.grey : const Color(0xFF128C7E),
              ),
              child: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
