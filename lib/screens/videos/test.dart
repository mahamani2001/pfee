import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mypsy_app/resources/services/signalling.service.dart';
import 'package:mypsy_app/screens/videos/join_screen.dart';

class VideoCallApp extends StatelessWidget {
  final String callerId;
  VideoCallApp({
    Key? key,
    required this.callerId,
  }) : super(key: key);

  // signalling server url
  final String websocketUrl = "http://10.225.1.87:3001";

  @override
  Widget build(BuildContext context) {
    print('Signnnaali to callll heree');
    // init signalling service
    SignallingService.instance.init(
      websocketUrl: websocketUrl,
    );

    // return material app

    return JoinScreen(
      selfCallerId: callerId,
    );
  }
}
