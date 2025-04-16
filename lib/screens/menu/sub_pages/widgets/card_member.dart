import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class MembershipCard extends StatelessWidget {
  final String icone;
  final String title;
  final String subtitle;
  final List<String> benefits;
  final Color color;
  final bool isLast;

  const MembershipCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.benefits,
    required this.color,
    this.isLast = false,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.only(bottom: 30, right: isLast ? 20 : 0),
        width: MediaQuery.of(context).size.width - 70,
        height: 490,
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: color,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 17),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.mypsyWhite,
                        ),
                        borderRadius: BorderRadius.circular(50)),
                    child: SvgPicture.asset(
                      'assets/icons/$icone.svg',
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Center(
                    child: Text(
                      title,
                      style: AppThemes.getTextStyle(
                        size: 22,
                        clr: AppColors.mypsyWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                subtitle,
                style: AppThemes.getTextStyle(
                  size: 17,
                  clr: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            buildDivider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: benefits
                    .map((benefit) => Padding(
                          padding: const EdgeInsets.only(bottom: 15.0),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: color),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  benefit,
                                  style: AppThemes.getTextStyle(),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      );

  Widget buildDivider() => const Padding(
        padding: EdgeInsets.only(bottom: 15, left: 16, right: 16),
        child: Divider(thickness: 1, color: AppColors.mypsyDivider),
      );
}
