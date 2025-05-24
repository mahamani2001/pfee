class QuestionModel {
  final String question;
  List<String> options;
  String userAnswered;

  QuestionModel({
    required this.question,
    required this.options,
    this.userAnswered = "",
  });
}

List<QuestionModel> questions = [
  QuestionModel(
    question:
        "Vous êtes-vous senti(e) nerveux(se), anxieux(se) ou sur les nerfs ?",
    options: ["Jamais", "Parfois", "Souvent", "Toujours"],
  ),
  QuestionModel(
    question:
        "Avez-vous eu du mal à contrôler vos inquiétudes ou à les arrêter ?",
    options: ["Jamais", "Parfois", "Souvent", "Toujours"],
  ),
  QuestionModel(
    question:
        "Vous êtes-vous inquiété(e) excessivement à propos de différentes choses ?",
    options: ["Jamais", "Parfois", "Souvent", "Toujours"],
  ),
  QuestionModel(
    question: "Avez-vous eu du mal à vous détendre ?",
    options: ["Jamais", "Parfois", "Souvent", "Toujours"],
  ),
  QuestionModel(
    question:
        "Vous êtes-vous senti(e) tellement agité(e) que rester assis(e) tranquillement était difficile ?",
    options: ["Jamais", "Parfois", "Souvent", "Toujours"],
  ),
  QuestionModel(
    question: "Vous êtes-vous senti(e) facilement agacé(e) ou irrité(e) ?",
    options: ["Jamais", "Parfois", "Souvent", "Toujours"],
  ),
  QuestionModel(
    question:
        "Avez-vous eu peur que quelque chose de terrible puisse arriver ?",
    options: ["Jamais", "Parfois", "Souvent", "Toujours"],
  ),
];
