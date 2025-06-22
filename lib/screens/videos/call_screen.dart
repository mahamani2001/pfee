import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mypsy_app/resources/services/appointment_service.dart';
import 'package:mypsy_app/resources/services/consultation_service.dart';
import 'package:mypsy_app/resources/services/signalling.service.dart';
import 'package:mypsy_app/screens/consultation/ConsultationEndedScreen.dart';
import 'package:mypsy_app/screens/layouts/top_bar_subpage.dart';
import 'package:mypsy_app/shared/ui/flushbar.dart';
import 'package:mypsy_app/utils/functions.dart';

class CallScreen extends StatefulWidget {
  final String callerId, calleeId;
  final dynamic offer;
  bool isVideoOn;
  bool isPatient;
  final int appointmentId;
  CallScreen(
      {super.key,
      this.offer,
      required this.callerId,
      required this.calleeId,
      this.isVideoOn = true,
      this.isPatient = true,
      required this.appointmentId});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  Duration remainingTime = Duration.zero;
  late DateTime startTime;
  Timer? _timer;
  Duration consultationDuration = const Duration(minutes: 30); // 🔥 initial
  Duration elapsedTime = Duration.zero;
  bool isConsultationEnded = false;
  // socket instance
  final socket = SignallingService.instance.socket;

  // videoRenderer for localPeer
  final _localRTCVideoRenderer = RTCVideoRenderer();

  // videoRenderer for remotePeer
  final _remoteRTCVideoRenderer = RTCVideoRenderer();

  // mediaStream for localPeer
  MediaStream? _localStream;

  // RTC peer connection
  RTCPeerConnection? _rtcPeerConnection;

  // list of rtcCandidates to be sent over signalling
  List<RTCIceCandidate> rtcIceCadidates = [];

  // media status
  bool isAudioOn = true, isFrontCameraSelected = true;
  Future<void> initConsultationTiming() async {
    print("🚀 initConsultationTiming lancé");
    final data =
        await AppointmentService().getAppointmentById(widget.appointmentId);

    if (data != null) {
      try {
        final dateStr = data['date']; // ex: "2025-04-30"
        final timeStr = data['start_time']; // ex: "23:15:00"

        final dateParts = dateStr.split('-');
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);

        final timeParts = timeStr.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        final start = DateTime(year, month, day, hour, minute).toLocal();
        final duration = Duration(minutes: data['duration_minutes']);
        final now = DateTime.now().toLocal();
        final end = start.add(duration);

        bool consultationHasEnded = false;

        if (now.isBefore(start)) {
          consultationHasEnded = false;
          remainingTime = Duration.zero;

          final delay = start.difference(now);
          Future.delayed(delay, () {
            if (!mounted) return;
            startConsultationTimer();
            setState(() {
              remainingTime = duration;
            });
          });
        } else if (now.isBefore(end)) {
          consultationHasEnded = false;
          remainingTime = end.difference(now);
        } else {
          consultationHasEnded = true;
          remainingTime = Duration.zero;
        }

        setState(() {
          startTime = start;
          consultationDuration = duration;
          isConsultationEnded = consultationHasEnded;
        });

        if (consultationHasEnded) {
          if (data['psychiatrist_id'] != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ConsultationEndedScreen(
                  peerName: widget.calleeId,
                  startTime: start,
                  duration: duration,
                  psychiatristId: int.parse(data['psychiatrist_id'].toString()),
                  appointmentId: data['id'],
                ),
              ),
            );
          }
        } else {
          startConsultationTimer();
        }

