import 'dart:async'; // ← important pour Timer
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mypsy_app/helpers/app_config.dart';
import 'package:mypsy_app/resources/services/appointment_service.dart';
import 'package:mypsy_app/resources/services/consultation_service.dart';
import 'package:mypsy_app/resources/services/http_service.dart';
import 'package:mypsy_app/resources/services/socket_service.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/resources/services/crypto_service.dart';
import 'package:mypsy_app/resources/services/chat_service.dart';
import 'package:mypsy_app/screens/consultation/ConsultationEndedScreen.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

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
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _recordedFilePath;
  bool _isRecorderInitialized = false;
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  bool _isPlayerInitialized = false;
  String myFullName = '';
  String baseUrl = AppConfig.instance()!.baseUrl!;

  final flutterSoundHelper = FlutterSoundHelper();
  Future<Duration?> getAudioDuration(String filePath) async {
    try {
      final player = AudioPlayer();
      await player.setFilePath(filePath); // ❌ ne joue rien, juste charge
      final duration = player.duration;
      await player.dispose(); // libère les ressources
      return duration;
    } catch (e) {
      print("❌ Erreur de durée audio : $e");
      return null;
    }
  }

  Future<void> _playAudioWithJustAudio(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      print("❌ Fichier audio introuvable : $filePath");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fichier audio introuvable")),
      );
      return;
    }

    final player = AudioPlayer();

    try {
      await player.setFilePath(filePath);
      await player.play();
      print("🎧 Lecture en cours...");
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          print("✅ Lecture terminée");
          player.dispose(); // Libère les ressources
        }
      });
    } catch (e) {
      print("❌ Erreur pendant la lecture : $e");
    }
  }

  Future<void> initConsultationTiming() async {
    print("🚀 initConsultationTiming lancé");
    final data = await AppointmentService().getAppointmentById(appointmentId);
    print(
        "🔍 Appointment ID juste avant initConsultationTiming : $appointmentId");

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

        final start = DateTime(year, month, day, hour, minute).toLocal();
        final duration = Duration(minutes: data['duration_minutes']);
        final now = DateTime.now().toLocal();
        final end = start.add(duration);

        bool consultationHasEnded = false;

        if (now.isBefore(start)) {
          consultationHasEnded = false;
          remainingTime = Duration.zero;

          final delay = start.difference(now);
          Future.delayed(delay, () {
            if (!mounted) return;
            startConsultationTimer();
            setState(() {
              remainingTime = duration;
            });
          });
        } else if (now.isBefore(end)) {
          consultationHasEnded = false;
          remainingTime = end.difference(now);
        } else {
          consultationHasEnded = true;
          remainingTime = Duration.zero;
        }

        setState(() {
          startTime = start;
          consultationDuration = duration;
          isConsultationEnded = consultationHasEnded;
        });

        if (consultationHasEnded) {
          final consultation = await ConsultationService()
              .getConsultationByAppointment(appointmentId: appointmentId);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ConsultationEndedScreen(
                peerName: peerName,
                startTime: start,
                duration: duration,
                psychiatristId: int.parse(data['psychiatrist_id'].toString()),
                consultationId: consultation?['id'] ??
                    appointmentId, // Use actual consultationId
              ),
            ),
          );
        } else {
          startConsultationTimer();
        }

        print("🕒 START   : $start");
        print("🕒 NOW     : $now");
        print("⏳ DURATION: $duration");
        print("⏳ END     : $end");
        print("⏳ RemainingTime Calculé: $remainingTime");
      } catch (e) {
        print("❌ Erreur parsing date/heure : $e");
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (!_isRecorderInitialized) {
      print("❌ Recorder non initialisé !");
      return;
    }

    if (_isRecording) {
      final path = await _recorder!.stopRecorder();
      print("🎯 Chemin enregistré : $path");

      final file = File(path!);
      final fileSize = await file.length();
      print("🎤 Fichier audio enregistré : $path");
      print("📏 Taille du fichier : $fileSize octets");
      final audioBytes = await file.readAsBytes();
      print("📏 Taille finale fichier: ${audioBytes.length}");

      setState(() {
        _isRecording = false;
        _recordedFilePath = path;
      });

      if (fileSize < 1000) {
        print("⚠️ Audio trop court ou vide.");
        return;
      }
      final audioDuration = await getAudioDuration(path);

      // On ajoute au chat localement pour tester
      final fileName = path.split('/').last;
      setState(() {
        messages.add({
          'text': '🎤 $fileName',
          'filePath': path,
          'duration': audioDuration?.inSeconds ?? 0,
          'type': 'audio',
          'fromMe': true,
          'status': 'sent',
          'createdAt': DateTime.now().toIso8601String(),
        });
      });

// 🔥 Émission via socket
      final bytes = await File(path).readAsBytes();

      SocketService().emit('send_voice', {
        'to': int.parse(peerId),
        'appointmentId': appointmentId,
        'fileName': fileName,
        'duration': audioDuration?.inSeconds ?? 0,
        'audio': bytes,
      });
    } else {
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
      // nom fixe

      final files = Directory(tempDir.path).listSync();
      files.forEach((f) => print("🗂️ ${f.path}"));

      await _recorder!.startRecorder(toFile: path, codec: Codec.aacADTS);
      print(path);
      setState(() {
        _isRecording = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _recorder = FlutterSoundRecorder();
    _initRecorder();
    _initPlayer();

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
        print("📡 PATIENT a reçu l'événement duration_extended: $data");

        final int receivedAppointmentId = data['appointmentId'];
        final int extraMinutes = data['extraMinutes'];

        if (receivedAppointmentId != appointmentId) return;

        final newData =
            await AppointmentService().getAppointmentById(appointmentId);
        if (newData == null) return;

        final dateStr = newData['date'];
        final timeStr = newData['start_time'];

        final parts = dateStr.split('-') + timeStr.split(':');
        final newStartTime = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
          int.parse(parts[3]),
          int.parse(parts[4]),
        ).toLocal();

        final updatedDuration = Duration(minutes: newData['duration_minutes']);
        final now = DateTime.now();
        final newEndTime = newStartTime.add(updatedDuration);

        setState(() {
          startTime = newStartTime;
          consultationDuration = updatedDuration;
          remainingTime = newEndTime.difference(now);
          isConsultationEnded = now.isAfter(newEndTime);
        });

        _timer?.cancel();
        startConsultationTimer();
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
      print(
          "🔍 Appointment ID juste avant initConsultationTiming : $appointmentId");
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

  Future<void> _initPlayer() async {
    await _audioPlayer.openPlayer();
    setState(() {
      _isPlayerInitialized = true;
    });
  }

  void startConsultationTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      final now = DateTime.now(); // ✅ Heure locale
      final endTime = startTime.add(consultationDuration);

      final remaining = endTime.difference(now);

      if (remaining <= Duration.zero && !isConsultationEnded) {
        _timer?.cancel();
        isConsultationEnded = true; // ⚠️ PAS de setState ici

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ConsultationEndedScreen(
              peerName: peerName,
              startTime: startTime,
              duration: consultationDuration,
              psychiatristId: int.parse(peerId),
              consultationId: appointmentId,
            ),
          ),
        );
      } else {
        setState(() {
          remainingTime = remaining;
          elapsedTime = now.difference(startTime);
        });
      }
    });
  }

  Future<void> _initRecorder() async {
    final micStatus = await Permission.microphone.request();
    if (micStatus != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }

    await _recorder?.openRecorder();
    _isRecorderInitialized = true;
  }

  Future<void> _playAudio(String fileName) async {
    if (!_isPlayerInitialized) return;

    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/$fileName';
    print("🎧 Demande de lecture : $filePath");
    print("🎧 Player initialized: $_isPlayerInitialized");

    final file = File(filePath);
    if (!await file.exists()) {
      print("❌ Fichier introuvable : $filePath");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fichier audio introuvable')),
      );
      return;
    }

    print("🎧 Lecture de $filePath");
    await _audioPlayer.startPlayer(
      fromURI: filePath, // ou fileUrl
      codec: Codec.aacADTS,
      whenFinished: () => print('✅ Lecture terminée'),
    );
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

    if (!mounted) return;

    // 🔊 Cas 1: Message vocal en temps réel (non chiffré)
    if (data['type'] == 'audio') {
      final fileUrl = data['fileUrl']; // 🔁 utilise bien cette clé
      final fileName = data['fileName'] ?? 'audio.aac';
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$fileName';

      try {
        await HttpService().downloadFile(fileUrl, filePath);
        setState(() {
          messages.add({
            'text': '🎤 $fileName',
            'filePath': filePath,
            'duration': data['duration'] ?? 0,
            'type': 'audio',
            'fromMe': false,
            'status': 'received',
            'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
          });
        });
      } catch (e) {
        print("❌ Erreur téléchargement audio : $e");
      }
      return;
    }
    if (data['type'] == 'pdf' || data['type'] == 'image') {
      setState(() {
        messages.add({
          'type': data['type'],
          'filePath': data['fileUrl'],
          'fileName': data['fileName'],
          'fromMe': false,
          'createdAt': data['createdAt'],
        });
      });
      return;
    }

    // 🔐 Cas 2: Message texte chiffré
    final peerPublicKey = await AuthService().fetchPeerPublicKey(fromId);
    final decrypted = await CryptoService().decryptMessage(
      cipherTextBase64: data['cipherText'],
      nonceBase64: data['nonce'],
      macBase64: data['tag'],
      peerPublicKeyBase64: peerPublicKey,
    );

    // 🔍 Cas 3: Message spécial
    if (decrypted == '__MEDICAL_CARD_REQUEST__') {
      setState(() {
        messages.add({
          'text': 'Do you have any medical card?',
          'type': 'choice',
          'options': ['Yes', 'No'],
          'fromMe': false,
        });
      });
      return;
    }

    // 📝 Cas 4: Message texte normal
    setState(() {
      messages.add({
        'text': decrypted,
        'fromMe': false,
        'status': data['status'] ?? 'sent',
        'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
      });
    });

    // Lecture confirmée
    await HttpService().request(
      url: '$baseUrl/messages/$appointmentId/read',
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

  // 🕒 Ajoute ici la fonction pour formater la durée
  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<void> loadMessages() async {
    final peerPublicKey = await AuthService().fetchPeerPublicKey(peerId);
    final data = await ChatService().getMessages(appointmentId);

    await HttpService().request(
      url: '$baseUrl/messages/$appointmentId/read',
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

      // 🟡 Cas des messages audio (non chiffrés, contiennent un fichier)
      if (msg['type'] == 'audio') {
        final fileUrl =
            msg['ciphertext']; // ou msg['fileUrl'] selon ton backend
        final fileName = msg['fileName'] ?? fileUrl.split('/').last;
        final localPath = '${(await getTemporaryDirectory()).path}/$fileName';

        try {
          await HttpService().downloadFile(fileUrl, localPath);

          setState(() {
            messages.add({
              'type': 'audio',
              'filePath': localPath,
              'duration': msg['duration'] ?? 0,
              'fromMe': msg['sender_id'] == myUserId,
              'createdAt': msg['created_at'],
            });
          });
        } catch (e) {
          print('❌ Erreur lors du téléchargement du vocal : $e');
        }

        continue; // 👈 évite d’aller au décryptage
      }

      // 🔐 Cas des messages texte chiffrés
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
    _recorder?.closeRecorder();
    _recorder = null;
    SocketService().onMessage = null;
    SocketService().onMessageRead = null;

    super.dispose();
  }

  String formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: const Color(0xFF457B9D),
          foregroundColor: Colors.black,
          centerTitle: false,
          toolbarHeight: 70,
          title: Row(
            children: [
              const CircleAvatar(
                radius: 20,
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
        body: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: Column(
            children: [
              if (!isConsultationEnded && isPsychiatrist)
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
                      ElevatedButton.icon(
                        onPressed: extendConsultation,
                        icon: const Icon(Icons.add_alarm, size: 18),
                        label: const Text('Prolonger'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 255, 255, 255),
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
                          final type = msg['type'] ?? 'text';
                          if (type == 'pdf') {
                            return _buildPdfBubble(
                                msg['fileName'], msg['filePath'], fromMe);
                          }

                          if (type == 'image') {
                            return _buildImageBubble(msg['filePath'], fromMe);
                          }

                          if (msg['text']
                              .toString()
                              .startsWith('🎤 Message vocal')) {
                            final fileName = msg['text'].split(':').last.trim();
                            return Align(
                              alignment: fromMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: GestureDetector(
                                onTap: () => _playAudio(fileName),
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.play_arrow,
                                          color: Colors.black),
                                      const SizedBox(width: 8),
                                      Text('Écouter le message'),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          if (type == 'audio') {
                            final filePath = msg['filePath'];
                            return buildAudioBubble(filePath, fromMe);
                          }

                          if (type == 'choice') {
                            return _buildChoiceMessage(
                                msg['text'], msg['options'] ?? [], fromMe);
                          }

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
        ),
      );
  Widget buildAudioBubble(String filePath, bool fromMe) {
    return FutureBuilder<Duration?>(
      future: getAudioDuration(filePath),
      builder: (context, snapshot) {
        final duration = snapshot.data ?? Duration.zero;
        final durationFormatted = formatDuration(duration.inSeconds);

        return Align(
          alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: fromMe ? const Color(0xFF128C7E) : const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.play_arrow,
                      color: fromMe ? Colors.white : Colors.black87),
                  onPressed: () => _playAudioWithJustAudio(filePath),
                ),
                const SizedBox(width: 4),
                Text(
                  durationFormatted,
                  style: TextStyle(
                    color: fromMe ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPdfBubble(String fileName, String filePath, bool fromMe) {
    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: fromMe ? const Color(0xFFDCF8C6) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, size: 28, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fileName ?? 'Document',
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 20),
              onPressed: () {
                // Ouvre le PDF avec n'importe quel lecteur ou WebView
                _openFile(filePath);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageBubble(String filePath, bool fromMe) {
    final isUrl = filePath.startsWith('http');

    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[100],
        ),
        clipBehavior: Clip.hardEdge,
        child: isUrl
            ? Image.network(
                filePath,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error),
              )
            : Image.file(
                File(filePath),
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  Widget _buildMessageInput() {
    final isDisabled = isConsultationEnded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFEDEDED),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: Colors.teal),
            onPressed: isConsultationEnded
                ? null
                : () => _showFileTypeChooser(context),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
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
                  hintText: "Type something...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _messageController,
            builder: (context, value, child) {
              final hasText = value.text.trim().isNotEmpty;
              return GestureDetector(
                onTap: isDisabled
                    ? null
                    : hasText
                        ? sendMessage
                        : _toggleRecording,
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.teal,
                  child: Icon(
                    hasText
                        ? Icons.send
                        : (_isRecording ? Icons.stop : Icons.mic),
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceMessage(String question, List options, bool fromMe) =>
      Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F5), // Couleur de bulle bleue/grise
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Choose one option",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: options.map<Widget>((option) {
                return ChoiceChip(
                  label: Text(option),
                  selected: false,
                  onSelected: (_) {
                    if (option.toLowerCase() == 'yes') {
                      setState(() {
                        messages.add({
                          'text': 'Please upload your medical card',
                          'fromMe': true,
                          'status': 'sent',
                          'createdAt': DateTime.now().toIso8601String(),
                        });
                      });
                      _showUploadDialog();
                    } else {
                      sendMessageWithText("No medical card available.");
                    }
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: option.toLowerCase() == 'yes'
                      ? Colors.green
                      : Colors.redAccent,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                );
              }).toList(),
            ),
          ],
        ),
      );

  void sendMessageWithText(String message) {
    _messageController.text = message;
    sendMessage();
  }

  void _openFile(String filePath) async {
    try {
      if (filePath.startsWith('http')) {
        final encoded = Uri.encodeFull(filePath);
        final uri = Uri.parse(encoded);

        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          print(
              '❌ Impossible d’ouvrir le lien dans une app... essai navigateur');
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } else {
        // ✅ ouvrir localement si c'est un fichier
        await OpenFile.open(filePath);
      }
    } catch (e) {
      print("❌ Impossible d’ouvrir le fichier : $e");
    }
  }

  void _showUploadDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding:
            const EdgeInsets.only(left: 20, right: 20, top: 30, bottom: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.medical_services_outlined,
                size: 40, color: Colors.teal),
            const SizedBox(height: 10),
            const Text(
              "Téléversez votre carte médicale",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await _pickMedicalFile(); // 👈 à ajouter ensuite
                Navigator.pop(context);
              },
              icon: const Icon(Icons.upload_file),
              label: const Text("Choisir un fichier (PDF ou image)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile({required String extension}) async {
    final allowedExtensions =
        extension == 'pdf' ? ['pdf'] : ['jpg', 'jpeg', 'png'];

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.first.path!);
      final fileName = result.files.first.name;

      final fileType = extension == 'pdf' ? 'pdf' : 'image';

      final fileUrl = await ChatService().uploadFileMessage(
        file: file,
        appointmentId: appointmentId,
        receiverId: int.parse(peerId),
      );

      if (fileUrl != null) {
        setState(() {
          messages.add({
            'type': fileType,
            'filePath': fileUrl,
            'fileName': fileName,
            'fromMe': true,
            'createdAt': DateTime.now().toIso8601String(),
          });
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur envoi fichier')),
        );
      }
    }
  }

  void _showFileTypeChooser(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Wrap(
            children: [
              ListTile(
                leading:
                    const Icon(Icons.picture_as_pdf, color: Colors.deepPurple),
                title: const Text('Document PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile(extension: 'pdf');
                },
              ),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.teal),
                title: const Text('Photo ou Image'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile(extension: 'image');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.grey),
                title: const Text('Annuler'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickMedicalFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.first.path!);
      final fileName = result.files.first.name;
      final extension = result.files.first.extension;
      final userId = await AuthService().getUserId();

      final fileUrl = await ChatService().uploadFileMessage(
        file: file,
        appointmentId: appointmentId,
        receiverId: int.parse(peerId),
      );
      print('📁 Fichier uploadé: $fileName → $fileUrl');

      if (fileUrl != null) {
        final fileType = (extension == 'pdf') ? 'pdf' : 'image';
        setState(() {
          messages.add({
            'type': fileType,
            'filePath': fileUrl,
            'fileName': fileName,
            'fromMe': true,
            'createdAt': DateTime.now().toIso8601String(),
          });
        });
        print("🖼️ type: $fileType | fileName: $fileName | fileUrl: $fileUrl");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur envoi fichier')),
        );
      }
    }
  }
}
