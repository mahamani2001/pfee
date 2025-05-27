import 'package:flutter/material.dart';
import 'package:mypsy_app/screens/anxiety_quiz/quiz_screen.dart';
import 'package:mypsy_app/screens/anxiety_quiz/history_page.dart';
import 'package:mypsy_app/screens/layouts/top_bar_subpage.dart';
import 'package:mypsy_app/shared/routes.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/buttons/button.dart';

class ResultPage extends StatelessWidget {
  final double score;
  final String category;

  const ResultPage({
    super.key,
    required this.score,
    required this.category,
  });

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

  Color getBackgroundColor(String category) {
    switch (category) {
      case "Anxiété minimale":
        return const Color.fromARGB(255, 255, 255, 255);
      case "Légère":
        return const Color.fromARGB(255, 255, 255, 255);
      case "Modérée":
        return const Color.fromARGB(255, 255, 255, 255);
      case "Sévère":
        return const Color.fromARGB(255, 255, 255, 255);
      default:
        return Colors.grey.shade100;
    }
  }

  String getMotivationalText(String category) {
    switch (category) {
      case "Anxiété minimale":
        return "Continue à prendre soin de toi 🌿";
      case "Légère":
        return "Respire profondément, tu vas dans la bonne direction 🌤️";
      case "Modérée":
        return "Tu n’es pas seul·e. Parler aide beaucoup 🤝";
      case "Sévère":
        return "Courage, chaque petit pas compte ❤️‍🩹";
      default:
        return "Prends soin de toi 🧘‍♀️";
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final scoreText = "${score.toStringAsFixed(1)}%";
    final emoji = getEmoji(category);
    final shouldConsult = category == "Modérée" || category == "Sévère";
    final bgColor = getBackgroundColor(category);

    return Scaffold(
        backgroundColor: AppColors.mypsyBgApp,
        appBar: const TopBarSubPage(
          title: 'Résultat du quiz',
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "$emoji $category",
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Score global : ",
                              style: AppThemes.getTextStyle(
                                  size: 15, fontWeight: FontWeight.w500)),
                          Text(scoreText,
                              style: AppThemes.getTextStyle(
                                  size: 15,
                                  fontWeight: FontWeight.w700,
                                  clr: AppColors.mypsyDarkBlue)),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 8),
                        child: Text(
                          getMotivationalText(category),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: getCategoryColor(category),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: score / 100,
                        backgroundColor: Colors.grey.shade300,
                        color: getCategoryColor(category),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 80),
                      Text(
                        "🙏 Merci d’avoir complété le quiz.\nCe résultat est indicatif et ne remplace pas un avis médical.",
                        textAlign: TextAlign.center,
                        style: AppThemes.getTextStyle(
                            size: 15, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    mypsyButton(
                      isFull: true,
                      onPress: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HistoryPage()),
                        );
                      },
                      bgColors: AppColors.mypsyPurple,
                      text: "Voir l’historique",
                    ),
                    const SizedBox(height: 12),
                    mypsyButton(
                      isFull: true,
                      onPress: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const QuestionPage()),
                        );
                      },
                      bgColors: AppColors.mypsyDarkBlue,
                      text: "Reprendre le quiz",
                    ),
                    if (shouldConsult) ...[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, Routes.doctorliste);
                        },
                        icon: const Icon(Icons.handshake),
                        label: const Text("Un coup de pouce professionnel"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink.shade50,
                          foregroundColor: Colors.pink.shade800,
                          minimumSize: const Size.fromHeight(48),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ));
  }
}
