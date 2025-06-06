import 'package:mypsy_app/screens/layouts/subpage_layout.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/commun_widget.dart';
import 'package:flutter/material.dart';

class Reglement extends StatelessWidget {
  final String title;
  final String description;
  const Reglement({super.key, required this.title, required this.description});

  @override
  Widget build(BuildContext context) => LayoutSubPage(
        withVerticalPadding: false,
        title: title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 27,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  spacerMedium,
                  Text(
                    description,
                    style: AppThemes.getTextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
