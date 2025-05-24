import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/NotificationService.dart';

import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/resources/services/quiz_service.dart';
import 'package:mypsy_app/screens/anxiety_quiz/history_page.dart';
import 'package:mypsy_app/shared/routes.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String userName = '';
  int quizCount = 0;
  String anxietyLevel = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await AuthService().getUserFullName();
    final history = await QuizService().getHistory();
    setState(() {
      userName = name ?? '👤';
      quizCount = history.length;
      if (history.isNotEmpty) {
        anxietyLevel = history.last['category'];
      } else {
        anxietyLevel = 'Aucun';
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF5F9FA),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(),
              const SizedBox(height: 12),
              _buildStats(),
              const SizedBox(height: 20),
              _buildShortcuts(context),
              const SizedBox(height: 20),
              _buildMotivationBanner(),
            ],
          ),
        ),
      );

  Widget _buildAppBar() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Bienvenue $userName 👋",
                  style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const Text("MyPsy App",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ]),
            FutureBuilder<bool>(
              future: NotificationService().hasUnread(),
              builder: (context, snapshot) {
                final hasUnread = snapshot.data == true;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none, size: 30),
                      onPressed: () {
                        Navigator.pushNamed(
                            context, Routes.notificationsScreen);
                      },
                    ),
                    if (hasUnread)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      );

  Widget _buildStats() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _statCard("Quiz effectués", quizCount.toString(), Icons.list_alt),
            const SizedBox(width: 12),
            _statCard("Score anxiété", anxietyLevel, Icons.mood),
          ],
        ),
      );

  Widget _statCard(String label, String value, IconData icon) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 30, color: Colors.teal),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        ),
      );

  Widget _buildShortcuts(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _shortcut(Icons.quiz, "Quiz", () {
              //   Navigator.pushNamed(context, Routes.quizPage);
            }),
            _shortcut(Icons.bar_chart, "Résultats", () {
              //   Navigator.pushNamed(context, Routes.HistoryPage);
            }),
            _shortcut(Icons.chat_bubble_outline, "Consultations", () {
              //  Navigator.pushNamed(context, Routes.activeAppointments);
            }),
          ],
        ),
      );

  Widget _shortcut(IconData icon, String label, VoidCallback onTap) => Column(
        children: [
          InkWell(
            onTap: onTap,
            child: CircleAvatar(
              backgroundColor: Colors.teal.shade50,
              radius: 28,
              child: Icon(icon, color: Colors.teal, size: 28),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      );

  Widget _buildMotivationBanner() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.teal.shade100.withOpacity(0.6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            "🌿 Prenez soin de votre santé mentale.\nUn petit pas aujourd’hui peut devenir un grand changement demain.",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      );
}
