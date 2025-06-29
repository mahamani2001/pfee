import 'package:flutter/material.dart';
import 'package:mypsy_app/helpers/app_config.dart';
import 'package:mypsy_app/resources/services/RatingService.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/screens/layouts/main_screen.dart';
import 'package:mypsy_app/screens/layouts/main_screen_psy.dart';
import 'package:mypsy_app/screens/layouts/top_bar_subpage.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/buttons/button.dart';
import 'package:smooth_star_rating_null_safety/smooth_star_rating_null_safety.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ConsultationEndedScreen extends StatefulWidget {
  final String peerName;
  final int psychiatristId;
  final int appointmentId;
  final DateTime startTime;
  final Duration duration;
  final int? patientId;
  final int consultationId;

  const ConsultationEndedScreen({
    super.key,
    required this.peerName,
    required this.psychiatristId,
    required this.appointmentId,
    required this.consultationId,
    required this.startTime,
    required this.duration,
    this.patientId,
  });

  @override
  State<ConsultationEndedScreen> createState() =>
      _ConsultationEndedScreenState();
}

final TextEditingController _feedbackController = TextEditingController();

class _ConsultationEndedScreenState extends State<ConsultationEndedScreen> {
  double _rating = 4.0;
  bool _loading = false;
  bool isPsychiatrist = false;
  String baseUrl = AppConfig.instance()!.baseUrl!;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    print("🧾 patientId reçu : ${widget.patientId}");
  }

  void _checkUserRole() async {
    final role = await AuthService().getUserRole();
    setState(() {
      isPsychiatrist = role == 'psychiatrist';
    });
  }

  void _showRatingDialog() {
    final TextEditingController _commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "Notez votre consultation",
          style: AppThemes.getTextStyle(),
          textAlign: TextAlign.center,
        ),
        content: StatefulBuilder(
          builder: (context, setStateDialog) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SmoothStarRating(
                rating: _rating,
                size: 40,
                filledIconData: Icons.star,
                halfFilledIconData: Icons.star_half,
                defaultIconData: Icons.star_border,
                starCount: 5,
                allowHalfRating: true,
                onRatingChanged: (val) {
                  setState(() => _rating = val);
                  setStateDialog(() {}); // pour mettre à jour l’UI du dialog
                },
              ),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Commentaire (facultatif)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : mypsyButton(
                      onPress: () async {
                        setState(() => _loading = true);
                        setStateDialog(() {}); // mettre à jour le dialog

                        try {
                          await RatingService().submitRating(
                            psychiatristId: widget.psychiatristId,
                            appointmentId: widget.appointmentId,
                            rating: _rating,
                            comment: _commentController.text.trim(),
                          );
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Merci pour votre note 🌟"),
                            ),
                          );
                        } catch (e) {
                          setState(() => _loading = false);
                          setStateDialog(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Erreur : $e")),
                          );
                        }
                      },
                      text: "Envoyer",
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("📝 Note sur le patient"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: "Rédigez une note confidentielle...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final note = _feedbackController.text.trim();

                try {
                  await RatingService().addOrUpdateNote(
                    appointmentId: widget.appointmentId,
                    note: note,
                  );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Note enregistrée")),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("❌ Erreur : $e")),
                  );
                }
              },
              icon: const Icon(Icons.send),
              label: const Text("Enregistrer"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final endTime = widget.startTime.add(widget.duration);
    final formattedStart =
        "${widget.startTime.hour.toString().padLeft(2, '0')}:${widget.startTime.minute.toString().padLeft(2, '0')}";
    final formattedEnd =
        "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: const TopBarSubPage(title: "Consultation Terminée"),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(
              height: 50,
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.1),
              ),
              child: const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.green,
                child: Icon(Icons.check, size: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 50),
            Text("Merci 🙏", style: AppThemes.getTextStyle(size: 16)),
            const SizedBox(height: 10),
            consultationInfo(),
            const SizedBox(height: 50),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  rowInfo("👤 Psychiatre :", widget.peerName),
                  const SizedBox(height: 8),
                  rowInfo("🕒 Heure : ", "$formattedStart - $formattedEnd"),
                  const SizedBox(height: 8),
                  rowInfo("⏳ Durée :", "${widget.duration.inMinutes} minutes"),
                ],
              ),
            ),
            if (isPsychiatrist)
              ElevatedButton.icon(
                onPressed: _showFeedbackDialog,
                icon: const Icon(Icons.edit_note),
                label: const Text("Ajouter une note confidentielle"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  minimumSize: const Size.fromHeight(45),
                ),
              ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                if (isPsychiatrist) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MainScreen(initialTabIndex: 0),
                    ),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MainScreenPsy(initialTabIndex: 0),
                    ),
                  );
                }
              },
              icon: const Icon(
                Icons.home,
                color: AppColors.mypsyWhite,
              ),
              label: Text(
                "Retour à l'accueil",
                style: AppThemes.getTextStyle(
                    clr: AppColors.mypsyWhite,
                    size: 15,
                    fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 12),
            if (!isPsychiatrist)
              OutlinedButton.icon(
                onPressed: _showRatingDialog,
                icon: const Icon(Icons.star_border),
                label: Text("Noter la consultation",
                    style: AppThemes.getTextStyle()),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget consultationInfo() => Wrap(
        children: [
          Text("Votre consultation avec",
              style: AppThemes.getTextStyle(), textAlign: TextAlign.center),
          Text("  ${widget.peerName}",
              style: AppThemes.getTextStyle(
                  fontWeight: FontWeight.bold, clr: AppColors.mypsyGreen),
              textAlign: TextAlign.center),
          Text(" est terminée.",
              style: AppThemes.getTextStyle(), textAlign: TextAlign.center),
        ],
      );

  Widget rowInfo(String title, String info) => Row(
        children: [
          Text(title, style: AppThemes.getTextStyle(size: 15)),
          const SizedBox(
            width: 5,
          ),
          Text(info,
              style: AppThemes.getTextStyle(fontWeight: FontWeight.bold)),
        ],
      );
}
