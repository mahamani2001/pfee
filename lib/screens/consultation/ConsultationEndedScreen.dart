import 'package:flutter/material.dart';

class ConsultationEndedScreen extends StatelessWidget {
  final String peerName;
  final DateTime startTime;
  final Duration duration;

  const ConsultationEndedScreen({
    super.key,
    required this.peerName,
    required this.startTime,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final endTime = startTime.add(duration);
    final formattedStart = "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}";
    final formattedEnd = "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation Terminée'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 100),
            const SizedBox(height: 20),
            Text(
              "Merci 🙏",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.black),
            ),
            const SizedBox(height: 10),
            Text(
              "Votre consultation avec $peerName est terminée.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("👤 Psychiatre : $peerName"),
                  const SizedBox(height: 8),
                  Text("🕒 Heure : $formattedStart - $formattedEnd"),
                  const SizedBox(height: 8),
                  Text("⏳ Durée : ${duration.inMinutes} minutes"),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              },
              icon: const Icon(Icons.home),
              label: const Text("Retour à l'accueil"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Naviguer vers la page de feedback/évaluation
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fonction noter à implémenter")));
              },
              icon: const Icon(Icons.star_border),
              label: const Text("Noter la consultation"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
