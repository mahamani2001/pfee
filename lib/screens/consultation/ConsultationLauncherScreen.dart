import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mypsy_app/helpers/app_config.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/resources/services/consultation_service.dart';
import 'package:mypsy_app/screens/consultation/modeselection.dart';

class ConsultationLauncherScreen extends StatelessWidget {
  final String peerId;
  final String peerName;
  final int appointmentId;
  final int? consultationId;

  const ConsultationLauncherScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    required this.appointmentId,
    this.consultationId,
  });

  Future<bool> _canAccessConsultation() async {
    final token = await AuthService().getToken();
    final url = Uri.parse(
        '${AppConfig.instance()!.baseUrl!}appointments/can-access/$appointmentId');

    final response =
        await http.get(url, headers: {'Authorization': 'Bearer $token'});
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>?> _checkConsultationStatus() async {
    final existing = await ConsultationService()
        .getConsultationByAppointment(appointmentId: appointmentId);

    if (existing != null) {
      final estActive = existing['est_active'] as bool? ?? false;
      final dateFin =
          DateTime.tryParse(existing['date_fin'] ?? '') ?? DateTime.now();
      if (estActive && dateFin.isAfter(DateTime.now())) {
        print(
            "Reusing existing active consultation for appointment $appointmentId");
        return existing;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text("Rejoindre la consultation"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Rejoindre votre consultation avec ${peerName}",
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () async {
                    if (await _canAccessConsultation()) {
                      final consultation = await _checkConsultationStatus();
                      final role = await AuthService().getUserRole();
                      if (consultation != null || role == 'patient') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ModeSelectionScreen(
                              peerId: peerId,
                              peerName: peerName,
                              appointmentId: appointmentId,
                            ),
                          ),
                        );
                      } else {}
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Impossible de rejoindre la consultation')),
                      );
                    }
                  },
                  child: const Text('Rejoindre'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
