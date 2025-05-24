import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class TestCallScreen extends StatefulWidget {
  const TestCallScreen({super.key});

  @override
  State<TestCallScreen> createState() => _TestCallScreenState();
}

class _TestCallScreenState extends State<TestCallScreen> {
  final _localRenderer = RTCVideoRenderer();
  MediaStream? _localStream;

  @override
  void initState() {
    super.initState();
    _initLocalCamera();
  }

  Future<void> _initLocalCamera() async {
    await _localRenderer.initialize();
    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'facingMode': 'user',
        'width': 640,
        'height': 480,
      }
    });
    _localRenderer.srcObject = stream;
    setState(() {
      _localStream = stream;
    });
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _localStream?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text("Test WebRTC")),
        body: Center(
          child: _localStream == null
              ? const CircularProgressIndicator()
              : RTCVideoView(_localRenderer),
        ),
      );
}
