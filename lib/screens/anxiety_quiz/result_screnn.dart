import 'package:flutter/material.dart';
import 'package:mypsy_app/screens/anxiety_quiz/quiz_screen.dart';
import 'package:mypsy_app/screens/anxiety_quiz/history_page.dart'; // ⚠️ à créer

class ResultPage extends StatelessWidget {
  final double score;
  final String category;

  const ResultPage({
    super.key,
    required this.score,
    required this.category,
  });

  Color getCategoryColor(String level) {
    switch (level) {
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

  String getEmoji(String category) {
    switch (category) {
      case "Anxiété minimale":
        return "😊";
      case "Légère":
        return "🙂";
      case "Modérée":
        return "😟";
      case "Sévère":
        return "😰";
      default:
        return "❓";
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreText = "${score.toStringAsFixed(1)}%";
    final color = getCategoryColor(category);
    final emoji = getEmoji(category);
    final bool shouldConsult = category == "Modérée" || category == "Sévère";

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: const Text(" Résultat du quiz"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text("Votre niveau d’anxiété",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              "$emoji $category",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.speed, color: color),
                const SizedBox(width: 8),
                Text("Score global : $scoreText"),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: score / 100,
              color: color,
              backgroundColor: Colors.grey[300],
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 24),
            const Text(
              "🙏 Merci d’avoir complété le quiz.\nCe résultat est indicatif et ne remplace pas un avis médical.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // 🔍 Voir l’historique
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text("Voir l’historique"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const QuestionPage()),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text("Reprendre le quiz"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),

            // ✅ Ajoute la virgule ici
            if (shouldConsult)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/psy-list');
                  },
                  icon: const Icon(Icons.support_agent),
                  label: const Text("Parler à un professionnel"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade800,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),

            // 🔄 Reprendre
          ],
        ),
      ),
    );
  }
}
