import 'package:flutter/material.dart';

class AudioCallScreen extends StatelessWidget {
  final String roomId;
  final String peerName;
  final int appointmentId;
  final bool isCaller;

  const AudioCallScreen({
    super.key,
    required this.roomId,
    required this.peerName,
    required this.appointmentId,
    required this.isCaller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Appel audio avec $peerName')),
      body: const Center(child: Text('Appel audio en cours...')),
    );
  }
}
