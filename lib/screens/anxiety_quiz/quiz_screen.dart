import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/resources/services/question_model.dart';
import 'package:mypsy_app/resources/services/quiz_service.dart';
import 'package:mypsy_app/resources/services/anxiety_model.dart';
import 'package:mypsy_app/screens/anxiety_quiz/result_screnn.dart';

class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key});

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  int currentQuestion = 0;
  final PageController _pageController = PageController();

  late AnxietyModel _anxietyModel;
  bool _modelReady = false;

  @override
  void initState() {
    super.initState();
    _anxietyModel = AnxietyModel();
    _anxietyModel.loadModel().then((_) {
      setState(() {
        _modelReady = true;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void submitQuiz() async {
    if (!_modelReady) {
      print("❌ Le modèle n’est pas prêt !");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Modèle non prêt, réessayez plus tard.")),
      );
      return;
    }

    // 🔢 Convertir réponses utilisateur en liste de double
    List<double> inputs = questions.map((q) {
      switch (q.userAnswered) {
        case "Jamais":
          return 0.0;
        case "Parfois":
          return 1.0;
        case "Souvent":
          return 2.0;
        case "Toujours":
          return 3.0;
        default:
          return 0.0;
      }
    }).toList();

    // 🔮 Prédiction avec le modèle TFLite
    int predictionIndex = await _anxietyModel.predict(inputs);
    List<String> labels = ["Anxiété minimale", "Légère", "Modérée", "Sévère"];
    final predictedLevel = labels[predictionIndex];

    final total = inputs.reduce((a, b) => a + b);
    final scorePercent = (total / (questions.length * 3)) * 100;

    final userId = await AuthService().getUserId();
    final token = await AuthService().getToken();

    if (userId == null || token == null) {
      print("❌ Impossible de récupérer l’utilisateur ou le token");
      return;
    }

    await QuizService().submitResult(
      userId: userId,
      score: scorePercent,
      anxietyLevel: predictedLevel,
      token: token,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ResultPage(score: scorePercent, category: predictedLevel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Quiz d’anxiété")),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                "Question ${currentQuestion + 1} / ${questions.length}",
                style: const TextStyle(fontSize: 18),
              ),
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
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
                child: Text(
                  currentQuestion < questions.length - 1
                      ? "Suivant"
                      : "Terminer",
                ),
              ),
            ],
          ),
        ),
      );
}
