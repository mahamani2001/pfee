import 'package:flutter/material.dart';

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

BoxDecoration mainDecorationBorder = BoxDecoration(
  borderRadius: BorderRadius.circular(12),
  gradient: const LinearGradient(
    colors: [
      Color(0xFF0097E0),
      Color(0xFF139DC0),
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
      Color(0xFF0097E0),
      Color.fromARGB(255, 19, 157, 192),
    ],
    stops: [0.1, 0.6],
    begin: Alignment.topLeft,
    end: Alignment.bottomCenter,
  ),
);
