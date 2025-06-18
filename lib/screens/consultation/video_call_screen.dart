import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mypsy_app/resources/services/appointment_service.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/screens/consultation/chatconsultation.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mypsy_app/resources/services/socket_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String roomId;
  final String peerName;
  final bool isCaller;
  final int appointmentId;
  final int consultationId;
  final bool isAudioOnly;
  const VideoCallScreen({
    super.key,
    required this.roomId,
    required this.peerName,
    required this.appointmentId,
    required this.consultationId,
    this.isCaller = false,
    this.isAudioOnly = false,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  late DateTime startTime;
  Duration consultationDuration = Duration.zero;
  Duration remainingTime = Duration.zero;
  bool isConsultationEnded = false;
  Timer? consultationTimer;
  bool isPsychiatrist = false;
  late int consultationId;
  bool _micEnabled = true;
  bool _cameraEnabled = true;
  Timer? _callTimer;
  String _callDuration = "00:00";
  late DateTime endTime;

  @override
  void initState() {
    print('Room ID is ${widget.roomId}');
    super.initState();
    SocketService().connectSocket();

    consultationId = widget.consultationId;
    print(consultationId);
    _initCall();
    _startTimer();
    _initConsultationTiming();
    AuthService().getUserRole().then((role) {
      setState(() {
        isPsychiatrist = (role == 'psychiatrist');
      });
    });
    _registerSocketEvents();
  }

  Future<void> _initCall() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    await [Permission.camera, Permission.microphone].request();

    if (!await Permission.camera.isGranted ||
        !await Permission.microphone.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permissions caméra et micro requises")),
      );
      Navigator.pop(context);
      return;
    }

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': widget.isAudioOnly ? false : {'facingMode': 'user'},
    });

    _localRenderer.srcObject = _localStream;

    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ]
    });

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate != null) {
        SocketService().emit('webrtc-ice-candidate', {
          'roomId': widget.roomId,
          'candidate': candidate.toMap(),
        });
      }
    };

    _peerConnection!.onTrack = (event) {
      print("🎥 Remote track received: ${event.streams.length}");
      if (event.track.kind == 'video' && event.streams.isNotEmpty) {
        setState(() {
          _remoteRenderer.srcObject = event.streams[0];
        });
      }
    };

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    SocketService().on('webrtc-offer', (data) async {
      final offer = RTCSessionDescription(data['sdp'], 'offer');
      await _peerConnection!.setRemoteDescription(offer);
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      SocketService().emit('webrtc-answer', {
        'roomId': widget.roomId,
        'sdp': answer.sdp,
      });
    });

    SocketService().on('webrtc-answer', (data) async {
      final answer = RTCSessionDescription(data['sdp'], 'answer');
      await _peerConnection!.setRemoteDescription(answer);
    });

    SocketService().on('webrtc-ice-candidate', (data) async {
      final candidate = RTCIceCandidate(
        data['candidate']['candidate'],
        data['candidate']['sdpMid'],
        data['candidate']['sdpMLineIndex'],
      );
      await _peerConnection!.addCandidate(candidate);
    });

    SocketService().emit('join-room', {'roomId': widget.roomId});

    if (widget.isCaller) {
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      SocketService().emit('webrtc-offer', {
        'roomId': widget.roomId,
        'sdp': offer.sdp,
      });
    }
  }

  void startConsultationTimer() {
    print('Room ID is ${widget.roomId} ${widget.appointmentId}');
    consultationTimer?.cancel(); // 🔁 Toujours annuler le précédent
    print(widget.roomId);
    consultationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final diff = endTime.difference(now);

      if (!mounted) return; // sécurité

      if (diff <= Duration.zero) {
        timer.cancel();
        setState(() => isConsultationEnded = true);
        Navigator.pop(context); // fin de consultation
      } else {
        setState(() => remainingTime = diff);
      }
    });
  }

  void _registerSocketEvents() {
    SocketService().on('duration_extended', (data) {
      if (data['appointmentId'] == widget.appointmentId) {
        final extraMinutes = data['extraMinutes'];

        setState(() {
          consultationDuration += Duration(minutes: extraMinutes);
          endTime = endTime.add(Duration(minutes: extraMinutes));
        });

        startConsultationTimer();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⏱ Prolongée de $extraMinutes minutes")),
        );
      }
    });
  }

  Future<void> _initConsultationTiming() async {
    final data =
        await AppointmentService().getAppointmentById(widget.appointmentId);
    // tu dois passer l'ID à cet écran

    if (data != null) {
      final dateStr = data['date']; // "2025-05-07"
      final timeStr = data['start_time']; // "11:30:00"
      final parts = dateStr.split('-') + timeStr.split(':');
      startTime = DateTime(int.parse(parts[0]), int.parse(parts[1]),
              int.parse(parts[2]), int.parse(parts[3]), int.parse(parts[4]))
          .toLocal();

      consultationDuration = Duration(minutes: data['duration_minutes']);
      final now = DateTime.now();
      endTime = startTime.add(consultationDuration); // ✅ à faire
      remainingTime =
          now.isBefore(endTime) ? endTime.difference(now) : Duration.zero;

      setState(() {
        remainingTime =
            now.isBefore(endTime) ? endTime.difference(now) : Duration.zero;
        isConsultationEnded = now.isAfter(endTime);
      });

      if (!isConsultationEnded)
        startConsultationTimer();
      else
        Navigator.pop(context); // consultation déjà finie
    }
  }

  void _startTimer() {
    int seconds = 0;
    _callTimer = Timer.periodic(Duration(seconds: 1), (_) {
      seconds++;
      final minutesStr = (seconds ~/ 60).toString().padLeft(2, '0');
      final secondsStr = (seconds % 60).toString().padLeft(2, '0');
      setState(() => _callDuration = "$minutesStr:$secondsStr");
    });
  }

  void _toggleMic() {
    final audioTrack = _localStream?.getAudioTracks().first;
    if (audioTrack != null) {
      audioTrack.enabled = !_micEnabled;
      setState(() => _micEnabled = !_micEnabled);
    }
  }

  void _toggleCamera() {
    final videoTrack = _localStream?.getVideoTracks().first;
    if (videoTrack != null) {
      videoTrack.enabled = !_cameraEnabled;
      setState(() => _cameraEnabled = !_cameraEnabled);
    }
  }

  void _showExtendDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [5, 10, 15]
            .map((min) => ListTile(
                  title: Text("Ajouter $min minutes"),
                  onTap: () async {
                    await AppointmentService().extendAppointment(
                      appointmentId: widget.appointmentId,
                      extraMinutes: min,
                    );

                    SocketService().emit('duration_extended', {
                      'appointmentId': widget.appointmentId,
                      'extraMinutes': min,
                    });
                    setState(() {
                      endTime = endTime.add(Duration(minutes: min));
                    });
                    startConsultationTimer();

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text("Consultation prolongée de $min min")),
                    );
                  },
                ))
            .toList(),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _localStream?.dispose();
    _peerConnection!.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF84B8D5),
        body: Stack(
          children: [
            // 📹 Remote video full screen
            Positioned.fill(
              child: RTCVideoView(
                _remoteRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),

            // 📍 Temps restant affiché en haut
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isConsultationEnded
                      ? "✅ Consultation terminée"
                      : "⏳ Restant : ${_formatDuration(remainingTime)}",
                  style: AppThemes.getTextStyle(),
                ),
              ),
            ),

            // 🧑‍⚕️ Bouton prolonger visible uniquement pour le psychiatre
            if (isPsychiatrist && !isConsultationEnded)
              Positioned(
                top: 16,
                right: 16,
                child: ElevatedButton.icon(
                  onPressed: _showExtendDialog,
                  icon: const Icon(Icons.add_alarm),
                  label: const Text(
                    "Prolonger",
                  ),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
              ),

            // 👤 Local video en haut à droite
            Positioned(
              top: 60,
              right: 16,
              width: 100,
              height: 140,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: RTCVideoView(_localRenderer, mirror: true),
                ),
              ),
            ),

            // 🧑‍⚕️ Nom et durée de l’appel
            Positioned(
              bottom: 140,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(widget.peerName + widget.roomId,
                      style: const TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  Text(_callDuration,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 16)),
                ],
              ),
            ),

            // 🎮 Boutons d’actions
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 🎥 Toggle Camera
                  FloatingActionButton(
                    heroTag: 'camera',
                    backgroundColor: Colors.white,
                    onPressed: _toggleCamera,
                    child: Icon(
                      _cameraEnabled ? Icons.videocam : Icons.videocam_off,
                      color: Colors.black,
                    ),
                  ),

                  // 🔇 Toggle Mic
                  FloatingActionButton(
                    heroTag: 'mic',
                    backgroundColor: Colors.white,
                    onPressed: _toggleMic,
                    child: Icon(
                      _micEnabled ? Icons.mic : Icons.mic_off,
                      color: Colors.black,
                    ),
                  ),

                  // 💬 Chat sécurisé
                  FloatingActionButton(
                    heroTag: 'chat',
                    backgroundColor: Colors.blueAccent,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            peerId: widget
                                .peerName, // ou autre ID utilisateur correct (pas roomId)
                            peerName: widget.peerName,
                            appointmentId: widget.appointmentId,
                            consultationId: consultationId,
                            roomId: widget
                                .roomId, // ✅ ici on fournit bien le paramètre requis
                          ),
                        ),
                      );
                    },
                    child: const Icon(Icons.chat),
                  ),

                  // ❌ Fin d'appel
                  FloatingActionButton(
                    heroTag: 'end',
                    backgroundColor: Colors.red,
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(Icons.call_end),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
