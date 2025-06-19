import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/auth_service.dart';
import 'package:mypsy_app/resources/services/consultation_service.dart';
import 'package:mypsy_app/resources/services/signalling.service.dart';
import 'package:mypsy_app/resources/services/socket_service.dart';
import 'package:mypsy_app/screens/consultation/chatconsultation.dart';
import 'package:mypsy_app/screens/layouts/top_bar_subpage.dart';
import 'package:mypsy_app/screens/videos/call_screen.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/commun_widget.dart';

class ConsultationLauncherScreenPsy extends StatefulWidget {
  final String peerId;
  final String peerName;
  final int appointmentId;
  final String mode; // optionnel côté patient

  const ConsultationLauncherScreenPsy({
    super.key,
    required this.peerId,
    required this.peerName,
    required this.appointmentId,
    this.mode = '', // par défaut vide
  });

  @override
  State<ConsultationLauncherScreenPsy> createState() =>
      _ConsultationLauncherScreenPsyState();
}

//final String selfCallerID = Random().nextInt(999999).toString().padLeft(6, '0');

class _ConsultationLauncherScreenPsyState
    extends State<ConsultationLauncherScreenPsy> {
  dynamic incomingSDPOffer;

  @override
  void initState() {
    super.initState();
    print('listing new call');

    // listen for incoming video call
    SignallingService.instance.socket!.on("newCall", (data) {
      if (mounted) {
        // set SDP Offer of incoming call
        setState(() => incomingSDPOffer = data);
      }
    });
  }

  Future<void> _handlePsychiatristJoin(BuildContext context) async {
    try {
      final data =
          await ConsultationService().joinConsultation(widget.appointmentId);
      if (data == null) throw Exception("Consultation introuvable");

      final consultation = data['consultation'];
      final consultationId = consultation['id'];
      final type = consultation['type'];

      if (type == 'chat') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              peerId: widget.peerId,
              peerName: widget.peerName,
              appointmentId: widget.appointmentId,
              consultationId: consultationId,
              roomId: 'room-$consultationId',
            ),
          ),
        );
      } else if (type == 'video') {
        /*Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoCallScreen(
              roomId: 'room-$consultationId',
              peerName: widget.peerName,
              appointmentId: widget.appointmentId,
              consultationId: consultationId,
              isCaller: false,
            ),
          ),
        );*/
      } else if (type == 'audio') {
        showComingSoon(context);
      }
    } catch (e) {
      print("❌ Erreur redirection psy: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Impossible de rejoindre la consultation")),
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
          child: Stack(
            children: [
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text("Consultation avec : ",
                    style: AppThemes.getTextStyle(size: 15)),
                const SizedBox(height: 8),
                Text(widget.peerName,
                    style: AppThemes.getTextStyle(
                        size: 23, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () => _handlePsychiatristJoin(context),
                  icon: const Icon(Icons.login),
                  label: Text("Rejoindre la consultation $incomingSDPOffer"),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    textStyle: AppThemes.appbarSubPageTitleStyle,
                    foregroundColor: AppColors.mypsyBgApp,
                    backgroundColor: AppColors.mypsyDarkBlue,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (incomingSDPOffer != null)
                  Positioned(
                    child: ListTile(
                      title: Text(
                        "Incoming Call from ${incomingSDPOffer["callerId"]}",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.call_end),
                            color: Colors.redAccent,
                            onPressed: () {
                              setState(() => incomingSDPOffer = null);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.call),
                            color: Colors.greenAccent,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CallScreen(
                                    callerId: incomingSDPOffer["callerId"]!,
                                    calleeId: '1004',
                                    offer: incomingSDPOffer["sdpOffer"],
                                  ),
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                  ),
              ]),
            ],
          ),
        ),
      );
}
