import 'package:mypsy_app/screens/layouts/subpage_layout.dart';
import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:mypsy_app/shared/ui/commun_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) => LayoutSubPage(
        withVerticalPadding: false,
        title: 'Contactez-nous',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/hotline.jpg',
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 27,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    style: AppThemes.headerTitleStyle,
                    'Besoin d’aide ? \nContactez-nous ! ',
                  ),
                  spacerMedium,
                  Text(
                    'Une assistance est dédiée pour vous ',
                    style: AppThemes.getTextStyle(fontWeight: FontWeight.w600),
                  ),
                  spaceBetweenInput,
                  const Text(
                    'Vous pouvez nous appeler du lundi au vendredi de 9h à 18h.',
                    style: AppThemes.pStyle,
                  ),
                  spacerXLarge,
                  Center(
                    child: Container(
                      height: 64,
                      width: 64,
                      padding: EdgeInsets.zero,
                      decoration: BoxDecoration(
                        color: AppColors.mypsyPrimary,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/star.svg',
                          width: 40,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
