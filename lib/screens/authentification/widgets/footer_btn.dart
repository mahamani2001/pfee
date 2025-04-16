import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:flutter/material.dart';

class FooterLink extends StatelessWidget {
  final Function onPress;
  final String text;

  const FooterLink({super.key, required this.onPress, required this.text});

  @override
  Widget build(BuildContext context) => Center(
        child: InkWell(
          onTap: onPress as void Function()?,
          child: Text(
            text,
            style: AppThemes.titleFooterLink,
          ),
        ),
      );
}
