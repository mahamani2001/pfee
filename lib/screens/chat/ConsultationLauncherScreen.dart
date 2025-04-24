import 'package:flutter/material.dart';
import 'package:mypsy_app/screens/consultation/chatconsultation.dart';

class ConsultationLauncherScreen extends StatelessWidget {
  final String peerId;
  final String peerName;
  final int appointmentId;

  const ConsultationLauncherScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    required this.appointmentId,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text("Salon de consultation")),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Bienvenue"),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
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
              },
              icon: const Icon(Icons.chat),
              label: const Text("Chat sécurisé"),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Naviguer vers l'appel audio
              },
              icon: const Icon(Icons.call),
              label: const Text("Appel audio"),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // Naviguer vers l'appel vidéo
              },
              icon: const Icon(Icons.videocam),
              label: const Text("Appel vidéo"),
            ),
          ],
        ),
      );
}
