import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/socket_service.dart';
import 'package:mypsy_app/screens/consultation/chatconsultation.dart';

class ConsultationLauncherScreen extends StatelessWidget {
  final String peerId;
  final String peerName;
  final int appointmentId;
  final String mode;

  const ConsultationLauncherScreen(
      {super.key,
      required this.peerId,
      required this.peerName,
      required this.appointmentId,
      required this.mode});

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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Salon de consultation"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        backgroundColor: Colors.grey[100],
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Bienvenue dans votre consultation avec",
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(
                peerName,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              const SizedBox(height: 40),
              // 🟢 Chat sécurisé
              ElevatedButton.icon(
                onPressed: () async {
                  SocketService().emit('join_consultation', {
                    'appointmentId': appointmentId,
                    'mode': mode, // 🔥 Utilise le mode passé
                  });

                  if (mode == 'chat') {
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
                  } else {
                    _showComingSoon(
                        context); // 🔥 Pour audio/video on montre "bientôt disponible"
                  }
                },
                icon:
                    const Icon(Icons.chat_bubble_outline, color: Colors.white),
                label: const Text('Chat sécurisé',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 🟡 Appel audio
              ElevatedButton.icon(
                onPressed: () {
                  _showComingSoon(context);
                },
                icon: const Icon(Icons.call_outlined, color: Colors.white),
                label: const Text('Appel audio',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 🟣 Appel vidéo
              ElevatedButton.icon(
                onPressed: () {
                  _showComingSoon(context);
                },
                icon: const Icon(Icons.videocam_outlined, color: Colors.white),
                label: const Text('Appel vidéo',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
