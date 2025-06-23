import 'package:flutter/material.dart';
import 'package:mypsy_app/helpers/app_config.dart';
import 'package:mypsy_app/resources/services/signalling.service.dart';
import 'package:mypsy_app/screens/consultation/chatconsultation.dart';
import 'package:mypsy_app/screens/layouts/top_bar_subpage.dart';
import 'package:mypsy_app/screens/videos/call_screen.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';

class ConsultationLauncherScreenPsy extends StatefulWidget {
  final String peerId;
  final String peerName;
  final int appointmentId;
  final String type;
  final int consultId;

  const ConsultationLauncherScreenPsy({
    super.key,
    required this.peerId,
    required this.peerName,
    required this.appointmentId,
    required this.type,
    required this.consultId,
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

    SignallingService.instance.init(
      websocketUrl: AppConfig.instance()!.socketUrl!,
    );
    SignallingService.instance.socket!.on("newCall", (data) {
      if (mounted) {
        setState(() => incomingSDPOffer = data);
      }
    });
  }

  Future<void> _handlePsychiatristJoin(BuildContext context) async {
    try {
      if (widget.type == 'chat') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              peerId: widget.peerId,
              peerName: widget.peerName,
              appointmentId: widget.appointmentId,
              consultationId: widget.consultId,
              roomId: 'room-${widget.consultId}',
            ),
          ),
        );
      } else if (widget.type == 'video') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallScreen(
              callerId: incomingSDPOffer["callerId"].toString(),
              calleeId: widget.peerId,
              offer: incomingSDPOffer["sdpOffer"],
              appointmentId: widget.appointmentId,
              consultationId: widget.consultId,
            ),
          ),
        );
      } else if (widget.type == 'audio') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallScreen(
              callerId: incomingSDPOffer["callerId"].toString(),
              calleeId: widget.peerId,
              offer: incomingSDPOffer["sdpOffer"],
              isVideoOn: false,
              isPatient: false,
              appointmentId: widget.appointmentId,
              consultationId: widget.consultId,
            ),
          ),
        );
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
                  onPressed: () => {
                    (incomingSDPOffer != null || widget.type == 'chat')
                        ? _handlePsychiatristJoin(context)
                        : null
                  },
                  icon: const Icon(Icons.login),
                  label:
                      Text("Rejoindre la consultation en mode  ${widget.type}"),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    textStyle: AppThemes.appbarSubPageTitleStyle,
                    foregroundColor: AppColors.mypsyBgApp,
                    backgroundColor:
                        (incomingSDPOffer != null || widget.type == 'chat')
                            ? AppColors.mypsyDarkBlue
                            : AppColors.mypsyGrey,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (incomingSDPOffer != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Appel depuis ${incomingSDPOffer["callerId"]}"),
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
                                appointmentId: widget.appointmentId,
                                callerId:
                                    incomingSDPOffer["callerId"].toString(),
                                calleeId: widget.peerId,
                                offer: incomingSDPOffer["sdpOffer"],
                                isVideoOn:
                                    widget.type == 'audio' ? false : true,
                                consultationId: widget.consultId,
                              ),
                            ),
                          );
                        },
                      )
                    ],
                  ),
              ]),
            ],
          ),
        ),
      );
}
