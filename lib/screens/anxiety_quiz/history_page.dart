import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mypsy_app/resources/services/quiz_service.dart';
import 'package:mypsy_app/screens/layouts/top_bar_subpage.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    try {
      final result = await QuizService().getHistory();
      setState(() {
        history = result;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur historique : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Erreur lors de la récupération de l’historique : $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDate(dynamic date) {
    DateTime dateTime;
    if (date is String) {
      dateTime = DateTime.parse(date); // Convertir la chaîne en DateTime
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return 'Date inconnue';
    }
    return DateFormat('dd/MM/yyyy – HH:mm').format(dateTime);
  }

  Color getCardColor(String level) {
    switch (level) {
      case "Anxiété minimale":
        return const Color.fromARGB(255, 125, 213, 150); // Vert pastel
      case "Légère":
        return const Color.fromARGB(255, 234, 232, 113); // Jaune doux
      case "Modérée":
        return const Color.fromARGB(255, 248, 143, 31); // Orange doux
      case "Sévère":
        return const Color.fromARGB(255, 216, 20, 20); // Rouge doux
      default:
        return Colors.grey.shade200;
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
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: const TopBarSubPage(
          title: 'Historique de mes résultats',
          goHome: true,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : history.isEmpty
                ? const Center(child: Text("Aucun historique disponible."))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final h = history[index];
                      final bgColor =
                          getCardColor(h['category']).withOpacity(0.4);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: bgColor,
                          /*borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(40),
                          ),*/
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${getEmoji(h['category'])}  ${h['category']}",
                                style: AppThemes.getTextStyle(
                                  size: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Score : ${(h['score'] as num).toDouble().toStringAsFixed(1)}%", // Conversion en double
                                style: AppThemes.getTextStyle(
                                  size: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "Date : ${formatDate(h['date'])}",
                                style: AppThemes.getTextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      );
}
