/* import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/appointment_service.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/resources/services/consultation_service.dart';
import 'package:mypsy_app/resources/services/socket_service.dart';
import 'package:mypsy_app/screens/consultation/chatconsultation.dart';
import 'package:mypsy_app/screens/consultation/video_call_screen.dart';

class ModeSelectionScreen extends StatefulWidget {
  final String peerId;
  final String peerName;
  final int appointmentId;

  const ModeSelectionScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    required this.appointmentId,
  });

  @override
  _ModeSelectionScreenState createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  bool _isLoading = true;
  bool _canJoin = false;
  bool _isProcessing = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkConsultationStatus();
    _initializeSocket();
  }

  void handleIncomingMessage(Map<String, dynamic> message) {
    print("📥 Message reçu dans ModeSelectionScreen : $message");
  }

  void _initializeSocket() async {
    if (!SocketService().isConnected) {
      await SocketService()
          .connectSocket(onMessageCallback: handleIncomingMessage);
      // await SocketService().waitForConnection();

      if (!SocketService().isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Connexion au serveur échouée")),
        );
        return;
      }
    }

    SocketService().joinRoom('appointment_${widget.appointmentId}');

    SocketService().on('redirect', (data) async {
      final mode = data['mode'] as String;
      final action = data['action'] as String?;
      final fullName = data['fullName'] ?? 'Patient';

      if (_userRole == 'psychiatrist' && action != null) {
        SocketService().emit('join_consultation', {
          'appointmentId': widget.appointmentId,
          'mode': mode,
        });

        _handleNotificationAction(action);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$fullName a lancé une consultation ($mode)')),
        );
      }
    });
  }

  void _handleNotificationAction(String action) async {
    final uri = Uri.parse(action);
    final mode = uri.queryParameters['mode'];
    final consultationId =
        int.tryParse(uri.queryParameters['consultationId'] ?? '');

    if (mode != null && consultationId != null) {
      _redirectToMode(mode, consultationId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Données de redirection manquantes")),
      );
    }
  }

  void _redirectToMode(String mode, int consultationId) {
    final roomId =
        'consultation_$consultationId'; // Utiliser la room basée sur consultationId

    if (mode == 'chat') {
      final page = ChatScreen(
        peerId: widget.peerId,
        peerName: widget.peerName,
        appointmentId: widget.appointmentId,
        roomId: roomId,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    } else {
      _showComingSoon();
    }
  }

  void _showComingSoon() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Fonctionnalité en cours'),
        content: const Text('Cette fonctionnalité sera bientôt disponible !'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkConsultationStatus() async {
    try {
      final appointment =
          await AppointmentService().getAppointmentById(widget.appointmentId);
      final userRole = await AuthService().getUserRole();
      final now = DateTime.now();

      final appointmentTime = DateTime.parse(
          '${appointment!['date']} ${appointment['start_time'] ?? '00:00:00'}');
      final isPatient = userRole == 'patient';
      final isTimeValid = appointment['status'] == 'confirmed' &&
          now.isAfter(appointmentTime.subtract(const Duration(minutes: 15)));

      setState(() {
        _userRole = userRole;
        _canJoin = isPatient || isTimeValid;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur _checkConsultationStatus: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur: $e")));
    }
  }

  void _selectMode(String mode) async {
    if (!_canJoin || _isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final patientName = await AuthService().getUserFullName();
      final consultation = await ConsultationService().startConsultation(
        appointmentId: widget.appointmentId,
        type: mode,
      );
      print('🔍 Consultation response: $consultation');
      final consultationId = consultation?['consultationId'];
      if (consultationId == null) throw Exception('Consultation invalide');

      final actionUrl = '/join?consultationId=$consultationId&mode=$mode';

      SocketService().emit('redirect', {
        'appointmentId': widget.appointmentId,
        'mode': mode,
        'fullName': patientName,
        'action': actionUrl,
      });

      _redirectToMode(mode, consultationId);
    } catch (e) {
      print('❌ Erreur _selectMode: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de consultation')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required String mode,
    Color color = Colors.blue,
  }) {
    final enabled = _canJoin && !_isProcessing && _userRole == 'patient';

    return ElevatedButton.icon(
      onPressed: enabled ? () => _selectMode(mode) : null,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : Colors.grey,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choisir un mode de consultation"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Sélectionnez un mode pour la consultation avec ${widget.peerName}",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 40),
                  _buildButton(
                    label: "Chat sécurisé",
                    icon: Icons.chat_bubble_outline,
                    mode: "chat",
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 20),
                  _buildButton(
                    label: "Appel vidéo",
                    icon: Icons.videocam_outlined,
                    mode: "video",
                    color: Colors.purple,
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    SocketService().disconnect();
    super.dispose();
  }
}
 */
