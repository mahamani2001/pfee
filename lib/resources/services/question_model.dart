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
        "Vous êtes-vous senti(e) nerveux(se) ou anxieux(se) sans raison particulière ?",
    options: ["Jamais", "Parfois", "Souvent", "Toujours"],
  ),
  QuestionModel(
    question:
        "Avez-vous eu du mal à contrôler vos inquiétudes ou à les arrêter ?",
    options: ["Jamais", "Parfois", "Souvent", "Toujours"],
  ),
  QuestionModel(
    question: "Avez-vous souvent trop de pensées stressantes ou négatives ?",
    options: ["Jamais", "Parfois", "Souvent", "Toujours"],
  ),
  QuestionModel(
    question: "Vos pensées deviennent-elles parfois catastrophiques ?",
    options: ["Jamais", "Parfois", "Souvent", "Toujours"],
  ),
  QuestionModel(
    question:
        "Avez-vous eu l’impression que quelque chose de grave allait arriver sans explication ?",
    options: ["Jamais", "Parfois", "Souvent", "Toujours"],
  ),
  QuestionModel(
    question:
        "Avez-vous ressenti des tensions musculaires ou des douleurs inexpliquées ?",
    options: ["Jamais", "Parfois", "Souvent", "Toujours"],
  ),
  QuestionModel(
    question: "Votre cœur s’est-il mis à battre rapidement ?",
    options: ["Jamais", "Parfois", "Souvent", "Toujours"],
  ),
];
