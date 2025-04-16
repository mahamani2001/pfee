import 'package:mypsy_app/shared/themes/app_colors.dart';
import 'package:mypsy_app/shared/themes/app_theme.dart';
import 'package:flutter/material.dart';

class TopBarMainPage extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const TopBarMainPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) => AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.mypsyWhite,
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: false,
        title: Text(
          title,
          style: AppThemes.appbarTitleStyle,
        ),
      );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
