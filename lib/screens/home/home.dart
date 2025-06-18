import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/NotificationService.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/resources/services/quiz_service.dart';
import 'package:mypsy_app/resources/services/appointment_service.dart';
import 'package:mypsy_app/screens/layouts/main_screen.dart';
import 'package:mypsy_app/shared/routes.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:intl/intl.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  String userName = '';
  int quizCount = 0;
  String anxietyLevel = '';
  double? anxietyScore;
  Map<String, dynamic>? upcomingAppointmentData;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _loadUserData();
    _startPolling();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final name = await AuthService().getUserFullName();
    final history = await QuizService().getHistory();
    final appointments =
        await AppointmentService().getAppointmentsByStatus('confirmed');

    final now = DateTime.now();
    final futureAppointments = appointments.where((appt) {
      final apptDate = DateTime.parse(appt['date']);
      return apptDate.isAfter(now);
    }).toList();

    final nextAppointment =
        futureAppointments.isNotEmpty ? futureAppointments.first : null;

    if (!mounted) return;

    setState(() {
      userName = name ?? '👤';
      quizCount = history.length;
      if (history.isNotEmpty) {
        anxietyLevel = history.last['category'];
        anxietyScore = history.last['score'];
      } else {
        anxietyLevel = 'Aucun';
        anxietyScore = null;
      }
      upcomingAppointmentData = nextAppointment;
      _isLoading = false;
    });
  }

  void _startPolling() {
    Future.delayed(const Duration(seconds: 30), () async {
      await _loadUserData();
      if (mounted) _startPolling();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF5F8FF),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        padding: const EdgeInsets.only(top: 50),
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: AppColors.mypsyPrimary,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(40),
                            bottomRight: Radius.circular(40),
                          ),
                        ),
                        child: topHeader(),
                      ),
                      const SizedBox(height: 44),
                      Transform.translate(
                        offset: const Offset(0, -70),
                        child: Column(
                          children: [
                            blocQuiz(),
                            const SizedBox(height: 15),
                            upcomingApointment(),
                            const SizedBox(height: 15),
                            menuCards(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      );

  Widget topHeader() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Bonjour,",
                      style: AppThemes.getTextStyle(
                          size: 18,
                          fontWeight: FontWeight.w500,
                          clr: AppColors.mypsyWhite)),
                  const SizedBox(height: 4),
                  Text(userName,
                      style: AppThemes.getTextStyle(
                          clr: AppColors.mypsyWhite,
                          size: 25,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text("Comment vous sentez-vous aujourd'hui ?",
                      style: AppThemes.getTextStyle(
                          size: 16,
                          clr: AppColors.mypsyWhite,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            notificationUI(),
          ],
        ),
      );

  Widget notificationUI() => FutureBuilder<int>(
        future: NotificationService().getUnreadCountFromApi(), // ✅ fixed!
        builder: (context, snapshot) {
          final unreadCount = snapshot.data ?? 0;

          return GestureDetector(
            onTap: () async {
              await Navigator.pushNamed(context, Routes.notificationsScreen);
              setState(() {}); // refresh on return
            },
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topRight,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 30,
                  color: unreadCount > 0 ? Colors.red : Colors.white,
                ),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          );
        },
      );

  Widget menuCards() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          children: [
            Expanded(
              child: AnimatedScaleButton(
                child: blocInfo("Mes rendez-vous", Icons.calendar_today),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MainScreen(initialTabIndex: 1),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedScaleButton(
                child: blocInfo("Trouver un psychiatre", Icons.psychology),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MainScreen(initialTabIndex: 3),
                    ),
                  );
                },
              ),
            ),
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
            Text(
              title,
              style: AppThemes.getTextStyle(
                size: 13,
                fontWeight: FontWeight.bold,
                clr: AppColors.mypsyDarkBlue,
              ),
            ),
          ],
        ),
      );

  Widget upcomingApointment() => AnimatedOpacity(
        opacity: upcomingAppointmentData != null ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 500),
        child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.mypsyDarkBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: upcomingAppointmentData != null
              ? Row(
                  children: [
                    const CircleAvatar(
                      backgroundImage: AssetImage("assets/images/psy.jpg"),
                      radius: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            upcomingAppointmentData!['psychiatristName'] ??
                                "Dr. Slimen",
                            style: AppThemes.getTextStyle(
                              size: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Consultation psychiatrique",
                            style: AppThemes.getTextStyle(
                              size: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: AppColors.mypsyPrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('dd/MM/yyyy').format(
                                  DateTime.parse(
                                      upcomingAppointmentData!['date']),
                                ),
                                style: AppThemes.getTextStyle(
                                  size: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: Text(
                    "Aucun rendez-vous à venir",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
        ),
      );

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
                Text(
                  "Quiz d’anxiété",
                  style: AppThemes.getTextStyle(
                      size: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text("Score récent: ", style: AppThemes.getTextStyle(size: 13)),
                Text(
                  anxietyLevel == 'Aucun'
                      ? "Aucun test effectué"
                      : "$anxietyLevel${anxietyScore != null ? ' (${anxietyScore!.toStringAsFixed(0)}%)' : ''}",
                  style: AppThemes.getTextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedScaleButton(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MainScreen(initialTabIndex: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mypsyDarkBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                ),
                child: Text(
                  "Commencer le test",
                  style: AppThemes.getTextStyle(
                    size: 14,
                    fontWeight: FontWeight.w600,
                    clr: AppColors.mypsyBgApp,
                  ),
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MainScreen(initialTabIndex: 2),
                  ),
                );
              },
            ),
          ],
        ),
      );
}

// Animation bouton "clic"
class AnimatedScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const AnimatedScaleButton(
      {required this.child, required this.onTap, super.key});

  @override
  _AnimatedScaleButtonState createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<AnimatedScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      );
}
