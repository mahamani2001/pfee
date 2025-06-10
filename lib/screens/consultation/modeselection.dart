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

  void _initializeSocket() async {
    if (!SocketService().isConnected) {
      await SocketService().connectSocket();
    }

    SocketService().joinRoom('appointment_${widget.appointmentId}');

    SocketService().on('redirect', (data) {
      final mode = data['mode'] as String;
      _redirectToMode(mode);
    });

    SocketService().on('patient_ready', (data) {
      final patientName = data['fullName'] ?? 'Patient';
      final mode = data['mode'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$patientName est prêt en mode $mode')),
      );
      setState(() => _canJoin = true);
    });
  }

  Future<void> _checkConsultationStatus() async {
    try {
      final appointment =
          await AppointmentService().getAppointmentById(widget.appointmentId);
      final userRole = await AuthService().getUserRole();

      print("🔐 Rôle détecté dans _checkConsultationStatus : $userRole");

      // Stocker le rôle pour que les boutons puissent l’utiliser
      setState(() {
        _userRole = userRole;
      });

      final now = DateTime.now();
      final appointmentTime = DateTime.parse(
        '${appointment!['date']} ${appointment['start_time'] ?? '00:00:00'}',
      );

      final isTimeValid =
          appointment['status'] == 'confirmed' && now.isAfter(appointmentTime);

      setState(() {
        _canJoin = true;
        _isLoading = false;
      });

      if (userRole == 'patient') {
        print("🟢 PATIENT autorisé à initier la consultation");
        setState(() {
          _canJoin = true;
          _isLoading = false;
        });
        return;
      }

      // Si c’est le psychiatre, on vérifie que la consultation est active
      final consultation = await ConsultationService()
          .getConsultationByAppointment(appointmentId: widget.appointmentId);

      print("🧠 Consultation existante : $consultation");

      final isActive = consultation != null &&
          consultation['est_active'] == true &&
          DateTime.parse(consultation['date_fin'] ?? '')
              .isAfter(DateTime.now());

      setState(() {
        _canJoin = isActive;
        _isLoading = false;
      });

      if (!isActive) {
        _showWaitingDialog();
      }
    } catch (e) {
      print('❌ Erreur _checkConsultationStatus: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: $e")),
      );
    }
  }

  void _showWaitingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("⏳ En attente..."),
        content: const Text(
            "Le psychiatre n’a pas encore commencé la consultation."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Retour"),
          ),
        ],
      ),
    );
  }

  void _redirectToMode(String mode) {
    if (!mounted) return;

    Widget page;
    if (mode == 'chat') {
      page = ChatScreen(
        peerId: widget.peerId,
        peerName: widget.peerName,
        appointmentId: widget.appointmentId,
      );
    } else if (mode == 'video') {
      page = VideoCallScreen(
        roomId: 'appointment_${widget.appointmentId}',
        peerName: widget.peerName,
        appointmentId: widget.appointmentId,
        isCaller: false,
      );
    } else {
      _showComingSoon();
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
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

  void _selectMode(String mode) async {
    if (!_canJoin || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final userFullName = await AuthService().getUserFullName();

      final consultation = await ConsultationService().startConsultation(
        appointmentId: widget.appointmentId,
        type: mode,
      );

      print("📦 Réponse consultation : $consultation");

      if (consultation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur de démarrage')),
        );
        setState(() => _isProcessing = false);
        return;
      }

      SocketService().emit('redirect', {
        'appointmentId': widget.appointmentId,
        'patientName': userFullName,
        'mode': mode,
      });

      _redirectToMode(mode);
    } catch (e) {
      print('❌ Erreur _selectMode: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de consultation')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildButton(
      {required String label,
      required IconData icon,
      required String mode,
      Color color = Colors.blue}) {
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
                      color: Colors.blueAccent),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.call_outlined, color: Colors.white),
                    label: const Text("Appel audio (bientôt)",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildButton(
                      label: "Appel vidéo",
                      icon: Icons.videocam_outlined,
                      mode: "video",
                      color: Colors.purple),
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
