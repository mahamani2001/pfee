import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/resources/services/question_model.dart';
import 'package:mypsy_app/resources/services/quiz_service.dart';
import 'package:mypsy_app/resources/services/anxiety_model.dart';
import 'package:mypsy_app/screens/anxiety_quiz/result_screnn.dart';
import 'package:mypsy_app/screens/layouts/top_bar_subpage.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/buttons/button.dart';
import 'package:mypsy_app/shared/ui/commun_widget.dart';
import 'package:mypsy_app/shared/ui/flushbar.dart';

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
  int selectedOption = -1;

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
      print('userAnswered ${q.userAnswered}');
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

    int predictionIndex = await _anxietyModel.predict(inputs);
    List<String> labels = ["Anxiété minimale", "Légère", "Modérée", "Sévère"];
    final predictedLevel = labels[predictionIndex];

    final total = inputs.reduce((a, b) => a + b);
    final scorePercent = (total / (questions.length * 3)) * 100;

    final userId = await AuthService().getUserId();
    final token = await AuthService().getToken();

    if (userId == null || token == null) {
      print("❌ Impossible de récupérer l’utilisateur ou le token");
      customFlushbar(
          '', 'Impossible de récupérer l’utilisateur ou le token', context,
          isError: true);
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
        backgroundColor: AppColors.mypsyBgApp,
        appBar: const TopBarSubPage(
          title: 'Quiz d’anxiété',
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Question',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Text('${currentQuestion + 1} ',
                            style: AppThemes.getTextStyle(
                                fontWeight: FontWeight.bold,
                                size: 17,
                                clr: AppColors.mypsyPrimary)),
                        Text('/${questions.length}',
                            style: AppThemes.getTextStyle(
                                fontWeight: FontWeight.bold, size: 15)),
                      ],
                    ),
                  ],
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
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: mainDecorationBorder,
                            child: Text(question.question,
                                style: AppThemes.getTextStyle(
                                    clr: AppColors.mypsyWhite,
                                    fontWeight: FontWeight.bold,
                                    size: 16)),
                          ),
                          const SizedBox(height: 15),
                          Expanded(
                            child: ListView.builder(
                              itemCount: question.options.length,
                              itemBuilder: (context, index) => GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedOption = index;
                                    question.userAnswered =
                                        question.options[index];
                                  });
                                },
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: selectedOption == index
                                        ? AppColors.mypsyPrimary
                                            .withOpacity(0.2)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selectedOption == index
                                          ? AppColors.mypsyPrimary
                                              .withOpacity(0.4)
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    question.options[index],
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          /*  ...question.options.map((option) {
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
                          }).toList(),*/
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: mypsyButton(
                    onPress: () {
                      selectedOption = -1;
                      if (currentQuestion < questions.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        submitQuiz();
                      }
                    },
                    text: currentQuestion < questions.length - 1
                        ? "Suivant"
                        : "Terminer",
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
