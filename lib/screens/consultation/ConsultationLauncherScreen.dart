import 'package:flutter/material.dart';
import 'package:mypsy_app/helpers/app_config.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/resources/services/signalling.service.dart';
import 'package:mypsy_app/resources/services/socket_service.dart';
import 'package:mypsy_app/screens/consultation/chatconsultation.dart';
import 'package:mypsy_app/screens/layouts/top_bar_subpage.dart';
import 'package:mypsy_app/screens/videos/call_screen.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';

class ConsultationLauncherScreen extends StatefulWidget {
  final String peerId;
  final String peerName;
  final int appointmentId;
  final int consultationId;

  const ConsultationLauncherScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    required this.appointmentId,
    required this.consultationId,
  });

  @override
  State<ConsultationLauncherScreen> createState() =>
      _ConsultationLauncherScreenState();
}

//final String selfCallerID = Random().nextInt(999999).toString().padLeft(6, '0');

class _ConsultationLauncherScreenState
    extends State<ConsultationLauncherScreen> {
  dynamic incomingSDPOffer;

  @override
  void initState() {
    super.initState();
    SocketService().connectSocket();
    // listen for incoming video call
    SignallingService.instance.init(
      websocketUrl: AppConfig.instance()!.socketUrl!,
    );

    SignallingService.instance.socket!.on("newCall", (data) {
      if (mounted) {
        // set SDP Offer of incoming call
        setState(() => incomingSDPOffer = data);
      }
    });
  }

  Future<void> _handlePatientMode(
      BuildContext context, String selectedMode) async {
    try {
      final fullName = await AuthService().getUserFullName();
      final userRole = await AuthService().getUserRole();
      final userId = await AuthService().getUserId();
      final callerName =
          userRole == 'psychiatrist' ? 'Dr. $fullName' : fullName;
      if (selectedMode == 'chat') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              peerId: widget.peerId,
              peerName: widget.peerName,
              appointmentId: widget.appointmentId,
              consultationId: widget.consultationId,
              roomId: 'room-${widget.consultationId}',
            ),
          ),
        );
      } else if (selectedMode == 'video') {
        print('User Id $userId Called Id : ${widget.peerId}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallScreen(
              callerId: userId.toString(),
              calleeId: widget.peerId.toString(),
              isVideoOn: true,
            ),
          ),
        );
      } else if (selectedMode == 'audio') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallScreen(
              callerId: userId.toString(),
              calleeId: widget.peerId.toString(),
              isVideoOn: false,
            ),
          ),
        );
      }
    } catch (e) {
      print("❌ Erreur lancement $selectedMode: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible de démarrer la consultation")),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: const TopBarSubPage(
        title: 'Consultation',
      ),
      body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Consultation avec : ",
                  style: AppThemes.getTextStyle(size: 15)),
              const SizedBox(height: 8),
              Text(widget.peerName,
                  style: AppThemes.getTextStyle(
                      size: 23, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),

              // Patient voit les 3 boutons
              ElevatedButton.icon(
                onPressed: () => _handlePatientMode(context, 'chat'),
                icon:
                    const Icon(Icons.chat_bubble_outline, color: Colors.white),
                label: Text(
                  'Chat sécurisé',
                  style: AppThemes.getTextStyle(
                      clr: AppColors.mypsyBgApp,
                      size: 16,
                      fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _handlePatientMode(context, 'audio'),
                icon: const Icon(Icons.call, color: Colors.white),
                label: Text(
                  'Appel audio',
                  style: AppThemes.getTextStyle(
                      clr: AppColors.mypsyBgApp,
                      size: 16,
                      fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _handlePatientMode(context, 'video'),
                icon: const Icon(Icons.videocam, color: Colors.white),
                label: Text(
                  'Appel vidéo',
                  style: AppThemes.getTextStyle(
                      clr: AppColors.mypsyBgApp,
                      size: 16,
                      fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          )));
}
