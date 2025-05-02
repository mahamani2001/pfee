import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';

import 'package:mypsy_app/resources/services/question_model.dart';
import 'package:mypsy_app/resources/services/quiz_service.dart';
import 'package:mypsy_app/screens/anxiety_quiz/result_screnn.dart';

class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key});

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  int currentQuestion = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 🔢 Convertir les réponses en score
  int getScore(String answer) {
    switch (answer) {
      case "Jamais":
        return 0;
      case "Parfois":
        return 1;
      case "Souvent":
        return 2;
      case "Toujours":
        return 3;
      default:
        return 0;
    }
  }

  // 🔎 Déterminer le niveau d’anxiété
  String getAnxietyLevel(int totalScore) {
    if (totalScore <= 5) return "Anxiété minimale";
    if (totalScore <= 10) return "Légère";
    if (totalScore <= 15) return "Modérée";
    return "Sévère";
  }

  void submitQuiz() async {
    int total = 0;
    for (var q in questions) {
      total += getScore(q.userAnswered);
    }

    final category = getAnxietyLevel(total);
    final scorePercent = (total / (questions.length * 3)) * 100;

    final userId = await AuthService().getUserId();
    final token =
        await AuthService().getToken(); // 👈 celui que tu stockes avec OTP

    if (userId == null || token == null) {
      print("❌ Impossible de récupérer l’utilisateur ou le token");
      return;
    }

    await QuizService().submitResult(
      userId: userId,
      score: scorePercent,
      anxietyLevel: category,
      token: token,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(score: scorePercent, category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quiz d’anxiété")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("Question ${currentQuestion + 1} / ${questions.length}",
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: questions.length,
                onPageChanged: (index) {
                  setState(() {
                    currentQuestion = index;
                  });
                },
                itemBuilder: (context, index) {
                  final question = questions[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.question,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 30),
                      ...question.options.map((option) {
                        return RadioListTile<String>(
                          title: Text(option),
                          value: option,
                          groupValue: question.userAnswered,
                          onChanged: (value) {
                            setState(() {
                              question.userAnswered = value!;
                            });
                          },
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (currentQuestion < questions.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  submitQuiz();
                }
              },
              child: Text(currentQuestion < questions.length - 1
                  ? "Suivant"
                  : "Terminer"),
            ),
          ],
        ),
      ),
    );
  }
}