        print("🕒 START   : $start");
        print("🕒 NOW     : $now");
        print("⏳ DURATION: $duration");
        print("⏳ END     : $end");
        print("⏳ RemainingTime Calculé: $remainingTime");
      } catch (e) {
        print("❌ Erreur parsing date/heure : $e");
      }
    }
  }

  void startConsultationTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      final now = DateTime.now(); // ✅ Heure locale
      final endTime = startTime.add(consultationDuration);

      final remaining = endTime.difference(now);

      if (remaining <= Duration.zero && !isConsultationEnded) {
        _timer?.cancel();
        isConsultationEnded = true; // ⚠️ PAS de setState ici

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ConsultationEndedScreen(
              peerName: widget.calleeId,
              startTime: startTime,
              duration: consultationDuration,
              psychiatristId: int.parse(widget.calleeId),
              appointmentId: widget.appointmentId,
            ),
          ),
        );
      } else {
        setState(() {
          remainingTime = remaining;
          elapsedTime = now.difference(startTime);
        });
      }
    });
  }

  @override
  void initState() {
    // initializing renderers
    _localRTCVideoRenderer.initialize();
    _remoteRTCVideoRenderer.initialize();

    // setup Peer Connection
    _setupPeerConnection();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initConsultationTiming();
    });
    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  _setupPeerConnection() async {
    // create peer connection
    _rtcPeerConnection = await createPeerConnection({
      'iceServers': [
        {
          'urls': [
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302'
          ]
        }
      ]
    });

    // listen for remotePeer mediaTrack event
    _rtcPeerConnection!.onTrack = (event) {
      _remoteRTCVideoRenderer.srcObject = event.streams[0];
      setState(() {});
    };

    // get localStream
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': isAudioOn,
      'video': widget.isVideoOn
          ? {'facingMode': isFrontCameraSelected ? 'user' : 'environment'}
          : false,
    });

    // add mediaTrack to peerConnection
    _localStream!.getTracks().forEach((track) {
      _rtcPeerConnection!.addTrack(track, _localStream!);
    });

    // set source for local video renderer
    _localRTCVideoRenderer.srcObject = _localStream;
    setState(() {});

    // for Incoming call
    if (widget.offer != null) {
      print('we are on widget.offer not nulllllll');
      // listen for Remote IceCandidate
      socket!.on("IceCandidate", (data) {
        String candidate = data["iceCandidate"]["candidate"];
        String sdpMid = data["iceCandidate"]["id"];
        int sdpMLineIndex = data["iceCandidate"]["label"];

        // add iceCandidate
        _rtcPeerConnection!.addCandidate(RTCIceCandidate(
          candidate,
          sdpMid,
          sdpMLineIndex,
        ));
      });

      // set SDP offer as remoteDescription for peerConnection
      await _rtcPeerConnection!.setRemoteDescription(
        RTCSessionDescription(widget.offer["sdp"], widget.offer["type"]),
      );

      // create SDP answer
      RTCSessionDescription answer = await _rtcPeerConnection!.createAnswer();

      // set SDP answer as localDescription for peerConnection
      _rtcPeerConnection!.setLocalDescription(answer);

      // send SDP answer to remote peer over signalling
      socket!.emit("answerCall", {
        "callerId": widget.callerId,
        "sdpAnswer": answer.toMap(),
      });
    }
    // for Outgoing Call
    else {
      // listen for local iceCandidate and add it to the list of IceCandidate
      _rtcPeerConnection!.onIceCandidate =
          (RTCIceCandidate candidate) => rtcIceCadidates.add(candidate);

      // when call is accepted by remote peer
      socket!.on("callAnswered", (data) async {
        // set SDP answer as remoteDescription for peerConnection
        await _rtcPeerConnection!.setRemoteDescription(
          RTCSessionDescription(
            data["sdpAnswer"]["sdp"],
            data["sdpAnswer"]["type"],
          ),
        );

        // send iceCandidate generated to remote peer over signalling
        for (RTCIceCandidate candidate in rtcIceCadidates) {
          socket!.emit("IceCandidate", {
            "calleeId": widget.calleeId,
            "iceCandidate": {
              "id": candidate.sdpMid,
              "label": candidate.sdpMLineIndex,
              "candidate": candidate.candidate
            }
          });
        }
      });

      // create SDP Offer
      RTCSessionDescription offer = await _rtcPeerConnection!.createOffer();

      // set SDP offer as localDescription for peerConnection
      await _rtcPeerConnection!.setLocalDescription(offer);

      // make a call to remote peer over signalling
      socket!.emit('makeCall', {
        "calleeId": widget.calleeId,
        "sdpOffer": offer.toMap(),
      });
    }
  }

  _leaveCall() {
    Navigator.pop(context);
  }

  _toggleMic() {
    // change status
    isAudioOn = !isAudioOn;
    // enable or disable audio track
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = isAudioOn;
    });
    setState(() {});
  }

  _toggleCamera() {
    // change status
    widget.isVideoOn = !widget.isVideoOn;

    // enable or disable video track
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = widget.isVideoOn;
    });
    setState(() {});
  }

  _switchCamera() {
    // change status
    isFrontCameraSelected = !isFrontCameraSelected;

    // switch camera
    _localStream?.getVideoTracks().forEach((track) {
      // ignore: deprecated_member_use
      track.switchCamera();
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    print('okkkk ');
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: TopBarSubPage(
        title: "${widget.isVideoOn ? 'Appel Video' : 'Appel audio'} en cours ",
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(children: [
                RTCVideoView(
                  _remoteRTCVideoRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: SizedBox(
                    height: 150,
                    width: 120,
                    child: RTCVideoView(
                      _localRTCVideoRenderer,
                      mirror: isFrontCameraSelected,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
                if (widget.isPatient == false && !isConsultationEnded)
                  Positioned(
                    top: 30,
                    right: 20,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(Icons.hourglass_bottom,
                                  color: Colors.orange),
                              const SizedBox(width: 8),
                              Text(
                                formatDuration(remainingTime),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: remainingTime.inMinutes <= 5
                                      ? Colors.red
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            width: 100,
                          ),
                          ElevatedButton.icon(
                            onPressed: extendConsultation,
                            icon: const Icon(Icons.add_alarm, size: 18),
                            label: const Text('Prolonger'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 255, 255, 255),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(isAudioOn ? Icons.mic : Icons.mic_off),
                    onPressed: _toggleMic,
                  ),
                  IconButton(
                    icon: const Icon(Icons.call_end),
                    iconSize: 30,
                    onPressed: _leaveCall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.cameraswitch),
                    onPressed: _switchCamera,
                  ),
                  IconButton(
                    icon: Icon(
                        widget.isVideoOn ? Icons.videocam : Icons.videocam_off),
                    onPressed: _toggleCamera,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _localRTCVideoRenderer.dispose();
    _remoteRTCVideoRenderer.dispose();
    _localStream?.dispose();
    _rtcPeerConnection?.dispose();
    super.dispose();
  }

  void extendConsultation() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        height: 300,
        child: Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '⏱️ Prolonger la consultation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(thickness: 1),
              for (int minutes in [5, 10, 15])
                ListTile(
                  leading: const Icon(Icons.access_time, color: Colors.teal),
                  title: Text(
                    'Ajouter $minutes minutes',
                    style: const TextStyle(fontSize: 16),
                  ),
                  onTap: () async {
                    await AppointmentService().extendAppointment(
                      appointmentId: widget.appointmentId,
                      extraMinutes: minutes,
                    );
                    setState(() {
                      consultationDuration += Duration(minutes: minutes);
                    });
                    Navigator.pop(context);
                    customFlushbar(
                        "",
                        '✅ Consultation prolongée de $minutes minutes.',
                        context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
