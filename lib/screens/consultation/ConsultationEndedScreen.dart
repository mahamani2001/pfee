import 'package:flutter/material.dart';
import 'package:mypsy_app/helpers/app_config.dart';
import 'package:mypsy_app/resources/services/RatingService.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:smooth_star_rating_null_safety/smooth_star_rating_null_safety.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ConsultationEndedScreen extends StatefulWidget {
  final String peerName;
  final int psychiatristId;
  final int consultationId;
  final DateTime startTime;
  final Duration duration;

  const ConsultationEndedScreen({
    super.key,
    required this.peerName,
    required this.psychiatristId,
    required this.consultationId,
    required this.startTime,
    required this.duration,
  });

  @override
  State<ConsultationEndedScreen> createState() =>
      _ConsultationEndedScreenState();
}

class _ConsultationEndedScreenState extends State<ConsultationEndedScreen> {
  double _rating = 4.0;
  bool _loading = false;
  bool isPsychiatrist = false;
  String baseUrl = AppConfig.instance()!.baseUrl!;

  @override
  void initState() {
    super.initState();
    _checkUserRole(); // ✅ vérifie le rôle à l'ouverture de l'écran
  }

  void _checkUserRole() async {
    final role = await AuthService().getUserRole();
    setState(() {
      isPsychiatrist = role == 'psychiatrist';
    });
  }

  Future<void> _submitRating() async {
    setState(() => _loading = true);
    final token = await AuthService().getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/appointments/ratings'), // Adjusted URL
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'psychiatristId': widget.psychiatristId,
        'appointmentId': widget.consultationId, // Use appointmentId for rating
        'rating': _rating,
      }),
    );
    setState(() => _loading = false);

    if (response.statusCode == 200) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Merci pour votre note 🌟")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : ${response.body}")),
      );
    }
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Notez votre consultation"),
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
              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        setState(() => _loading = true);
                        setStateDialog(() {}); // mettre à jour le dialog

                        try {
                          await RatingService().submitRating(
                            psychiatristId: widget.psychiatristId,
                            consultationId: widget.consultationId,
                            rating: _rating,
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
                      child: const Text("Envoyer"),
                    ),
            ],
          ),
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
      appBar: AppBar(
        title: const Text('Consultation Terminée'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.green, size: 100),
            const SizedBox(height: 20),
            Text("Merci 🙏", style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 10),
            Text("Votre consultation avec ${widget.peerName} est terminée.",
                textAlign: TextAlign.center),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("👤 Psychiatre : ${widget.peerName}"),
                  const SizedBox(height: 8),
                  Text("🕒 Heure : $formattedStart - $formattedEnd"),
                  const SizedBox(height: 8),
                  Text("⏳ Durée : ${widget.duration.inMinutes} minutes"),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (route) => false);
              },
              icon: const Icon(Icons.home),
              label: const Text("Retour à l'accueil"),
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
                label: const Text("Noter la consultation"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
