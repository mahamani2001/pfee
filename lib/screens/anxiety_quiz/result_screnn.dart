import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final double score; // en pourcentage (0 - 100)
  final String category; // Exemple : "Modérée", "Sévère", etc.

  const ResultPage({
    Key? key,
    required this.score,
    required this.category,
  }) : super(key: key);

  Color getColor(String category) {
    switch (category) {
      case "Anxiété minimale":
        return Colors.green;
      case "Légère":
        return Colors.orange;
      case "Modérée":
        return Colors.deepOrange;
      case "Sévère":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = getColor(category);

    return Scaffold(
      appBar: AppBar(title: const Text("Résultat du quiz")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            Text(
              "Votre niveau d’anxiété",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              category,
              style: TextStyle(fontSize: 22, color: color),
            ),
            const SizedBox(height: 30),
            Text(
              "Score global : ${score.toStringAsFixed(1)}%",
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: score / 100,
              minHeight: 14,
              color: color,
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(height: 40),
            Text(
              "Merci d’avoir complété le quiz.\nCe résultat est à titre indicatif.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Revenir au quiz
              },
              icon: const Icon(Icons.replay),
              label: const Text("Reprendre le quiz"),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
