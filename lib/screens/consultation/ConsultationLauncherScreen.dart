import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/resources/services/consultation_service.dart';
import 'package:mypsy_app/resources/services/socket_service.dart';
import 'package:mypsy_app/screens/consultation/chatconsultation.dart';
import 'package:mypsy_app/screens/consultation/video_call_screen.dart';

class ConsultationLauncherScreen extends StatelessWidget {
  final String peerId;
  final String peerName;
  final int appointmentId;
  final String mode; // optionnel côté patient

  const ConsultationLauncherScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    required this.appointmentId,
    this.mode = '', // par défaut vide
  });

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Fonctionnalité en cours'),
        content:
            const Text('Cette fonctionnalité sera bientôt disponible ! 🎯'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePatientMode(
      BuildContext context, String selectedMode) async {
    try {
      final consultation = await ConsultationService().startConsultation(
        appointmentId: appointmentId,
        type: selectedMode,
      );

      if (consultation == null) throw Exception("Consultation non trouvée");

      final consultationId =
          consultation['id'] ?? consultation['consultationId'];

      if (selectedMode == 'chat') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              peerId: peerId,
              peerName: peerName,
              appointmentId: appointmentId,
              consultationId: consultationId,
              roomId: 'room-$appointmentId',
            ),
          ),
        );
      } else if (selectedMode == 'video') {
        final fullName = await AuthService().getUserFullName();
        final userRole = await AuthService().getUserRole();
        final callerName =
            userRole == 'psychiatrist' ? 'Dr. $fullName' : fullName;

        SocketService().emit('incoming_call', {
          'to': peerId,
          'appointmentId': appointmentId,
          'callerName': callerName,
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoCallScreen(
              roomId: 'room-$appointmentId',
              peerName: peerName,
              appointmentId: appointmentId,
              consultationId: consultationId,
              isCaller: true,
            ),
          ),
        );
      } else if (selectedMode == 'audio') {
        _showComingSoon(context); // ou rediriger vers audio plus tard
      }
    } catch (e) {
      print("❌ Erreur lancement $selectedMode: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible de démarrer la consultation")),
      );
    }
  }

  Future<void> _handlePsychiatristJoin(BuildContext context) async {
    try {
      final data = await ConsultationService().joinConsultation(appointmentId);
      if (data == null) throw Exception("Consultation introuvable");

      final consultation = data['consultation'];
      final consultationId = consultation['id'];
      final type = consultation['type'];

      if (type == 'chat') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              peerId: peerId,
              peerName: peerName,
              appointmentId: appointmentId,
              consultationId: consultationId,
              roomId: 'room-$appointmentId',
            ),
          ),
        );
      } else if (type == 'video') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoCallScreen(
              roomId: 'room-$appointmentId',
              peerName: peerName,
              appointmentId: appointmentId,
              consultationId: consultationId,
              isCaller: false,
            ),
          ),
        );
      } else if (type == 'audio') {
        _showComingSoon(context);
      }
    } catch (e) {
      print("❌ Erreur redirection psy: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Impossible de rejoindre la consultation")),
      );
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
        future: AuthService().getUserRole(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final isPsy = snapshot.data == 'psychiatrist';

          return Scaffold(
            appBar: AppBar(
              title: const Text("Consultation"),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Consultation avec",
                      style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Text(peerName,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 40),
                  if (isPsy)
                    ElevatedButton.icon(
                      onPressed: () => _handlePsychiatristJoin(context),
                      icon: const Icon(Icons.login),
                      label: const Text("Rejoindre la consultation"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    )
                  else ...[
                    // Patient voit les 3 boutons
                    ElevatedButton.icon(
                      onPressed: () => _handlePatientMode(context, 'chat'),
                      icon: const Icon(Icons.chat_bubble_outline,
                          color: Colors.white),
                      label: const Text('Chat sécurisé',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _handlePatientMode(context, 'audio'),
                      icon: const Icon(Icons.call, color: Colors.white),
                      label: const Text('Appel audio',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _handlePatientMode(context, 'video'),
                      icon: const Icon(Icons.videocam, color: Colors.white),
                      label: const Text('Appel vidéo',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
}
