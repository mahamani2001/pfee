// custom_error_widget.dart
import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget {
  final String errorMessage;

  const ErrorScreen(
      {super.key,
      this.errorMessage =
          "Une erreur s'est produite. Veuillez réessayer plus tard",});

  @override
  Widget build(BuildContext context) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.black87),
          ),
        ],
      ),
    );
}
