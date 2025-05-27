import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/NotificationService.dart';

import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/resources/services/quiz_service.dart';
import 'package:mypsy_app/screens/anxiety_quiz/history_page.dart';
import 'package:mypsy_app/shared/routes.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';

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
        appBar: null,
        backgroundColor: const Color(0xFFF5F8FF),
        body: SingleChildScrollView(
          child: Column(
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Positioned(right: 15, top: 50, child: notificationUI()),
                  Container(
                      padding: const EdgeInsets.only(top: 50),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.mypsyPrimary.withOpacity(0.3),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                      child: topHeader()),
                ],
              ),
              const SizedBox(height: 44),

              // Quiz Card
              Transform.translate(
                  offset: const Offset(0, -70),
                  child: Column(
                    children: [
                      blocQuiz(),
                      const SizedBox(height: 15),
                      upcomingApointment(),
                      const SizedBox(height: 15),
                      menuCards()
                    ],
                  )),

              // Bottom buttons
            ],
          ),
        ),
      );

  /*Scaffold(
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
      );*/

  Widget menuCards() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          children: [
            Expanded(
                child: GestureDetector(
                    onTap: () {
                      // Ton action ici
                    },
                    child: blocInfo("Mes rendez-vous", Icons.calendar_today))),
            const SizedBox(width: 12),
            Expanded(
                child: GestureDetector(
                    onTap: () {
                      // Ton action ici
                    },
                    child:
                        blocInfo("Trouver un psychiatre", Icons.psychology))),
          ],
        ),
      );
  Widget blocInfo(String title, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.mypsyDarkBlue, width: 0.3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 29, color: AppColors.mypsyDarkBlue),
            const SizedBox(height: 10),
            Text(title,
                style: AppThemes.getTextStyle(
                    size: 13,
                    fontWeight: FontWeight.bold,
                    clr: AppColors.mypsyDarkBlue)),
          ],
        ),
      );

  Widget upcomingApointment() => Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.mypsyDarkBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundImage: NetworkImage("https://i.pravatar.cc/100?img=12"),
              radius: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Dr. Jennifer Smith",
                      style: AppThemes.getTextStyle(
                          size: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text("Orthopedic Consultation (Foot & Ankle)",
                      style: AppThemes.getTextStyle(
                          size: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.mypsyPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text("Wed, 7 Sep 2024",
                          style: AppThemes.getTextStyle(
                              size: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.mypsyPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text("10:30 - 11:30 AM",
                          style: AppThemes.getTextStyle(
                              size: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget notificationUI() => FutureBuilder<bool>(
        future: NotificationService().hasUnread(),
        builder: (context, snapshot) {
          final hasUnread = snapshot.data == true;
          return Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, size: 30),
                onPressed: () {
                  Navigator.pushNamed(context, Routes.notificationsScreen);
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
      );

  Widget topHeader() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Bonjour,",
                      style: AppThemes.getTextStyle(
                          size: 20, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text("Mainul Islam",
                      style: AppThemes.getTextStyle(
                          size: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text("Comment vous sentez-vous aujourd'hui ?",
                      style: AppThemes.getTextStyle(size: 16)),
                ],
              ),
            ),
            const CircleAvatar(
              radius: 40,
              backgroundImage: const NetworkImage(
                "https://i.pravatar.cc/100?img=8",
              ),
            )
          ],
        ),
      ]));
  Widget blocQuiz() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 32, color: AppColors.mypsyDarkBlue),
                const SizedBox(width: 12),
                Text("Quiz d’anxiété",
                    style: AppThemes.getTextStyle(
                        size: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text("Score récent: ", style: AppThemes.getTextStyle(size: 13)),
                Text("Modéré (65%)",
                    style: AppThemes.getTextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mypsyDarkBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text("Commencer le test",
                    style: AppThemes.getTextStyle(
                        size: 15,
                        fontWeight: FontWeight.w600,
                        clr: AppColors.mypsyBgApp)),
              ),
            ),
          ],
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

class HeaderBackground extends StatelessWidget {
  const HeaderBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        height: 200,
        color: const Color(0xFFF5F8FF),
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);

    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 60);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
