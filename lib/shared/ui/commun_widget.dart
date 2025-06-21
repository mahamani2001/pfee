import 'package:flutter/material.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';

SizedBox spaceBetween = const SizedBox(
  height: 11,
);
SizedBox spacerSubTitle = const SizedBox(
  height: 15,
);

SizedBox spacerMedium = const SizedBox(
  height: 17,
);

SizedBox spacerLarge = const SizedBox(
  height: 20,
);
SizedBox spacerXLarge = const SizedBox(
  height: 28,
);

SizedBox spaceBetweenInput = const SizedBox(
  height: 14,
);
showComingSoon(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Fonctionnalité en cours'),
      content: const Text('Cette fonctionnalité sera bientôt disponible ! 🎯'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

BoxDecoration mainDecorationBorder = BoxDecoration(
  borderRadius: BorderRadius.circular(12),
  gradient: const LinearGradient(
    colors: [
      AppColors.mypsyPrimary,
      AppColors.mypsyPrimary,
    ],
    stops: [0.1, 0.6],
    begin: Alignment.topLeft,
    end: Alignment.bottomCenter,
  ),
);

BoxDecoration mainDecoration = BoxDecoration(
  borderRadius: BorderRadius.circular(12),
  gradient: const LinearGradient(
    colors: [
      AppColors.mypsyPrimary,
      Color.fromARGB(255, 19, 157, 192),
    ],
    stops: [0.1, 0.6],
    begin: Alignment.topLeft,
    end: Alignment.bottomCenter,
  ),
);
