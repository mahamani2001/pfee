import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:flutter/material.dart';

class HotlineButton extends StatelessWidget {
  const HotlineButton({super.key});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 7),
        padding: const EdgeInsets.only(
          right: 13,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.mypsyWhite, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              padding: const EdgeInsets.all(11),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: const Icon(
                Icons.phone,
                color: Colors.black,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '04 37 72 24 00',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
}
