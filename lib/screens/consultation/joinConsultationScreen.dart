import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/consultation_service.dart';
import 'package:mypsy_app/screens/consultation/chatconsultation.dart';
import 'package:mypsy_app/screens/consultation/video_call_screen.dart';

class JoinConsultationScreen extends StatelessWidget {
  final int appointmentId;
  final String peerId;
  final String peerName;

  const JoinConsultationScreen({
    super.key,
    required this.appointmentId,
    required this.peerId,
    required this.peerName,
  });

  Future<void> _joinConsultation(BuildContext context) async {
    try {
      final consultation = await ConsultationService()
          .getConsultationByAppointment(appointmentId);
      print('consultation info ---- ${consultation.toString()}');
      if (consultation == null) {
        throw Exception("Consultation introuvable");
      }

      final consultationId =
          consultation['id'] ?? consultation['consultationId'];
      final String mode = consultation['type']; // "chat", "video", "audio"

      print("🔁 Mode consultation détecté : $mode");

      if (mode == 'chat') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              peerId: peerId,
              peerName: peerName,
              appointmentId: appointmentId,
              consultationId: consultationId,
              roomId: 'room-$consultationId',
            ),
          ),
        );
      } else if (mode == 'video') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoCallScreen(
              roomId: 'room-$consultationId',
              peerName: peerName,
              appointmentId: appointmentId,
              consultationId: consultationId,
              isCaller: false,
            ),
          ),
        );
      } else {
        _showDialog(context, 'Audio non supporté pour le moment.');
      }
    } catch (e) {
      print("❌ Erreur redirection psy: $e");
      _showDialog(context, "Impossible de rejoindre la consultation.");
    }
  }

  void _showDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Rejoindre une consultation'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Vous allez rejoindre une consultation avec $peerName."),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => _joinConsultation(context),
                icon: const Icon(Icons.login),
                label: const Text("Rejoindre"),
              ),
            ],
          ),
        ),
      );
}
